import 'dart:convert';
import 'dart:math';

import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/models/daily_streak.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyProvider with ChangeNotifier {
  static const String _streakPrefsKey = 'daily_streak_data';
  static const String _completedDaysPrefsKey = 'daily_completed_days';

  DailyStreak _streak = DailyStreak();
  Set<String> _completedDays = {};
  AchievementProvider? _achievementProvider;

  DailyStreak get streak => _streak;
  int get currentStreak => _streak.currentStreak;
  int get longestStreak => _streak.longestStreak;
  int get totalDays => _streak.totalDays;
  bool get isTodayCompleted => _streak.todayCompleted;

  DailyProvider() {
    _init();
  }

  /// Sets the achievement provider for integration.
  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  Future<void> _init() async {
    await _loadFromPrefs();
    _checkStreakContinuity();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Daily animal (deterministic based on date)
  // ---------------------------------------------------------------------------

  /// Returns today's animal using a date-based seed so the same day
  /// always returns the same animal.
  Animal getDailyAnimal() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);
    final index = random.nextInt(AnimalRepository.animals.length);
    return AnimalRepository.animals[index];
  }

  /// Returns a random fun fact for today's animal using the same date seed.
  String getDailyFunFact() {
    final animal = getDailyAnimal();
    if (animal.funFacts.isEmpty) return '';
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day + 42;
    final random = Random(seed);
    return animal.funFacts[random.nextInt(animal.funFacts.length)];
  }

  // ---------------------------------------------------------------------------
  // Streak management
  // ---------------------------------------------------------------------------

  /// Marks today as completed and updates streak.
  Future<void> completeDailyDiscovery() async {
    if (_streak.todayCompleted) return;

    final todayKey = _dateKey(DateTime.now());
    _completedDays.add(todayKey);

    final newStreak = _streak.currentStreak + 1;
    final newLongest = max(newStreak, _streak.longestStreak);

    _streak = _streak.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      totalDays: _streak.totalDays + 1,
      lastVisitDate: DateTime.now(),
      todayCompleted: true,
    );

    await _saveToPrefs();
    notifyListeners();

    // Trigger streak achievements
    _checkStreakAchievements();
  }

  /// Returns the completion status of the last [days] days.
  /// Each entry is a map with 'date', 'completed', and 'isToday'.
  List<Map<String, dynamic>> getStreakCalendar(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> calendar = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = _dateKey(date);
      calendar.add({
        'date': date,
        'completed': _completedDays.contains(key),
        'isToday': i == 0,
      });
    }

    return calendar;
  }

  /// Checks if the streak has been broken (missed one or more days).
  void _checkStreakContinuity() {
    if (_streak.lastVisitDate == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastVisit = DateTime(
      _streak.lastVisitDate!.year,
      _streak.lastVisitDate!.month,
      _streak.lastVisitDate!.day,
    );

    final daysDiff = today.difference(lastVisit).inDays;

    if (daysDiff == 0) {
      // Same day, already completed or not
      return;
    } else if (daysDiff == 1) {
      // Yesterday was the last visit, streak continues but today not yet done
      _streak = _streak.copyWith(todayCompleted: false);
    } else {
      // Missed days, reset streak
      _streak = _streak.copyWith(
        currentStreak: 0,
        todayCompleted: false,
      );
    }

    _saveToPrefs();
  }

  void _checkStreakAchievements() {
    if (_achievementProvider == null) return;

    _achievementProvider!.incrementProgress(
      'week_streak',
      _streak.currentStreak >= 7 ? 7 : _streak.currentStreak,
    );
    _achievementProvider!.incrementProgress(
      'month_streak',
      _streak.currentStreak >= 30 ? 30 : _streak.currentStreak,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load streak
    final streakJson = prefs.getString(_streakPrefsKey);
    if (streakJson != null) {
      try {
        _streak = DailyStreak.fromJson(
          jsonDecode(streakJson) as Map<String, dynamic>,
        );
      } catch (_) {
        _streak = DailyStreak();
      }
    }

    // Load completed days set
    final daysJson = prefs.getString(_completedDaysPrefsKey);
    if (daysJson != null) {
      try {
        final List<dynamic> daysList = jsonDecode(daysJson) as List<dynamic>;
        _completedDays = daysList.map((e) => e as String).toSet();
      } catch (_) {
        _completedDays = {};
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_streakPrefsKey, jsonEncode(_streak.toJson()));
    await prefs.setString(
      _completedDaysPrefsKey,
      jsonEncode(_completedDays.toList()),
    );
  }
}
