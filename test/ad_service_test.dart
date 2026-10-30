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
}
