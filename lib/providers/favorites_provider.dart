import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/favorite.dart';
import '../models/animal.dart';
import '../repositories/animal_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];
  final String _prefsKey = 'favorites';

  List<Favorite> get favorites => _favorites;

  /// Called after every toggle with the new favourite count, whether the
  /// animal was added, and its index. Achievements and weekly challenges
  /// listen here.
  void Function(int count, bool added, int animalId)? onFavoritesChanged;

  List<Animal> get favoriteAnimals {
    return _favorites.map((fav) {
      return AnimalRepository.animals.firstWhere(
        (animal) => animal.index == fav.animalId,
      );
    }).toList();
  }

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString(_prefsKey);

    if (favoritesJson != null) {
      final List<dynamic> decoded = jsonDecode(favoritesJson);
      _favorites = decoded.map((item) => Favorite.fromJson(item)).toList();
      _sortFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded =
        jsonEncode(_favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  bool isFavorite(int animalId) {
    return _favorites.any((fav) => fav.animalId == animalId);
  }

  Future<void> toggleFavorite(int animalId) async {
    final added = !isFavorite(animalId);
    if (!added) {
      _favorites.removeWhere((fav) => fav.animalId == animalId);
    } else {
      _favorites.add(Favorite(
        animalId: animalId,
        addedDate: DateTime.now(),
      ));
    }
    _sortFavorites();
    notifyListeners();
    onFavoritesChanged?.call(_favorites.length, added, animalId);
    await _saveFavorites();
  }

  void _sortFavorites() {
    _favorites.sort((a, b) => b.addedDate.compareTo(a.addedDate));
  }

  void clearFavorites() async {
    _favorites.clear();
    notifyListeners();
    await _saveFavorites();
  }
}
