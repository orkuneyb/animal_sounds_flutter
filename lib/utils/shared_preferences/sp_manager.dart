import 'package:animal_sounds_flutter/utils/shared_preferences/sp_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SPManager {
  static setAnimalSoundLevel(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(SPConstants.animalSoundLevel, value);
  }

  static Future<double> getAnimalSoundLevel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double value = prefs.getDouble(SPConstants.animalSoundLevel) ?? 1.0;
    return Future.value(value);
  }

  static Future<void> setSoundPlayCount(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SPConstants.soundPlayCount, value);
  }

  static Future<int> getSoundPlayCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int value = prefs.getInt(SPConstants.soundPlayCount) ?? 0;
    return Future.value(value);
  }
}
