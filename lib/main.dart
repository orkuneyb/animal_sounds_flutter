import 'package:animal_sounds_flutter/pages/home.dart';
import 'package:animal_sounds_flutter/pages/settings.dart';
import 'package:animal_sounds_flutter/providers/category_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/providers/search_provider.dart';
import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();

  runApp(EasyLocalization(
    supportedLocales: const [Locale('en', 'US'), Locale('tr', 'TR')],
    path: 'assets/translations',
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> showParentAlert(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownAlert = prefs.getBool('has_shown_parent_alert') ?? false;

    if (!hasShownAlert) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('parent_alert_title'.tr()),
            content: Text('parent_alert_content'.tr()),
            actions: [
              TextButton(
                child: Text('parent_alert_button'.tr()),
                onPressed: () {
                  Navigator.pop(context);
                  prefs.setBool('has_shown_parent_alert', true);
                },
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => "app_name".tr(),
        theme: ThemeData(
          primarySwatch: themeColor,
        ),
        initialRoute: "/homePage",
        routes: {
          '/homePage': (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showParentAlert(context);
            });
            return const HomePage();
          },
          '/settingsPage': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
