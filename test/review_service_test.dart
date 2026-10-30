import 'package:animal_sounds_flutter/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 30);

  group('shouldAutoPromptReview', () {
    test('waits until the app was opened 5 times', () {
      expect(shouldAutoPromptReview(appOpens: 4, lastPrompt: null, now: now), isFalse);
      expect(shouldAutoPromptReview(appOpens: 5, lastPrompt: null, now: now), isTrue);
    });

    test('does not prompt again within 90 days', () {
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      expect(
        shouldAutoPromptReview(appOpens: 50, lastPrompt: thirtyDaysAgo, now: now),
        isFalse,
      );
    });

    test('prompts again after 90 days', () {
      final ninetyOneDaysAgo = now.subtract(const Duration(days: 91));

      expect(
        shouldAutoPromptReview(appOpens: 50, lastPrompt: ninetyOneDaysAgo, now: now),
        isTrue,
      );
    });
  });

  test('store URL points at this app', () {
    expect(ReviewService.storeUrl, endsWith('id=com.devork.animalsounds'));
  });
}
