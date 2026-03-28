import 'dart:convert';

import 'package:animal_sounds_flutter/models/discovery.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscoveryProvider extends ChangeNotifier {
  static const String _storageKey = 'animal_discoveries';

  final Map<int, AnimalDiscovery> _discoveries = {};

  /// Callback invoked when an animal becomes fully discovered.
  /// Can be used by other systems (e.g. achievements) to react.
  void Function(int animalId)? onAnimalDiscovered;

  DiscoveryProvider() {
    _loadFromPrefs();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  int get totalAnimals => AnimalRepository.animals.length;

  int get discoveredCount =>
      _discoveries.values.where((d) => d.isDiscovered).length;

  double get progressPercentage =>
      totalAnimals == 0 ? 0.0 : discoveredCount / totalAnimals;

  bool isDiscovered(int animalId) =>
      _discoveries[animalId]?.isDiscovered ?? false;

  AnimalDiscovery getDiscovery(int animalId) =>
      _discoveries[animalId] ??
      AnimalDiscovery(animalId: animalId);

  Map<int, AnimalDiscovery> get allDiscoveries =>
      Map.unmodifiable(_discoveries);

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> markSoundListened(int animalId) async {
    final current = getDiscovery(animalId);
    if (current.soundListened) return;

    final wasDiscovered = current.isDiscovered;
    final updated = current.copyWith(
      soundListened: true,
      discoveredAt:
          (!wasDiscovered && current.infoVisited) ? DateTime.now() : null,
    );

    _discoveries[animalId] = updated;
    notifyListeners();

    if (!wasDiscovered && updated.isDiscovered) {
      onAnimalDiscovered?.call(animalId);
    }

    await _saveToPrefs();
  }

  Future<void> markInfoVisited(int animalId) async {
    final current = getDiscovery(animalId);
    if (current.infoVisited) return;

    final wasDiscovered = current.isDiscovered;
    final updated = current.copyWith(
      infoVisited: true,
      discoveredAt:
          (!wasDiscovered && current.soundListened) ? DateTime.now() : null,
    );

    _discoveries[animalId] = updated;
    notifyListeners();

    if (!wasDiscovered && updated.isDiscovered) {
      onAnimalDiscovered?.call(animalId);
    }

    await _saveToPrefs();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap =
            json.decode(jsonString) as Map<String, dynamic>;

        for (final entry in jsonMap.entries) {
          final discovery = AnimalDiscovery.fromJson(
              entry.value as Map<String, dynamic>);
          _discoveries[discovery.animalId] = discovery;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('DiscoveryProvider: failed to load discoveries: $e');
      }
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};

    for (final entry in _discoveries.entries) {
      jsonMap[entry.key.toString()] = entry.value.toJson();
    }

    await prefs.setString(_storageKey, json.encode(jsonMap));
  }
}
