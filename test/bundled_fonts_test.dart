import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nunito ships inside the app so google_fonts never fetches it over the
/// network (the 1.3.x offline "Failed to load font" errors).
void main() {
  const weights = ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'];

  for (final weight in weights) {
    test('Nunito-$weight.ttf is bundled', () {
      final file = File('assets/google_fonts/Nunito-$weight.ttf');
      expect(file.existsSync(), isTrue, reason: '${file.path} missing');
      expect(file.lengthSync(), greaterThan(100000));
    });
  }

  test('pubspec lists the google_fonts asset folder', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/google_fonts/'),
    );
  });

  test('runtime font fetching is disabled at startup', () {
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('GoogleFonts.config.allowRuntimeFetching = false'),
    );
  });
}
