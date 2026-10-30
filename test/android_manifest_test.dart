import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  group('AndroidManifest', () {
    test('registers the receiver that shows scheduled notifications', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
    });

    test('registers the receiver that restores reminders after a reboot', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
        ),
      );
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('does not request the advertising ID permission', () {
      final adIdPermission = RegExp(
        r'<uses-permission[^>]*com\.google\.android\.gms\.permission\.AD_ID[^>]*>',
      ).firstMatch(manifest);

      expect(adIdPermission, isNotNull);
      expect(adIdPermission!.group(0), contains('tools:node="remove"'));
    });

    test('disables advertising-ID collection and ad personalization for Analytics', () {
      expect(
        manifest,
        contains(
          '<meta-data android:name="google_analytics_adid_collection_enabled" android:value="false" />',
        ),
      );
      expect(
        manifest,
        contains(
          '<meta-data android:name="google_analytics_default_allow_ad_personalization_signals" android:value="false" />',
        ),
      );
    });
  });
}
