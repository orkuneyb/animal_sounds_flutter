import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks usage statistics for the parent dashboard.
///
/// All data is persisted to [SharedPreferences] so it survives app restarts.
class UsageStatsProvider extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // SharedPreferences keys
  // ---------------------------------------------------------------------------
  static const _keySoundsListened = 'stats_sounds_listened';
  static const _keyQuizzesCompleted = 'stats_quizzes_completed';
  static const _keyInfoVisited = 'stats_info_visited';
  static const _keyAppOpens = 'stats_app_opens';
  static const _keyAnimalListenCounts = 'stats_animal_listen_counts';
  static const _keyAnimalInfoCounts = 'stats_animal_info_counts';
  static const _keyQuizScores = 'stats_quiz_scores';
  static const _keyDailyActivity = 'stats_daily_activity';
  static const _keyFavoriteCount = 'stats_favorite_count';

  // ---------------------------------------------------------------------------
  // In-memory state
  // ---------------------------------------------------------------------------
  int _soundsListened = 0;
  int _quizzesCompleted = 0;
  int _infoVisited = 0;
  int _appOpens = 0;
  int _favoriteCount = 0;
  Map<String, int> _animalListenCounts = {};
  Map<String, int> _animalInfoCounts = {};
  List<int> _quizScores = [];
  Map<String, int> _dailyActivity = {}; // key: 'yyyy-MM-dd', value: count

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  int get soundsListened => _soundsListened;
  int get quizzesCompleted => _quizzesCompleted;
  int get infoVisited => _infoVisited;
  int get appOpens => _appOpens;
  int get favoriteCount => _favoriteCount;
  List<int> get quizScores => List.unmodifiable(_quizScores);

  /// Number of unique animals whose info page was visited OR sound was played.
  int get animalsDiscovered {
    final all = <String>{
      ..._animalListenCounts.keys,
      ..._animalInfoCounts.keys,
    };
    return all.length;
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  UsageStatsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundsListened = prefs.getInt(_keySoundsListened) ?? 0;
    _quizzesCompleted = prefs.getInt(_keyQuizzesCompleted) ?? 0;
    _infoVisited = prefs.getInt(_keyInfoVisited) ?? 0;
    _appOpens = prefs.getInt(_keyAppOpens) ?? 0;
    _favoriteCount = prefs.getInt(_keyFavoriteCount) ?? 0;

    final listenJson = prefs.getString(_keyAnimalListenCounts);
    if (listenJson != null) {
      _animalListenCounts =
          Map<String, int>.from(json.decode(listenJson) as Map);
    }

    final infoJson = prefs.getString(_keyAnimalInfoCounts);
    if (infoJson != null) {
      _animalInfoCounts = Map<String, int>.from(json.decode(infoJson) as Map);
    }

    final scoresJson = prefs.getString(_keyQuizScores);
    if (scoresJson != null) {
      _quizScores = List<int>.from(json.decode(scoresJson) as List);
    }

    final dailyJson = prefs.getString(_keyDailyActivity);
    if (dailyJson != null) {
      _dailyActivity = Map<String, int>.from(json.decode(dailyJson) as Map);
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Increment helpers
  // ---------------------------------------------------------------------------

  Future<void> incrementSoundsListened(int animalId) async {
    _soundsListened++;
    final key = animalId.toString();
    _animalListenCounts[key] = (_animalListenCounts[key] ?? 0) + 1;
    _incrementDailyActivity();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySoundsListened, _soundsListened);
    await prefs.setString(
        _keyAnimalListenCounts, json.encode(_animalListenCounts));
    notifyListeners();
  }

  Future<void> incrementQuizzesCompleted(int score) async {
    _quizzesCompleted++;
    _quizScores.add(score);
    _incrementDailyActivity();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuizzesCompleted, _quizzesCompleted);
    await prefs.setString(_keyQuizScores, json.encode(_quizScores));
    notifyListeners();
  }

  Future<void> incrementInfoVisited(int animalId) async {
    _infoVisited++;
    final key = animalId.toString();
    _animalInfoCounts[key] = (_animalInfoCounts[key] ?? 0) + 1;
    _incrementDailyActivity();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInfoVisited, _infoVisited);
    await prefs.setString(
        _keyAnimalInfoCounts, json.encode(_animalInfoCounts));
    notifyListeners();
  }

  Future<void> incrementAppOpens() async {
    _appOpens++;
    _incrementDailyActivity();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAppOpens, _appOpens);
    notifyListeners();
  }

  Future<void> updateFavoriteCount(int count) async {
    _favoriteCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFavoriteCount, _favoriteCount);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------------

  /// Returns the top 5 most-listened animal IDs with their listen counts,
  /// sorted descending by count.
  List<MapEntry<int, int>> getMostListenedAnimals() {
    final entries = _animalListenCounts.entries
        .map((e) => MapEntry(int.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Returns average quiz score, or 0 if no quizzes played.
  double getQuizAverage() {
    if (_quizScores.isEmpty) return 0;
    final sum = _quizScores.reduce((a, b) => a + b);
    return sum / _quizScores.length;
  }

  /// Returns activity counts for the last 7 days (index 0 = 6 days ago,
  /// index 6 = today).
  List<int> getWeeklyActivity() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = _dateKey(day);
      return _dailyActivity[key] ?? 0;
    });
  }

  /// Returns the day-of-week labels for the last 7 days, matching the order
  /// of [getWeeklyActivity].
  List<String> getWeeklyLabels() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return labels[day.weekday - 1];
    });
  }

  // ---------------------------------------------------------------------------
  // Reset
  // ---------------------------------------------------------------------------

  Future<void> resetAll() async {
    _soundsListened = 0;
    _quizzesCompleted = 0;
    _infoVisited = 0;
    _appOpens = 0;
    _favoriteCount = 0;
    _animalListenCounts = {};
    _animalInfoCounts = {};
    _quizScores = [];
    _dailyActivity = {};

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySoundsListened);
    await prefs.remove(_keyQuizzesCompleted);
    await prefs.remove(_keyInfoVisited);
    await prefs.remove(_keyAppOpens);
    await prefs.remove(_keyFavoriteCount);
    await prefs.remove(_keyAnimalListenCounts);
    await prefs.remove(_keyAnimalInfoCounts);
    await prefs.remove(_keyQuizScores);
    await prefs.remove(_keyDailyActivity);

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _incrementDailyActivity() async {
    final key = _dateKey(DateTime.now());
    _dailyActivity[key] = (_dailyActivity[key] ?? 0) + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyActivity, json.encode(_dailyActivity));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
