import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/widgets/rewarded_ad_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AdService().resetEntitlementForTesting());

  testWidgets('premium mode grants the reward on tap without an ad',
      (tester) async {
    SharedPreferences.setMockInitialValues({'ads_removed': true});
    final provider =
        PurchaseProvider(prefs: await SharedPreferences.getInstance());
    int? earned;

    await tester.pumpWidget(
      ChangeNotifierProvider<PurchaseProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: RewardedAdButton(
              rewardDescription: 'watch_ad_hint',
              placement: 'quiz_hint',
              onRewardEarned: (amount) => earned = amount,
            ),
          ),
        ),
      ),
    );

    // Without EasyLocalization, .tr() returns the key itself.
    expect(find.text('premium_hint'), findsOneWidget);
    expect(find.text('watch_ad_hint'), findsNothing);
    expect(find.byIcon(Icons.play_circle_filled_rounded), findsNothing);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(earned, 1);
    expect(tester.takeException(), isNull);
  });

  test('premiumLabelKey maps every placement', () {
    expect(RewardedAdButton.premiumLabelKey('quiz_hint'), 'premium_hint');
    expect(RewardedAdButton.premiumLabelKey('quiz_extra_life'),
        'premium_extra_life');
    expect(RewardedAdButton.premiumLabelKey('quiz_double_score'),
        'premium_double_score');
    expect(RewardedAdButton.premiumLabelKey('achievement_hint'),
        'premium_achievement_hint');
    expect(RewardedAdButton.premiumLabelKey('fun_fact'), 'premium_fun_fact');
    expect(RewardedAdButton.premiumLabelKey('x'), 'premium_reward');
  });
}
