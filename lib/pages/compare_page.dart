import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../repositories/animal_repository.dart';
import '../utils/animal_data_parser.dart';
import '../utils/colors/colors.dart';
import '../utils/styles.dart';
import '../widgets/comparison_bar_widget.dart';

/// Side-by-side animal comparison page.
///
/// Users select two animals and the page animates comparison bars for size,
/// weight, and lifespan, plus shows habitat and diet cards.
class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  Animal? _left;
  Animal? _right;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingBoth = false;

  // Force a rebuild of comparison bars to re-trigger animations.
  Key _comparisonKey = UniqueKey();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _selectAnimal(bool isLeft) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AnimalSelectorSheet(
        onSelected: (animal) {
          Navigator.pop(ctx);
          setState(() {
            if (isLeft) {
              _left = animal;
            } else {
              _right = animal;
            }
            _comparisonKey = UniqueKey();
          });
        },
      ),
    );
  }

  void _swap() {
    setState(() {
      final temp = _left;
      _left = _right;
      _right = temp;
      _comparisonKey = UniqueKey();
    });
  }

  Future<void> _playBothSounds() async {
    if (_left == null || _right == null || _isPlayingBoth) return;
    setState(() => _isPlayingBoth = true);

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_left!.soundPath.replaceFirst('assets/', '')));
      await Future.delayed(const Duration(milliseconds: 1500));
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_right!.soundPath.replaceFirst('assets/', '')));
      await Future.delayed(const Duration(milliseconds: 1500));
      await _audioPlayer.stop();
    } catch (_) {
      // Gracefully ignore playback errors.
    }

    if (mounted) setState(() => _isPlayingBoth = false);
  }

  @override
  Widget build(BuildContext context) {
    final bothSelected = _left != null && _right != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'compare_title'.tr(),
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          if (bothSelected)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'compare_swap'.tr(),
              onPressed: _swap,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ---- Selection Row ----
            Row(
              children: [
                Expanded(child: _buildAnimalSlot(_left, true)),
                _buildVsBadge(),
                Expanded(child: _buildAnimalSlot(_right, false)),
              ],
            ),
            const SizedBox(height: 16),

            // ---- Play Both Sounds ----
            if (bothSelected)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: _isPlayingBoth ? null : _playBothSounds,
                  icon: Icon(
                    _isPlayingBoth
                        ? Icons.volume_up_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _isPlayingBoth
                        ? 'compare_playing'.tr()
                        : 'compare_play_both'.tr(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),

            // ---- Comparison Cards ----
            if (bothSelected) _buildComparisons(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Animal slot (image + name or placeholder)
  // ---------------------------------------------------------------------------

  Widget _buildAnimalSlot(Animal? animal, bool isLeft) {
    return GestureDetector(
      onTap: () => _selectAnimal(isLeft),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: animal != null
                    ? AppColors.cardColors[
                        animal.index % AppColors.cardColors.length]
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: animal != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        animal.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.pets, size: 40),
                      ),
                    )
                  : Icon(
                      Icons.add_rounded,
                      size: 40,
                      color: AppColors.outline,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              animal != null
                  ? animal.name.tr()
                  : 'compare_select'.tr(),
              style: AppTextStyles.bodyLarge.copyWith(
                color: animal != null
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VS badge
  // ---------------------------------------------------------------------------

  Widget _buildVsBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7043), Color(0xFFFF5252)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5252).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'VS',
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Comparison sections
  // ---------------------------------------------------------------------------

  Widget _buildComparisons() {
    final left = _left!;
    final right = _right!;

    // Translated text for each attribute.
    final leftSizeText = left.size.tr();
    final rightSizeText = right.size.tr();
    final leftWeightText = left.weight.tr();
    final rightWeightText = right.weight.tr();
    final leftLifespanText = left.lifespan.tr();
    final rightLifespanText = right.lifespan.tr();

    // Parsed numeric values.
    final leftSizeVal = AnimalDataParser.parseSize(leftSizeText);
    final rightSizeVal = AnimalDataParser.parseSize(rightSizeText);
    final leftWeightVal = AnimalDataParser.parseWeight(leftWeightText);
    final rightWeightVal = AnimalDataParser.parseWeight(rightWeightText);
    final leftLifespanVal = AnimalDataParser.parseLifespan(leftLifespanText);
    final rightLifespanVal = AnimalDataParser.parseLifespan(rightLifespanText);

    final leftColor = AppColors.cardColors[
        left.index % AppColors.cardColors.length];
    final rightColor = AppColors.cardColors[
        right.index % AppColors.cardColors.length];

    return Column(
      key: _comparisonKey,
      children: [
        // Size
        _ComparisonSection(
          title: 'size'.tr(),
          icon: Icons.straighten_rounded,
          child: ComparisonBarWidget(
            leftLabel: _shortNumericLabel(leftSizeVal, 'cm'),
            rightLabel: _shortNumericLabel(rightSizeVal, 'cm'),
            leftValue: leftSizeVal,
            rightValue: rightSizeVal,
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ),

        // Weight
        _ComparisonSection(
          title: 'weight'.tr(),
          icon: Icons.fitness_center_rounded,
          child: ComparisonBarWidget(
            leftLabel: _shortNumericLabel(leftWeightVal, 'kg'),
            rightLabel: _shortNumericLabel(rightWeightVal, 'kg'),
            leftValue: leftWeightVal,
            rightValue: rightWeightVal,
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ),

        // Lifespan
        _ComparisonSection(
          title: 'lifespan'.tr(),
          icon: Icons.hourglass_bottom_rounded,
          child: ComparisonBarWidget(
            leftLabel: _shortNumericLabel(leftLifespanVal, 'compare_years'.tr()),
            rightLabel: _shortNumericLabel(rightLifespanVal, 'compare_years'.tr()),
            leftValue: leftLifespanVal,
            rightValue: rightLifespanVal,
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ),

        // Habitat (text cards)
        _ComparisonSection(
          title: 'habitat'.tr(),
          icon: Icons.forest_rounded,
          child: _TextComparisonRow(
            leftText: left.habitat.tr(),
            rightText: right.habitat.tr(),
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ),

        // Diet (text cards)
        _ComparisonSection(
          title: 'diet'.tr(),
          icon: Icons.restaurant_rounded,
          child: _TextComparisonRow(
            leftText: left.diet.tr(),
            rightText: right.diet.tr(),
            leftColor: leftColor,
            rightColor: rightColor,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _shortNumericLabel(double value, String unit) {
    if (value == 0) return '-';
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k $unit';
    }
    final str = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$str $unit';
  }
}

// =============================================================================
// Comparison Section wrapper
// =============================================================================

class _ComparisonSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ComparisonSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// =============================================================================
// Side-by-side text cards for habitat / diet
// =============================================================================

class _TextComparisonRow extends StatelessWidget {
  final String leftText;
  final String rightText;
  final Color leftColor;
  final Color rightColor;

  const _TextComparisonRow({
    required this.leftText,
    required this.rightText,
    required this.leftColor,
    required this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _card(leftText, leftColor)),
        const SizedBox(width: 8),
        Expanded(child: _card(rightText, rightColor)),
      ],
    );
  }

  Widget _card(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.onSurface,
        ),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// =============================================================================
// Animal Selector Bottom Sheet
// =============================================================================

class _AnimalSelectorSheet extends StatelessWidget {
  final ValueChanged<Animal> onSelected;
  const _AnimalSelectorSheet({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final animals = AnimalRepository.animals;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'compare_choose_animal'.tr(),
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return GestureDetector(
                      onTap: () => onSelected(animal),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardColors[
                                    index % AppColors.cardColors.length],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                animal.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.pets),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animal.name.tr(),
                            style: AppTextStyles.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
