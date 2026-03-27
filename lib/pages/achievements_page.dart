import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/providers/quiz_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onSurface,
        title: Text(
          'achievements'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          final achievements = quizProvider.achievements;
          final unlockedCount =
              achievements.where((a) => a.isUnlocked).length;
          final totalCount = achievements.length;

          return Column(
            children: [
              // Header with progress
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _AchievementHeader(
                  unlocked: unlockedCount,
                  total: totalCount,
                ),
              ),

              const SizedBox(height: 8),

              // Achievement grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _AchievementCard(achievement: achievement);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _AchievementHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryContainer,
            AppColors.secondaryContainer.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlocked / $total',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Unlocked',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
        border: isUnlocked
            ? Border.all(
                color: AppColors.secondary.withOpacity(0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Unlocked glow effect
          if (isUnlocked)
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.15),
                      AppColors.secondary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon area
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: isUnlocked
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            )
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Opacity(
                        opacity: isUnlocked ? 1.0 : 0.4,
                        child: Image.asset(
                          achievement.iconPath,
                          height: 56,
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest
                              .withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                // Description
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isUnlocked
                        ? AppColors.onSurfaceVariant
                        : AppColors.outline.withOpacity(0.5),
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
