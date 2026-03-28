import 'package:animal_sounds_flutter/pages/weekly_challenge_page.dart';
import 'package:animal_sounds_flutter/providers/challenge_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChallengeProgressWidget extends StatelessWidget {
  const ChallengeProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        if (provider.challenges.isEmpty) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WeeklyChallengePage(),
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: provider.allCompleted
                        ? const LinearGradient(
                            colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 18,
                    color: provider.allCompleted
                        ? Colors.white
                        : AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: 10),
                // Progress text
                Text(
                  'weekly_challenges_compact'.tr(namedArgs: {
                    'completed': '${provider.completedCount}',
                    'total': '${provider.totalCount}',
                  }),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                // Dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(provider.totalCount, (index) {
                    final completed = index < provider.completedCount;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? AppColors.success
                            : AppColors.surfaceContainerHigh,
                        border: completed
                            ? null
                            : Border.all(
                                color: AppColors.outlineVariant,
                                width: 1,
                              ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
