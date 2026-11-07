import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:animal_sounds_flutter/utils/colors/colors.dart';
import 'package:animal_sounds_flutter/utils/styles.dart';
import 'package:animal_sounds_flutter/widgets/parent_gate_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Logs the offer, shows the parent gate and, if it is passed, opens
/// [RemoveAdsPage]. Every entry point to the purchase goes through here.
///
/// [source] is one of: profile, profile_card, home_banner, settings.
Future<void> openRemoveAds(BuildContext context, {required String source}) async {
  AnalyticsService().removeAdsOfferShown(source);
  final passed = await ParentGateWidget.showAsDialog(context);
  if (!passed || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const RemoveAdsPage()),
  );
}

/// The parent-facing screen for the one-time "remove ads" purchase.
///
/// Renders from [PurchaseProvider]: loading, store unavailable, ready to buy
/// (with the store-localised price), pending, and purchased. Restore is
/// always reachable.
class RemoveAdsPage extends StatelessWidget {
  const RemoveAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<PurchaseProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onSurface,
        title: Text(
          'remove_ads'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Text(
              'remove_ads_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _Benefit(text: 'benefit_no_banners'.tr()),
            _Benefit(text: 'benefit_no_interstitials'.tr()),
            _Benefit(text: 'benefit_free_rewards'.tr()),
            const SizedBox(height: 28),
            _buildAction(context, purchases),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.pets_rounded,
          size: 64,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, PurchaseProvider purchases) {
    if (purchases.adsRemoved) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          Text(
            'ads_removed_thanks'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _RestoreButton(purchases: purchases),
        ],
      );
    }

    if (purchases.productLoadFailed || !purchases.storeAvailable) {
      return Column(
        children: [
          Text(
            'store_unavailable'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: purchases.reloadProduct,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('retry'.tr()),
          ),
          const SizedBox(height: 8),
          _RestoreButton(purchases: purchases),
        ],
      );
    }

    final product = purchases.product;
    if (product == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorKey = purchases.lastErrorKey;
    return Column(
      children: [
        FilledButton(
          onPressed: purchases.purchasePending ? null : purchases.buy,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('remove_ads'.tr())),
              const Text('  ·  '),
              Text(product.price),
            ],
          ),
        ),
        if (purchases.purchasePending) ...[
          const SizedBox(height: 10),
          Text(
            'purchase_pending'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        if (errorKey != null) ...[
          const SizedBox(height: 10),
          Text(
            errorKey.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 8),
        _RestoreButton(purchases: purchases),
        const SizedBox(height: 12),
        Text(
          'one_time_note'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton({required this.purchases});

  final PurchaseProvider purchases;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _restore(context),
      child: Text('restore_purchases'.tr()),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final result = await purchases.restoreManually();
    if (!context.mounted) return;
    final key = switch (result) {
      RestoreResult.restored => 'restore_success',
      RestoreResult.nothingFound => 'restore_nothing_found',
      RestoreResult.failed => 'purchase_failed',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.tr()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
