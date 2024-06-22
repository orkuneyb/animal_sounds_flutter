import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  onTap() {
    AppSettings.openAppSettingsPanel(AppSettingsPanelType.volume);
  }

  @override
  Widget build(BuildContext context) {
    SettingsProvider settingsProvider = Provider.of<SettingsProvider>(context);
    double soundLevel = settingsProvider.getAnimalSoundLevel;
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'settings'.tr(),
            textAlign: TextAlign.center,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text("sound_settings".tr(),
                    style: MyTextStyles.subtitleTextStyle),
                onTap: () => onTap(),
              ),
              const Divider(
                thickness: 2,
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  Text("sound_level".tr(),
                      style: MyTextStyles.subtitleTextStyle),
                  Slider(
                      value: soundLevel,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (double dbVal) {
                        settingsProvider.setAnimalSoundLevel = dbVal;
                      }),
                ],
              )
            ],
          ),
        ));
  }
}
