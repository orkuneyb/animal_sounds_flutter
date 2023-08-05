import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:flutter/material.dart';

import '../utils/colors/colors.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Animal animal;
  const AnimalDetailsPage({super.key, required this.animal});

  @override
  State<AnimalDetailsPage> createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  late int currentAnimalIndex;

  @override
  void initState() {
    currentAnimalIndex = widget.animal.index;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: appBarWidget(),
        body: bodyWidget(),
        bottomNavigationBar: bottomNavigationBarWidget(),
      ),
    );
  }

  AppBar appBarWidget() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        "Hayvan Sesleri",
      ),
    );
  }

  AnimatedSwitcher bodyWidget() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Column(
        key: ValueKey<int>(currentAnimalIndex),
        children: [
          Container(
            color: Colors.pink[300],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  color: iconColor,
                  onPressed: () {
                    //TODO: HAYVANI LİKELAYABİLECEK
                  },
                  icon: const Icon(
                    Icons.favorite,
                  ),
                ),
                Text(
                  AnimalRepository.animals[currentAnimalIndex].name,
                  style: MyTextStyles.myCustomTextStyle,
                ),
                IconButton(
                  color: iconColor,
                  onPressed: () {
                    //TODO: HAYVANIN SESİ ÇALACAK
                  },
                  icon: const Icon(
                    Icons.volume_up,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.75,
            width: MediaQuery.of(context).size.width,
            color: themeColor,
            child: Image.asset(
              AnimalRepository.animals[currentAnimalIndex].imagePath,
              errorBuilder: (context, error, stackTrace) =>
                  const Text("resim yüklenemedi"),
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Row bottomNavigationBarWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          iconSize: 50,
          color: bottomNavigationBarButtonColor,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              if (currentAnimalIndex > 0) {
                currentAnimalIndex--;
              } else {
                currentAnimalIndex = AnimalRepository.animals.length - 1;
              }
            });
          },
        ),
        IconButton(
          iconSize: 50,
          color: bottomNavigationBarButtonColor,
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            setState(() {
              if (currentAnimalIndex < AnimalRepository.animals.length - 1) {
                currentAnimalIndex++;
              } else {
                currentAnimalIndex = 0;
              }
            });
          },
        ),
      ],
    );
  }
}
