import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the parent dashboard may ask for a store review automatically.
///
/// Only after the app has been opened at least 5 times, and at most once
/// every 90 days. Google decides whether the system sheet actually appears.
bool shouldAutoPromptReview({
  required int appOpens,
  DateTime? lastPrompt,
  required DateTime now,
}) =>
    appOpens >= 5 &&
    (lastPrompt == null || now.difference(lastPrompt).inDays >= 90);

/// Store review and share actions. Parent-area only; never throws.
class ReviewService {
  static const String storeUrl =
      'https://play.google.com/store/apps/details?id=com.devork.animalsounds';

  static const String _lastPromptKey = 'review_last_prompt';

  /// Opens the in-app review sheet. For a manual request on a device where
  /// the sheet is unavailable, opens the store listing instead.
  Future<void> requestReview({required bool automatic}) async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else if (!automatic) {
        await review.openStoreListing();
      }
      AnalyticsService().reviewPrompted(automatic: automatic);
    } catch (error) {
      debugPrint('Review request failed: $error');
    }
  }

  /// Called when the parent dashboard opens. Records the timestamp before
  /// asking so a slow or failing plugin cannot cause repeated prompts.
  Future<void> maybeAutoPrompt(int appOpens) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMillis = prefs.getInt(_lastPromptKey);
    final lastPrompt = lastMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastMillis);
    final now = DateTime.now();
    if (!shouldAutoPromptReview(
      appOpens: appOpens,
      lastPrompt: lastPrompt,
      now: now,
    )) {
      return;
    }
    await prefs.setInt(_lastPromptKey, now.millisecondsSinceEpoch);
    await requestReview(automatic: true);
  }

  /// Opens the system share sheet with a localized invitation.
  Future<void> share() async {
    AnalyticsService().shareTapped();
    try {
      await SharePlus.instance.share(
        ShareParams(text: 'share_text'.tr(namedArgs: {'url': storeUrl})),
      );
    } catch (error) {
      debugPrint('Share failed: $error');
    }
  }
}
