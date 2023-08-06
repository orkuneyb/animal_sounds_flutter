import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Animal animal;
  const AnimalDetailsPage({super.key, required this.animal});

  @override
  State<AnimalDetailsPage> createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  late int currentAnimalIndex;
  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    currentAnimalIndex = widget.animal.index;
    playAnimalAudio();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  playAnimalAudio() async {
    try {
      String audioPath = widget.animal.soundPath;
      await audioPlayer.open(
        Audio(audioPath),
      );
      audioPlayer.playlistAudioFinished.listen((event) {
        Navigator.pop(context);
      });
    } catch (e) {
      Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bodyWidget(),
    );
  }

  bodyWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.yellow[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AnimalRepository.animals[currentAnimalIndex].imagePath,
                fit: BoxFit.contain,
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                widget.animal.name.toUpperCase(),
                style: MyTextStyles.titleTextStyle,
              )
            ],
          ),
        ),
      ],
    );
  }
}
