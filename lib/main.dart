import 'package:animal_sounds_flutter/pages/home.dart';
import 'package:animal_sounds_flutter/pages/settings.dart';
import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: themeColor,
        ),
        initialRoute: "/homePage",
        routes: {
          '/homePage': (context) => const HomePage(),
          // '/animalDetails': (context) => const AnimalDetailsPage(),
          '/settingsPage': (context) => const SettingsPage(),
        },
        home: const HomePage(),
      ),
    );
  }
}
