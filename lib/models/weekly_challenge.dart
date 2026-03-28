class WeeklyChallenge {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String type;
  final int target;
  int progress;
  final int iconCodePoint;

  WeeklyChallenge({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.iconCodePoint,
  });

  bool get isCompleted => progress >= target;
  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'] as String,
      titleKey: json['titleKey'] as String,
      descriptionKey: json['descriptionKey'] as String,
      type: json['type'] as String,
      target: json['target'] as int,
      progress: json['progress'] as int? ?? 0,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'type': type,
      'target': target,
      'progress': progress,
      'iconCodePoint': iconCodePoint,
    };
  }
}
