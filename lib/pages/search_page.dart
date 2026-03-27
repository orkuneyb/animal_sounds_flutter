import 'package:animal_sounds_flutter/pages/animal_info_page.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/search_provider.dart';
import '../models/animal.dart';
import '../transitions/page_transitions.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SearchProvider>(context, listen: false).init(context);
    });
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        Provider.of<SearchProvider>(context, listen: false).clearSearch();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AppColors.onSurface,
          title: Text(
            'search_hint'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
        body: Column(
          children: [
            // Floating search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _FloatingSearchBar(),
            ),

            // Results or history
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, searchProvider, child) {
                  if (searchProvider.isSearching) {
                    return _SearchResults();
                  }
                  return _SearchHistory();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: searchProvider.searchController,
        autofocus: true,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'search_hint'.tr(),
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.outline,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 46,
            minHeight: 46,
          ),
          suffixIcon: searchProvider.isSearching
              ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                    onPressed: () => searchProvider.clearSearch(),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: AppColors.outline.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_results_found'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          physics: const BouncingScrollPhysics(),
          itemCount: searchProvider.searchResults.length,
          itemBuilder: (context, index) {
            final animal = searchProvider.searchResults[index];
            return _AnimalSearchCard(
              animal: animal,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _AnimalSearchCard extends StatefulWidget {
  final Animal animal;
  final int index;

  const _AnimalSearchCard({required this.animal, required this.index});

  @override
  State<_AnimalSearchCard> createState() => _AnimalSearchCardState();
}

class _AnimalSearchCardState extends State<_AnimalSearchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 60)),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Provider.of<SearchProvider>(context, listen: false)
                    .addToHistory(widget.animal.name.tr());
                Navigator.push(
                  context,
                  PageTransitions.createScaleTransition(
                    AnimalInfoPage(animal: widget.animal),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Animal image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        widget.animal.imagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.animal.name.tr(),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.animal.description.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.outline.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.searchHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.manage_search_rounded,
                  size: 72,
                  color: AppColors.outline.withOpacity(0.25),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_search_history'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'recent_searches'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => searchProvider.clearHistory(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text('clear_all'.tr()),
                  ),
                ],
              ),
            ),

            // History list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: searchProvider.searchHistory.length,
                itemBuilder: (context, index) {
                  final query = searchProvider.searchHistory[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => searchProvider.searchFromHistory(query),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: AppColors.outline.withOpacity(0.6),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  query,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    searchProvider.removeFromHistory(query),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.outline.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
