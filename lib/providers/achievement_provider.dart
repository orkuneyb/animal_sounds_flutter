import 'dart:async';
import 'dart:convert';

import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Callback signature for when an achievement is unlocked.
typedef AchievementUnlockCallback = void Function(Achievement achievement);

class AchievementProvider with ChangeNotifier {
  static const String _prefsKey = 'achievements_data';

  List<Achievement> _achievements = [];
  final List<AchievementUnlockCallback> _unlockListeners = [];

  List<Achievement> get achievements => List.unmodifiable(_achievements);

  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  int get totalCount => _achievements.length;

  AchievementProvider() {
    _initAchievements();
  }

  /// Register a listener that fires when any achievement is unlocked.
  void addUnlockListener(AchievementUnlockCallback callback) {
    _unlockListeners.add(callback);
  }

  void removeUnlockListener(AchievementUnlockCallback callback) {
    _unlockListeners.remove(callback);
  }

  // ---------------------------------------------------------------------------
  // Achievement definitions
  // ---------------------------------------------------------------------------

  static List<Achievement> get _defaultAchievements => [
        // LISTENING
        Achievement(
          id: 'first_sound',
          title: 'achievement_first_sound_title',
          description: 'achievement_first_sound_desc',
          category: AchievementCategory.listening,
          maxProgress: 1,
          iconData: Icons.music_note_rounded,
        ),
        Achievement(
          id: 'sound_explorer',
          title: 'achievement_sound_explorer_title',
          description: 'achievement_sound_explorer_desc',
          category: AchievementCategory.listening,
          maxProgress: 10,
          iconData: Icons.explore_rounded,
        ),
        Achievement(
          id: 'sound_master',
          title: 'achievement_sound_master_title',
          description: 'achievement_sound_master_desc',
          category: AchievementCategory.listening,
          maxProgress: 30,
          iconData: Icons.stars_rounded,
        ),
        Achievement(
          id: 'repeat_listener',
          title: 'achievement_repeat_listener_title',
          description: 'achievement_repeat_listener_desc',
          category: AchievementCategory.listening,
          maxProgress: 50,
          iconData: Icons.replay_rounded,
        ),
        Achievement(
          id: 'sound_marathon',
          title: 'achievement_sound_marathon_title',
          description: 'achievement_sound_marathon_desc',
          category: AchievementCategory.listening,
          maxProgress: 100,
          iconData: Icons.surround_sound_rounded,
        ),

        // QUIZ
        Achievement(
          id: 'first_quiz',
          title: 'achievement_first_quiz_title',
          description: 'achievement_first_quiz_desc',
          category: AchievementCategory.quiz,
          maxProgress: 1,
          iconData: Icons.quiz_rounded,
        ),
        Achievement(
          id: 'quiz_perfect',
          title: 'achievement_quiz_perfect_title',
          description: 'achievement_quiz_perfect_desc',
          category: AchievementCategory.quiz,
          maxProgress: 1,
          iconData: Icons.verified_rounded,
        ),
        Achievement(
          id: 'quiz_streak',
          title: 'achievement_quiz_streak_title',
          description: 'achievement_quiz_streak_desc',
          category: AchievementCategory.quiz,
          maxProgress: 5,
          iconData: Icons.trending_up_rounded,
        ),
        Achievement(
          id: 'quiz_champion',
          title: 'achievement_quiz_champion_title',
          description: 'achievement_quiz_champion_desc',
          category: AchievementCategory.quiz,
          maxProgress: 10,
          iconData: Icons.emoji_events_rounded,
        ),
        Achievement(
          id: 'quiz_master',
          title: 'achievement_quiz_master_title',
          description: 'achievement_quiz_master_desc',
          category: AchievementCategory.quiz,
          maxProgress: 5,
          iconData: Icons.workspace_premium_rounded,
        ),

        // DISCOVERY
        Achievement(
          id: 'first_info',
          title: 'achievement_first_info_title',
          description: 'achievement_first_info_desc',
          category: AchievementCategory.discovery,
          maxProgress: 1,
          iconData: Icons.info_outline_rounded,
        ),
        Achievement(
          id: 'curious_mind',
          title: 'achievement_curious_mind_title',
          description: 'achievement_curious_mind_desc',
          category: AchievementCategory.discovery,
          maxProgress: 10,
          iconData: Icons.psychology_rounded,
        ),
        Achievement(
          id: 'animal_expert',
          title: 'achievement_animal_expert_title',
          description: 'achievement_animal_expert_desc',
          category: AchievementCategory.discovery,
          maxProgress: 30,
          iconData: Icons.school_rounded,
        ),
        Achievement(
          id: 'fact_lover',
          title: 'achievement_fact_lover_title',
          description: 'achievement_fact_lover_desc',
          category: AchievementCategory.discovery,
          maxProgress: 20,
          iconData: Icons.auto_stories_rounded,
        ),

        // STREAK
        Achievement(
          id: 'first_day',
          title: 'achievement_first_day_title',
          description: 'achievement_first_day_desc',
          category: AchievementCategory.streak,
          maxProgress: 1,
          iconData: Icons.wb_sunny_rounded,
        ),
        Achievement(
          id: 'week_streak',
          title: 'achievement_week_streak_title',
          description: 'achievement_week_streak_desc',
          category: AchievementCategory.streak,
          maxProgress: 7,
          iconData: Icons.local_fire_department_rounded,
        ),
        Achievement(
          id: 'month_streak',
          title: 'achievement_month_streak_title',
          description: 'achievement_month_streak_desc',
          category: AchievementCategory.streak,
          maxProgress: 30,
          iconData: Icons.whatshot_rounded,
        ),

        // COLLECTION
        Achievement(
          id: 'first_favorite',
          title: 'achievement_first_favorite_title',
          description: 'achievement_first_favorite_desc',
          category: AchievementCategory.collection,
          maxProgress: 1,
          iconData: Icons.favorite_rounded,
        ),
        Achievement(
          id: 'collector',
          title: 'achievement_collector_title',
          description: 'achievement_collector_desc',
          category: AchievementCategory.collection,
          maxProgress: 10,
          iconData: Icons.collections_bookmark_rounded,
        ),
        Achievement(
          id: 'super_collector',
          title: 'achievement_super_collector_title',
          description: 'achievement_super_collector_desc',
          category: AchievementCategory.collection,
          maxProgress: 20,
          iconData: Icons.diamond_rounded,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Initialization & persistence
  // ---------------------------------------------------------------------------

  Future<void> _initAchievements() async {
    _achievements = List.from(_defaultAchievements);
    await _loadFromPrefs();
    // Auto-unlock first_day on first launch
    if (!_getById('first_day').isUnlocked) {
      await incrementProgress('first_day', 1);
    }
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return;

    try {
      final List<dynamic> savedList = jsonDecode(jsonStr) as List<dynamic>;
      final Map<String, Map<String, dynamic>> savedMap = {
        for (final item in savedList)
          (item as Map<String, dynamic>)['id'] as String: item,
      };

      _achievements = _achievements.map((template) {
        final saved = savedMap[template.id];
        if (saved != null) {
          return Achievement.fromSaved(saved, template);
        }
        return template;
      }).toList();
    } catch (_) {
      // If data is corrupt, keep defaults.
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(
      _achievements.map((a) => a.toJson()).toList(),
    );
    await prefs.setString(_prefsKey, jsonStr);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Achievement _getById(String id) {
    return _achievements.firstWhere((a) => a.id == id);
  }

  int _indexById(String id) {
    return _achievements.indexWhere((a) => a.id == id);
  }

  /// Returns the current progress for a given achievement.
  int getProgress(String id) {
    final idx = _indexById(id);
    if (idx == -1) return 0;
    return _achievements[idx].progress;
  }

  /// Increments progress and auto-unlocks when target is reached.
  /// Returns `true` if the achievement was just unlocked.
  Future<bool> incrementProgress(String id, int amount) async {
    final idx = _indexById(id);
    if (idx == -1) return false;

    final achievement = _achievements[idx];
    if (achievement.isUnlocked) return false;

    final newProgress =
        (achievement.progress + amount).clamp(0, achievement.maxProgress);
    final justUnlocked = newProgress >= achievement.maxProgress;

    _achievements[idx] = achievement.copyWith(
      progress: newProgress,
      isUnlocked: justUnlocked,
      unlockedAt: justUnlocked ? DateTime.now() : null,
    );

    await _saveToPrefs();
    notifyListeners();

    if (justUnlocked) {
      _fireUnlockEvent(_achievements[idx]);
    }

    return justUnlocked;
  }

  /// Directly checks and unlocks an achievement if the condition is met.
  /// Useful for one-shot achievements (maxProgress == 1).
  Future<bool> checkAndUnlock(String id) async {
    return incrementProgress(id, 1);
  }

  /// Returns achievements filtered by category.
  List<Achievement> getByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  void _fireUnlockEvent(Achievement achievement) {
    for (final listener in _unlockListeners) {
      listener(achievement);
    }
  }
}
