import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<(String, Map<String, Object>?)> captured;

  setUp(() {
    captured = [];
    AnalyticsService().setBackend((name, params) async {
      captured.add((name, params));
    });
  });

  tearDown(() => AnalyticsService().setBackend(null));

  test('forwards events to the backend', () {
    AnalyticsService().logEvent('sound_played', {'animal': 'lion'});

    expect(captured.single.$1, 'sound_played');
    expect(captured.single.$2, {'animal': 'lion'});
  });

  test('named helpers use the event names from the spec', () {
    final service = AnalyticsService();
    service.soundPlayed('cow');
    service.dailyDiscoveryCompleted(3);
    service.quizCompleted(4);
    service.soundGameOver(7);
    service.reminderOfferShown();
    service.reminderOfferAccepted();
    service.reminderOfferDeclined();
    service.notificationPermission(true);
    service.rewardedAdWatched('quiz_hint');
    service.parentDashboardOpened();
    service.reviewPrompted(automatic: false);
    service.shareTapped();

    expect(captured.map((e) => e.$1).toList(), [
      'sound_played',
      'daily_discovery_completed',
      'quiz_completed',
      'sound_game_over',
      'reminder_offer_shown',
      'reminder_offer_accepted',
      'reminder_offer_declined',
      'notification_permission',
      'rewarded_ad_watched',
      'parent_dashboard_opened',
      'review_prompted',
      'share_tapped',
    ]);
    expect(captured[1].$2, {'streak': 3});
    expect(captured[7].$2, {'granted': 1});
    expect(captured[10].$2, {'automatic': 0});
  });

  test('a throwing backend does not propagate', () async {
    AnalyticsService().setBackend((_, __) => Future.error(StateError('down')));

    expect(() => AnalyticsService().logEvent('sound_played'), returnsNormally);
    await Future<void>.delayed(Duration.zero); // let the error surface if it was going to
  });

  test('without a backend events are dropped silently', () {
    AnalyticsService().setBackend(null);

    expect(() => AnalyticsService().logEvent('sound_played'), returnsNormally);
    expect(captured, isEmpty);
  });
}
