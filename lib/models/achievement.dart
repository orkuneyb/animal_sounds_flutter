import 'package:flutter/material.dart';

enum AchievementCategory {
  listening,
  quiz,
  discovery,
  streak,
  collection,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final AchievementCategory category;
  final int progress;
  final int maxProgress;
  final DateTime? unlockedAt;
  final IconData iconData;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.iconPath = '',
    this.isUnlocked = false,
    required this.category,
    this.progress = 0,
    required this.maxProgress,
    this.unlockedAt,
    this.iconData = Icons.emoji_events_rounded,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    bool? isUnlocked,
    AchievementCategory? category,
    int? progress,
    int? maxProgress,
    DateTime? unlockedAt,
    IconData? iconData,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconData: iconData ?? this.iconData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromSaved(
    Map<String, dynamic> json,
    Achievement template,
  ) {
    return template.copyWith(
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }

  double get progressPercent =>
      maxProgress > 0 ? (progress / maxProgress).clamp(0.0, 1.0) : 0.0;
}
