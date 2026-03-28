class DailyStreak {
  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final DateTime? lastVisitDate;
  final bool todayCompleted;

  DailyStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalDays = 0,
    this.lastVisitDate,
    this.todayCompleted = false,
  });

  DailyStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalDays,
    DateTime? lastVisitDate,
    bool? todayCompleted,
  }) {
    return DailyStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalDays: totalDays ?? this.totalDays,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      todayCompleted: todayCompleted ?? this.todayCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalDays': totalDays,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'todayCompleted': todayCompleted,
    };
  }

  factory DailyStreak.fromJson(Map<String, dynamic> json) {
    return DailyStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalDays: json['totalDays'] as int? ?? 0,
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.tryParse(json['lastVisitDate'] as String)
          : null,
      todayCompleted: json['todayCompleted'] as bool? ?? false,
    );
  }
}
