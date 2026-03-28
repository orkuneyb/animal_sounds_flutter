import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/streak_calendar_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

/// A list of gradient color pairs, one per animal index (mod 10).
const List<List<Color>> _dailyGradients = [
  [Color(0xFFFF9A8B), Color(0xFFFF6A88)], // warm coral
  [Color(0xFF89CFF0), Color(0xFF4D96FF)], // ocean blue
  [Color(0xFFA8E6CF), Color(0xFF56C596)], // mint green
  [Color(0xFFFFD1DC), Color(0xFFFF85A1)], // soft pink
  [Color(0xFFFFE5A0), Color(0xFFFFC23C)], // sunny yellow
  [Color(0xFFD4A5FF), Color(0xFF9B59B6)], // lavender
  [Color(0xFFFFCCBC), Color(0xFFFF7043)], // peach
  [Color(0xFFB2EBF2), Color(0xFF00ACC1)], // cyan
  [Color(0xFFC8E6C9), Color(0xFF4CAF50)], // nature green
  [Color(0xFFFFE0B2), Color(0xFFFF9800)], // amber
];

class DailyDiscoveryPage extends StatefulWidget {
  const DailyDiscoveryPage({super.key});

  @override
  State<DailyDiscoveryPage> createState() => _DailyDiscoveryPageState();
}

class _DailyDiscoveryPageState extends State<DailyDiscoveryPage>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _isPlayingSound = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _audioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _playSound(String soundPath) async {
    if (_isPlayingSound) return;
    setState(() => _isPlayingSound = true);
    try {
      await _audioPlayer.play(AssetSource(soundPath.replaceFirst('assets/', '')));
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlayingSound = false);
      });
    } catch (_) {
      if (mounted) setState(() => _isPlayingSound = false);
    }
  }

  Future<void> _speakFact(String text) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    await _tts.speak(text.tr());
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyProvider>(
      builder: (context, dailyProvider, _) {
        final Animal animal = dailyProvider.getDailyAnimal();
        final String funFact = dailyProvider.getDailyFunFact();
        final bool completed = dailyProvider.isTodayCompleted;
        final gradientColors =
            _dailyGradients[animal.index % _dailyGradients.length];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  gradientColors[0].withOpacity(0.6),
                  gradientColors[1].withOpacity(0.3),
                  AppColors.surface,
                ],
                stops: const [0.0, 0.4, 0.7],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App bar row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.onSurface,
                        ),
                        const Spacer(),
                        Text(
                          'daily_discovery'.tr(),
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // "Animal of the Day" label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: gradientColors[0].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: gradientColors[0].withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'animal_of_the_day'.tr(),
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: gradientColors[1],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Animal image with entrance animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          gradientColors[0].withOpacity(0.3),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Image.asset(
                                  animal.imagePath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Animal name
                          Text(
                            animal.name.tr(),
                            style: AppTextStyles.headingLarge.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Play sound button
                          FilledButton.tonalIcon(
                            onPressed: () => _playSound(animal.soundPath),
                            icon: Icon(
                              _isPlayingSound
                                  ? Icons.volume_up_rounded
                                  : Icons.play_circle_filled_rounded,
                            ),
                            label: Text('play_sound'.tr()),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  gradientColors[0].withOpacity(0.2),
                              foregroundColor: gradientColors[1],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Fun fact card
                          if (funFact.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_rounded,
                                        color: AppColors.warning,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'todays_fun_fact'.tr(),
                                        style:
                                            AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      // TTS button
                                      IconButton(
                                        onPressed: () =>
                                            _speakFact(funFact),
                                        icon: Icon(
                                          _isSpeaking
                                              ? Icons.stop_circle_rounded
                                              : Icons
                                                  .volume_up_rounded,
                                          color: AppColors.tertiary,
                                        ),
                                        tooltip: 'listen_fact'.tr(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    funFact.tr(),
                                    style:
                                        AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // "I Learned Today" button or completion status
                          if (!completed)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: () {
                                  dailyProvider.completeDailyDiscovery();
                                },
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 24,
                                ),
                                label: Text(
                                  'i_learned_today'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.successContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primaryDark,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'daily_completed'.tr(),
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                            color: AppColors
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'daily_streak_info'.tr(
                                            namedArgs: {
                                              'count': dailyProvider
                                                  .currentStreak
                                                  .toString()
                                            },
                                          ),
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: AppColors
                                                .onPrimaryContainer
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Streak calendar
                          const StreakCalendarWidget(),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
