class QuizScore {
  final int correctAnswers;
  final int totalQuestions;
  final DateTime dateTime;

  /// Whether a hint was used on any question of this quiz.
  final bool usedHint;

  QuizScore({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.dateTime,
    this.usedHint = false,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;
}
