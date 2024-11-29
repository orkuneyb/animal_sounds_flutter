import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final IconData icon;
  final String description;
  final List<int> animalIds;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.animalIds,
  });

  Category.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        icon = json['icon'],
        description = json['description'],
        animalIds = List<int>.from(json['animalIds']);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'description': description,
        'animalIds': animalIds,
      };
}
