import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release builds run R8. Without these rules R8 strips the generic
/// signature Gson needs, and flutter_local_notifications crashes with
/// "Missing type parameter" whenever it loads scheduled reminders
/// (on every app update, reboot, and every reminder toggle).
void main() {
  final rulesFile = File('android/app/proguard-rules.pro');
  final buildGradle = File('android/app/build.gradle').readAsStringSync();

  group('Android release shrinker rules', () {
    test('build.gradle applies proguard-rules.pro to release builds', () {
      expect(buildGradle, contains("'proguard-rules.pro'"));
    });

    test('keep generic signatures that Gson relies on', () {
      expect(rulesFile.existsSync(), isTrue);
      final rules = rulesFile.readAsStringSync();
      expect(rules, contains('-keepattributes Signature'));
      expect(rules, contains('com.google.gson.reflect.TypeToken'));
      expect(rules, contains('* extends com.google.gson.reflect.TypeToken'));
    });

    test('keep the notification plugin models Gson serializes by reflection', () {
      expect(rulesFile.existsSync(), isTrue);
      expect(
        rulesFile.readAsStringSync(),
        contains('-keep class com.dexterous.flutterlocalnotifications.** { *; }'),
      );
    });
  });
}
