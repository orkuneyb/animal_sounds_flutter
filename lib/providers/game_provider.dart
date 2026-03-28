import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/animal.dart';
import '../repositories/animal_repository.dart';

class GameProvider with ChangeNotifier {
  static const String _highScoreKey = 'sound_guess_high_score';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  int _highScore = 0;
  int _currentScore = 0;
  bool _isGameOver = false;
  bool _isPlaying = false;

  List<Animal> _currentOptions = [];
  Animal? _correctAnimal;
  Animal? _selectedAnimal;
  bool? _lastAnswerCorrect;

  int get highScore => _highScore;
  int get currentScore => _currentScore;
  bool get isGameOver => _isGameOver;
  bool get isPlaying => _isPlaying;
  List<Animal> get currentOptions => _currentOptions;
  Animal? get correctAnimal => _correctAnimal;
  Animal? get selectedAnimal => _selectedAnimal;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;

  GameProvider() {
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_highScoreKey) ?? 0;
    notifyListeners();
  }

  void startGame() {
    _currentScore = 0;
    _isGameOver = false;
    _selectedAnimal = null;
    _lastAnswerCorrect = null;
    pickNextRound();
    notifyListeners();
  }

  void pickNextRound() {
    _selectedAnimal = null;
    _lastAnswerCorrect = null;

    final animals = List<Animal>.from(AnimalRepository.animals);
    animals.shuffle(_random);

    _correctAnimal = animals.first;

    final wrongAnimals = animals.skip(1).take(3).toList();

    _currentOptions = [_correctAnimal!, ...wrongAnimals];
    _currentOptions.shuffle(_random);

    notifyListeners();
  }

  Future<void> playSound() async {
    if (_correctAnimal == null) return;

    try {
      _isPlaying = true;
      notifyListeners();

      await _audioPlayer.stop();
      String cleanPath = _correctAnimal!.soundPath;
      if (cleanPath.startsWith('assets/')) {
        cleanPath = cleanPath.substring(7);
      }
      await _audioPlayer.play(AssetSource(cleanPath));

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        notifyListeners();
      });
    } catch (e) {
      _isPlaying = false;
      notifyListeners();
      debugPrint('Error playing sound: $e');
    }
  }

  bool checkAnswer(int animalIndex) {
    if (_isGameOver || _correctAnimal == null) return false;

    final selectedOption = _currentOptions[animalIndex];
    _selectedAnimal = selectedOption;
    final isCorrect = selectedOption.index == _correctAnimal!.index;

    if (isCorrect) {
      _currentScore++;
      _lastAnswerCorrect = true;
    } else {
      _isGameOver = true;
      _lastAnswerCorrect = false;
      saveHighScore();
    }

    notifyListeners();
    return isCorrect;
  }

  Future<void> saveHighScore() async {
    if (_currentScore > _highScore) {
      _highScore = _currentScore;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _highScore);
      notifyListeners();
    }
  }

  bool get isNewHighScore => _currentScore > 0 && _currentScore >= _highScore;

  int get starRating {
    if (_currentScore >= 15) return 3;
    if (_currentScore >= 8) return 2;
    if (_currentScore >= 3) return 1;
    return 0;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
