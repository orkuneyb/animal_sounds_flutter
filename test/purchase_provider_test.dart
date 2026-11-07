import 'dart:async';

import 'package:animal_sounds_flutter/providers/purchase_provider.dart';
import 'package:animal_sounds_flutter/services/ad_service.dart';
import 'package:animal_sounds_flutter/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_purchase_store.dart';

void main() {
  late FakePurchaseStore store;
  late List<(String, Map<String, Object>?)> events;

  setUp(() {
    store = FakePurchaseStore();
    events = [];
    AnalyticsService().setBackend((name, params) async {
      events.add((name, params));
    });
  });

  tearDown(() async {
    AnalyticsService().setBackend(null);
    AdService().resetEntitlementForTesting();
    await store.close();
  });

  Future<PurchaseProvider> build(
    Map<String, Object> prefsValues, {
    Duration timeout = const Duration(milliseconds: 50),
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return PurchaseProvider(
      store: store,
      prefs: prefs,
      firstLaunchTimeout: timeout,
      restoreSettleDelay: Duration.zero,
    );
  }

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  List<String> eventNames() => events.map((e) => e.$1).toList();

  group('cold start', () {
    test('cached true is known before initialize', () async {
      final p = await build({'ads_removed': true});

      expect(p.entitlement, AdsEntitlement.removed);
      expect(p.adsRemoved, isTrue);
      expect(AdService().adsDisabled, isTrue);
      expect(await p.waitForAdsDecision(), isTrue);
      expect(store.restoreCalls, 0);
    });

    test('fresh install, restore finds purchase → removed and persisted',
        () async {
      store.restoreResults = [ownedPurchase()];
      final p = await build({});
      expect(p.entitlement, AdsEntitlement.unknown);

      final decision = p.waitForAdsDecision();
      await p.initialize();

      expect(p.entitlement, AdsEntitlement.removed);
      expect((await prefs()).getBool('ads_removed'), isTrue);
      expect(AdService().adsDisabled, isTrue);
      expect(await decision, isTrue);
    });

    test('fresh install, restore finds nothing → notRemoved persisted',
        () async {
      final p = await build({});
      final decision = p.waitForAdsDecision();
      await p.initialize();

      expect(p.entitlement, AdsEntitlement.notRemoved);
      expect((await prefs()).getBool('ads_removed'), isFalse);
      expect(AdService().adsDisabled, isFalse);
      expect(await decision, isFalse);
    });

    test('fresh install, store unavailable → notRemoved in memory only',
        () async {
      store.available = false;
      final p = await build({});
      await p.initialize();

      expect(p.entitlement, AdsEntitlement.notRemoved);
      expect(p.storeAvailable, isFalse);
      expect((await prefs()).containsKey('ads_removed'), isFalse);
      expect(store.restoreCalls, 0);
      expect(await p.waitForAdsDecision(), isFalse);
    });

    test('fresh install, restore slow → ads decision times out to false',
        () async {
      store.neverCompleteRestore = true;
      final p = await build({});
      unawaited(p.initialize());

      expect(await p.waitForAdsDecision(), isFalse);
      expect(p.entitlement, AdsEntitlement.unknown);
    });
  });

  group('purchase stream', () {
    test('purchased event grants and completes the purchase', () async {
      final p = await build({});
      await p.initialize();

      store.emit([
        ownedPurchase(status: PurchaseStatus.purchased, pendingComplete: true),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(p.adsRemoved, isTrue);
      expect(store.completeCalls, 1);
      expect(eventNames(), contains('remove_ads_purchased'));
      expect((await prefs()).getBool('ads_removed'), isTrue);
    });

    test('restored event logs remove_ads_restored', () async {
      store.restoreResults = [ownedPurchase()];
      final p = await build({});
      await p.initialize();

      expect(eventNames(), contains('remove_ads_restored'));
      expect(eventNames(), isNot(contains('remove_ads_purchased')));
    });

    test('event for another product is ignored', () async {
      final p = await build({});
      await p.initialize();

      store.emit([ownedPurchase(id: 'other', status: PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);

      expect(p.entitlement, AdsEntitlement.notRemoved);
      expect((await prefs()).getBool('ads_removed'), isFalse);
    });

    test('purchase with empty server verification is ignored', () async {
      final p = await build({});
      await p.initialize();

      store.emit([ownedPurchase(status: PurchaseStatus.purchased, token: '')]);
      await Future<void>.delayed(Duration.zero);

      expect(p.adsRemoved, isFalse);
    });

    test('pending then purchased', () async {
      final p = await build({});
      await p.initialize();

      store.emit([ownedPurchase(status: PurchaseStatus.pending)]);
      await Future<void>.delayed(Duration.zero);
      expect(p.purchasePending, isTrue);
      expect(p.adsRemoved, isFalse);

      store.emit([ownedPurchase(status: PurchaseStatus.purchased)]);
      await Future<void>.delayed(Duration.zero);
      expect(p.purchasePending, isFalse);
      expect(p.adsRemoved, isTrue);
    });

    test('error event sets lastErrorKey and logs the code', () async {
      final p = await build({});
      await p.initialize();

      store.emit([
        ownedPurchase(status: PurchaseStatus.error)
          ..error = IAPError(
            source: 'google_play',
            code: 'BillingResponse.itemUnavailable',
            message: 'x',
          ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(p.lastErrorKey, 'purchase_failed');
      expect(p.adsRemoved, isFalse);
      final failed =
          events.where((e) => e.$1 == 'remove_ads_purchase_failed').toList();
      expect(failed, hasLength(1));
      expect(failed.single.$2, {'code': 'BillingResponse.itemUnavailable'});
    });
  });

  group('revocation', () {
    test('cached true, one empty restore → still removed, miss count 1',
        () async {
      final p = await build({'ads_removed': true});
      await p.initialize();

      expect(p.adsRemoved, isTrue);
      expect((await prefs()).getBool('ads_removed'), isTrue);
      expect((await prefs()).getInt('ads_removed_miss_count'), 1);
    });

    test('cached true, second consecutive empty restore → notRemoved, miss reset',
        () async {
      final p = await build({'ads_removed': true, 'ads_removed_miss_count': 1});
      await p.initialize();

      expect(p.entitlement, AdsEntitlement.notRemoved);
      expect(AdService().adsDisabled, isFalse);
      expect((await prefs()).getBool('ads_removed'), isFalse);
      expect((await prefs()).getInt('ads_removed_miss_count'), 0);
    });

    test('cached true, restore throws → flag and miss count unchanged',
        () async {
      store.restoreError = Exception('BillingResponse.serviceDisconnected');
      final p = await build({'ads_removed': true});
      await p.initialize();

      expect(p.adsRemoved, isTrue);
      expect((await prefs()).getBool('ads_removed'), isTrue);
      expect((await prefs()).getInt('ads_removed_miss_count') ?? 0, 0);
    });

    test('cached true, store unavailable → unchanged', () async {
      store.available = false;
      final p = await build({'ads_removed': true, 'ads_removed_miss_count': 1});
      await p.initialize();

      expect(p.adsRemoved, isTrue);
      expect((await prefs()).getInt('ads_removed_miss_count'), 1);
    });

    test('a restored purchase resets the miss count', () async {
      store.restoreResults = [ownedPurchase()];
      final p = await build({'ads_removed': true, 'ads_removed_miss_count': 1});
      await p.initialize();

      expect(p.adsRemoved, isTrue);
      expect((await prefs()).getInt('ads_removed_miss_count'), 0);
    });
  });

  group('manual restore', () {
    test('finding nothing never revokes', () async {
      final p = await build({'ads_removed': true, 'ads_removed_miss_count': 1});
      await p.initialize(); // miss count becomes 2? no: initialize already evaluated once
      final missAfterInit = (await prefs()).getInt('ads_removed_miss_count');

      final result = await p.restoreManually();

      expect(result, RestoreResult.nothingFound);
      expect(p.adsRemoved, p.entitlement == AdsEntitlement.removed);
      expect((await prefs()).getInt('ads_removed_miss_count'), missAfterInit);
    });

    test('finding nothing on a paid install keeps the entitlement', () async {
      final p = await build({'ads_removed': true});
      await p.initialize(); // one miss recorded, still removed
      expect(p.adsRemoved, isTrue);

      await p.restoreManually();
      await p.restoreManually();

      expect(p.adsRemoved, isTrue);
      expect((await prefs()).getInt('ads_removed_miss_count'), 1);
    });

    test('that throws reports failed', () async {
      final p = await build({});
      await p.initialize();
      store.restoreError = Exception('boom');

      expect(await p.restoreManually(), RestoreResult.failed);
    });

    test('that finds the purchase reports restored', () async {
      final p = await build({});
      await p.initialize();
      store.restoreResults = [ownedPurchase()];

      expect(await p.restoreManually(), RestoreResult.restored);
      expect(p.adsRemoved, isTrue);
    });
  });

  group('product', () {
    test('not found → product null and productLoadFailed true', () async {
      final p = await build({});
      await p.initialize();

      expect(p.product, isNull);
      expect(p.productLoadFailed, isTrue);
    });

    test('found exposes store price', () async {
      store.product = removeAdsProduct();
      final p = await build({});
      await p.initialize();

      expect(p.product?.price, '₺89,99');
      expect(p.productLoadFailed, isFalse);
    });
  });

  group('buy', () {
    test('with no product is a no-op', () async {
      final p = await build({});
      await p.initialize();

      await p.buy();

      expect(store.buyCalls, 0);
      expect(eventNames(), isNot(contains('remove_ads_purchase_started')));
    });

    test('twice before the store answers calls the store once', () async {
      store.product = removeAdsProduct();
      store.buyGate = Completer<bool>();
      final p = await build({});
      await p.initialize();

      final first = p.buy();
      final second = p.buy();
      store.buyGate!.complete(true);
      await first;
      await second;

      expect(store.buyCalls, 1);
      expect(eventNames().where((e) => e == 'remove_ads_purchase_started').length, 1);
    });

    test('that throws sets lastErrorKey', () async {
      store.product = removeAdsProduct();
      store.buyError = Exception('boom');
      final p = await build({});
      await p.initialize();

      await p.buy();

      expect(p.lastErrorKey, 'purchase_failed');
    });
  });
}
