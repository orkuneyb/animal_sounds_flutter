import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/pages/coloring_page.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/settings_provider.dart';
import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/shared_preferences/sp_manager.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/pressable.dart';
import 'package:animal_sounds_flutter/widgets/voice_recorder_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// One animal, full screen: a big picture, a big play button, and arrows to
/// the previous and next animal. Everything a small child needs is one tap.
class AnimalSoundPage extends StatefulWidget {
  const AnimalSoundPage({super.key, required this.animal, this.animals});

  /// The animal shown first.
  final Animal animal;

  /// The list the arrows step through (the group the child was browsing).
  /// Defaults to every animal.
  final List<Animal>? animals;

  @override
  State<AnimalSoundPage> createState() => _AnimalSoundPageState();
}

class _AnimalSoundPageState extends State<AnimalSoundPage>
    with TickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  final AdService _adService = AdService();
  StreamSubscription<void>? _completeSubscription;

  late final List<Animal> _animals =
      widget.animals ?? AnimalRepository.animals;
  late Animal _animal = widget.animal;

  bool _isPlaying = false;
  bool _hasAutoPlayed = false;

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) _setPlaying(false);
    });
    _adService.createInterstitialAd();
    _countVisitForInterstitial();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasAutoPlayed) {
      _hasAutoPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void dispose() {
    _completeSubscription?.cancel();
    _player.dispose();
    _bounce.dispose();
    _wave.dispose();
    super.dispose();
  }

  /// A full-screen ad after every 15 times this page is opened from a list.
  Future<void> _countVisitForInterstitial() async {
    var count = await SPManager.getSoundPlayCount() + 1;
    if (count >= 15) {
      if (_adService.isInterstitialAdReady) _adService.showInterstitialAd();
      count = 0;
    }
    await SPManager.setSoundPlayCount(count);
  }

  /// Tracks a play across discovery, usage stats, badges and challenges.
  void _trackPlay() {
    final discovery = context.read<DiscoveryProvider>();
    final achievements = context.read<AchievementProvider>();

    discovery.markSoundListened(_animal.index);
    context.read<UsageStatsProvider>().incrementSoundsListened(_animal.index);
    achievements.incrementProgress('first_sound', 1);
    achievements.incrementProgress('sound_explorer', 1);
    // "Listen to every animal" counts distinct animals, not plays.
    achievements.setProgress('sound_master', discovery.soundListenedCount);
    achievements.incrementProgress('repeat_listener', 1);
    achievements.incrementProgress('sound_marathon', 1);
    context
        .read<ChallengeProvider>()
        .recordEvent('listen', animalId: _animal.index);
  }

  void _setPlaying(bool playing) {
    setState(() => _isPlaying = playing);
    if (playing) {
      _bounce.repeat(reverse: true);
      _wave.repeat();
    } else {
      _bounce.animateTo(0, duration: const Duration(milliseconds: 250));
      _wave.stop();
    }
  }

  Future<void> _play() async {
    final volume = context.read<SettingsProvider>().getAnimalSoundLevel;
    try {
      await _player.stop();
      await _player.setVolume(volume);
      await _player.play(
        AssetSource(_animal.soundPath.replaceFirst('assets/', '')),
      );
      if (!mounted) return;
      AnalyticsService().soundPlayed(_animal.name);
      _setPlaying(true);
      _trackPlay();
    } catch (_) {
      if (mounted) _setPlaying(false);
    }
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stop();
      if (mounted) _setPlaying(false);
    } else {
      await _play();
    }
  }

  void _step(int delta) {
    final position = _animals.indexWhere((a) => a.index == _animal.index);
    final next = _animals[(position + delta) % _animals.length];
    if (next.index == _animal.index) return;
    // No full-screen ad here: it would open under a finger mid-tap.
    setState(() => _animal = next);
    _play();
  }

  Future<void> _openRecorder() async {
    await _player.stop();
    if (!mounted) return;
    _setPlaying(false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          // The recorder would otherwise stretch over the whole screen.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: SingleChildScrollView(
              child: VoiceRecorderWidget(
                animalSoundPath: _animal.soundPath,
                animalName: _animal.name.tr(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(Widget page) {
    _player.stop();
    _setPlaying(false);
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _animal.color,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 250) return;
              final towardsNext =
                  (velocity < 0) == (Directionality.of(context) == ui.TextDirection.ltr);
              _step(towardsNext ? 1 : -1);
            },
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildAnimal()),
                _buildWave(),
                const SizedBox(height: 12),
                _buildControls(),
                const SizedBox(height: 20),
                _buildActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            icon: Icons.arrow_back_rounded,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => Navigator.pop(context),
          ),
          Consumer<FavoritesProvider>(
            builder: (context, favorites, _) {
              final isFavorite = favorites.isFavorite(_animal.index);
              return _RoundButton(
                icon: isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: isFavorite ? const Color(0xFFE5484D) : AppColors.ink,
                label: 'favorites_title'.tr(),
                onTap: () => favorites.toggleFavorite(_animal.index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimal() {
    return Pressable(
      onTap: _togglePlay,
      semanticLabel: _animal.name.tr(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Column(
          key: ValueKey(_animal.index),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 1.06).animate(
                    CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
                  ),
                  child: Hero(
                    tag: 'animal_image_${_animal.index}',
                    child: Image.asset(_animal.imagePath),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _animal.name.tr(),
                  maxLines: 1,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWave() {
    return AnimatedBuilder(
      animation: _wave,
      builder: (context, _) {
        return SizedBox(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(7, (i) {
              final phase = i * 0.18 + _wave.value;
              final height = _isPlaying
                  ? 8.0 + 20.0 * ((math.sin(phase * 2 * math.pi) + 1) / 2)
                  : 6.0;
              return AnimatedContainer(
                duration: Duration(milliseconds: _isPlaying ? 100 : 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: _isPlaying ? 0.7 : 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    final showArrows = _animals.length > 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showArrows)
          _RoundButton(
            icon: Icons.chevron_left_rounded,
            size: 60,
            iconSize: 36,
            label: MaterialLocalizations.of(context).previousPageTooltip,
            onTap: () => _step(-1),
          ),
        const SizedBox(width: 22),
        Pressable(
          onTap: _togglePlay,
          semanticLabel: 'play_sound'.tr(),
          child: Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: AppColors.pop,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 22),
        if (showArrows)
          _RoundButton(
            icon: Icons.chevron_right_rounded,
            size: 60,
            iconSize: 36,
            label: MaterialLocalizations.of(context).nextPageTooltip,
            onTap: () => _step(1),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: Icons.menu_book_rounded,
          size: 64,
          iconSize: 30,
          label: 'animal_info'.tr(),
          onTap: () => _open(AnimalInfoPage(animal: _animal)),
        ),
        const SizedBox(width: 18),
        _RoundButton(
          icon: Icons.palette_rounded,
          size: 64,
          iconSize: 30,
          label: 'coloring'.tr(),
          onTap: () => _open(ColoringPage(animal: _animal)),
        ),
        const SizedBox(width: 18),
        _RoundButton(
          icon: Icons.mic_rounded,
          size: 64,
          iconSize: 30,
          label: 'you_try'.tr(),
          onTap: _openRecorder,
        ),
      ],
    );
  }
}

/// White round icon button with a screen-reader label.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 52,
    this.iconSize = 26,
    this.iconColor = AppColors.ink,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
