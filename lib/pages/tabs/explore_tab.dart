import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/achievements_page.dart';
import 'package:animal_sounds_flutter/pages/collection_page.dart';
import 'package:animal_sounds_flutter/pages/daily_discovery_page.dart';
import 'package:animal_sounds_flutter/providers/achievement_provider.dart';
import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Explore tab — daily discovery, collection progress, achievements.
class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDailyAnimalCard(context),
                const SizedBox(height: 20),
                _buildCollectionSection(context),
                const SizedBox(height: 20),
                _buildAchievementsSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'tab_explore'.tr(),
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.explore_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Daily Animal Card
  // ---------------------------------------------------------------------------

  Widget _buildDailyAnimalCard(BuildContext context) {
    return Consumer<DailyProvider>(
      builder: (context, dailyProvider, _) {
        final Animal dailyAnimal = dailyProvider.getDailyAnimal();
        final String funFact = dailyProvider.getDailyFunFact();
        final int streak = dailyProvider.currentStreak;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyDiscoveryPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: label + streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'daily_animal'.tr(),
                        style: AppTextStyles.label.copyWith(
                          color: const Color(0xFFAA8800),
                          letterSpacing: 1,
                        ),
                      ),
                      if (streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 16,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Animal image + info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 90,
                          height: 90,
                          color: Colors.white.withValues(alpha: 0.6),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            dailyAnimal.imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dailyAnimal.name.tr(),
                              style: AppTextStyles.headingSmall.copyWith(
                                color: const Color(0xFF5D4E3C),
                              ),
                            ),
                            if (funFact.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                funFact.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF8D7B6A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyDiscoveryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text('explore_daily'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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

  // ---------------------------------------------------------------------------
  // Collection Progress
  // ---------------------------------------------------------------------------

  Widget _buildCollectionSection(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, _) {
        final discovered = provider.discoveredCount;
        final total = provider.totalAnimals;
        final progress = provider.progressPercentage;

        // Get last 4 discovered animals for the preview grid
        final discoveredAnimals = AnimalRepository.animals
            .where((a) => provider.isDiscovered(a.index))
            .toList();
        final previewAnimals = discoveredAnimals.length > 4
            ? discoveredAnimals.sublist(discoveredAnimals.length - 4)
            : discoveredAnimals;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CollectionPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return CircularProgressIndicator(
                              value: value,
                              strokeWidth: 7,
                              backgroundColor:
                                  AppColors.primaryContainer.withValues(alpha: 0.4),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              strokeCap: StrokeCap.round,
                            );
                          },
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$discovered',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '/ $total',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Text + preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.collections_bookmark_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'collection_title'.tr(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Preview of discovered animals
                      if (previewAnimals.isNotEmpty)
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              ...previewAnimals.map((animal) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: AppColors.primaryContainer
                                          .withValues(alpha: 0.3),
                                      padding: const EdgeInsets.all(4),
                                      child: Image.asset(
                                        animal.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              if (discovered > 4)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${discovered - 4}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'no_discoveries_yet'.tr(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Achievements
  // ---------------------------------------------------------------------------

  Widget _buildAchievementsSection(BuildContext context) {
    return Consumer<AchievementProvider>(
      builder: (context, provider, _) {
        final unlocked = provider.unlockedCount;
        final total = provider.totalCount;

        // Show the most recent unlocked + next to unlock
        final recentUnlocked = provider.achievements
            .where((a) => a.isUnlocked)
            .toList()
          ..sort((a, b) =>
              (b.unlockedAt ?? DateTime(2000))
                  .compareTo(a.unlockedAt ?? DateTime(2000)));
        final nextToUnlock = provider.achievements
            .where((a) => !a.isUnlocked)
            .toList()
          ..sort((a, b) {
            final aRatio =
                a.maxProgress > 0 ? a.progress / a.maxProgress : 0.0;
            final bRatio =
                b.maxProgress > 0 ? b.progress / b.maxProgress : 0.0;
            return bRatio.compareTo(aRatio);
          });

        final badgesToShow = [
          ...recentUnlocked.take(3),
          ...nextToUnlock.take(4),
        ].take(6).toList();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AchievementsPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFC107),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'achievements_title'.tr(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unlocked/$total',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFAA8800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Badge row (scrollable)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: badgesToShow.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final badge = badgesToShow[index];
                      final isUnlocked = badge.isUnlocked;
                      final progressRatio = badge.maxProgress > 0
                          ? badge.progress / badge.maxProgress
                          : 0.0;

                      return Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? const Color(0xFFFFF8E1)
                                  : AppColors.surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isUnlocked
                                    ? const Color(0xFFFFC107)
                                    : AppColors.outlineVariant,
                                width: isUnlocked ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              badge.iconData,
                              size: 22,
                              color: isUnlocked
                                  ? const Color(0xFFFFA000)
                                  : AppColors.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!isUnlocked)
                            SizedBox(
                              width: 48,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 3,
                                  backgroundColor: AppColors.outlineVariant
                                      .withValues(alpha: 0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
