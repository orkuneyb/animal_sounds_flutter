import 'dart:math';

import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shows the achievement unlock celebration dialog.
/// Auto-dismisses after 3 seconds or can be tapped to dismiss.
void showAchievementUnlockDialog(
  BuildContext context,
  Achievement achievement,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Achievement Unlock',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AchievementUnlockDialog(achievement: achievement);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeInBack,
      );
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class _AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;

  const _AchievementUnlockDialog({required this.achievement});

  @override
  State<_AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<_AchievementUnlockDialog>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _glowController;
  late final AnimationController _iconBounceController;
  late final List<_ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _particles = List.generate(20, (_) => _ConfettiParticle(_random));

    // Auto-dismiss after 3 seconds.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _glowController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Confetti particles
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(320, 400),
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  );
                },
              ),

              // Main card
              Container(
                width: 280,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow + Icon
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glowOpacity =
                            0.2 + _glowController.value * 0.3;
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondary
                                    .withOpacity(glowOpacity),
                                AppColors.secondary.withOpacity(0.0),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _iconBounceController,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.secondaryLight,
                                AppColors.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.secondary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.achievement.iconData,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Achievement unlocked label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'achievement_unlocked'.tr(),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Achievement name
                    Text(
                      widget.achievement.title.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.achievement.description.tr(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Great job message
                    Text(
                      'achievement_great_job'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti painting
// ---------------------------------------------------------------------------

class _ConfettiParticle {
  final double startX; // 0..1 horizontal start
  final double startY; // 0..0.2 vertical start
  final double speed; // fall speed multiplier
  final double wobble; // horizontal wobble amplitude
  final double size;
  final Color color;
  final bool isStar;

  _ConfettiParticle(Random random)
      : startX = random.nextDouble(),
        startY = random.nextDouble() * 0.15,
        speed = 0.5 + random.nextDouble() * 0.8,
        wobble = 0.02 + random.nextDouble() * 0.06,
        size = 4 + random.nextDouble() * 6,
        color = _confettiColors[random.nextInt(_confettiColors.length)],
        isStar = random.nextBool();

  static const List<Color> _confettiColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF9E80),
    Color(0xFFB388FF),
    Color(0xFF80DEEA),
    Color(0xFFFF80AB),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = size.width * p.startX +
          sin(progress * pi * 4 * p.speed) * size.width * p.wobble;
      final y = size.height * p.startY + progress * size.height * p.speed;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.fill;

      if (p.isStar) {
        _drawStar(canvas, Offset(x, y), p.size, paint);
      } else {
        canvas.drawCircle(Offset(x, y), p.size / 2, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerR = size / 2;
    final innerR = outerR * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (pi / points) * i - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
