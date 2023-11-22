import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/animal_details.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/transitions/page_transitions.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: AnimalRepository.animals.length,
        itemBuilder: (BuildContext context, int index) {
          Animal animal = AnimalRepository.animals[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageTransitions.createScaleTransition(
                  AnimalDetailsPage(animal: animal),
                ),
              );
            },
            child: Card(
              elevation: 4,
              color: Colors.yellow[200],
              child: Image.asset(
                animal.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar appBarWidget() {
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        "Hayvan Sesleri",
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, "/settingsPage");
          },
        ),
      ],
    );
  }
}
