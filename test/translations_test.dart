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
}
