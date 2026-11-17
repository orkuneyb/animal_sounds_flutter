import 'dart:convert';

import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One photo or sound credit, as stored in `assets/credits.json`.
class Credit {
  const Credit({
    required this.animal,
    required this.kind,
    required this.author,
    required this.license,
    required this.licenseUrl,
  });

  factory Credit.fromJson(Map<String, dynamic> json) => Credit(
        animal: json['animal'] as String,
        kind: json['kind'] as String,
        author: json['author'] as String? ?? '',
        license: json['license'] as String? ?? '',
        licenseUrl: json['license_url'] as String? ?? '',
      );

  /// Animal key, as in [AnimalRepository].
  final String animal;

  /// `image` or `sound`.
  final String kind;
  final String author;
  final String license;
  final String licenseUrl;

  /// Author, licence and, for attribution licences, the licence address.
  String get line {
    final url = licenseUrl
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
    final needsLink = license.toUpperCase().startsWith('CC BY');
    return [
      if (author.isNotEmpty) author,
      license,
      if (needsLink && url.isNotEmpty) url,
    ].join(' · ');
  }

  static Future<List<Credit>> load() async {
    final text = await rootBundle.loadString('assets/credits.json');
    return [
      for (final item in jsonDecode(text) as List<dynamic>)
        Credit.fromJson(item as Map<String, dynamic>),
    ];
  }
}

/// "Sources and licences": who took each photo and recorded each sound, and
/// under which licence it is used. The attribution licences require this
/// page. Full source links are kept in docs/credits/credits.json.
class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  late final Future<List<Credit>> _credits = Credit.load();

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
      body: FutureBuilder<List<Credit>>(
        future: _credits,
        builder: (context, snapshot) {
          final credits = snapshot.data;
          if (credits == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // In the app's own animal order; animals without a credit are
          // left out.
          final byAnimal = <String, List<Credit>>{};
          for (final credit in credits) {
            byAnimal.putIfAbsent(credit.animal, () => []).add(credit);
          }
          final animals = [
            for (final animal in AnimalRepository.animals)
              if (byAnimal.containsKey(animal.name)) animal,
          ];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: Text(
                  'sound_credits_note'.tr(),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.inkSoft),
                ),
              ),
              for (final animal in animals)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(animal.imagePath, width: 44, height: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animal.name.tr(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            for (final credit in byAnimal[animal.name]!)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${(credit.kind == 'image' ? 'credit_photo' : 'credit_sound').tr()}: ${credit.line}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
