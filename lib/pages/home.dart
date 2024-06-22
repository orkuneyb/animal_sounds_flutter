import 'package:flutter/material.dart';
import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/animal_details.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/transitions/page_transitions.dart';

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
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.amber[100 * ((index % 8) + 1)],
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      animal.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
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
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, "/settingsPage");
          },
        ),
      ],
      backgroundColor: Colors.orangeAccent,
    );
  }
}
