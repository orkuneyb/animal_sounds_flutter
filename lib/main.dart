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
          '/homePage': (context) => const HomePage(),
          // '/animalDetails': (context) => const AnimalDetailsPage(),
          '/settingsPage': (context) => const SettingsPage(),
        },
      ),
    );
  }
}
