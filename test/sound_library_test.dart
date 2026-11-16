import 'dart:io';

import 'package:animal_sounds_flutter/providers/game_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/sound_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An animal can be in the app before its sound is added. It must then stay
/// silent everywhere: no crash, and never another animal's sound.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final name in const [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  tearDown(() => SoundLibrary.setForTest(null));

  test('before the list is read every animal counts as having a sound', () {
    SoundLibrary.setForTest(null);
    expect(AnimalRepository.withSound, hasLength(AnimalRepository.animals.length));
  });

  test('the bundled list matches the sound files on disk', () async {
    await SoundLibrary.load();
    for (final animal in AnimalRepository.animals) {
      expect(animal.hasSound, File(animal.soundPath).existsSync(),
          reason: animal.name);
    }
  });

  test('an animal without a file has no sound', () {
    SoundLibrary.setForTest({'lion', 'cat'});
    final lion = AnimalRepository.animals.firstWhere((a) => a.name == 'lion');
    final dog = AnimalRepository.animals.firstWhere((a) => a.name == 'dog');
    expect(lion.hasSound, isTrue);
    expect(dog.hasSound, isFalse);
    expect([for (final a in AnimalRepository.withSound) a.name], ['lion', 'cat']);
  });

  test('Guess the Sound only asks for animals that have a sound', () {
    SoundLibrary.setForTest({'lion', 'cat'});
    final game = GameProvider();
    for (var round = 0; round < 200; round++) {
      game.pickNextRound();
      expect(['lion', 'cat'], contains(game.correctAnimal!.name));
      expect(game.currentOptions, hasLength(4));
      expect({for (final a in game.currentOptions) a.index}, hasLength(4));
      expect(game.currentOptions, contains(game.correctAnimal));
    }
  });

  test('playing a silent animal in the game does nothing', () async {
    SoundLibrary.setForTest({'lion'});
    final game = GameProvider()..pickNextRound();
    SoundLibrary.setForTest(<String>{});
    await game.playSound();
    expect(game.isPlaying, isFalse);
  });
}
