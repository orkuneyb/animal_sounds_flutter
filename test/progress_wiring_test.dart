import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/models/weekly_challenge.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/game_provider.dart';
import 'package:animal_sounds_flutter/providers/progress_wiring.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Providers load from SharedPreferences in their constructors.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

WeeklyChallenge challenge(String template, int target) => WeeklyChallenge(
      id: '${template}_w46',
      titleKey: 't',
      descriptionKey: 'd',
      type: 'unused',
      target: target,
      iconCodePoint: 0,
    );

Future<ChallengeProvider> challengesWith(List<WeeklyChallenge> list) async {
  final provider = ChallengeProvider();
  await settle();
  provider.setChallengesForTesting(list);
  return provider;
}

// Animal indexes used below.
const lion = 0, dog = 3, cow = 5, horse = 6, rooster = 7, dolphin = 14;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // GameProvider owns an AudioPlayer; answer its channels with nothing.
    for (final name in const [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });

  group('AchievementProvider.setProgress', () {
    test('raises progress to the value and never lowers it', () async {
      final achievements = AchievementProvider();
      await settle();

      await achievements.setProgress('collector', 4);
      expect(achievements.getProgress('collector'), 4);

      await achievements.setProgress('collector', 2);
      expect(achievements.getProgress('collector'), 4);
    });

    test('unlocks exactly when the target is reached', () async {
      final achievements = AchievementProvider();
      await settle();

      expect(await achievements.setProgress('week_streak', 6), isFalse);
      expect(await achievements.setProgress('week_streak', 7), isTrue);
    });
  });

  test('the 7-day streak badge needs 7 days, not 4', () async {
    final achievements = AchievementProvider();
    final daily = DailyProvider()..setAchievementProvider(achievements);
    await settle();

    await daily.completeDailyDiscovery();
    await settle();

    expect(achievements.getProgress('week_streak'), 1);
    expect(achievements.getProgress('month_streak'), 1);
  });

  test('discovery counts distinct animals, not repeated plays', () async {
    final discovery = DiscoveryProvider();
    await settle();

    await discovery.markSoundListened(0);
    await discovery.markSoundListened(0);
    await discovery.markSoundListened(1);
    await discovery.markInfoVisited(0);

    expect(discovery.soundListenedCount, 2);
    expect(discovery.infoVisitedCount, 1);
  });

  group('weekly challenges count what their description says', () {
    test('farm sounds: only farm animals, each once', () async {
      final farm = challenge('listen_farm_5', 5);
      final challenges = await challengesWith([farm]);

      challenges.recordEvent('listen', animalId: lion);
      challenges.recordEvent('listen', animalId: cow);
      challenges.recordEvent('listen', animalId: cow);
      challenges.recordEvent('listen', animalId: horse);

      expect(farm.progress, 2);
    });

    test('sounds total counts every play; different animals counts once',
        () async {
      final total = challenge('listen_15_total', 15);
      final different = challenge('listen_10_diff', 10);
      final challenges = await challengesWith([total, different]);

      challenges.recordEvent('listen', animalId: dog);
      challenges.recordEvent('listen', animalId: dog);

      expect(total.progress, 2);
      expect(different.progress, 1);
    });

    test('bird lover needs a bird', () async {
      final bird = challenge('fav_bird', 1);
      final challenges = await challengesWith([bird]);

      challenges.recordEvent('favorite', animalId: dolphin);
      expect(bird.progress, 0);

      challenges.recordEvent('favorite', animalId: rooster);
      expect(bird.isCompleted, isTrue);
    });

    test('quiz challenges check score and hints', () async {
      final any = challenge('complete_quiz_3', 3);
      final perfect = challenge('perfect_quiz', 1);
      final noHint = challenge('quiz_no_hint', 1);
      final good = challenge('quiz_good_2', 2);
      final challenges = await challengesWith([any, perfect, noHint, good]);

      challenges.recordEvent('quiz', correct: 3, total: 5, usedHint: true);

      expect(any.progress, 1);
      expect(perfect.progress, 0);
      expect(noHint.progress, 0);
      expect(good.progress, 0);

      challenges.recordEvent('quiz', correct: 5, total: 5);

      expect(any.progress, 2);
      expect(perfect.progress, 1);
      expect(noHint.progress, 1);
      expect(good.progress, 1);
    });

    test('sound guess pro needs a score of 10', () async {
      final play = challenge('play_game_3', 3);
      final pro = challenge('game_score_10', 1);
      final challenges = await challengesWith([play, pro]);

      challenges.recordEvent('game', score: 4);
      expect(play.progress, 1);
      expect(pro.progress, 0);

      challenges.recordEvent('game', score: 10);
      expect(pro.progress, 1);
    });

    test('seen animals survive a save and reload', () {
      final farm = challenge('listen_farm_5', 5)..seenAnimals.add(cow);
      final restored = WeeklyChallenge.fromJson(farm.toJson());

      expect(restored.seenAnimals, {cow});
    });
  });

  test('wireProgress links favourites and quizzes to badges and challenges',
      () async {
    final achievements = AchievementProvider();
    final favorites = FavoritesProvider();
    final quiz = QuizProvider();
    final favChallenge = challenge('add_fav_3', 3);
    final quizChallenge = challenge('complete_quiz_3', 3);
    final challenges = await challengesWith([favChallenge, quizChallenge]);
    wireProgress(
      achievements: achievements,
      challenges: challenges,
      favorites: favorites,
      discovery: DiscoveryProvider(),
      quiz: quiz,
      game: GameProvider(),
    );
    await settle();

    await favorites.toggleFavorite(lion);
    await favorites.toggleFavorite(lion); // removed again
    await favorites.toggleFavorite(dog);
    await quiz.saveScore(QuizScore(
      correctAnswers: 2,
      totalQuestions: 5,
      dateTime: DateTime(2026, 11, 15),
    ));
    await settle();

    expect(achievements.getProgress('first_favorite'), 1);
    expect(achievements.getProgress('collector'), 1);
    expect(favChallenge.progress, 2);
    expect(quizChallenge.progress, 1);
  });
}
