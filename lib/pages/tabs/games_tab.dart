import 'package:animal_sounds_flutter/pages/coloring_page.dart';
import 'package:animal_sounds_flutter/pages/compare_page.dart';
import 'package:animal_sounds_flutter/pages/quiz_start_page.dart';
import 'package:animal_sounds_flutter/pages/sound_guess_game_page.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The Games tab — quiz, sound guess, compare, coloring activities.
class GamesTab extends StatefulWidget {
  const GamesTab({super.key});

  @override
  State<GamesTab> createState() => _GamesTabState();
}

class _GamesTabState extends State<GamesTab>
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
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _GameCard(
                  icon: Icons.extension_rounded,
                  title: 'game_quiz'.tr(),
                  subtitle: 'game_quiz_desc'.tr(),
                  gradientColors: const [Color(0xFF7B68EE), Color(0xFF5B4FCF)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizStartPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _GameCard(
                  icon: Icons.headphones_rounded,
                  title: 'game_sound_guess'.tr(),
                  subtitle: 'game_sound_guess_desc'.tr(),
                  gradientColors: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SoundGuessGamePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _GameCard(
                  icon: Icons.compare_arrows_rounded,
                  title: 'game_compare'.tr(),
                  subtitle: 'game_compare_desc'.tr(),
                  gradientColors: const [Color(0xFFFF9800), Color(0xFFF57C00)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComparePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _GameCard(
                  icon: Icons.palette_rounded,
                  title: 'game_coloring'.tr(),
                  subtitle: 'game_coloring_desc'.tr(),
                  gradientColors: const [Color(0xFFEC407A), Color(0xFFD81B60)],
                  onTap: () {
                    // Pick a random animal for coloring
                    final animals = AnimalRepository.animals;
                    final randomAnimal =
                        animals[DateTime.now().millisecond % animals.length];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ColoringPage(animal: randomAnimal),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF7B68EE),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'tab_games'.tr(),
          style: AppTextStyles.headingSmall.copyWith(
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9B8FFF), Color(0xFF7B68EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Icon(
                Icons.sports_esports_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Game Card Widget
// =============================================================================

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),

                  // Text content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headingSmall.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
