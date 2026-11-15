import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/compare_page.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/banner_ad_widget.dart';
import 'package:animal_sounds_flutter/widgets/pressable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

/// Picture facts about one animal for children who cannot read yet: where it
/// lives, what it eats and how big it is, each as one picture and one word
/// that is read aloud on tap. Longer texts sit in a fold-out for grown-ups.
class AnimalInfoPage extends StatefulWidget {
  const AnimalInfoPage({super.key, required this.animal});

  final Animal animal;

  @override
  State<AnimalInfoPage> createState() => _AnimalInfoPageState();
}

class _AnimalInfoPageState extends State<AnimalInfoPage> {
  final FlutterTts _tts = FlutterTts();

  /// The text being read aloud right now, or null.
  final ValueNotifier<String?> _speaking = ValueNotifier<String?>(null);
  bool _ttsReady = false;
  bool _visitTracked = false;

  Animal get _animal => widget.animal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ttsReady) {
      _ttsReady = true;
      _initTts(context.locale.languageCode);
    }
    if (!_visitTracked) {
      _visitTracked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _trackVisit();
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _speaking.dispose();
    super.dispose();
  }

  Future<void> _initTts(String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.05);
      _tts.setCompletionHandler(() => _speaking.value = null);
    } catch (_) {
      // No speech engine on this device; the page still works silently.
    }
  }

  /// Reads [text] aloud; a second tap on the same text stops it.
  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      if (_speaking.value == text) {
        _speaking.value = null;
        return;
      }
      _speaking.value = text;
      await _tts.speak(text);
    } catch (_) {
      _speaking.value = null;
    }
  }

  /// Tracks the visit across discovery, usage stats, badges and challenges.
  void _trackVisit() {
    final discovery = context.read<DiscoveryProvider>();
    final achievements = context.read<AchievementProvider>();

    discovery.markInfoVisited(_animal.index);
    context.read<UsageStatsProvider>().incrementInfoVisited(_animal.index);
    achievements.incrementProgress('first_info', 1);
    achievements.incrementProgress('curious_mind', 1);
    // "Read about every animal" counts distinct animals, not visits.
    achievements.setProgress('animal_expert', discovery.infoVisitedCount);
    achievements.incrementProgress('fact_lover', 1);
    context
        .read<ChallengeProvider>()
        .recordEvent('info', animalId: _animal.index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _FactCard(
                  icon: _animal.home.icon,
                  tint: const Color(0xFFDDF0C8),
                  label: 'info_lives'.tr(),
                  value: _animal.home.labelKey.tr(),
                  speaking: _speaking,
                  onSpeak: _speak,
                ),
                _FactCard(
                  icon: _animal.food.icon,
                  tint: const Color(0xFFFFD9D6),
                  label: 'info_eats'.tr(),
                  value: _animal.food.labelKey.tr(),
                  speaking: _speaking,
                  onSpeak: _speak,
                ),
                _FactCard(
                  icon: Icons.straighten_rounded,
                  tint: const Color(0xFFCFE6FB),
                  label: 'info_size'.tr(),
                  value: _animal.bigness.labelKey.tr(),
                  speaking: _speaking,
                  onSpeak: _speak,
                  footer: _SizePicture(animal: _animal),
                ),
                for (final fact in _animal.funFacts)
                  _FunFactCard(
                    text: fact.tr(),
                    speaking: _speaking,
                    onSpeak: _speak,
                  ),
                _buildDetails(),
              ],
            ),
          ),
          const SafeArea(top: false, child: BannerAdWidget()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _animal.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          child: Row(
            children: [
              _HeaderButton(
                icon: Icons.arrow_back_rounded,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Image.asset(_animal.imagePath, width: 76, height: 76),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    _animal.name.tr(),
                    maxLines: 1,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _HeaderButton(
                icon: Icons.compare_arrows_rounded,
                label: 'compare'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ComparePage()),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<FavoritesProvider>(
                builder: (context, favorites, _) {
                  final isFavorite = favorites.isFavorite(_animal.index);
                  return _HeaderButton(
                    icon: isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor:
                        isFavorite ? const Color(0xFFE5484D) : AppColors.ink,
                    label: 'favorites_title'.tr(),
                    onTap: () => favorites.toggleFavorite(_animal.index),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The long texts, folded away so the page stays picture-first.
  Widget _buildDetails() {
    final rows = <(String, String)>[
      ('description', _animal.description),
      ('size', _animal.size),
      ('weight', _animal.weight),
      ('lifespan', _animal.lifespan),
      ('habitat', _animal.habitat),
      ('diet', _animal.diet),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 10, 14),
          iconColor: AppColors.ink,
          collapsedIconColor: AppColors.inkSoft,
          title: Text(
            'info_more'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          children: [
            for (final (labelKey, textKey) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelKey.tr(),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            textKey.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SpeakButton(
                      text: textKey.tr(),
                      speaking: _speaking,
                      onSpeak: _speak,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One picture fact: a tinted icon, a small label and one big word.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.speaking,
    required this.onSpeak,
    this.footer,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;
  final ValueNotifier<String?> speaking;
  final ValueChanged<String> onSpeak;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final spoken = '$label: $value';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => onSpeak(spoken),
        semanticLabel: spoken,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 36, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          value,
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SpeakButton(
                    text: spoken,
                    speaking: speaking,
                    onSpeak: onSpeak,
                  ),
                ],
              ),
              if (footer != null) footer!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A child figure next to the animal, drawn to rough scale.
class _SizePicture extends StatelessWidget {
  const _SizePicture({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    const childHeight = 80.0;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 136,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.boy_rounded,
                size: childHeight, color: AppColors.inkSoft),
            const SizedBox(width: 18),
            Image.asset(
              animal.imagePath,
              height: (childHeight * animal.bigness.scale).clamp(40.0, 136.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _FunFactCard extends StatelessWidget {
  const _FunFactCard({
    required this.text,
    required this.speaking,
    required this.onSpeak,
  });

  final String text;
  final ValueNotifier<String?> speaking;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => onSpeak(text),
        semanticLabel: text,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1C9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_rounded,
                  size: 30, color: Color(0xFFE8A317)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _SpeakButton(text: text, speaking: speaking, onSpeak: onSpeak),
            ],
          ),
        ),
      ),
    );
  }
}

/// Speaker button that turns into a stop button while its text is read.
class _SpeakButton extends StatelessWidget {
  const _SpeakButton({
    required this.text,
    required this.speaking,
    required this.onSpeak,
  });

  final String text;
  final ValueNotifier<String?> speaking;
  final ValueChanged<String> onSpeak;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: speaking,
      builder: (context, current, _) {
        final active = current == text;
        return IconButton(
          onPressed: () => onSpeak(text),
          iconSize: 28,
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          color: AppColors.pop,
          icon: Icon(active ? Icons.stop_circle_rounded : Icons.volume_up_rounded),
        );
      },
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: iconColor),
      ),
    );
  }
}
