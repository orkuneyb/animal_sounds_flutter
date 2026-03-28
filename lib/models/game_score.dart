class GameScore {
  final int score;
  final int highScore;
  final DateTime playedAt;

  GameScore({
    required this.score,
    required this.highScore,
    required this.playedAt,
  });

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      score: json['score'] as int,
      highScore: json['highScore'] as int,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'highScore': highScore,
      'playedAt': playedAt.toIso8601String(),
    };
  }
}
