import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Who recorded the animal sounds, and under which licence each is used.
///
/// The Creative Commons Attribution licences require this list. Full source
/// links are kept in docs/credits/sounds.md.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  /// (animal key, author, licence)
  static const List<(String, String, String)> soundCredits = [
    ('goat', 'stephan (PDSounds.org)', 'Public domain'),
    ('donkey', 'felix-blume (Freesound)', 'CC0 1.0'),
    ('chicken', 'alys (PDSounds.org)', 'Public domain'),
    ('turkey', 'bod (PDSounds.org)', 'Public domain'),
    ('goose', 'U.S. Fish and Wildlife Service', 'Public domain'),
    ('parrot', 'Richard Ranft / The British Library Board', 'CC BY 4.0'),
    ('eagle', 'U.S. National Park Service', 'Public domain'),
    ('crow', 'G McGrane', 'Public domain'),
    ('seagull', 'U.S. National Park Service', 'Public domain'),
    ('cuckoo', 'Σ64 (Wikimedia Commons)', 'CC BY 3.0'),
    ('peacock', 'Ke4roh (Wikimedia Commons)', 'Public domain'),
    ('pigeon', 'Oona Räisänen', 'Public domain'),
    ('swan', 'Richard Ridgeway / The British Library Board', 'CC BY 4.0'),
    ('hyena', 'David Watts / The British Library', 'CC BY 4.0'),
    ('deer', 'U.S. National Park Service', 'Public domain'),
    ('panda', 'Wikimedia Commons contributor', 'Public domain'),
    ('seal', 'Department of Conservation (New Zealand)', 'CC BY 4.0'),
    ('cricket', 'Natural History Museum, London (BioAcoustica)', 'CC BY 3.0'),
    ('mouse', 'Holy T, Guo Z. PLOS Biology, 2005', 'CC BY 3.0'),
    ('squirrel', 'U.S. National Park Service', 'Public domain'),
  ];

  /// Attribution licences must be named with a link to their text.
  static String _licenseUrl(String license) => switch (license) {
        'CC BY 4.0' => ' · creativecommons.org/licenses/by/4.0',
        'CC BY 3.0' => ' · creativecommons.org/licenses/by/3.0',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'sound_credits'.tr(),
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'sound_credits_note'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkSoft),
            ),
          ),
          for (final (animal, author, license) in soundCredits)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Image.asset('assets/animal_images/$animal.png',
                      width: 44, height: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.tr(),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$author · $license${_licenseUrl(license)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
