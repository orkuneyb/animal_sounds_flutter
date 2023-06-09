import 'package:animal_sounds_flutter/pages/home.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: themeColor),
      home: const HomePage(),
    );
  }
}
