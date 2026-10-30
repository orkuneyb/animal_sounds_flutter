import 'package:flutter/foundation.dart';

/// Sends one event to whatever analytics backend is plugged in.
typedef AnalyticsBackend = Future<void> Function(
  String name,
  Map<String, Object>? parameters,
);

/// Single entry point for product analytics.
///
/// The backend is injected (see `main.dart`) so the app, and every test,
/// runs without Firebase. Calls are fire-and-forget and never throw.
/// Parameters are limited to strings and numbers; booleans are sent as 1/0
/// because Firebase Analytics does not accept bool parameters.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService _instance = AnalyticsService._();

  factory AnalyticsService() => _instance;

  AnalyticsBackend? _backend;

  void setBackend(AnalyticsBackend? backend) => _backend = backend;

  void logEvent(String name, [Map<String, Object>? parameters]) {
    final backend = _backend;
    if (backend == null) return;
    try {
      backend(name, parameters).catchError((Object error) {
        debugPrint('Analytics event "$name" failed: $error');
      });
    } catch (error) {
      debugPrint('Analytics event "$name" failed: $error');
    }
  }

  // --- Named events (keep in sync with the spec's event table) ---

  void soundPlayed(String animal) => logEvent('sound_played', {'animal': animal});

  void dailyDiscoveryCompleted(int streak) =>
      logEvent('daily_discovery_completed', {'streak': streak});

  void quizCompleted(int score) => logEvent('quiz_completed', {'score': score});

  void soundGameOver(int score) => logEvent('sound_game_over', {'score': score});

  void reminderOfferShown() => logEvent('reminder_offer_shown');

  void reminderOfferAccepted() => logEvent('reminder_offer_accepted');

  void reminderOfferDeclined() => logEvent('reminder_offer_declined');

  void notificationPermission(bool granted) =>
      logEvent('notification_permission', {'granted': granted ? 1 : 0});

  void rewardedAdWatched(String placement) =>
      logEvent('rewarded_ad_watched', {'placement': placement});

  void parentDashboardOpened() => logEvent('parent_dashboard_opened');

  void reviewPrompted({required bool automatic}) =>
      logEvent('review_prompted', {'automatic': automatic ? 1 : 0});

  void shareTapped() => logEvent('share_tapped');
}
