import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A reusable, child-friendly button that shows a rewarded ad
/// and delivers a reward upon completion.
///
/// Shows a video/gift icon with a description of the reward.
/// Handles loading state and error feedback automatically.
///
/// When the parent owns the remove-ads purchase ([PurchaseProvider.adsRemoved])
/// the button keeps its place and size but switches to "premium" mode: a gift
/// icon, a label without the "watch ad" wording, and the reward is granted on
/// tap without any ad.
class RewardedAdButton extends StatefulWidget {
  /// Text describing what reward the user will receive.
  final String rewardDescription;

  /// Called when the user successfully watches the ad and earns the reward.
  final Function(int amount) onRewardEarned;

  /// Optional icon to show. Defaults to a play-circle icon.
  final IconData icon;

  /// Stable identifier of where this button lives, for analytics
  /// (e.g. 'quiz_hint'). Never localized.
  final String placement;

  /// Optional gradient colors. Defaults to a warm orange-amber gradient.
  final List<Color>? gradientColors;

  /// Whether this button should be compact (icon-only with tooltip).
  final bool compact;

  const RewardedAdButton({
    Key? key,
    required this.rewardDescription,
    required this.placement,
    required this.onRewardEarned,
    this.icon = Icons.play_circle_filled_rounded,
    this.gradientColors,
    this.compact = false,
  }) : super(key: key);

  /// Translation key of the label shown in premium mode for [placement].
  static String premiumLabelKey(String placement) {
    switch (placement) {
      case 'quiz_hint':
        return 'premium_hint';
      case 'quiz_extra_life':
        return 'premium_extra_life';
      case 'quiz_double_score':
        return 'premium_double_score';
      case 'achievement_hint':
        return 'premium_achievement_hint';
      case 'fun_fact':
        return 'premium_fun_fact';
      default:
        return 'premium_reward';
    }
  }

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

    // Ensure a rewarded ad is loading (never when ads are removed).
    final adsRemoved = context.read<PurchaseProvider>().adsRemoved;
    if (!adsRemoved && !_adService.isRewardedAdReady) {
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
          AnalyticsService().rewardedAdWatched(widget.placement);
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

  /// Premium mode: the reward is included in the purchase, no ad.
  void _grantPremium() {
    AnalyticsService().rewardGrantedPremium(widget.placement);
    widget.onRewardEarned(1);
    _showRewardSnackBar();
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
    final premium = context.watch<PurchaseProvider>().adsRemoved;
    if (widget.compact) {
      return _buildCompactButton(premium);
    }
    return _buildFullButton(premium);
  }

  List<Color> get _colors =>
      widget.gradientColors ??
      [const Color(0xFFFF9800), const Color(0xFFFF6D00)];

  String _label(bool premium) => premium
      ? RewardedAdButton.premiumLabelKey(widget.placement).tr()
      : widget.rewardDescription;

  Widget _buildCompactButton(bool premium) {
    final colors = _colors;

    return Tooltip(
      message: _label(premium),
      child: GestureDetector(
        onTap: premium ? _grantPremium : (_isLoading ? null : _onTap),
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
              : Icon(
                  premium ? Icons.card_giftcard_rounded : widget.icon,
                  color: Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }

  Widget _buildFullButton(bool premium) {
    final colors = _colors;

    final button = GestureDetector(
      onTap: premium ? _grantPremium : (_isLoading ? null : _onTap),
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
            if (_isLoading && !premium)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (premium)
              const Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: 22,
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
                _label(premium),
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

    if (premium) return button;

    // The shimmer animation only decorates the ad-backed button.
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) => child!,
      child: button,
    );
  }
}
