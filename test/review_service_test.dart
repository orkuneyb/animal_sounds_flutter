import 'package:animal_sounds_flutter/services/review_service.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review_platform_interface/in_app_review_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('ReviewService with a fake platform', () {
    late List<(String, Map<String, Object>?)> events;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      events = [];
      AnalyticsService().setBackend((name, params) async => events.add((name, params)));
    });

    tearDown(() => AnalyticsService().setBackend(null));

    test('logs review_prompted only when the review sheet is shown', () async {
      InAppReviewPlatform.instance = _FakeReviewPlatform(available: true);

      await ReviewService().requestReview(automatic: true);

      expect(events.map((e) => e.$1), ['review_prompted']);
      expect(events.single.$2, {'automatic': 1});
    });

    test('does not log review_prompted when the sheet is unavailable', () async {
      InAppReviewPlatform.instance = _FakeReviewPlatform(available: false);

      await ReviewService().requestReview(automatic: true);

      expect(events, isEmpty);
    });

    test('automatic prompt records its timestamp even if the plugin throws',
        () async {
      InAppReviewPlatform.instance = _FakeReviewPlatform(throws: true);

      await ReviewService().maybeAutoPrompt(5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('review_last_prompt'), isNotNull);
    });
  });
}

class _FakeReviewPlatform extends InAppReviewPlatform
    with MockPlatformInterfaceMixin {
  _FakeReviewPlatform({this.available = true, this.throws = false});

  final bool available;
  final bool throws;

  @override
  Future<bool> isAvailable() async {
    if (throws) throw StateError('plugin down');
    return available;
  }

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing({String? appStoreId, String? microsoftStoreId}) async {}
}
