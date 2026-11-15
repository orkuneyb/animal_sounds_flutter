import 'achievement_provider.dart';
import 'challenge_provider.dart';
import 'discovery_provider.dart';
import 'favorites_provider.dart';
import 'game_provider.dart';
import 'quiz_provider.dart';

/// Connects what the child does (favourites, discoveries, quizzes, games) to
/// collection badges and weekly challenges. Called once at app start.
void wireProgress({
  required AchievementProvider achievements,
  required ChallengeProvider challenges,
  required FavoritesProvider favorites,
  required DiscoveryProvider discovery,
  required QuizProvider quiz,
  required GameProvider game,
}) {
  favorites.onFavoritesChanged = (count, added, animalId) {
    achievements.setProgress('first_favorite', count);
    achievements.setProgress('collector', count);
    achievements.setProgress('super_collector', count);
    if (added) challenges.recordEvent('favorite', animalId: animalId);
  };
  discovery.onAnimalDiscovered = (_) => challenges.recordEvent('discover');
  quiz.onQuizCompleted = (score) => challenges.recordEvent(
        'quiz',
        correct: score.correctAnswers,
        total: score.totalQuestions,
        usedHint: score.usedHint,
      );
  game.onGameOver = (score) => challenges.recordEvent('game', score: score);
}
