class QuizScore {
  final int correctAnswers;
  final int totalQuestions;
  final DateTime dateTime;

  QuizScore({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.dateTime,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;
}
