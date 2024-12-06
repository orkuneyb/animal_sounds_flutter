import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    return 'ca-app-pub-2856437880287416/7483594187';
  }

  static String get interstitialAdUnitId {
    return 'ca-app-pub-2856437880287416/4857430848';
  }

  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void showInterstitialAd({Function? onAdClosed}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdReady = false;
          createInterstitialAd();
          onAdClosed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      onAdClosed?.call();
    }
  }

  BannerAd createBannerAd() {
    return BannerAd(
      size: AdSize.banner,
      adUnitId: bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) {},
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    );
  }
}
