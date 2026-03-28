import 'package:animal_sounds_flutter/models/achievement.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/rewarded_ad_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({Key? key}) : super(key: key);

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AdService _adService = AdService();

  /// Tracks which locked achievements have had their hint revealed via ad.
  final Set<String> _revealedHints = {};

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
  }

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
      body: Consumer<AchievementProvider>(
        builder: (context, achievementProvider, child) {
          final achievements = achievementProvider.achievements;
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return _AchievementCard(
                      achievement: achievement,
                      hintRevealed: _revealedHints.contains(achievement.id),
                      onHintRevealed: () {
                        setState(() {
                          _revealedHints.add(achievement.id);
                        });
                      },
                    );
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
                    'achievements'.tr(),
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
  final bool hintRevealed;
  final VoidCallback onHintRevealed;

  const _AchievementCard({
    required this.achievement,
    required this.hintRevealed,
    required this.onHintRevealed,
  });

  Widget _buildDescription(bool isUnlocked) {
    if (!isUnlocked && hintRevealed) {
      return Text(
        '${'achievement_hint_prefix'.tr()}${achievement.description.tr()}',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          fontSize: 11,
        ),
      );
    }
    return Text(
      isUnlocked ? achievement.description.tr() : '???',
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySmall.copyWith(
        color: isUnlocked
            ? AppColors.onSurfaceVariant
            : AppColors.outline.withOpacity(0.5),
        fontSize: 11,
      ),
    );
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon area
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnlocked
                                ? AppColors.secondaryContainer
                                : AppColors.surfaceContainerHigh,
                          ),
                          child: Icon(
                            achievement.iconData,
                            size: 24,
                            color: isUnlocked
                                ? AppColors.secondaryDark
                                : AppColors.outline.withOpacity(0.4),
                          ),
                        ),
                        if (!isUnlocked)
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 18,
                              height: 18,
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
                                size: 10,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Progress bar (locked with multi-step only)
                if (!isUnlocked && achievement.maxProgress > 1) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progressPercent,
                        minHeight: 4,
                        backgroundColor:
                            AppColors.outlineVariant.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${achievement.progress}/${achievement.maxProgress}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Title
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      achievement.title.tr(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),

                // Description
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _buildDescription(isUnlocked),
                  ),
                ),

                // Ad button for locked achievements
                if (!isUnlocked && !hintRevealed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: RewardedAdButton(
                      compact: true,
                      rewardDescription: 'watch_ad_achievement_hint'.tr(),
                      gradientColors: const [
                        Color(0xFF7E57C2),
                        Color(0xFF512DA8),
                      ],
                      icon: Icons.lightbulb_outline_rounded,
                      onRewardEarned: (amount) {
                        onHintRevealed();
                      },
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
