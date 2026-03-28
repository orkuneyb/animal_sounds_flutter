import 'package:animal_sounds_flutter/pages/sound_guess_game_page.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animal_sounds_flutter/pages/quiz_page.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum GameMode { quiz, soundGuess }

class QuizStartPage extends StatefulWidget {
  const QuizStartPage({Key? key}) : super(key: key);

  @override
  State<QuizStartPage> createState() => _QuizStartPageState();
}

class _QuizStartPageState extends State<QuizStartPage>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  final AdService _adService = AdService();
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GameMode _selectedMode = GameMode.quiz;

  @override
  void initState() {
    super.initState();
    _adService.createInterstitialAd();
    _bannerAd = _adService.createBannerAd()
      ..load().then((_) {
        setState(() {
          _isBannerAdReady = true;
        });
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTtsInitialized) {
      _initTts();
      _isTtsInitialized = true;
    }
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage(context.locale.languageCode);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bannerAd.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _navigateToSelectedMode() {
    final Widget destination = _selectedMode == GameMode.quiz
        ? const QuizPage()
        : const SoundGuessGamePage();

    if (_adService.isInterstitialAdReady) {
      _adService.showInterstitialAd(
        onAdClosed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destination,
            ),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => destination,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F5E9),
                    Color(0xFFFFF8E1),
                    Color(0xFFE3F2FD),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Back button row
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.onSurface,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                      // Animated icon
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _selectedMode == GameMode.quiz
                                  ? [
                                      const Color(0xFF66BB6A),
                                      const Color(0xFF43A047),
                                    ]
                                  : [
                                      const Color(0xFF42A5F5),
                                      const Color(0xFF1565C0),
                                    ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedMode == GameMode.quiz
                                        ? AppColors.primary
                                        : AppColors.tertiary)
                                    .withOpacity(0.3),
                                spreadRadius: 4,
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _selectedMode == GameMode.quiz
                                ? Icons.extension_rounded
                                : Icons.headphones_rounded,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title with TTS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedMode == GameMode.quiz
                                  ? 'quiz_welcome'.tr()
                                  : 'sound_guess_title'.tr(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildSmallTtsButton(() => _speak(
                              _selectedMode == GameMode.quiz
                                  ? 'quiz_welcome'.tr()
                                  : 'sound_guess_title'.tr())),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description with TTS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedMode == GameMode.quiz
                                  ? 'quiz_description'.tr()
                                  : 'sound_guess_description'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildSmallTtsButton(() => _speak(
                              _selectedMode == GameMode.quiz
                                  ? 'quiz_description'.tr()
                                  : 'sound_guess_description'.tr())),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Mode Selection Cards
                      _buildModeSelection(),
                      const Spacer(flex: 2),
                      // Start button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _selectedMode == GameMode.quiz
                                  ? [
                                      const Color(0xFF66BB6A),
                                      const Color(0xFF43A047),
                                    ]
                                  : [
                                      const Color(0xFF42A5F5),
                                      const Color(0xFF1565C0),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(29),
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedMode == GameMode.quiz
                                        ? AppColors.primary
                                        : AppColors.tertiary)
                                    .withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _navigateToSelectedMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(29),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedMode == GameMode.quiz
                                      ? 'start_quiz'.tr()
                                      : 'sound_guess_start'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildModeCard(
            mode: GameMode.quiz,
            icon: Icons.extension_rounded,
            title: 'mode_quiz_title'.tr(),
            description: 'mode_quiz_desc'.tr(),
            gradientColors: [const Color(0xFF66BB6A), const Color(0xFF43A047)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModeCard(
            mode: GameMode.soundGuess,
            icon: Icons.headphones_rounded,
            title: 'mode_sound_guess_title'.tr(),
            description: 'mode_sound_guess_desc'.tr(),
            gradientColors: [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required GameMode mode,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? gradientColors.first.withOpacity(0.1)
              : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? gradientColors.first
                : AppColors.outlineVariant.withOpacity(0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: gradientColors)
                    : null,
                color: isSelected ? null : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? gradientColors.first
                    : AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTtsButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          size: 16,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
