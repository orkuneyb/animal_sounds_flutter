import 'package:animal_sounds_flutter/utils/shared_preferences/sp_manager.dart';
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  double _animalSoundLevel = 0.0;

  SettingsProvider() {
    _initSoundLevel();
  }

  Future<void> _initSoundLevel() async {
    _animalSoundLevel = await SPManager.getAnimalSoundLevel();
    notifyListeners();
  }

  double get getAnimalSoundLevel => _animalSoundLevel;

  set setAnimalSoundLevel(double value) {
    _animalSoundLevel = value;
    SPManager.setAnimalSoundLevel(_animalSoundLevel);
    notifyListeners();
  }
}
