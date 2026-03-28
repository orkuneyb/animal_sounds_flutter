import 'dart:io';

import 'package:animal_sounds_flutter/pages/favorites_page.dart';
import 'package:animal_sounds_flutter/pages/gallery_page.dart';
import 'package:animal_sounds_flutter/pages/parent_dashboard_page.dart';
import 'package:animal_sounds_flutter/pages/weekly_challenge_page.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/providers/coloring_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/parent_gate_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Profile tab — challenges, favorites, gallery, quick links.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load gallery paintings when the profile tab is first created.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coloringProvider =
          Provider.of<ColoringProvider>(context, listen: false);
      if (!coloringProvider.isLoaded) {
        coloringProvider.loadSavedPaintings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildChallengesSection(context),
                const SizedBox(height: 20),
                _buildFavoritesSection(context),
                const SizedBox(height: 20),
                _buildGallerySection(context),
                const SizedBox(height: 24),
                _buildQuickLinks(context),
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

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFFFF7043),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'profile_greeting'.tr(),
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24, top: 20),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Weekly Challenges
  // ---------------------------------------------------------------------------

  Widget _buildChallengesSection(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        if (provider.challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        final daysLeft = provider.daysRemaining;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WeeklyChallengePage(),
              ),
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
                    Expanded(
                      child: Text(
                        'weekly_challenges'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Timer badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'days_remaining'
                                    .tr(namedArgs: {'days': '$daysLeft'}),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tertiary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Challenge items
                ...provider.challenges.map((challenge) {
                  final progressRatio = challenge.target > 0
                      ? (challenge.progress / challenge.target)
                          .clamp(0.0, 1.0)
                      : 0.0;
                  final isComplete = challenge.isCompleted;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isComplete
                                ? AppColors.successContainer
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            challenge.icon,
                            size: 16,
                            color: isComplete
                                ? AppColors.success
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title + progress bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.titleKey.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                  decoration: isComplete
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 4,
                                  backgroundColor: AppColors.outlineVariant
                                      .withValues(alpha: 0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isComplete
                                        ? AppColors.success
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Progress label
                        Text(
                          '${challenge.progress}/${challenge.target}',
                          style: AppTextStyles.label.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isComplete
                                ? AppColors.success
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  Widget _buildFavoritesSection(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, _) {
        final favoriteAnimals = provider.favoriteAnimals;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
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
                      Icons.favorite_rounded,
                      color: Color(0xFFE91E63),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'favorites_title'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (favoriteAnimals.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${favoriteAnimals.length}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE91E63),
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
                const SizedBox(height: 14),

                // Horizontal scrollable previews
                if (favoriteAnimals.isNotEmpty)
                  SizedBox(
                    height: 76,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: favoriteAnimals.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final animal = favoriteAnimals[index];
                        return SizedBox(
                          width: 56,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.cardColors[
                                      animal.index % AppColors.cardColors.length],
                                  padding: const EdgeInsets.all(5),
                                  child: Image.asset(
                                    animal.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                animal.name.tr(),
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'no_favorites_yet'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Gallery
  // ---------------------------------------------------------------------------

  Widget _buildGallerySection(BuildContext context) {
    return Consumer<ColoringProvider>(
      builder: (context, provider, _) {
        final paintings = provider.savedPaintings;
        final previewPaintings = paintings.take(4).toList();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GalleryPage()),
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
                      Icons.palette_rounded,
                      color: Color(0xFF9C27B0),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'gallery_title'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (paintings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${paintings.length}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9C27B0),
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
                const SizedBox(height: 14),

                // 2x2 preview grid
                if (previewPaintings.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 3.5,
                    child: Row(
                      children: [
                        for (int i = 0; i < 4; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: i < previewPaintings.length
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(previewPaintings[i].filePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.surfaceContainerHigh,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'no_paintings_yet'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Quick Links
  // ---------------------------------------------------------------------------

  Widget _buildQuickLinks(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _QuickLinkTile(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF1565C0),
            title: 'parent_dashboard'.tr(),
            onTap: () async {
              final passed = await ParentGateWidget.showAsDialog(context);
              if (passed && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ParentDashboardPage(),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, indent: 56),
          _QuickLinkTile(
            icon: Icons.settings_rounded,
            iconColor: AppColors.onSurfaceVariant,
            title: 'settings'.tr(),
            onTap: () => Navigator.pushNamed(context, '/settingsPage'),
          ),
          const Divider(height: 1, indent: 56),
          _QuickLinkTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.onSurfaceVariant,
            title: 'about_app'.tr(),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'app_name'.tr(),
                // TODO: Replace with PackageInfo.fromPlatform() for dynamic versioning.
                applicationVersion: '1.1.0+4',
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.pets, size: 40, color: AppColors.primary),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Quick Link Tile
// =============================================================================

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }
}
