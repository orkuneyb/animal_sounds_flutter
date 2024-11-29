import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  int? _selectedCategoryId;

  CategoryProvider() {
    _loadCategories();
  }

  void _loadCategories() {
    _categories = CategoryRepository.getCategories();
    notifyListeners();
  }

  List<Category> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  List<int> getAnimalIdsByCategory(int categoryId) {
    return _categories
        .firstWhere((category) => category.id == categoryId)
        .animalIds;
  }
}
