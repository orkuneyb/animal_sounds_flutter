import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:flutter/material.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Animal animal;
  const AnimalDetailsPage({super.key, required this.animal});

  @override
  State<AnimalDetailsPage> createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
