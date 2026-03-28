// providers/quiz_provider.dart
import 'dart:convert';

import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProvider with ChangeNotifier {
  static const String _scoresPrefsKey = 'quiz_scores';
  static const String _statsPrefsKey = 'quiz_stats';

  List<QuizScore> _scores = [];
  int _highestScore = 0;
  int _totalQuizzes = 0;
  int _perfectScores = 0;
  AchievementProvider? _achievementProvider;

  List<QuizScore> get scores => _scores;
  int get highestScore => _highestScore;
  int get totalQuizzes => _totalQuizzes;
  int get perfectScores => _perfectScores;

  QuizProvider() {
    _loadFromPrefs();
  }

  /// Sets the achievement provider for integration.
  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  Future<void> saveScore(QuizScore score) async {
    _scores.add(score);
    _totalQuizzes++;

    if (score.percentage > _highestScore) {
      _highestScore = score.percentage.toInt();
    }

    final isPerfect =
        score.correctAnswers == score.totalQuestions && score.totalQuestions > 0;
    if (isPerfect) {
      _perfectScores++;
    }

    _checkAchievements(isPerfect: isPerfect);
    await _saveToPrefs();
    notifyListeners();
  }

  void _checkAchievements({required bool isPerfect}) {
    if (_achievementProvider == null) return;

    // First quiz completed
    _achievementProvider!.incrementProgress('first_quiz', 1);

    // Quiz streak (total quizzes completed)
    _achievementProvider!.incrementProgress('quiz_streak', 1);

    // Quiz champion (10 quizzes)
    _achievementProvider!.incrementProgress('quiz_champion', 1);

    // Perfect score
    if (isPerfect) {
      _achievementProvider!.checkAndUnlock('quiz_perfect');
      _achievementProvider!.incrementProgress('quiz_master', 1);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load stats
    final statsJson = prefs.getString(_statsPrefsKey);
    if (statsJson != null) {
      try {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        _highestScore = stats['highestScore'] as int? ?? 0;
        _totalQuizzes = stats['totalQuizzes'] as int? ?? 0;
        _perfectScores = stats['perfectScores'] as int? ?? 0;
      } catch (_) {}
    }

    // Load score history
    final scoresJson = prefs.getString(_scoresPrefsKey);
    if (scoresJson != null) {
      try {
        final List<dynamic> list = jsonDecode(scoresJson) as List<dynamic>;
        _scores = list.map((item) {
          final map = item as Map<String, dynamic>;
          return QuizScore(
            correctAnswers: map['correctAnswers'] as int,
            totalQuestions: map['totalQuestions'] as int,
            dateTime: DateTime.parse(map['dateTime'] as String),
          );
        }).toList();
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Save stats
    await prefs.setString(
      _statsPrefsKey,
      jsonEncode({
        'highestScore': _highestScore,
        'totalQuizzes': _totalQuizzes,
        'perfectScores': _perfectScores,
      }),
    );

    // Save last 50 scores
    final recentScores = _scores.length > 50
        ? _scores.sublist(_scores.length - 50)
        : _scores;
    await prefs.setString(
      _scoresPrefsKey,
      jsonEncode(recentScores
          .map((s) => {
                'correctAnswers': s.correctAnswers,
                'totalQuestions': s.totalQuestions,
                'dateTime': s.dateTime.toIso8601String(),
              })
          .toList()),
    );
  }
}
