import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryRepository {
  static final List<Category> categories = [
    Category(
      id: 1,
      name: "domestic_animals",
      icon: Icons.pets,
      description: "domestic_animals_desc",
      animalIds: [3, 4], // Köpek, kedi
    ),
    Category(
      id: 2,
      name: "wild_animals",
      icon: Icons.forest,
      description: "wild_animals_desc",
      animalIds: [0, 1, 2, 23, 24], // Aslan, fil, kaplan, ayı, kurt
    ),
    Category(
      id: 3,
      name: "sea_animals",
      icon: Icons.water,
      description: "sea_animals_desc",
      animalIds: [14, 15], // Yunus, balina
    ),
    Category(
      id: 4,
      name: "birds",
      icon: Icons.flutter_dash,
      description: "birds_desc",
      animalIds: [7, 8, 20], // Horoz, ördek, baykuş
    ),
    Category(
      id: 5,
      name: "insects",
      icon: Icons.bug_report,
      description: "insects_desc",
      animalIds: [22], // Arı
    ),
    Category(
      id: 6,
      name: "farm_animals",
      icon: Icons.agriculture,
      description: "farm_animals_desc",
      animalIds: [5, 6, 9, 10], // İnek, at, domuz, koyun
    ),
    Category(
      id: 7,
      name: "jungle_animals",
      icon: Icons.park,
      description: "jungle_animals_desc",
      animalIds: [11, 12, 17], // Maymun, goril, zürafa
    ),
    Category(
      id: 8,
      name: "desert_animals",
      icon: Icons.landscape,
      description: "desert_animals_desc",
      animalIds: [27], // Deve
    ),
  ];

  static List<Category> getCategories() {
    return categories;
  }

  static Category getCategoryById(int id) {
    return categories.firstWhere((category) => category.id == id);
  }
}
