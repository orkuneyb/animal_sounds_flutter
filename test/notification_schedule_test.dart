import 'package:animal_sounds_flutter/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextLocalInstanceOf', () {
    test('returns today when the time has not passed yet', () {
      final now = DateTime(2026, 10, 6, 9, 0);

      expect(nextLocalInstanceOf(now, 10, 0), DateTime(2026, 10, 6, 10, 0));
    });

    test('returns tomorrow when the time has already passed', () {
      final now = DateTime(2026, 10, 6, 10, 30);

      expect(nextLocalInstanceOf(now, 10, 0), DateTime(2026, 10, 7, 10, 0));
    });

    test('returns tomorrow when the time is exactly now', () {
      final now = DateTime(2026, 10, 6, 10, 0);

      expect(nextLocalInstanceOf(now, 10, 0), DateTime(2026, 10, 7, 10, 0));
    });

    test('rolls over the end of the month', () {
      final now = DateTime(2026, 10, 31, 21, 0);

      expect(nextLocalInstanceOf(now, 20, 0), DateTime(2026, 11, 1, 20, 0));
    });
  });

  group('shouldShowReminderOffer', () {
    test('shows for a fresh install', () {
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: false),
        isTrue,
      );
    });

    test('shows once more for an existing user without reminders', () {
      // has_shown_parent_alert from 1.2.x is deliberately ignored
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: false),
        isTrue,
      );
    });

    test('never shows again after it was shown, even if declined', () {
      expect(
        shouldShowReminderOffer(offerShown: true, dailyReminderEnabled: false),
        isFalse,
      );
    });

    test('does not show to users who already enabled reminders in Settings', () {
      expect(
        shouldShowReminderOffer(offerShown: false, dailyReminderEnabled: true),
        isFalse,
      );
    });
  });
}
