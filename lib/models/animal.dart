import 'package:flutter/material.dart';

import '../services/sound_library.dart';
import '../utils/colors/colors.dart';
import 'animal_traits.dart';

/// One animal: its picture, sound, translation keys and picture facts.
///
/// [index] is the animal's permanent id. Favourites, discoveries and usage
/// stats are saved by index, so an index is never reused or reordered.
class Animal {
  final int index;

  /// English key, also the base of every translation key and asset name.
  final String name;
  final AnimalGroup group;
  final AnimalHome home;
  final AnimalFood food;
  final AnimalSize bigness;

  const Animal({
    required this.index,
    required this.name,
    required this.group,
    required this.home,
    required this.food,
    required this.bigness,
  });

  String get imagePath => 'assets/animal_images/$name.png';
  String get soundPath => 'assets/animal_sounds/$name.mp3';

  /// False while the animal's sound has not been added yet. Screens then
  /// show the animal without a play button and games never ask for it.
  bool get hasSound => SoundLibrary.has(name);

  // Translation keys of the longer texts.
  String get description => '${name}_desc';
  String get size => '${name}_size';
  String get weight => '${name}_weight';
  String get lifespan => '${name}_lifespan';
  String get habitat => '${name}_habitat';
  String get diet => '${name}_diet';
  List<String> get funFacts =>
      ['${name}_fun_fact_1', '${name}_fun_fact_2', '${name}_fun_fact_3'];

  /// The animal's own soft background colour, the same on every screen.
  Color get color => AppColors.cardColors[index % AppColors.cardColors.length];
}
