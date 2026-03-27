import 'dart:async';
import 'package:animal_sounds_flutter/models/quiz_question.dart';
import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/repositories/quiz_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  late List<QuizQuestion> questions;
  String? selectedAnswer;
  final AudioPlayer audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

  late AnimationController _soundBtnController;
  late Animation<double> _soundBtnAnimation;

  Future<void> _initTts() async {
    await flutterTts.setLanguage(context.locale.languageCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    _soundBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _soundBtnAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _soundBtnController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _soundBtnController.dispose();
    flutterTts.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isTtsInitialized) {
      _initTts();
      _isTtsInitialized = true;
    }

    questions = QuizRepository.getQuestions(context);
    questions.shuffle();
    questions = questions.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'quiz'.tr(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildScoreBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildProgressBar(),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildQuestionCard(),
                    const SizedBox(height: 16),
                    _buildAnswerOptions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF57F17), size: 20),
          const SizedBox(width: 4),
          Text(
            '$_score',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF57F17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / questions.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'quiz_progress.question_progress'.tr(namedArgs: {
                'current': '${_currentQuestionIndex + 1}',
                'total': '${questions.length}'
              }),
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'quiz_progress.completion'.tr(namedArgs: {
                'percent':
                    '${((_currentQuestionIndex) / questions.length * 100).toInt()}'
              }),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(5),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight,
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = questions[_currentQuestionIndex];
    final isSoundQuestion =
        question.question.contains("quiz_questions.which_animal_sound".tr());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isSoundQuestion && question.imagePath != null)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: AppColors.surfaceContainerLow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  question.imagePath!,
                  fit: BoxFit.contain,
                ),
              ),
            )
          else if (isSoundQuestion && question.soundPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ScaleTransition(
                scale: _soundBtnAnimation,
                child: GestureDetector(
                  onTap: () => _playSound(question.soundPath!),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF81D4FA), Color(0xFF039BE5)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              _buildSmallTtsButton(() => _speak(question.question)),
            ],
          ),
        ],
      ),
    );
  }

  void _playSound(String soundPath) async {
    try {
      await audioPlayer.stop();
      String cleanPath =
          soundPath.startsWith('assets/') ? soundPath.substring(7) : soundPath;
      await audioPlayer.play(AssetSource(cleanPath));

      audioPlayer.onPlayerComplete.listen((event) {});
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Widget _buildAnswerOptions() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: questions[_currentQuestionIndex].options.length,
        itemBuilder: (context, index) {
          final option = questions[_currentQuestionIndex].options[index];
          final isCorrectOption =
              index == questions[_currentQuestionIndex].correctOptionIndex;
          final isSelectedOption = selectedAnswer == option;

          Color bgColor = AppColors.surfaceContainerLow;
          Color borderColor = AppColors.outlineVariant.withOpacity(0.3);
          Color textColor = AppColors.onSurface;
          IconData? trailingIcon;
          Color? trailingIconColor;

          if (_isAnswered) {
            if (isCorrectOption) {
              bgColor = const Color(0xFFE8F5E9);
              borderColor = AppColors.success;
              textColor = const Color(0xFF2E7D32);
              trailingIcon = Icons.check_circle_rounded;
              trailingIconColor = AppColors.success;
            } else if (isSelectedOption) {
              bgColor = const Color(0xFFFFEBEE);
              borderColor = AppColors.error;
              textColor = const Color(0xFFC62828);
              trailingIcon = Icons.cancel_rounded;
              trailingIconColor = AppColors.error;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  if (!_isAnswered)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _isAnswered ? null : () => _checkAnswer(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Row(
                      children: [
                        // Option letter badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isAnswered && isCorrectOption
                                ? AppColors.success
                                : _isAnswered && isSelectedOption
                                    ? AppColors.error
                                    : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _isAnswered &&
                                        (isCorrectOption || isSelectedOption)
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        _buildSmallTtsButton(() => _speak(option)),
                        if (_isAnswered && trailingIcon != null) ...[
                          const SizedBox(width: 6),
                          Icon(trailingIcon,
                              color: trailingIconColor, size: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _checkAnswer(String answer) {
    setState(() {
      _isAnswered = true;
      selectedAnswer = answer;
      questions[_currentQuestionIndex].userAnswer = answer;
    });

    final selectedIndex =
        questions[_currentQuestionIndex].options.indexOf(answer);
    final isCorrect =
        selectedIndex == questions[_currentQuestionIndex].correctOptionIndex;

    if (isCorrect) {
      _score++;
    }

    Future.delayed(const Duration(seconds: 2), () {
      audioPlayer.stop();

      if (_currentQuestionIndex < questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _isAnswered = false;
          selectedAnswer = null;
        });
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    final score = QuizScore(
      correctAnswers: _score,
      totalQuestions: questions.length,
      dateTime: DateTime.now(),
    );

    final successPercent =
        ((_score / questions.length) * 100).toStringAsFixed(0);
    final percentage = _score / questions.length;
    final isGreatScore = percentage >= 0.7;

    final textsToRead = [
      'quiz_completed'.tr(),
      'result_correct_answers'.tr(namedArgs: {
        'count': '$_score',
        'total': '${questions.length}'
      }),
      'result_success_rate'.tr(namedArgs: {'percent': successPercent}),
    ];

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _speakResultTexts(textsToRead);
        });

        return Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'quiz_result.completed'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              // Circular progress
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 10,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isGreatScore
                              ? AppColors.success
                              : AppColors.secondary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_score/${questions.length}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '$successPercent%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stars row
              if (isGreatScore)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < (_score / questions.length * 3).ceil()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFC107),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              if (isGreatScore) const SizedBox(height: 8),
              Text(
                'quiz_result.success_rate'.tr(namedArgs: {
                  'percent': successPercent,
                }),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              // Action buttons
              Row(
                children: [
                  // Go Home
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        flutterTts.stop();
                        sheetContext.read<QuizProvider>().saveScore(score);
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppColors.outlineVariant, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'finish'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Try Again
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          flutterTts.stop();
                          sheetContext.read<QuizProvider>().saveScore(score);
                          Navigator.of(sheetContext).pop();
                          setState(() {
                            _currentQuestionIndex = 0;
                            _score = 0;
                            _isAnswered = false;
                            selectedAnswer = null;
                            questions =
                                QuizRepository.getQuestions(context);
                            questions.shuffle();
                            questions = questions.take(5).toList();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'quiz_result.completed'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _speakResultTexts(List<String> texts) async {
    for (var i = 0; i < texts.length; i++) {
      Completer completer = Completer();

      flutterTts.setCompletionHandler(() {
        completer.complete();
      });

      await flutterTts.speak(texts[i]);

      await completer.future;

      if (i < texts.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Widget _buildSmallTtsButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          size: 15,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
