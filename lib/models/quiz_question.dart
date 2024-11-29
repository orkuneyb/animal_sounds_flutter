class QuizQuestion {
  final int id;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String? imagePath;
  final String? soundPath;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    required List<String> options,
    this.imagePath,
    this.soundPath,
  }) : options = List.unmodifiable(options);

  int get correctOptionIndex => options.indexOf(correctAnswer);
}
