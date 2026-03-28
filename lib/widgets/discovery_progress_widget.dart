import 'package:animal_sounds_flutter/pages/collection_page.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Compact progress widget for the home page.
///
/// Shows discovered count, an animated progress bar, and navigates
/// to the full [CollectionPage] on tap.
class DiscoveryProgressWidget extends StatelessWidget {
  const DiscoveryProgressWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryProvider>(
      builder: (context, provider, _) {
        final discovered = provider.discoveredCount;
        final total = provider.totalAnimals;
        final progress = provider.progressPercentage;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CollectionPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Animated circular progress indicator
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            backgroundColor:
                                AppColors.primaryContainer.withOpacity(0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            strokeCap: StrokeCap.round,
                          );
                        },
                      ),
                      Icon(
                        Icons.pets_rounded,
                        size: 18,
                        color: discovered > 0
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: discovered),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, _) {
                          return Text(
                            'discovery_progress'.tr(
                              namedArgs: {
                                'discovered': value.toString(),
                                'total': total.toString(),
                              },
                            ),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),

                      // Linear progress bar
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              backgroundColor:
                                  AppColors.primaryContainer.withOpacity(0.5),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.outline.withOpacity(0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
