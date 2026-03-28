import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weekly_challenge.dart';

class ChallengeProvider with ChangeNotifier {
  static const String _challengesKey = 'weekly_challenges';
  static const String _weekNumberKey = 'weekly_challenge_week';

  List<WeeklyChallenge> _challenges = [];
  int _storedWeekNumber = -1;

  List<WeeklyChallenge> get challenges => _challenges;

  int get completedCount => _challenges.where((c) => c.isCompleted).length;
  int get totalCount => _challenges.length;
  String get weeklyProgress => '$completedCount/$totalCount';
  bool get allCompleted =>
      _challenges.isNotEmpty && _challenges.every((c) => c.isCompleted);

  int get currentWeekNumber {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;
    return (dayOfYear / 7).ceil();
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    // Find next Monday
    final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    final nextMonday = DateTime(now.year, now.month, now.day)
        .add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    return nextMonday.difference(now);
  }

  int get daysRemaining => timeRemaining.inDays;

  ChallengeProvider() {
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    _storedWeekNumber = prefs.getInt(_weekNumberKey) ?? -1;

    if (_storedWeekNumber != currentWeekNumber) {
      // New week: generate new challenges
      _challenges = _generateChallenges(currentWeekNumber);
      await _saveChallenges();
    } else {
      // Load stored challenges
      final stored = prefs.getString(_challengesKey);
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        _challenges =
            decoded.map((e) => WeeklyChallenge.fromJson(e)).toList();
      } else {
        _challenges = _generateChallenges(currentWeekNumber);
        await _saveChallenges();
      }
    }
    notifyListeners();
  }

  List<WeeklyChallenge> _generateChallenges(int weekNumber) {
    final templates = _getChallengeTemplates();
    final random = Random(weekNumber * 1337);

    final shuffled = List<Map<String, dynamic>>.from(templates);
    shuffled.shuffle(random);

    return shuffled.take(3).map((t) {
      return WeeklyChallenge(
        id: '${t['id']}_w$weekNumber',
        titleKey: t['titleKey'] as String,
        descriptionKey: t['descriptionKey'] as String,
        type: t['type'] as String,
        target: t['target'] as int,
        progress: 0,
        icon: t['icon'] as IconData,
      );
    }).toList();
  }

  List<Map<String, dynamic>> _getChallengeTemplates() {
    return [
      {
        'id': 'listen_farm_5',
        'titleKey': 'challenge_listen_farm_title',
        'descriptionKey': 'challenge_listen_farm_desc',
        'type': 'listen',
        'target': 5,
        'icon': Icons.headphones_rounded,
      },
      {
        'id': 'complete_quiz_3',
        'titleKey': 'challenge_complete_quiz_title',
        'descriptionKey': 'challenge_complete_quiz_desc',
        'type': 'quiz',
        'target': 3,
        'icon': Icons.quiz_rounded,
      },
      {
        'id': 'perfect_quiz',
        'titleKey': 'challenge_perfect_quiz_title',
        'descriptionKey': 'challenge_perfect_quiz_desc',
        'type': 'quiz_perfect',
        'target': 1,
        'icon': Icons.star_rounded,
      },
      {
        'id': 'visit_info_wild_5',
        'titleKey': 'challenge_visit_info_wild_title',
        'descriptionKey': 'challenge_visit_info_wild_desc',
        'type': 'info',
        'target': 5,
        'icon': Icons.info_rounded,
      },
      {
        'id': 'add_fav_3',
        'titleKey': 'challenge_add_fav_title',
        'descriptionKey': 'challenge_add_fav_desc',
        'type': 'favorite',
        'target': 3,
        'icon': Icons.favorite_rounded,
      },
      {
        'id': 'listen_10_diff',
        'titleKey': 'challenge_listen_10_diff_title',
        'descriptionKey': 'challenge_listen_10_diff_desc',
        'type': 'listen',
        'target': 10,
        'icon': Icons.music_note_rounded,
      },
      {
        'id': 'discover_5_new',
        'titleKey': 'challenge_discover_5_title',
        'descriptionKey': 'challenge_discover_5_desc',
        'type': 'discover',
        'target': 5,
        'icon': Icons.explore_rounded,
      },
      {
        'id': 'play_game_3',
        'titleKey': 'challenge_play_game_title',
        'descriptionKey': 'challenge_play_game_desc',
        'type': 'game',
        'target': 3,
        'icon': Icons.gamepad_rounded,
      },
      {
        'id': 'read_facts_5',
        'titleKey': 'challenge_read_facts_title',
        'descriptionKey': 'challenge_read_facts_desc',
        'type': 'info',
        'target': 5,
        'icon': Icons.auto_stories_rounded,
      },
      {
        'id': 'listen_sea_all',
        'titleKey': 'challenge_listen_sea_title',
        'descriptionKey': 'challenge_listen_sea_desc',
        'type': 'listen',
        'target': 3,
        'icon': Icons.waves_rounded,
      },
      {
        'id': 'quiz_no_hint',
        'titleKey': 'challenge_quiz_no_hint_title',
        'descriptionKey': 'challenge_quiz_no_hint_desc',
        'type': 'quiz',
        'target': 1,
        'icon': Icons.psychology_rounded,
      },
      {
        'id': 'visit_info_8',
        'titleKey': 'challenge_visit_info_8_title',
        'descriptionKey': 'challenge_visit_info_8_desc',
        'type': 'info',
        'target': 8,
        'icon': Icons.menu_book_rounded,
      },
      {
        'id': 'listen_15_total',
        'titleKey': 'challenge_listen_15_title',
        'descriptionKey': 'challenge_listen_15_desc',
        'type': 'listen',
        'target': 15,
        'icon': Icons.volume_up_rounded,
      },
      {
        'id': 'fav_bird',
        'titleKey': 'challenge_fav_bird_title',
        'descriptionKey': 'challenge_fav_bird_desc',
        'type': 'favorite',
        'target': 1,
        'icon': Icons.flutter_dash_rounded,
      },
      {
        'id': 'quiz_good_2',
        'titleKey': 'challenge_quiz_good_title',
        'descriptionKey': 'challenge_quiz_good_desc',
        'type': 'quiz',
        'target': 2,
        'icon': Icons.emoji_events_rounded,
      },
      {
        'id': 'game_score_10',
        'titleKey': 'challenge_game_score_10_title',
        'descriptionKey': 'challenge_game_score_10_desc',
        'type': 'game',
        'target': 1,
        'icon': Icons.leaderboard_rounded,
      },
    ];
  }

  void incrementProgress(String challengeType, {String? category}) {
    bool changed = false;
    for (final challenge in _challenges) {
      if (challenge.isCompleted) continue;
      if (challenge.type == challengeType) {
        challenge.progress++;
        changed = true;
      }
    }
    if (changed) {
      _saveChallenges();
      notifyListeners();
    }
  }

  Future<void> _saveChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_challenges.map((c) => c.toJson()).toList());
    await prefs.setString(_challengesKey, encoded);
    await prefs.setInt(_weekNumberKey, currentWeekNumber);
  }

  Future<void> refresh() async {
    await _loadChallenges();
  }
}
