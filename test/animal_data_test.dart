import 'dart:convert';
import 'dart:io';

import 'package:animal_sounds_flutter/models/animal_traits.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the one animal list: every animal must ship complete, and the
/// saved ids of the first release must never move.
void main() {
  final animals = AnimalRepository.animals;
  const languages = [
    'en-US', 'tr-TR', 'ru-RU', 'pt-BR', 'hi-IN', 'es-ES', 'ar-SA', 'de-DE', //
  ];

  test('the first 30 animals keep their saved ids', () {
    const original = [
      'lion', 'elephant', 'tiger', 'dog', 'cat', 'cow', 'horse', 'rooster',
      'duck', 'pig', 'sheep', 'monkey', 'gorilla', 'penguin', 'dolphin',
      'whale', 'zebra', 'giraffe', 'crocodile', 'snake', 'owl', 'frog', 'bee',
      'bear', 'wolf', 'koala', 'kangaroo', 'camel', 'cheetah', 'fox', //
    ];
    expect([for (final a in animals.take(30)) a.name], original);
    expect([for (final a in animals) a.index],
        List.generate(animals.length, (i) => i));
  });

  test('names are unique', () {
    expect({for (final a in animals) a.name}, hasLength(animals.length));
  });

  test('every animal has a picture', () {
    for (final animal in animals) {
      expect(File(animal.imagePath).existsSync(), isTrue,
          reason: '${animal.imagePath} missing');
    }
  });

  // Animals added later may wait for their sound (see SoundLibrary); the
  // fifty that shipped with one must never lose it.
  test('the first 50 animals keep their sounds', () {
    for (final animal in animals.take(50)) {
      expect(File(animal.soundPath).existsSync(), isTrue,
          reason: '${animal.soundPath} missing');
    }
  });

  test('every sound file belongs to an animal', () {
    final names = {for (final a in animals) a.name};
    for (final file in Directory('assets/animal_sounds').listSync()) {
      final name = file.uri.pathSegments.last.replaceFirst('.mp3', '');
      expect(names, contains(name), reason: '${file.path} matches no animal');
    }
  });

  test('every credit names a known animal, an author and a licence', () {
    final credits = jsonDecode(File('assets/credits.json').readAsStringSync())
        as List<dynamic>;
    final names = {for (final a in animals) a.name};
    final seen = <String>{};
    for (final credit in credits.cast<Map<String, dynamic>>()) {
      final id = '${credit['animal']}/${credit['kind']}';
      expect(names, contains(credit['animal']), reason: id);
      expect(['image', 'sound'], contains(credit['kind']), reason: id);
      expect((credit['author'] as String).trim(), isNotEmpty, reason: id);
      expect((credit['license'] as String).trim(), isNotEmpty, reason: id);
      // Share-alike and non-commercial licences are not accepted.
      expect(credit['license'], isNot(matches(RegExp(r'SA|NC|ND'))),
          reason: id);
      if ((credit['license'] as String).startsWith('CC BY')) {
        expect(credit['license_url'], startsWith('http'), reason: id);
      }
      expect(seen.add(id), isTrue, reason: '$id listed twice');
    }
  });

  for (final language in languages) {
    test('every animal text exists in $language', () {
      final texts = jsonDecode(
        File('assets/translations/$language.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final names = texts['animal_names'] as Map<String, dynamic>;
      for (final animal in animals) {
        final keys = [
          animal.name,
          animal.description,
          animal.size,
          animal.weight,
          animal.lifespan,
          animal.habitat,
          animal.diet,
          ...animal.funFacts,
          animal.home.labelKey,
          animal.food.labelKey,
          animal.bigness.labelKey,
          animal.group.labelKey,
        ];
        for (final key in keys) {
          expect(texts[key], isA<String>(), reason: '$language lacks $key');
          expect((texts[key] as String).trim(), isNotEmpty,
              reason: '$language has an empty $key');
        }
        expect(names[animal.name], isA<String>(),
            reason: '$language lacks animal_names.${animal.name}');
      }
    });
  }

  test('every group has at least two animals', () {
    for (final group in AnimalGroup.values) {
      expect(AnimalRepository.inGroup(group).length, greaterThanOrEqualTo(2),
          reason: '$group is nearly empty');
    }
  });
}
