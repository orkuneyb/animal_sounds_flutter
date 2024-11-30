import 'dart:async';

import 'package:animal_sounds_flutter/models/quiz_question.dart';
import 'package:animal_sounds_flutter/models/quiz_score.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/repositories/quiz_repository.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  late List<QuizQuestion> questions;
  String? selectedAnswer;
  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

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
  void dispose() {
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
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        title: Text(
          'quiz'.tr(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreIndicator(),
            _buildProgressIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildQuestionCard(),
                    const SizedBox(height: 10),
                    _buildAnswerOptions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orangeAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'quiz_progress.question_progress'.tr(namedArgs: {
              'current': '${_currentQuestionIndex + 1}',
              'total': '${questions.length}'
            }),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'quiz_progress.current_score'.tr(namedArgs: {'score': '$_score'}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(
                questions.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getProgressDotColor(index),
                      border: Border.all(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _currentQuestionIndex >= index
                              ? Colors.white
                              : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (_currentQuestionIndex + 1) / questions.length,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'quiz_progress.remaining'.tr(namedArgs: {
                  'count': '${questions.length - _currentQuestionIndex}'
                }),
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
              Text(
                'quiz_progress.completion'.tr(namedArgs: {
                  'percent':
                      '${((_currentQuestionIndex) / questions.length * 100).toInt()}'
                }),
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressDotColor(int index) {
    if (index < _currentQuestionIndex) {
      QuizQuestion question = questions[index];
      if (question.userAnswer != null) {
        bool wasCorrect =
            questions[index].options.indexOf(question.userAnswer!) ==
                questions[index].correctOptionIndex;
        return wasCorrect ? Colors.green : Colors.red;
      }
      return Colors.grey;
    } else if (index == _currentQuestionIndex) {
      return Colors.orangeAccent;
    } else {
      return Colors.white;
    }
  }

  Widget _buildQuestionCard() {
    final question = questions[_currentQuestionIndex];
    final isSoundQuestion =
        question.question.contains("quiz_questions.which_animal_sound".tr());

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!isSoundQuestion && question.imagePath != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    question.imagePath!,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else if (isSoundQuestion && question.soundPath != null)
              Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: () => _playSound(question.soundPath!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    elevation: 8,
                  ),
                  child: const Icon(
                    Icons.volume_up,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Column(
              children: [
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                IconButton(
                  onPressed: () => _speak(question.question),
                  icon: const Icon(
                    Icons.volume_up,
                    size: 30, // Biraz daha büyük bir ikon
                  ),
                  color: Colors.orangeAccent,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8), // Düğme için padding
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _playSound(String soundPath) async {
    try {
      await audioPlayer.stop();
      await audioPlayer.open(
        Audio(soundPath),
      );

      audioPlayer.playlistAudioFinished.listen((event) {});
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Widget _buildAnswerOptions() {
    return Expanded(
      child: ListView.builder(
        itemCount: questions[_currentQuestionIndex].options.length,
        itemBuilder: (context, index) {
          final option = questions[_currentQuestionIndex].options[index];
          final isCorrectOption =
              index == questions[_currentQuestionIndex].correctOptionIndex;
          final isSelectedOption = selectedAnswer == option;

          Color buttonColor = Colors.white;
          Color textColor = Colors.black87;

          if (_isAnswered) {
            if (isCorrectOption) {
              buttonColor = Colors.green;
              textColor = Colors.white;
            } else if (isSelectedOption) {
              buttonColor = Colors.red;
              textColor = Colors.white;
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: _isAnswered ? null : () => _checkAnswer(option),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: buttonColor,
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _speak(option),
                    icon: const Icon(
                      Icons.volume_up,
                      size: 30,
                    ),
                    color: textColor,
                  ),
                  if (_isAnswered)
                    Icon(
                      isCorrectOption
                          ? Icons.check_circle
                          : (isSelectedOption ? Icons.cancel : null),
                      color: Colors.white,
                    ),
                ],
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

    // Başarı yüzdesini hesapla
    final successPercent =
        ((_score / questions.length) * 100).toStringAsFixed(0);

    // Okunacak metinleri Türkçe cümle yapısına uygun hazırla
    final textsToRead = [
      'quiz_completed'.tr(), // "Quiz tamamlandı!"
      'result_correct_answers'.tr(namedArgs: {
        'count': '$_score',
        'total': '${questions.length}'
      }), // "5 sorudan 3 tanesini doğru bildiniz"
      'result_success_rate'.tr(
          namedArgs: {'percent': successPercent}), // "Başarı oranınız yüzde 60"
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _speakResultTexts(textsToRead);
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'quiz_result.completed'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orangeAccent,
                ),
                child: Icon(
                  _score >= (questions.length * 0.7).round()
                      ? Icons.emoji_events
                      : Icons.stars,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'quiz_result.score'.tr(namedArgs: {
                  'correct': '$_score',
                  'total': '${questions.length}'
                }),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'quiz_result.success_rate'.tr(namedArgs: {
                  'percent':
                      '${((_score / questions.length) * 100).toStringAsFixed(0)}'
                }),
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                flutterTts.stop();
                context.read<QuizProvider>().saveScore(score);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'finish'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
}
