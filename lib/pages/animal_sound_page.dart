import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class AnimalSoundPage extends StatefulWidget {
  final Animal animal;
  const AnimalSoundPage({super.key, required this.animal});

  @override
  State<AnimalSoundPage> createState() => _AnimalSoundPageState();
}

class _AnimalSoundPageState extends State<AnimalSoundPage> {
  late int currentAnimalIndex;
  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  late SettingsProvider _settingsProvider;

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

      audioPlayer.setVolume(_settingsProvider.getAnimalSoundLevel);
      audioPlayer.playlistAudioFinished.listen((event) {
        Navigator.pop(context);
      });
    } catch (e) {
      Exception(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context);
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
                widget.animal.name.tr().toUpperCase(),
                style: MyTextStyles.titleTextStyle,
              )
            ],
          ),
        ),
      ],
    );
  }
}