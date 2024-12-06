import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/shared_preferences/sp_manager.dart';
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
  final AdService _adService = AdService();

  @override
  void initState() {
    currentAnimalIndex = widget.animal.index;
    _adService.createInterstitialAd();
    _incrementSoundPlayCount();
    playAnimalAudio();
    super.initState();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _incrementSoundPlayCount() async {
    int currentCount = await SPManager.getSoundPlayCount();
    currentCount++;

    if (currentCount >= 15) {
      if (_adService.isInterstitialAdReady) {
        _adService.showInterstitialAd();
      }
      currentCount = 0;
    }

    await SPManager.setSoundPlayCount(currentCount);
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
