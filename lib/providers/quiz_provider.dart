// providers/quiz_provider.dart
import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:flutter/foundation.dart';

class QuizProvider with ChangeNotifier {
  List<QuizScore> _scores = [];
  List<Achievement> _achievements = [];
  int _highestScore = 0;

  List<QuizScore> get scores => _scores;
  List<Achievement> get achievements => _achievements;
  int get highestScore => _highestScore;

  Future<void> saveScore(QuizScore score) async {
    _scores.add(score);
    if (score.percentage > _highestScore) {
      _highestScore = score.percentage.toInt();
      // _checkAchievements();
    }
    await _saveToPrefs();
    notifyListeners();
  }

  void _checkAchievements() {
    if (_highestScore >= 100) {
      _unlockAchievement('perfect_score');
    } else if (_highestScore >= 80) {
      _unlockAchievement('expert');
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    final achievement = _achievements.firstWhere((a) => a.id == achievementId);
    if (!achievement.isUnlocked) {
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {}
}
