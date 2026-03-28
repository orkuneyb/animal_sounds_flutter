import 'package:flutter/material.dart';

import '../utils/colors/colors.dart';
import '../utils/styles.dart';

/// An animated bar that compares two numeric values side by side.
///
/// Both bars grow from the center outward. The bar with the larger value is
/// highlighted, and value labels are placed at each end.
class ComparisonBarWidget extends StatelessWidget {
  /// Display name for the left value (e.g. "150 kg").
  final String leftLabel;

  /// Display name for the right value.
  final String rightLabel;

  /// Numeric value for the left bar.
  final double leftValue;

  /// Numeric value for the right bar.
  final double rightValue;

  /// Pastel color for the left animal.
  final Color leftColor;

  /// Pastel color for the right animal.
  final Color rightColor;

  /// Duration of the grow animation.
  final Duration duration;

  const ComparisonBarWidget({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftValue,
    required this.rightValue,
    this.leftColor = const Color(0xFF81D4FA),
    this.rightColor = const Color(0xFFFFCC80),
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final maxVal =
        leftValue > rightValue ? leftValue : rightValue;
    final leftFraction = maxVal > 0 ? leftValue / maxVal : 0.0;
    final rightFraction = maxVal > 0 ? rightValue / maxVal : 0.0;
    final leftWins = leftValue > rightValue;
    final rightWins = rightValue > leftValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Left value label
          SizedBox(
            width: 70,
            child: Text(
              leftLabel,
              style: AppTextStyles.label.copyWith(
                color: leftWins
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontWeight: leftWins ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Bars
          Expanded(
            child: SizedBox(
              height: 24,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final halfWidth = constraints.maxWidth / 2;
                  return Stack(
                    children: [
                      // Left bar (grows right-to-left from center)
                      Positioned(
                        right: halfWidth,
                        top: 0,
                        bottom: 0,
                        child: _AnimatedBar(
                          width: halfWidth * leftFraction,
                          color: leftColor,
                          isHighlighted: leftWins,
                          alignment: Alignment.centerRight,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(6),
                          ),
                          duration: duration,
                        ),
                      ),
                      // Right bar (grows left-to-right from center)
                      Positioned(
                        left: halfWidth,
                        top: 0,
                        bottom: 0,
                        child: _AnimatedBar(
                          width: halfWidth * rightFraction,
                          color: rightColor,
                          isHighlighted: rightWins,
                          alignment: Alignment.centerLeft,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(6),
                          ),
                          duration: duration,
                        ),
                      ),
                      // Center divider
                      Positioned(
                        left: halfWidth - 1,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 2,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right value label
          SizedBox(
            width: 70,
            child: Text(
              rightLabel,
              style: AppTextStyles.label.copyWith(
                color: rightWins
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
                fontWeight: rightWins ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.left,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Animated bar segment
// -----------------------------------------------------------------------------

class _AnimatedBar extends StatelessWidget {
  final double width;
  final Color color;
  final bool isHighlighted;
  final AlignmentGeometry alignment;
  final BorderRadiusGeometry borderRadius;
  final Duration duration;

  const _AnimatedBar({
    required this.width,
    required this.color,
    required this.isHighlighted,
    required this.alignment,
    required this.borderRadius,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: width),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedWidth, _) {
          return Container(
            width: animatedWidth,
            decoration: BoxDecoration(
              color: isHighlighted ? color : color.withOpacity(0.5),
              borderRadius: borderRadius,
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }
}
