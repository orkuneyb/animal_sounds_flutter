import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A reusable, child-friendly button that shows a rewarded ad
/// and delivers a reward upon completion.
///
/// Shows a video/gift icon with a description of the reward.
/// Handles loading state and error feedback automatically.
class RewardedAdButton extends StatefulWidget {
  /// Text describing what reward the user will receive.
  final String rewardDescription;

  /// Called when the user successfully watches the ad and earns the reward.
  final Function(int amount) onRewardEarned;

  /// Optional icon to show. Defaults to a play-circle icon.
  final IconData icon;

  /// Optional gradient colors. Defaults to a warm orange-amber gradient.
  final List<Color>? gradientColors;

  /// Whether this button should be compact (icon-only with tooltip).
  final bool compact;

  const RewardedAdButton({
    Key? key,
    required this.rewardDescription,
    required this.onRewardEarned,
    this.icon = Icons.play_circle_filled_rounded,
    this.gradientColors,
    this.compact = false,
  }) : super(key: key);

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton>
    with SingleTickerProviderStateMixin {
  final AdService _adService = AdService();
  bool _isLoading = false;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Ensure a rewarded ad is loading
    if (!_adService.isRewardedAdReady) {
      _adService.loadRewardedAd();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    _adService.showRewardedAd(
      onReward: (amount) {
        if (mounted) {
          setState(() => _isLoading = false);
          widget.onRewardEarned(amount);
          _showRewardSnackBar();
        }
      },
      onAdNotReady: () {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNotReadySnackBar();
          // Try loading again for next attempt
          _adService.loadRewardedAd();
        }
      },
      onAdDismissed: () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _showRewardSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ad_reward_received'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNotReadySnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ad_not_ready'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() {
    final colors = widget.gradientColors ??
        [const Color(0xFFFF9800), const Color(0xFFFF6D00)];

    return Tooltip(
      message: widget.rewardDescription,
      child: GestureDetector(
        onTap: _isLoading ? null : _onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildFullButton() {
    final colors = widget.gradientColors ??
        [const Color(0xFFFF9800), const Color(0xFFFF6D00)];

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isLoading ? null : _onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.rewardDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
