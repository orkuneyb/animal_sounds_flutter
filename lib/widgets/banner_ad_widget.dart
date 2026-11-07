import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/purchase_provider.dart';
import '../services/ad_service.dart';

/// The shared banner used on the home and explore tabs.
///
/// Collapses to nothing while no ad is loaded, and never requests an ad when
/// the parent owns the remove-ads purchase ([PurchaseProvider.adsRemoved]).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    if (!context.read<PurchaseProvider>().adsRemoved) {
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    final ads = AdService();
    // Waits for the entitlement decision on first launch; false when the
    // purchase is owned.
    if (!await ads.ensureAdsEnabled()) return;
    await ads.initialize();
    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isBannerAdReady = false;
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = context.watch<PurchaseProvider>().adsRemoved;
    final ad = _bannerAd;
    if (adsRemoved || !_isBannerAdReady || ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
