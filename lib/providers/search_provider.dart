import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';
import '../repositories/animal_repository.dart';

class SearchProvider extends ChangeNotifier {
  List<Animal> _searchResults = [];
  List<String> _searchHistory = [];
  final int _maxHistoryItems = 10;
  String _searchQuery = '';
  TextEditingController searchController = TextEditingController();

  List<Animal> get searchResults => _searchResults;
  List<String> get searchHistory => _searchHistory;
  String get searchQuery => _searchQuery;
  bool get isSearching => searchController.text.isNotEmpty;

  SearchProvider() {
    _loadSearchHistory();
    searchController.addListener(() {
      search(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void init(BuildContext context) {
    searchController.addListener(() {
      if (context.mounted) {
        search(searchController.text);
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    notifyListeners();
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
  }

  void addToHistory(String query) {
    if (query.isEmpty) return;

    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeLast();
    }

    _saveSearchHistory();
    notifyListeners();
  }

  void clearHistory() {
    _searchHistory.clear();
    _saveSearchHistory();
    notifyListeners();
  }

  void removeFromHistory(String query) {
    _searchHistory.remove(query);
    _saveSearchHistory();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();

    if (_searchQuery.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = AnimalRepository.animals.where((animal) {
        final name = animal.name.tr().toLowerCase();
        final originalName = animal.name.toLowerCase();
        final description = animal.description.tr().toLowerCase();
        final originalDescription = animal.description.toLowerCase();

        return name.contains(_searchQuery) ||
            originalName.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            originalDescription.contains(_searchQuery);
      }).toList();
    }

    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  void searchFromHistory(String query) {
    searchController.text = query;
    search(query);
  }
}
