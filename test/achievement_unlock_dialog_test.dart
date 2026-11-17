import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/widgets/achievement_unlock_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RouteCounter extends NavigatorObserver {
  int open = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => open++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => open--;
}

void main() {
  late List<Achievement> achievements;
  late _RouteCounter routes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final provider = AchievementProvider();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    achievements = provider.achievements;
  });

  Future<BuildContext> pumpPage(WidgetTester tester) async {
    late BuildContext pageContext;
    routes = _RouteCounter();
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [routes],
      home: Builder(builder: (context) {
        pageContext = context;
        return const Scaffold(body: Text('page'));
      }),
    ));
    return pageContext;
  }

  int openRoutes(WidgetTester tester) => routes.open;

  testWidgets('a second tap does not close the page underneath',
      (tester) async {
    final context = await pumpPage(tester);
    showAchievementUnlockDialog(context, achievements.first);
    await tester.pump(const Duration(milliseconds: 500));
    expect(openRoutes(tester), 2);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(seconds: 4));

    expect(openRoutes(tester), 1);
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('two celebrations opened together both close on their own',
      (tester) async {
    final context = await pumpPage(tester);
    showAchievementUnlockDialog(context, achievements[0]);
    showAchievementUnlockDialog(context, achievements[1]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(openRoutes(tester), 3);

    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(openRoutes(tester), 1);
    expect(find.text('page'), findsOneWidget);
  });
}
