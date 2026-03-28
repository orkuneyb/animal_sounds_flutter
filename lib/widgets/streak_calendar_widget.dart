import 'package:animal_sounds_flutter/providers/daily_provider.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A horizontal row of 7 day indicators showing streak progress.
class StreakCalendarWidget extends StatelessWidget {
  const StreakCalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyProvider>(
      builder: (context, dailyProvider, _) {
        final calendar = dailyProvider.getStreakCalendar(7);
        final streak = dailyProvider.currentStreak;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Streak counter with fire icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$streak',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'streak_days'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Day indicators row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: calendar.map((day) {
                  final date = day['date'] as DateTime;
                  final completed = day['completed'] as bool;
                  final isToday = day['isToday'] as bool;

                  return _DayIndicator(
                    date: date,
                    completed: completed,
                    isToday: isToday,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayIndicator extends StatefulWidget {
  final DateTime date;
  final bool completed;
  final bool isToday;

  const _DayIndicator({
    required this.date,
    required this.completed,
    required this.isToday,
  });

  @override
  State<_DayIndicator> createState() => _DayIndicatorState();
}

class _DayIndicatorState extends State<_DayIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Only animate if today and not completed
    if (widget.isToday && !widget.completed) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _DayIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToday && !widget.completed) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _dayLetter(DateTime date) {
    // Use localized short day names
    final weekdays = [
      'day_mon'.tr(),
      'day_tue'.tr(),
      'day_wed'.tr(),
      'day_thu'.tr(),
      'day_fri'.tr(),
      'day_sat'.tr(),
      'day_sun'.tr(),
    ];
    return weekdays[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day letter
        Text(
          _dayLetter(widget.date),
          style: AppTextStyles.label.copyWith(
            color: widget.isToday
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
            fontWeight:
                widget.isToday ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),

        // Circle indicator
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double borderWidth = widget.isToday && !widget.completed
                ? 2.0 + _pulseController.value * 1.5
                : 2.0;

            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.completed
                    ? AppColors.success
                    : AppColors.surfaceContainerHigh,
                border: widget.isToday
                    ? Border.all(
                        color: widget.completed
                            ? const Color(0xFFFFD700) // Gold
                            : AppColors.primary.withOpacity(
                                0.5 + _pulseController.value * 0.5,
                              ),
                        width: borderWidth,
                      )
                    : null,
                boxShadow: widget.completed
                    ? [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            );
          },
        ),

        const SizedBox(height: 4),

        // Day number
        Text(
          '${widget.date.day}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
