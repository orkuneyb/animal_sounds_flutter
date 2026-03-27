import 'dart:math' as math;

import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/shared_preferences/sp_manager.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class AnimalSoundPage extends StatefulWidget {
  final Animal animal;
  final Color? cardColor;

  const AnimalSoundPage({
    super.key,
    required this.animal,
    this.cardColor,
  });

  @override
  State<AnimalSoundPage> createState() => _AnimalSoundPageState();
}

class _AnimalSoundPageState extends State<AnimalSoundPage>
    with TickerProviderStateMixin {
  late int currentAnimalIndex;
  final AudioPlayer audioPlayer = AudioPlayer();
  late SettingsProvider _settingsProvider;
  final AdService _adService = AdService();

  bool _isPlaying = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _imageScaleController;
  late AnimationController _playButtonPulseController;
  late AnimationController _soundWaveController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _playButtonPulseAnimation;

  // Derived color for the gradient background
  late Color _baseColor;

  @override
  void initState() {
    super.initState();
    currentAnimalIndex = widget.animal.index;

    // Determine base color from cardColor or derive a default pastel
    _baseColor = widget.cardColor ?? Colors.amber[200]!;

    // Fade-in animation for the whole page
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Image scale animation: gentle breathing when playing
    _imageScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _imageScaleController,
        curve: Curves.easeInOut,
      ),
    );

    // Play button pulse animation
    _playButtonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _playButtonPulseAnimation =
        Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _playButtonPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Sound wave animation
    _soundWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeController.forward();

    _adService.createInterstitialAd();
    _incrementSoundPlayCount();
    // Delay playback slightly so the provider is available via didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsProvider = Provider.of<SettingsProvider>(context);
  }

  bool _hasAutoPlayed = false;

  void _autoPlayOnce() {
    if (!_hasAutoPlayed) {
      _hasAutoPlayed = true;
      _playAnimalAudio();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _fadeController.dispose();
    _imageScaleController.dispose();
    _playButtonPulseController.dispose();
    _soundWaveController.dispose();
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

  Future<void> _playAnimalAudio() async {
    try {
      String audioPath = widget.animal.soundPath;
      String cleanPath =
          audioPath.startsWith('assets/') ? audioPath.substring(7) : audioPath;
      await audioPlayer.play(AssetSource(cleanPath));
      await audioPlayer.setVolume(_settingsProvider.getAnimalSoundLevel);

      setState(() => _isPlaying = true);
      _startPlayingAnimations();

      audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() => _isPlaying = false);
          _stopPlayingAnimations();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _stopPlayingAnimations();
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await audioPlayer.pause();
      setState(() => _isPlaying = false);
      _stopPlayingAnimations();
    } else {
      // If the player has completed, replay from the start
      await _playAnimalAudio();
    }
  }

  Future<void> _replay() async {
    await audioPlayer.stop();
    setState(() => _isPlaying = false);
    _stopPlayingAnimations();
    await _playAnimalAudio();
  }

  void _startPlayingAnimations() {
    _imageScaleController.repeat(reverse: true);
    _playButtonPulseController.repeat(reverse: true);
    _soundWaveController.repeat();
  }

  void _stopPlayingAnimations() {
    _imageScaleController.stop();
    _imageScaleController.animateTo(0.0,
        duration: const Duration(milliseconds: 300));
    _playButtonPulseController.stop();
    _playButtonPulseController.animateTo(0.0,
        duration: const Duration(milliseconds: 300));
    _soundWaveController.stop();
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context);
    // Trigger auto-play after build so provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlayOnce());

    final size = MediaQuery.of(context).size;
    final imageSize = size.width * 0.55;

    // Build a soft gradient from the base color
    final Color gradientTop = _lighten(_baseColor, 0.3);
    final Color gradientBottom = _lighten(_baseColor, 0.05);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gradientTop, gradientBottom],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar: back button + favorite button
                _buildTopBar(),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.04),
                        // Animal image with shadow/glow
                        _buildAnimalImage(imageSize),
                        const SizedBox(height: 28),
                        // Animal name
                        _buildAnimalName(),
                        const SizedBox(height: 12),
                        // Sound wave indicator
                        _buildSoundWaveIndicator(),
                        const SizedBox(height: 28),
                        // Playback controls
                        _buildPlaybackControls(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _CircularIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
            backgroundColor: Colors.white.withOpacity(0.6),
            iconColor: Colors.black87,
          ),
          // Favorite button
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              final isFav =
                  favoritesProvider.isFavorite(widget.animal.index);
              return _CircularIconButton(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                onTap: () =>
                    favoritesProvider.toggleFavorite(widget.animal.index),
                backgroundColor: Colors.white.withOpacity(0.6),
                iconColor: isFav ? Colors.redAccent : Colors.black54,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalImage(double imageSize) {
    return AnimatedBuilder(
      animation: _imageScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _imageScaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _baseColor.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            color: Colors.white.withOpacity(0.35),
            padding: const EdgeInsets.all(20),
            child: Hero(
              tag: 'animal_image_${widget.animal.index}',
              child: Image.asset(
                AnimalRepository.animals[currentAnimalIndex].imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalName() {
    return Text(
      widget.animal.name.tr().toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.5,
        color: _darken(_baseColor, 0.45),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaveIndicator() {
    return AnimatedBuilder(
      animation: _soundWaveController,
      builder: (context, _) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              final phase = (index * 0.18) + _soundWaveController.value;
              final height = _isPlaying
                  ? 8.0 + 20.0 * ((math.sin(phase * 2 * math.pi) + 1) / 2)
                  : 6.0;
              return AnimatedContainer(
                duration: Duration(milliseconds: _isPlaying ? 100 : 400),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? _darken(_baseColor, 0.25).withOpacity(0.8)
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Replay button
        _CircularIconButton(
          icon: Icons.replay_rounded,
          onTap: _replay,
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: _darken(_baseColor, 0.35),
          size: 52,
          iconSize: 26,
        ),
        const SizedBox(width: 28),
        // Main play/pause button with pulse
        AnimatedBuilder(
          animation: _playButtonPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPlaying ? _playButtonPulseAnimation.value : 1.0,
              child: child,
            );
          },
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _darken(_baseColor, 0.15),
                    _darken(_baseColor, 0.35),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _darken(_baseColor, 0.2).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 28),
        // Stop button
        _CircularIconButton(
          icon: Icons.stop_rounded,
          onTap: () async {
            await audioPlayer.stop();
            if (mounted) {
              setState(() => _isPlaying = false);
              _stopPlayingAnimations();
            }
          },
          backgroundColor: Colors.white.withOpacity(0.5),
          iconColor: _darken(_baseColor, 0.35),
          size: 52,
          iconSize: 26,
        ),
      ],
    );
  }

  /// Lighten a color by blending it with white.
  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final lightened =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }

  /// Darken a color by reducing its lightness.
  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}

/// A reusable circular icon button with subtle background.
class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const _CircularIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 44,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}
