import 'dart:ui';

import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/pages/animal_sound_page.dart';
import 'package:animal_sounds_flutter/providers/category_provider.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/usage_stats_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/transitions/page_transitions.dart';
import 'package:animal_sounds_flutter/widgets/banner_ad_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Accent color palette for animal card text and highlights
// ---------------------------------------------------------------------------
const List<Color> _kAccentColors = [
  Color(0xFFFF9800), // Orange
  Color(0xFF03A9F4), // Blue
  Color(0xFF4CAF50), // Green
  Color(0xFFE91E63), // Pink
  Color(0xFF673AB7), // Purple
  Color(0xFFFFC107), // Amber
  Color(0xFF009688), // Teal
  Color(0xFFFF5722), // Deep orange
  Color(0xFF9C27B0), // Violet
  Color(0xFF8BC34A), // Lime
];

/// Clean animal browsing tab — search, categories, and animal grid only.
class AnimalsTab extends StatefulWidget {
  const AnimalsTab({super.key});

  @override
  State<AnimalsTab> createState() => _AnimalsTabState();
}

class _AnimalsTabState extends State<AnimalsTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  late final AnimationController _searchAnimController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  late final Animation<double> _searchAnimation = CurvedAnimation(
    parent: _searchAnimController,
    curve: Curves.easeOutCubic,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (_isSearchOpen) {
        _searchAnimController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimController.reverse();
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
            const BannerAdWidget(),
            _buildCategoryChips(),
            Expanded(child: _buildAnimalGrid()),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Frosted-glass AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xCCFF9E80), // warm coral, semi-transparent
                  Color(0xCCFFCC80), // warm amber, semi-transparent
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Title area (hidden when searching)
                      if (!_isSearchOpen) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.pets, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'app_name'.tr(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      // Expandable search field
                      if (_isSearchOpen)
                        Expanded(
                          child: SizeTransition(
                            sizeFactor: _searchAnimation,
                            axis: Axis.horizontal,
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'search_hint'.tr(),
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: _toggleSearch,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Action icons
                      if (!_isSearchOpen) ...[
                        _AppBarCircleButton(
                          icon: Icons.search,
                          onTap: _toggleSearch,
                        ),
                        _AppBarCircleButton(
                          icon: Icons.settings_rounded,
                          onTap: () =>
                              Navigator.pushNamed(context, '/settingsPage'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category chip bar
  // ---------------------------------------------------------------------------

  Widget _buildCategoryChips() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        return SizedBox(
          height: 56,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: categoryProvider.categories.length + 1,
            itemBuilder: (context, index) {
              final bool isAll = index == 0;
              final bool isSelected = isAll
                  ? categoryProvider.selectedCategoryId == null
                  : categoryProvider.categories[index - 1].id ==
                      categoryProvider.selectedCategoryId;

              final String label = isAll
                  ? 'all'.tr()
                  : categoryProvider.categories[index - 1].name.tr();
              final IconData icon = isAll
                  ? Icons.apps_rounded
                  : categoryProvider.categories[index - 1].icon;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: label,
                  icon: icon,
                  isSelected: isSelected,
                  onTap: () {
                    final selectedId = isAll
                        ? null
                        : categoryProvider.categories[index - 1].id;
                    categoryProvider.selectCategory(selectedId);

                    if (!isAll) {
                      final usageStats = Provider.of<UsageStatsProvider>(
                        context,
                        listen: false,
                      );
                      usageStats.incrementAppOpens();
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Animal grid
  // ---------------------------------------------------------------------------

  Widget _buildAnimalGrid() {
    return Consumer2<CategoryProvider, FavoritesProvider>(
      builder: (context, categoryProvider, favoritesProvider, _) {
        List<Animal> filteredAnimals =
            categoryProvider.selectedCategoryId == null
                ? AnimalRepository.animals
                : AnimalRepository.animals
                    .where((animal) => categoryProvider
                        .getAnimalIdsByCategory(
                            categoryProvider.selectedCategoryId!)
                        .contains(animal.index))
                    .toList();

        // Apply local search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredAnimals = filteredAnimals
              .where((a) => a.name.tr().toLowerCase().contains(query))
              .toList();
        }

        if (filteredAnimals.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'no_results_found'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredAnimals.length,
          itemBuilder: (context, index) {
            final Animal animal = filteredAnimals[index];
            final Color cardColor =
                AppColors.cardColors[index % AppColors.cardColors.length];
            final Color accentColor =
                _kAccentColors[index % _kAccentColors.length];
            final bool isFav = favoritesProvider.isFavorite(animal.index);

            return _AnimalCard(
              animal: animal,
              cardColor: cardColor,
              accentColor: accentColor,
              isFavorite: isFav,
              onTap: () {
                Navigator.push(
                  context,
                  PageTransitions.createScaleTransition(
                    AnimalSoundPage(animal: animal),
                  ),
                );
              },
              onInfoTap: () {
                Navigator.push(
                  context,
                  PageTransitions.createScaleTransition(
                    AnimalInfoPage(animal: animal),
                  ),
                );
              },
              onFavoriteTap: () {
                favoritesProvider.toggleFavorite(animal.index);
              },
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// Private widgets
// =============================================================================

/// Circular icon button used in the app bar.
class _AppBarCircleButton extends StatelessWidget {
  const _AppBarCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.white.withValues(alpha: 0.25),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped category chip with selection animation.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF9E80) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFF9E80)
                  : const Color(0xFFE0D6CC),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9E80).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected ? Colors.white : const Color(0xFF8D7B6A),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : const Color(0xFF5D4E3C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern animal card with soft pastel background and hero animation.
class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.cardColor,
    required this.accentColor,
    required this.isFavorite,
    required this.onTap,
    required this.onInfoTap,
    required this.onFavoriteTap,
  });

  final Animal animal;
  final Color cardColor;
  final Color accentColor;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.15),
          highlightColor: accentColor.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
                      child: Hero(
                        tag: 'animal_image_${animal.index}',
                        child: Image.asset(
                          animal.imagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: Text(
                      animal.name.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Top-right overlay icons
              Positioned(
                top: 6,
                right: 6,
                child: Column(
                  children: [
                    _OverlayIconButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE91E63)
                          : Colors.grey.shade400,
                      onTap: onFavoriteTap,
                    ),
                    const SizedBox(height: 4),
                    _OverlayIconButton(
                      icon: Icons.info_outline_rounded,
                      color: accentColor.withValues(alpha: 0.7),
                      onTap: onInfoTap,
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

/// Small circular overlay button used on cards.
class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
