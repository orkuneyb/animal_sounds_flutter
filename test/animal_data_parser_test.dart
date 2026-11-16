import 'dart:convert';
import 'dart:io';

import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/animal_data_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> texts(String language) => jsonDecode(
      File('assets/translations/$language.json').readAsStringSync(),
    ) as Map<String, dynamic>;

void main() {
  group('units', () {
    test('grams become kilograms at any size', () {
      expect(AnimalDataParser.parseWeight('20-30 g'), closeTo(0.025, 0.0001));
      expect(AnimalDataParser.parseWeight('200-600 g'), closeTo(0.4, 0.0001));
      expect(AnimalDataParser.parseWeight('30-65 kg'), 47.5);
      expect(AnimalDataParser.parseWeight('20-30 г'), closeTo(0.025, 0.0001));
      expect(AnimalDataParser.parseWeight('30-65 кг'), 47.5);
    });

    test('centimetres stay, metres are converted', () {
      expect(AnimalDataParser.parseSize('Length: 7-10 cm'), 8.5);
      expect(AnimalDataParser.parseSize('Height: 1.2-1.5 m'), 135);
      expect(AnimalDataParser.parseSize('Длина: 7-10 см'), 8.5);
      expect(AnimalDataParser.parseSize('Males: 1.7-2.5 meters in length'), 210);
    });
  });

  // The compare screen draws bars from these numbers; zero or absurd values
  // would show an empty or a full bar.
  for (final language in const ['en-US', 'tr-TR', 'de-DE', 'es-ES', 'pt-BR']) {
    test('every animal has plausible numbers in $language', () {
      final t = texts(language);
      for (final animal in AnimalRepository.animals) {
        final size = AnimalDataParser.parseSize(t[animal.size] as String);
        final weight = AnimalDataParser.parseWeight(t[animal.weight] as String);
        final life = AnimalDataParser.parseLifespan(t[animal.lifespan] as String);
        expect(size, inInclusiveRange(0.5, 3500),
            reason: '$language ${animal.name} size "${t[animal.size]}"');
        // An ant weighs a few milligrams.
        expect(weight, inInclusiveRange(0.000001, 200000),
            reason: '$language ${animal.name} weight "${t[animal.weight]}"');
        expect(life, inInclusiveRange(0.05, 120),
            reason: '$language ${animal.name} lifespan "${t[animal.lifespan]}"');
      }
    });
  }

  test('small animals weigh less than big ones in every Latin-script language',
      () {
    for (final language in const ['en-US', 'tr-TR', 'de-DE', 'es-ES', 'pt-BR']) {
      final t = texts(language);
      double kg(String name) =>
          AnimalDataParser.parseWeight(t['${name}_weight'] as String);
      expect(kg('mouse'), lessThan(kg('squirrel')), reason: language);
      expect(kg('squirrel'), lessThan(kg('goat')), reason: language);
      expect(kg('parrot'), lessThan(kg('donkey')), reason: language);
    }
  });
}
