// Renders real app screens to PNG files for the Play Store listing.
//
// Run from the project root:
//   flutter test scripts/store_assets/capture_test.dart --dart-define=SHOT_LOCALE=en-US
//
// Output: build/store_assets/raw/<locale>/<name>.png (1080x2340).
// No device or emulator is needed; plugins are stubbed.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:animal_sounds_flutter/main.dart';
import 'package:animal_sounds_flutter/pages/achievements_page.dart';
import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/pages/animal_sound_page.dart';
import 'package:animal_sounds_flutter/pages/collection_page.dart';
import 'package:animal_sounds_flutter/pages/coloring_page.dart';
import 'package:animal_sounds_flutter/pages/compare_page.dart';
import 'package:animal_sounds_flutter/pages/daily_discovery_page.dart';
import 'package:animal_sounds_flutter/pages/quiz_page.dart';
import 'package:animal_sounds_flutter/pages/sound_guess_game_page.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/sound_library.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeTag = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'en-US');
const _steps = String.fromEnvironment('SHOT_STEPS', defaultValue: 'home');

/// The animal shown on the sound and info screens (SHOT_ANIMAL=squirrel).
const _animal = String.fromEnvironment('SHOT_ANIMAL', defaultValue: 'lion');

const double _dpr = 2.75;
const Size _physical = Size(1080, 2340);

final _boundaryKey = GlobalKey();

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

String _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  return File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
}

/// Answers every plugin channel with null so missing native code never throws.
void _stubPlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channels = <String>[
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'flutter_tts',
    'plugins.flutter.io/google_mobile_ads',
    'dexterous.com/flutter/local_notifications',
    'plugins.flutter.io/path_provider',
    'dev.fluttercommunity.plus/package_info',
    'dev.britannio.in_app_review',
    'com.devork.animalsounds/recorder',
    'plugins.flutter.io/firebase_analytics',
    'plugins.flutter.io/firebase_core',
    'plugins.flutter.io/firebase_crashlytics',
    'com.spencerccf.app_settings/methods',
  ];
  for (final name in channels) {
    messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
      if (call.method == 'getTemporaryDirectory' ||
          call.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      if (call.method == 'initialize') return true;
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'Animal Sounds',
          'packageName': 'com.devork.animalsounds',
          'version': '1.5.0',
          'buildNumber': '13',
        };
      }
      return null;
    });
  }
  // Channels created at runtime (one event channel per audio player) cannot
  // be listed up front, so every unhandled plugin message gets an empty reply.
  messenger.allMessagesHandler = (channel, handler, message) async {
    if (handler != null) return handler(message);
    if (channel.startsWith('flutter/')) return null;
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  };
}

Future<void> _settle(WidgetTester tester, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _shoot(WidgetTester tester, String name) async {
  // Decode every asset image currently in the tree before painting.
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  await tester.runAsync(() async {
    for (final image in images) {
      final element = tester.element(find.byWidget(image).first);
      try {
        await precacheImage(image.image, element);
      } catch (_) {}
    }
  });
  await _settle(tester, 4);

  final boundary = _boundaryKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  final dir = Directory('build/store_assets/raw/$_localeTag')
    ..createSync(recursive: true);
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: _dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('shot: $_localeTag/$name');
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A lived-in profile, so the shots show progress instead of empty states.
Map<String, Object> _seedPrefs() {
  final now = DateTime.now();
  const discovered = [0, 1, 2, 3, 4, 5, 7, 8, 11, 14, 17, 20, 21, 25];
  return <String, Object>{
    'reminder_offer_shown': true,
    'ads_removed': true,
    'sound_guess_high_score': 12,
    'animal_discoveries': jsonEncode({
      for (final id in discovered)
        '$id': {
          'animalId': id,
          'soundListened': true,
          'infoVisited': true,
          'discoveredAt': now.toIso8601String(),
        },
    }),
    'favorites': jsonEncode([
      for (final id in const [0, 14, 21])
        {'animalId': id, 'addedDate': now.toIso8601String()},
    ]),
    'daily_streak_data': jsonEncode({
      'currentStreak': 5,
      'longestStreak': 5,
      'totalDays': 5,
      'lastVisitDate': now.toIso8601String(),
      'todayCompleted': false,
    }),
    'daily_completed_days': jsonEncode([
      for (var i = 1; i <= 4; i++) _dayKey(now.subtract(Duration(days: i))),
    ]),
  };
}

void main() {
  testWidgets('capture store screenshots', (tester) async {
    final parts = _localeTag.split('-');
    final locale = Locale(parts[0], parts[1]);

    tester.view.physicalSize = _physical;
    tester.view.devicePixelRatio = _dpr;
    addTearDown(tester.view.reset);

    _stubPlugins();
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    // Layout hints and plugin stubs raise debug-only errors that do not
    // affect the rendered frames; keep them from failing the run.
    final reportError = FlutterError.onError;
    FlutterError.onError = (_) {};
    GoogleFonts.config.allowRuntimeFetching = false;
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(_seedPrefs());

    final root = _flutterRoot();
    await tester.runAsync(() async {
      await _loadFont('MaterialIcons', [
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ]);
      await _loadFont('Nunito', [
        for (final w in const [
          'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'
        ])
          'assets/google_fonts/Nunito-$w.ttf',
      ]);
      await EasyLocalization.ensureInitialized();
      await SoundLibrary.load();
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(RepaintBoundary(
        key: _boundaryKey,
        child: EasyLocalization(
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('tr', 'TR'),
            Locale('ru', 'RU'),
            Locale('pt', 'BR'),
            Locale('hi', 'IN'),
            Locale('es', 'ES'),
            Locale('ar', 'SA'),
            Locale('de', 'DE'),
          ],
          path: 'assets/translations',
          startLocale: locale,
          saveLocale: false,
          child: const MyApp(),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await _settle(tester);

    final steps = _steps.split(',');
    bool want(String s) => steps.contains('all') || steps.contains(s);
    NavigatorState nav() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> page(String step, String name, Widget Function() build,
        {Future<void> Function()? before}) async {
      if (!want(step)) return;
      nav().push(MaterialPageRoute<void>(builder: (_) => build()));
      await _settle(tester);
      // Close an achievement celebration if one opened over the page.
      await _settle(tester, 10);
      nav().popUntil((route) => route is MaterialPageRoute);
      await _settle(tester, 6);
      if (before != null) await before();
      await _shoot(tester, name);
      nav().popUntil((route) => route.isFirst);
      await _settle(tester, 6);
    }

    Future<void> tab(String step, String name, IconData icon) async {
      if (!want(step)) return;
      await tester.tap(find.byIcon(icon).last);
      await _settle(tester);
      await _shoot(tester, name);
    }

    final lion = AnimalRepository.animals.firstWhere((a) => a.name == _animal);
    final elephant =
        AnimalRepository.animals.firstWhere((a) => a.name == 'elephant');

    if (want('home')) await _shoot(tester, '01_home');
    await page('sound', '02_sound', () => AnimalSoundPage(animal: lion));
    await page('info', '03_info', () => AnimalInfoPage(animal: lion));
    await page('quiz', '04_quiz', () => const QuizPage());
    await page('guess', '05_guess', () => const SoundGuessGamePage());
    await page('compare', '06_compare', () => const ComparePage(),
        before: () async {
      for (final pick in const [1, 0]) {
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await _settle(tester, 8);
        final target = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate((w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  AnimalRepository.animals[pick].imagePath),
        );
        await tester.tap(target.first);
        await _settle(tester, 10);
      }
    });
    await page('coloring', '07_coloring', () => ColoringPage(animal: elephant));
    await page('daily', '08_daily', () => const DailyDiscoveryPage());
    await page('collection', '09_collection', () => const CollectionPage());
    await page(
        'achievements', '10_achievements', () => const AchievementsPage());
    await tab('explore', '11_explore', Icons.explore_outlined);
    await tab('games', '12_games', Icons.sports_esports_outlined);
    await tab('profile', '13_profile', Icons.person_outlined);

    // Plugin stubs make some background futures fail; they are irrelevant to
    // the rendered frames, so drain them instead of failing the run.
    await _settle(tester, 4);
    FlutterError.onError = reportError;
    while (tester.takeException() != null) {}
  });
}
