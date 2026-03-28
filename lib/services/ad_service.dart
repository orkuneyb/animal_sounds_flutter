import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    return 'ca-app-pub-2856437880287416/7483594187';
  }

  static String get interstitialAdUnitId {
    return 'ca-app-pub-2856437880287416/4857430848';
  }

  static String get rewardedAdUnitId {
    return 'ca-app-pub-2856437880287416/2822074889';
  }

  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  int _rewardedAdRetryCount = 0;
  static const int _maxRetryCount = 3;

  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;

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

  // -------------------------------------------------------------------------
  // Rewarded Ad
  // -------------------------------------------------------------------------

  /// Loads a rewarded ad. Call this early so the ad is ready when needed.
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _rewardedAdRetryCount = 0;
          debugPrint('Rewarded ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          _rewardedAd = null;
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _retryLoadRewardedAd();
        },
      ),
    );
  }

  /// Retries loading a rewarded ad with exponential backoff.
  void _retryLoadRewardedAd() {
    if (_rewardedAdRetryCount < _maxRetryCount) {
      _rewardedAdRetryCount++;
      final delaySeconds = _rewardedAdRetryCount * 2;
      Future.delayed(Duration(seconds: delaySeconds), () {
        debugPrint(
          'Retrying rewarded ad load (attempt $_rewardedAdRetryCount/$_maxRetryCount)...',
        );
        loadRewardedAd();
      });
    }
  }

  /// Shows a rewarded ad and invokes [onReward] with the reward amount
  /// upon successful completion.
  ///
  /// If the ad is not ready, [onAdNotReady] is called instead.
  void showRewardedAd({
    required Function(int amount) onReward,
    VoidCallback? onAdNotReady,
    VoidCallback? onAdDismissed,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdReady = false;
          _rewardedAd = null;
          // Auto-reload for next use
          loadRewardedAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          _isRewardedAdReady = false;
          _rewardedAd = null;
          loadRewardedAd();
          onAdNotReady?.call();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint(
            'User earned reward: ${reward.amount} ${reward.type}',
          );
          onReward(reward.amount.toInt());
        },
      );
    } else {
      onAdNotReady?.call();
    }
  }
}
