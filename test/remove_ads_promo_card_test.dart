import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/widgets/remove_ads_promo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AdService().resetEntitlementForTesting());

  Future<void> pump(WidgetTester tester, {required bool adsRemoved}) async {
    SharedPreferences.setMockInitialValues({'ads_removed': adsRemoved});
    final provider =
        PurchaseProvider(prefs: await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider<PurchaseProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: RemoveAdsPromoCard())),
      ),
    );
  }

  testWidgets('invites parents while ads are on', (tester) async {
    await pump(tester, adsRemoved: false);

    expect(find.text('promo_title'), findsOneWidget);
    expect(find.text('promo_body'), findsOneWidget);
    expect(find.text('remove_ads'), findsOneWidget);
  });

  testWidgets('disappears once ads are removed', (tester) async {
    await pump(tester, adsRemoved: true);

    expect(find.text('promo_title'), findsNothing);
    expect(find.byType(RemoveAdsPromoCard), findsOneWidget);
  });
}
