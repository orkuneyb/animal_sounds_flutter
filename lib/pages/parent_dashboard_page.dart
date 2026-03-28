import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/usage_stats_provider.dart';
import '../repositories/animal_repository.dart';
import '../utils/colors/colors.dart';
import '../utils/styles.dart';

/// A professional, data-focused dashboard for parents.
///
/// Shows usage statistics, learning progress, popular animals, and weekly
/// activity. Accessed only after passing the parent gate.
class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          'parent_dashboard'.tr(),
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      body: Consumer<UsageStatsProvider>(
        builder: (context, stats, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Overview Cards ----
                _buildSectionTitle('dashboard_overview'.tr()),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _OverviewCard(
                        icon: Icons.headphones_rounded,
                        color: const Color(0xFF4A90D9),
                        label: 'dashboard_sounds_listened'.tr(),
                        value: '${stats.soundsListened}',
                      ),
                      _OverviewCard(
                        icon: Icons.quiz_rounded,
                        color: const Color(0xFF4CAF50),
                        label: 'dashboard_quizzes_completed'.tr(),
                        value: '${stats.quizzesCompleted}',
                      ),
                      _OverviewCard(
                        icon: Icons.pets_rounded,
                        color: const Color(0xFFFF9800),
                        label: 'dashboard_animals_discovered'.tr(),
                        value: '${stats.animalsDiscovered}',
                      ),
                      _OverviewCard(
                        icon: Icons.phone_android_rounded,
                        color: const Color(0xFF9C27B0),
                        label: 'dashboard_app_opens'.tr(),
                        value: '${stats.appOpens}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ---- Learning Progress ----
                _buildSectionTitle('dashboard_learning_progress'.tr()),
                const SizedBox(height: 8),
                _LearningProgressCard(stats: stats),
                const SizedBox(height: 24),

                // ---- Most Popular Animals ----
                _buildSectionTitle('dashboard_popular_animals'.tr()),
                const SizedBox(height: 8),
                _PopularAnimalsSection(stats: stats),
                const SizedBox(height: 24),

                // ---- Weekly Activity ----
                _buildSectionTitle('dashboard_weekly_activity'.tr()),
                const SizedBox(height: 8),
                _WeeklyActivityChart(stats: stats),
                const SizedBox(height: 24),

                // ---- Quick Actions ----
                _buildSectionTitle('dashboard_quick_actions'.tr()),
                const SizedBox(height: 8),
                _QuickActionsCard(stats: stats),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// =============================================================================
// Overview Card
// =============================================================================

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _OverviewCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Learning Progress
// =============================================================================

class _LearningProgressCard extends StatelessWidget {
  final UsageStatsProvider stats;
  const _LearningProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalAnimals = AnimalRepository.animals.length;
    final explored = stats.animalsDiscovered;
    final progress = totalAnimals > 0 ? explored / totalAnimals : 0.0;
    final quizAvg = stats.getQuizAverage();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.outlineVariant.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '$explored/$totalAnimals',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard_animals_explored'.tr(
                    namedArgs: {
                      'count': '$explored',
                      'total': '$totalAnimals',
                    },
                  ),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.quiz_rounded,
                        size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text(
                      'dashboard_quiz_average'.tr(
                        namedArgs: {'score': quizAvg.toStringAsFixed(1)},
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded,
                        size: 16, color: Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    Text(
                      'dashboard_favorites_count'.tr(
                        namedArgs: {'count': '${stats.favoriteCount}'},
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Popular Animals
// =============================================================================

class _PopularAnimalsSection extends StatelessWidget {
  final UsageStatsProvider stats;
  const _PopularAnimalsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final topAnimals = stats.getMostListenedAnimals();
    if (topAnimals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'dashboard_no_data'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topAnimals.length,
        itemBuilder: (context, index) {
          final entry = topAnimals[index];
          final animalId = entry.key;
          final count = entry.value;

          if (animalId >= AnimalRepository.animals.length) {
            return const SizedBox.shrink();
          }

          final animal = AnimalRepository.animals[animalId];
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.cardColors[
                            animalId % AppColors.cardColors.length],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        animal.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.pets, size: 32),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90D9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  animal.name.tr(),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Weekly Activity Chart
// =============================================================================

class _WeeklyActivityChart extends StatelessWidget {
  final UsageStatsProvider stats;
  const _WeeklyActivityChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final activity = stats.getWeeklyActivity();
    final labels = stats.getWeeklyLabels();
    final maxVal = activity.fold<int>(0, (a, b) => a > b ? a : b);
    final chartMax = maxVal > 0 ? maxVal.toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = activity[i];
                final fraction = value / chartMax;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$value',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: (fraction * 100).clamp(4.0, 100.0),
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Text(
                  labels[i],
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Quick Actions
// =============================================================================

class _QuickActionsCard extends StatelessWidget {
  final UsageStatsProvider stats;
  const _QuickActionsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            title: Text(
              'dashboard_reset_stats'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () => _confirmReset(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant),
            title: Text(
              'dashboard_manage_notifications'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
            onTap: () {
              // Placeholder — will be wired during integration
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('dashboard_reset_confirm_title'.tr()),
        content: Text('dashboard_reset_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'clear'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<UsageStatsProvider>().resetAll();
    }
  }
}
