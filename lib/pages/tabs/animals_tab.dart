import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/models/animal_traits.dart';
import 'package:animal_sounds_flutter/pages/animal_sound_page.dart';
import 'package:animal_sounds_flutter/pages/remove_ads_page.dart';
import 'package:animal_sounds_flutter/providers/favorites_provider.dart';
import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/repositories/animal_repository.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/banner_ad_widget.dart';
import 'package:animal_sounds_flutter/widgets/pressable.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The picture shown on each group tile.
const Map<AnimalGroup, String> _groupMascots = {
  AnimalGroup.farm: 'cow',
  AnimalGroup.wild: 'lion',
  AnimalGroup.birds: 'owl',
  AnimalGroup.water: 'dolphin',
  AnimalGroup.small: 'bee',
};

/// Home tab: picture groups on top, a grid of animals below.
///
/// A card shows only the animal and its name; one tap opens its sound.
class AnimalsTab extends StatefulWidget {
  const AnimalsTab({super.key});

  @override
  State<AnimalsTab> createState() => _AnimalsTabState();
}

class _AnimalsTabState extends State<AnimalsTab>
    with AutomaticKeepAliveClientMixin {
  AnimalGroup? _group;
  bool _searchOpen = false;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        _searchFocus.requestFocus();
      } else {
        _searchController.clear();
        _query = '';
        _searchFocus.unfocus();
      }
    });
  }

  List<Animal> get _visibleAnimals {
    final animals = AnimalRepository.inGroup(_group);
    if (_query.isEmpty) return animals;
    final query = _query.toLowerCase();
    return animals
        .where((animal) => animal.name.tr().toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final animals = _visibleAnimals;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const BannerAdWidget(reserveSpace: true),
            _buildRemoveAdsCaption(),
            _buildGroupTiles(),
            Expanded(
              child: animals.isEmpty
                  ? _buildEmpty()
                  : _AnimalGrid(animals: animals),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: _searchOpen
                ? TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) => setState(() => _query = value),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr(),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  )
                // Long titles (Spanish, Russian) shrink instead of being cut.
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'app_name'.tr(),
                      maxLines: 1,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            tooltip: 'search_hint'.tr(),
            onTap: _toggleSearch,
          ),
          _HeaderButton(
            icon: Icons.settings_rounded,
            tooltip: 'settings'.tr(),
            onTap: () => Navigator.pushNamed(context, '/settingsPage'),
          ),
        ],
      ),
    );
  }

  /// A discreet, parent-facing link under the banner. Hidden once ads are
  /// removed. Shown even when no ad is served so a parent can always find it.
  Widget _buildRemoveAdsCaption() {
    if (context.watch<PurchaseProvider>().adsRemoved) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: TextButton.icon(
          onPressed: () => openRemoveAds(context, source: 'home_banner'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.inkSoft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          icon: const Icon(Icons.block_rounded, size: 14),
          label: Text(
            'remove_ads_short'.tr(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTiles() {
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 12),
        children: [
          _GroupTile(
            label: 'all'.tr(),
            color: const Color(0xFFFFE9D6),
            selected: _group == null,
            onTap: () => setState(() => _group = null),
            child: const Icon(Icons.pets_rounded,
                size: 40, color: AppColors.pop),
          ),
          for (final group in AnimalGroup.values)
            _GroupTile(
              label: group.labelKey.tr(),
              color: group.color,
              selected: _group == group,
              onTap: () => setState(() => _group = group),
              child: Image.asset(
                'assets/animal_images/${_groupMascots[group]}.png',
                width: 52,
                height: 52,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'no_results_found'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _AnimalGrid extends StatelessWidget {
  const _AnimalGrid({required this.animals});

  final List<Animal> animals;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two columns on phones, more on tablets and in landscape.
        final columns = (constraints.maxWidth / 190).floor().clamp(2, 6);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.86,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: animals.length,
          itemBuilder: (context, index) {
            final animal = animals[index];
            return _AnimalCard(
              animal: animal,
              isFavorite: favorites.isFavorite(animal.index),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AnimalSoundPage(animal: animal, animals: animals),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.isFavorite,
    required this.onTap,
  });

  final Animal animal;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: animal.name.tr(),
      child: Container(
        decoration: BoxDecoration(
          color: animal.color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
                    child: Hero(
                      tag: 'animal_image_${animal.index}',
                      child: Image.asset(animal.imagePath),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
                  child: Text(
                    animal.name.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            ),
            if (isFavorite)
              const PositionedDirectional(
                top: 12,
                end: 12,
                child: Icon(Icons.favorite_rounded,
                    size: 20, color: Color(0xFFE5484D)),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 10),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 86,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 54, child: Center(child: child)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 24,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
      ),
      icon: Icon(icon),
    );
  }
}
