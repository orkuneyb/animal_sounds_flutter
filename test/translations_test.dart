import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String locale) {
  final file = File('assets/translations/$locale.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  const locales = [
    'en-US',
    'tr-TR',
    'ru-RU',
    'pt-BR',
    'hi-IN',
    'es-ES',
    'ar-SA',
    'de-DE',
  ];

  final reference = _load('en-US');

  for (final locale in locales) {
    test('$locale has the same keys as en-US', () {
      expect(_load(locale).keys.toSet(), reference.keys.toSet());
    });
  }

  test('parent alert no longer claims the app needs internet', () {
    expect(
      reference['parent_alert_content'],
      isNot(contains('Requires internet connection')),
    );
  });

  test('reminder offer keys exist', () {
    expect(reference, containsPair('reminder_offer_accept', isNotEmpty));
    expect(reference, containsPair('reminder_offer_decline', isNotEmpty));
    expect(reference['parent_alert_content'], contains('daily reminder'));
  });

  test('rate and share keys exist and share_text carries the url placeholder', () {
    expect(reference, containsPair('rate_app', isNotEmpty));
    expect(reference, containsPair('share_app', isNotEmpty));
    expect(reference['share_text'], contains('{url}'));
  });

  test('remove-ads keys exist in every locale', () {
    for (final key in [
      'remove_ads', 'remove_ads_short', 'remove_ads_title', 'benefit_no_banners',
      'benefit_no_interstitials', 'benefit_free_rewards',
      'one_time_note', 'restore_purchases', 'restore_success',
      'restore_nothing_found', 'store_unavailable', 'purchase_pending',
      'purchase_failed', 'ads_removed_thanks', 'purchases', 'promo_title',
      'promo_body', 'retry', 'premium_hint', 'premium_extra_life',
      'premium_double_score', 'premium_fun_fact', 'premium_achievement_hint',
      'premium_reward',
    ]) {
      expect(reference, containsPair(key, isNotEmpty), reason: key);
    }
  });
}
