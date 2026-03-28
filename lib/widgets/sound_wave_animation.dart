import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated sound wave visualization with staggered vertical bars.
///
/// Displays 5-7 bars that animate their height in a wave pattern,
/// suitable for showing during audio recording or playback.
class SoundWaveAnimation extends StatefulWidget {
  /// Number of bars to display (typically 5-7).
  final int barCount;

  /// Color of the bars.
  final Color color;

  /// Maximum height of the tallest bar.
  final double maxHeight;

  /// Width of each individual bar.
  final double barWidth;

  /// Spacing between bars.
  final double spacing;

  /// Whether the animation is currently active.
  final bool isAnimating;

  const SoundWaveAnimation({
    super.key,
    this.barCount = 7,
    this.color = Colors.green,
    this.maxHeight = 40,
    this.barWidth = 5,
    this.spacing = 4,
    this.isAnimating = true,
  });

  @override
  State<SoundWaveAnimation> createState() => _SoundWaveAnimationState();
}

class _SoundWaveAnimationState extends State<SoundWaveAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(widget.barCount, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 80)),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isAnimating) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
        if (mounted && widget.isAnimating) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (final controller in _controllers) {
      controller.stop();
      controller.animateTo(0.15,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
    }
  }

  @override
  void didUpdateWidget(covariant SoundWaveAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, _) {
              final height = widget.isAnimating
                  ? widget.maxHeight * _animations[index].value
                  : widget.maxHeight * 0.15;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                width: widget.barWidth,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
