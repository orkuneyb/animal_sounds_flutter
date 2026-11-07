import 'package:animal_sounds_flutter/pages/remove_ads_page.dart';
import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_purchase_store.dart';

void main() {
  late FakePurchaseStore store;

  setUp(() => store = FakePurchaseStore());

  tearDown(() async {
    AdService().resetEntitlementForTesting();
    await store.close();
  });

  Future<PurchaseProvider> provider(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = PurchaseProvider(
      store: store,
      prefs: await SharedPreferences.getInstance(),
      restoreSettleDelay: Duration.zero,
      firstLaunchTimeout: const Duration(milliseconds: 50),
    );
    // Real async: the provider awaits a Future.delayed during initialize.
    await tester.runAsync(p.initialize);
    await tester.pumpWidget(
      ChangeNotifierProvider<PurchaseProvider>.value(
        value: p,
        child: const MaterialApp(home: RemoveAdsPage()),
      ),
    );
    await tester.pump();
    return p;
  }

  testWidgets('shows the store price on the buy button', (tester) async {
    store.product = removeAdsProduct(price: '₺89,99');
    await provider(tester);

    expect(find.textContaining('₺89,99'), findsOneWidget);
    expect(find.text('one_time_note'), findsOneWidget);
    expect(find.text('restore_purchases'), findsOneWidget);
    expect(find.text('store_unavailable'), findsNothing);
  });

  testWidgets('shows store_unavailable with retry when the product is missing',
      (tester) async {
    await provider(tester);

    expect(find.text('store_unavailable'), findsOneWidget);
    expect(find.text('retry'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('tapping buy calls the store once', (tester) async {
    store.product = removeAdsProduct();
    await provider(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(store.buyCalls, 1);
  });

  testWidgets('purchased state shows thanks and keeps restore', (tester) async {
    store.product = removeAdsProduct();
    await provider(tester, prefs: {'ads_removed': true});

    expect(find.text('ads_removed_thanks'), findsOneWidget);
    expect(find.text('restore_purchases'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });

  testWidgets('pending shows purchase_pending', (tester) async {
    store.product = removeAdsProduct();
    await provider(tester);

    await tester.runAsync(() async {
      store.emit([ownedPurchase(status: PurchaseStatus.pending)]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();

    expect(find.text('purchase_pending'), findsOneWidget);
  });

  testWidgets('restore with nothing found shows restore_nothing_found',
      (tester) async {
    store.product = removeAdsProduct();
    await provider(tester);

    await tester.runAsync(() async {
      await tester.tap(find.text('restore_purchases'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();

    expect(find.text('restore_nothing_found'), findsOneWidget);
  });
}
