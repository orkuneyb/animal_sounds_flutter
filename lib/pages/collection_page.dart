import 'package:animal_sounds_flutter/models/discovery.dart';
import 'package:animal_sounds_flutter/providers/discovery_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full collection page showing all animals and their discovery status.
class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  int _selectedCategoryIndex = 0;

  // Category definitions matching the existing app categories
  static const List<String> _categoryKeys = [
    'all',
    'wild_animals',
    'domestic_animals',
    'sea_animals',
    'farm_animals',
  ];

  static const Map<String, List<int>> _categoryAnimalIndices = {
    'all': [], // empty means show all
    'wild_animals': [0, 2, 11, 12, 16, 17, 18, 19, 23, 24, 28, 29],
    'domestic_animals': [3, 4],
    'sea_animals': [14, 15, 13],
    'farm_animals': [5, 6, 7, 8, 9, 10],
  };

  List<int> get _filteredAnimalIndices {
    final key = _categoryKeys[_selectedCategoryIndex];
    final indices = _categoryAnimalIndices[key]!;
    if (indices.isEmpty) {
      return List.generate(AnimalRepository.animals.length, (i) => i);
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onSurface,
        title: Text(
          'collection'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Progress stats header
              _ProgressHeader(provider: provider),

              const SizedBox(height: 12),

              // Category filter tabs
              _CategoryTabs(
                selectedIndex: _selectedCategoryIndex,
                categories: _categoryKeys,
                onSelected: (index) {
                  setState(() => _selectedCategoryIndex = index);
                },
              ),

              const SizedBox(height: 12),

              // Animal grid
              Expanded(
                child: _AnimalGrid(
                  animalIndices: _filteredAnimalIndices,
                  provider: provider,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress header with count, percentage, and circular progress
// ---------------------------------------------------------------------------

class _ProgressHeader extends StatelessWidget {
  final DiscoveryProvider provider;

  const _ProgressHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final discovered = provider.discoveredCount;
    final total = provider.totalAnimals;
    final percentage = (provider.progressPercentage * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: provider.progressPercentage),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
                Text(
                  '$percentage%',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Stats text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'collection_progress'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: discovered),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, _) {
                    return Text(
                      '$value / $total',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'animals_discovered'.tr(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.75),
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

// ---------------------------------------------------------------------------
// Category filter tabs
// ---------------------------------------------------------------------------

class _CategoryTabs extends StatelessWidget {
  final int selectedIndex;
  final List<String> categories;
  final ValueChanged<int> onSelected;

  const _CategoryTabs({
    required this.selectedIndex,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index].tr(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animal grid
// ---------------------------------------------------------------------------

class _AnimalGrid extends StatelessWidget {
  final List<int> animalIndices;
  final DiscoveryProvider provider;

  const _AnimalGrid({
    required this.animalIndices,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemCount: animalIndices.length,
      itemBuilder: (context, index) {
        final animalIndex = animalIndices[index];
        final animal = AnimalRepository.animals[animalIndex];
        final discovery = provider.getDiscovery(animalIndex);

        return _AnimalCard(
          name: animal.name.tr(),
          imagePath: animal.imagePath,
          discovery: discovery,
          cardColor: AppColors.cardColors[animalIndex % AppColors.cardColors.length],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual animal card
// ---------------------------------------------------------------------------

class _AnimalCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final AnimalDiscovery discovery;
  final Color cardColor;

  const _AnimalCard({
    required this.name,
    required this.imagePath,
    required this.discovery,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool discovered = discovery.isDiscovered;

    return Container(
      decoration: BoxDecoration(
        color: discovered
            ? cardColor.withOpacity(0.6)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animal image + name + steps
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ColorFiltered(
                      colorFilter: discovered
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            )
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0.2126, 0.7152, 0.0722, 0, 0, //
                              0, 0, 0, 1, 0, //
                            ]),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  discovered ? name : '???',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: discovered
                        ? AppColors.onSurface
                        : AppColors.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Step indicators inline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(
                      icon: Icons.hearing_rounded,
                      done: discovery.soundListened,
                    ),
                    const SizedBox(width: 6),
                    _StepDot(
                      icon: Icons.menu_book_rounded,
                      done: discovery.infoVisited,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Discovery badge (top-right)
          Positioned(
            top: 6,
            right: 6,
            child: _DiscoveryBadge(discovered: discovered),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery badge
// ---------------------------------------------------------------------------

class _DiscoveryBadge extends StatelessWidget {
  final bool discovered;

  const _DiscoveryBadge({required this.discovered});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: discovered ? AppColors.success : AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        discovered ? Icons.check_rounded : Icons.question_mark_rounded,
        size: 14,
        color: discovered ? Colors.white : AppColors.outline,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step dot indicator (sound / info)
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  final IconData icon;
  final bool done;

  const _StepDot({required this.icon, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 12,
        color: done ? AppColors.primaryDark : AppColors.outline.withOpacity(0.5),
      ),
    );
  }
}
