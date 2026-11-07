import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  group('AdService.childDirectedConfiguration', () {
    test('tags every ad request as child-directed', () {
      expect(
        AdService.childDirectedConfiguration.tagForChildDirectedTreatment,
        TagForChildDirectedTreatment.yes,
      );
    });

    test('limits ad content to the G rating', () {
      expect(
        AdService.childDirectedConfiguration.maxAdContentRating,
        MaxAdContentRating.g,
      );
    });
  });
  group('ads disabled', () {
    tearDown(() => AdService().resetEntitlementForTesting());

    test('ensureAdsEnabled is false and loads return without platform calls', () async {
      final ads = AdService()
        ..adsDisabled = true
        ..adsAllowed = () async => false;
      expect(await ads.ensureAdsEnabled(), isFalse);
      // Reaching MobileAds here would throw MissingPluginException.
      await expectLater(ads.createInterstitialAd(), completes);
      await expectLater(ads.loadRewardedAd(), completes);
    });

    test('showInterstitialAd calls onAdClosed immediately when disabled', () {
      var closed = false;
      (AdService()..adsDisabled = true).showInterstitialAd(onAdClosed: () => closed = true);
      expect(closed, isTrue);
    });

    test('showRewardedAd calls onAdNotReady when disabled', () {
      var notReady = false;
      (AdService()..adsDisabled = true).showRewardedAd(
        onReward: (_) => fail('no reward without an ad'),
        onAdNotReady: () => notReady = true,
      );
      expect(notReady, isTrue);
    });
  });
}
