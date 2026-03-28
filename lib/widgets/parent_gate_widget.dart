import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../utils/colors/colors.dart';
import '../utils/styles.dart';

/// A math-question gate to prevent children from accessing parent settings.
///
/// Shows a random addition or subtraction question with 4 answer choices.
/// On correct answer the [onSuccess] callback fires.
/// Can be shown as a dialog via [ParentGateWidget.showAsDialog] or embedded
/// directly in the widget tree.
class ParentGateWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const ParentGateWidget({
    super.key,
    required this.onSuccess,
    this.onCancel,
  });

  /// Convenience method to show the parent gate as a dialog.
  static Future<bool> showAsDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ParentGateWidget(
          onSuccess: () => Navigator.of(ctx).pop(true),
          onCancel: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );
    return result ?? false;
  }

  /// Convenience method to show the parent gate as a bottom sheet.
  static Future<bool> showAsBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ParentGateWidget(
        onSuccess: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  State<ParentGateWidget> createState() => _ParentGateWidgetState();
}

class _ParentGateWidgetState extends State<ParentGateWidget>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late int _operand1;
  late int _operand2;
  late bool _isAddition;
  late int _correctAnswer;
  late List<int> _options;
  bool _wrongAnswer = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
    _generateQuestion();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _generateQuestion() {
    _isAddition = _random.nextBool();
    if (_isAddition) {
      _operand1 = _random.nextInt(15) + 3; // 3..17
      _operand2 = _random.nextInt(10) + 2; // 2..11
      _correctAnswer = _operand1 + _operand2;
    } else {
      _operand1 = _random.nextInt(15) + 8; // 8..22
      _operand2 = _random.nextInt(_operand1 - 2) + 1;
      _correctAnswer = _operand1 - _operand2;
    }

    final wrongAnswers = <int>{};
    while (wrongAnswers.length < 3) {
      final offset = _random.nextInt(7) - 3; // -3..3
      final wrong = _correctAnswer + (offset == 0 ? 4 : offset);
      if (wrong != _correctAnswer && wrong >= 0) {
        wrongAnswers.add(wrong);
      }
    }

    _options = [_correctAnswer, ...wrongAnswers]..shuffle(_random);
    _wrongAnswer = false;
  }

  void _onOptionSelected(int value) {
    if (value == _correctAnswer) {
      widget.onSuccess();
    } else {
      setState(() => _wrongAnswer = true);
      _shakeController.forward(from: 0).then((_) {
        setState(() {
          _generateQuestion();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionText = _isAddition
        ? '$_operand1 + $_operand2 = ?'
        : '$_operand1 - $_operand2 = ?';

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Icon(
              Icons.lock_outline,
              size: 36,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'parent_gate_title'.tr(),
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'parent_gate_subtitle'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Question
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _wrongAnswer
                      ? AppColors.error.withOpacity(0.5)
                      : AppColors.outlineVariant,
                ),
              ),
              child: Text(
                questionText,
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.onSurface,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_wrongAnswer) ...[
              const SizedBox(height: 8),
              Text(
                'parent_gate_wrong'.tr(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Answer buttons — 2x2 grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _options.map((option) {
                return OutlinedButton(
                  onPressed: () => _onOptionSelected(option),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '$option',
                    style: AppTextStyles.headingSmall,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Cancel button
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'cancel'.tr(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
