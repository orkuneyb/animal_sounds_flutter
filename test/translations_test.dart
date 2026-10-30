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
}
