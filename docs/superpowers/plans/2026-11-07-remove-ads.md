# Remove Ads (1.4.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Parents can buy a one-time `remove_ads` product that permanently hides every ad and makes rewarded-video perks free, plus three small stability fixes, shipped as 1.4.0+12.

**Architecture:** A `PurchaseStore` interface wraps the `in_app_purchase` plugin so a `PurchaseProvider` (ChangeNotifier) can own the tri-state entitlement, persistence and revocation rules and be unit-tested with a fake. `AdService` gains two switches the provider drives: an async "may ads start?" gate used once per launch and a sync `adsDisabled` flag every ad call checks. UI reads `PurchaseProvider.adsRemoved` through Provider; all offer entry points funnel into one `openRemoveAds(context, source:)` helper that logs, shows the parent gate, and pushes `RemoveAdsPage`.

**Tech Stack:** Flutter 3.41 / Dart 3.11, provider, easy_localization, shared_preferences, google_mobile_ads 6, in_app_purchase ^3.3.1 (Android: in_app_purchase_android 0.5.x), google_fonts 6.3, firebase_crashlytics 6.

**Spec:** `docs/superpowers/specs/2026-11-07-remove-ads-design.md`

## Global Constraints

- Version bump to `1.4.0+12` in `pubspec.yaml` (last task).
- Product ID is exactly `remove_ads`; prefs keys exactly `ads_removed` (bool) and `ads_removed_miss_count` (int).
- First-launch ad gate timeout: 3 seconds. Revocation only after 2 consecutive empty cold-start restores; manual restore never revokes.
- Every new translation key goes into all 8 files under `assets/translations/` (`en-US`, `tr-TR`, `ar-SA`, `de-DE`, `es-ES`, `hi-IN`, `pt-BR`, `ru-RU`) in the same commit; `test/translations_test.dart` enforces key parity.
- Price is never hardcoded; the UI shows `ProductDetails.price` from the store.
- Every entry to the purchase flow passes `ParentGateWidget.showAsDialog` first.
- Analytics parameters: strings and ints only, no user identifiers.
- Commit messages: imperative, no `Co-Authored-By` line (owner rule). Never push.
- Before declaring done: `flutter analyze` with 0 errors, `flutter test` all green, `flutter build appbundle --release` succeeds.

## Review Focus

1. Play returns `remove_ads` in `notFoundIDs` (product not yet activated in Console): the page must show `store_unavailable` with a retry, never a null-price crash. Test in Task 4.
2. `purchaseStream` delivers a purchase for some other product ID: it must be ignored, not grant the entitlement. Test in Task 4.
3. `restorePurchases()` throws (`InAppPurchaseException`) on a device with the cached flag true: the flag and the miss counter must not change. Test in Task 4.
4. Cached flag already true on a cold start: `waitForAdsDecision()` must resolve immediately with `true`, not after the 3-second timeout, so a paying parent's startup is not delayed and no ad loads. Test in Task 4.
5. `buy()` called while the product is still loading, or twice in a row: no exception, at most one store call per completed purchase attempt. Test in Task 4.

---

### Task 1: Quiz early-exit guard

**Files:**
- Modify: `lib/pages/quiz_page.dart:672-675`

**Interfaces:** none.

- [ ] **Step 1: Add the mounted check**

In `_checkAnswer`, the `else` branch's `Future.delayed(const Duration(seconds: 2), () { _advanceToNextQuestion(); })` becomes `Future.delayed(const Duration(seconds: 2), () { if (mounted) _advanceToNextQuestion(); })`, matching the 4-second branch above it.

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/pages/quiz_page.dart`
Expected: `No issues found!` (pre-existing infos elsewhere are fine; zero errors).

- [ ] **Step 3: Commit**

```bash
git add lib/pages/quiz_page.dart
git commit -m "fix: Do not advance the quiz after the page was closed"
```

---

### Task 2: Bundle the Nunito font

**Files:**
- Create: `assets/google_fonts/Nunito-Regular.ttf`, `Nunito-Medium.ttf`, `Nunito-SemiBold.ttf`, `Nunito-Bold.ttf`, `Nunito-ExtraBold.ttf`, `Nunito-Black.ttf`
- Modify: `pubspec.yaml` (assets list, line ~70)
- Modify: `lib/main.dart` (`main()`)
- Test: `test/bundled_fonts_test.dart`

**Interfaces:** none.

- [ ] **Step 1: Write the failing test**

```dart
// test/bundled_fonts_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const weights = ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'];

  for (final w in weights) {
    test('Nunito-$w.ttf is bundled', () {
      final file = File('assets/google_fonts/Nunito-$w.ttf');
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100000));
    });
  }

  test('pubspec lists the google_fonts asset folder', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/google_fonts/'));
  });

  test('runtime font fetching is disabled at startup', () {
    expect(File('lib/main.dart').readAsStringSync(),
        contains('GoogleFonts.config.allowRuntimeFetching = false'));
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/bundled_fonts_test.dart`
Expected: FAIL, files do not exist.

- [ ] **Step 3: Download the six static files**

These are the exact files google_fonts 6.3.3 would fetch at runtime (weights 400–900, normal style). File names must match the google_fonts naming scheme exactly.

```bash
mkdir -p assets/google_fonts && cd assets/google_fonts
curl -sSfL -o Nunito-Regular.ttf   https://fonts.gstatic.com/s/a/6f96017e762896b4cf3c2db345d41d7a72a3720a95698c3cd47020bf433db435.ttf
curl -sSfL -o Nunito-Medium.ttf    https://fonts.gstatic.com/s/a/1f6452d3509db129d3468088c1c952f1a844b6dc865703a09595fc53700a6251.ttf
curl -sSfL -o Nunito-SemiBold.ttf  https://fonts.gstatic.com/s/a/f165190d31319dc6384c83fdd014ed983630541b21d005b5caadf1d74fbd513d.ttf
curl -sSfL -o Nunito-Bold.ttf      https://fonts.gstatic.com/s/a/8148a236e4127dad38346ce596c544389aa2fdaaa9f311e589741de30d25ddb8.ttf
curl -sSfL -o Nunito-ExtraBold.ttf https://fonts.gstatic.com/s/a/43364ac2d05d1033b5e255ce77e4d84d2f6467bfadb5e5985ca4e688949e73bf.ttf
curl -sSfL -o Nunito-Black.ttf     https://fonts.gstatic.com/s/a/a5ddd59da28c281984ae3bd12aa3b9af3b204e61156e50f1108d5fcf71aa5665.ttf
```

Expected sizes: each about 125 KB. Also copy the OFL licence: `curl -sSfL -o OFL.txt https://raw.githubusercontent.com/googlefonts/nunito/main/OFL.txt` into the same folder.

- [ ] **Step 4: Declare the folder and disable fetching**

In `pubspec.yaml` under `flutter: assets:` add `- assets/google_fonts/`. In `lib/main.dart` `main()`, after `WidgetsFlutterBinding.ensureInitialized();` add `GoogleFonts.config.allowRuntimeFetching = false;` (import `package:google_fonts/google_fonts.dart`).

- [ ] **Step 5: Run the test and the app build**

Run: `flutter test test/bundled_fonts_test.dart` → PASS.
Run: `flutter build apk --debug` → succeeds (asset bundling).

- [ ] **Step 6: Commit**

```bash
git add assets/google_fonts pubspec.yaml lib/main.dart test/bundled_fonts_test.dart
git commit -m "fix: Bundle Nunito so the app never downloads fonts"
```

---

### Task 3: Record caught Flutter errors as non-fatal

**Files:**
- Modify: `lib/main.dart:68`

**Interfaces:** none.

- [ ] **Step 1: Change the handler**

`FlutterError.onError = crashlytics.recordFlutterFatalError;` becomes `FlutterError.onError = crashlytics.recordFlutterError;`. Leave `PlatformDispatcher.instance.onError` fatal. Update the comment above `_initFirebase` to say framework-caught errors are non-fatal, uncaught async errors fatal.

- [ ] **Step 2: Analyze and commit**

Run: `flutter analyze lib/main.dart` → 0 errors.

```bash
git add lib/main.dart
git commit -m "fix: Record framework-caught Flutter errors as non-fatal in Crashlytics"
```

---

### Task 4: PurchaseStore, PurchaseProvider and the AdService switches

**Files:**
- Modify: `pubspec.yaml` (add `in_app_purchase: ^3.3.1`)
- Create: `lib/services/purchase_service.dart`
- Create: `lib/providers/purchase_provider.dart`
- Modify: `lib/services/ad_service.dart`
- Modify: `lib/services/analytics_service.dart`
- Test: `test/purchase_provider_test.dart`, `test/ad_service_test.dart`, `test/analytics_service_test.dart`

**Interfaces:**
- Produces (`lib/services/purchase_service.dart`):
  ```dart
  abstract class PurchaseStore {
    Stream<List<PurchaseDetails>> get purchaseStream;
    Future<bool> isAvailable();
    Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);
    Future<bool> buyNonConsumable(ProductDetails product);
    Future<void> restorePurchases();          // throws on store error (Android does)
    Future<void> completePurchase(PurchaseDetails purchase);
  }
  class InAppPurchaseStore implements PurchaseStore { /* delegates to InAppPurchase.instance */ }
  class NoopPurchaseStore implements PurchaseStore { /* isAvailable → false, empty stream, notFoundIDs = ids */ }
  ```
- Produces (`lib/providers/purchase_provider.dart`):
  ```dart
  enum AdsEntitlement { unknown, removed, notRemoved }
  enum RestoreResult { restored, nothingFound, failed }
  class PurchaseProvider extends ChangeNotifier {
    static const String productId = 'remove_ads';
    static const String prefsKey = 'ads_removed';
    static const String missCountKey = 'ads_removed_miss_count';
    PurchaseProvider({
      PurchaseStore? store,                 // default NoopPurchaseStore()
      SharedPreferences? prefs,             // if given, cached state is read synchronously in the constructor
      AdService? adService,                 // default AdService()
      Duration firstLaunchTimeout = const Duration(seconds: 3),
      Duration restoreSettleDelay = const Duration(seconds: 1),
    });
    AdsEntitlement get entitlement;
    bool get adsRemoved;                    // entitlement == removed
    bool get storeAvailable;
    ProductDetails? get product;            // null until loaded or when not found
    bool get productLoadFailed;             // true when query finished without the product
    bool get purchasePending;
    String? get lastErrorKey;               // translation key, e.g. 'purchase_failed'; cleared on next attempt
    Future<void> initialize();              // idempotent; subscribe → availability → restore → settle → evaluate → load product
    Future<bool> waitForAdsDecision();      // true = ads removed; resolves at once if known, else after restore or timeout (false)
    Future<void> buy();                     // no-op if product == null or a buy is in flight
    Future<RestoreResult> restoreManually();// never revokes
    Future<void> reloadProduct();
  }
  ```
- Produces (`lib/services/ad_service.dart` additions):
  ```dart
  bool adsDisabled = false;                          // set by PurchaseProvider on every entitlement change
  Future<bool> Function() adsAllowed = () async => true; // replaced by PurchaseProvider with waitForAdsDecision
  Future<bool> ensureAdsEnabled();                   // awaits adsAllowed() once per launch (cached), then returns !adsDisabled
  ```
  `initialize()`, `createInterstitialAd()`, `loadRewardedAd()` return early when `!await ensureAdsEnabled()`; `showInterstitialAd` calls `onAdClosed` and returns when `adsDisabled`; `showRewardedAd` calls `onAdNotReady` and returns when `adsDisabled`.
- Produces (`lib/services/analytics_service.dart` additions):
  `removeAdsOfferShown(String source)`, `removeAdsPurchaseStarted()`, `removeAdsPurchased()`, `removeAdsRestored()`, `removeAdsPurchaseFailed(String code)`, `rewardGrantedPremium(String placement)` → events `remove_ads_offer_shown {source}`, `remove_ads_purchase_started`, `remove_ads_purchased`, `remove_ads_restored`, `remove_ads_purchase_failed {code}`, `reward_granted_premium {placement}`.

- [ ] **Step 1: Add the dependency**

Run: `flutter pub add in_app_purchase:^3.3.1`
Expected: `pubspec.lock` gains `in_app_purchase`, `in_app_purchase_android`, `in_app_purchase_storekit`, `in_app_purchase_platform_interface`.

- [ ] **Step 2: Write the failing provider tests**

`test/purchase_provider_test.dart`, importing `test/fakes/fake_purchase_store.dart` (created here, reused by Tasks 5–6). `FakePurchaseStore implements PurchaseStore` with: `StreamController<List<PurchaseDetails>>.broadcast()`, `bool available = true`, `ProductDetails? product` (null → `notFoundIDs: ['remove_ads']`), `Object? restoreError`, `List<PurchaseDetails> restoreResults = []` (emitted on the stream by `restorePurchases()` after an `await Future<void>.delayed(Duration.zero)`), counters `buyCalls`, `completeCalls`, `restoreCalls`. Helper `PurchaseDetails owned({String id = 'remove_ads', PurchaseStatus status = PurchaseStatus.restored, String token = 'tok'})` builds `PurchaseDetails(purchaseID: 'p1', productID: id, verificationData: PurchaseVerificationData(localVerificationData: token, serverVerificationData: token, source: 'google_play'), transactionDate: '0', status: status)`. Build every provider with `restoreSettleDelay: Duration.zero, firstLaunchTimeout: const Duration(milliseconds: 50)` and `prefs: await SharedPreferences.getInstance()` after `SharedPreferences.setMockInitialValues(...)`. Use `fakeAsync` only where a timeout is asserted; otherwise `await provider.initialize()`.

Tests (names and the assertion each makes):

```dart
test('cached true is known before initialize', ...)   // prefs {ads_removed: true} → entitlement removed, adsRemoved true, AdService().adsDisabled true, waitForAdsDecision() completes true without initialize()
test('fresh install, restore finds purchase → removed and persisted', ...) // restoreResults=[owned()] → removed; prefs ads_removed true; AdService().adsDisabled true; waitForAdsDecision true
test('fresh install, restore finds nothing → notRemoved persisted', ...)   // entitlement notRemoved; prefs ads_removed false; waitForAdsDecision false
test('fresh install, store unavailable → notRemoved in memory only', ...)  // available=false → notRemoved; prefs has no ads_removed key; restoreCalls 0
test('fresh install, restore slow → ads decision times out to false', ...) // store.restorePurchases never completes; waitForAdsDecision() → false after timeout; entitlement still unknown
test('purchased event grants and completes the purchase', ...)            // emit owned(status: purchased) with pendingCompletePurchase (construct, then set `..pendingCompletePurchase = true`) → removed, completeCalls 1, analytics 'remove_ads_purchased'
test('restored event logs remove_ads_restored', ...)
test('event for another product is ignored', ...)                          // owned(id: 'other') → entitlement unchanged (notRemoved), prefs unchanged
test('purchase with empty server verification is ignored', ...)            // token '' → not granted
test('cached true, one empty restore → still removed, miss count 1', ...)
test('cached true, second consecutive empty restore → notRemoved, miss reset', ...) // prefs {ads_removed:true, ads_removed_miss_count:1} → false, miss 0
test('cached true, restore throws → flag and miss count unchanged', ...)   // restoreError = Exception() → removed, miss 0
test('cached true, store unavailable → unchanged', ...)
test('a restored purchase resets the miss count', ...)                     // prefs miss 1, restoreResults=[owned()] → miss 0
test('manual restore finding nothing never revokes', ...)                  // cached true, restoreResults [] → restoreManually() == nothingFound, still removed, miss unchanged
test('manual restore that throws reports failed', ...)
test('manual restore that finds the purchase reports restored', ...)
test('pending then purchased', ...)                                        // emit status pending → purchasePending true; emit purchased → pending false, removed
test('error event sets lastErrorKey and logs the code', ...)               // PurchaseDetails(status: error)..error = IAPError(source:'google_play', code:'BillingResponse.itemUnavailable', message:'x') → lastErrorKey 'purchase_failed', analytics 'remove_ads_purchase_failed' {code: 'BillingResponse.itemUnavailable'}
test('product not found → product null and productLoadFailed true', ...)
test('product found exposes store price', ...)                             // ProductDetails(id:'remove_ads', title:'Remove ads', description:'', price:'₺89,99', rawPrice:89.99, currencyCode:'TRY') → product!.price == '₺89,99'
test('buy with no product is a no-op', ...)                                // buyCalls 0
test('buy twice before the store answers calls the store once', ...)       // fake buyNonConsumable awaits a Completer; two buy() → buyCalls 1; analytics 'remove_ads_purchase_started' once
test('buy that throws sets lastErrorKey', ...)
```

Analytics assertions use the pattern from `test/analytics_service_test.dart` (`AnalyticsService().setBackend(...)` capturing a list; reset in `tearDown`).

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/purchase_provider_test.dart`
Expected: compile errors, `purchase_provider.dart` missing.

- [ ] **Step 4: Implement `lib/services/purchase_service.dart`**

`PurchaseStore`, `InAppPurchaseStore` (fields: `final InAppPurchase _iap = InAppPurchase.instance;` `buyNonConsumable` → `_iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product))`), `NoopPurchaseStore` as in Interfaces. Import `package:in_app_purchase/in_app_purchase.dart`.

- [ ] **Step 5: Add the AdService switches**

In `lib/services/ad_service.dart` add the three members from Interfaces. `ensureAdsEnabled()` caches the first `adsAllowed()` future in a `Future<bool>? _adsAllowedFuture`; after it resolves return `!adsDisabled && result`. Guard `initialize()` (do not cache `_initialization` when ads are not allowed, so a later enablement in the same session can still initialise), `createInterstitialAd()`, `loadRewardedAd()`, `showInterstitialAd()`, `showRewardedAd()` as described in Interfaces.

- [ ] **Step 6: Add the analytics helpers**

Six methods in `lib/services/analytics_service.dart` exactly as named in Interfaces. Extend the `named helpers use the event names from the spec` test in `test/analytics_service_test.dart` with the six calls and expected names.

- [ ] **Step 7: Implement `lib/providers/purchase_provider.dart`**

Constructor: store defaults, read `prefs?.getBool(prefsKey)` → `removed` / `notRemoved` / `unknown` (null), `_missCount = prefs?.getInt(missCountKey) ?? 0`; set `_adService.adsAllowed = waitForAdsDecision` and `_syncAdService()`; if known, complete `_decision` (a `Completer<bool>`).

`initialize()`: guard with `_initialized`; `prefs ??= await SharedPreferences.getInstance()` (re-read cached state if the constructor had none); subscribe `store.purchaseStream.listen(_onPurchases, onError: (_) {})`; `storeAvailable = await store.isAvailable()`; if unavailable: if unknown → `_entitlement = notRemoved` in memory, complete decision false; notify; return. Else `_sawEntitlement = false; try { await store.restorePurchases(); await Future<void>.delayed(restoreSettleDelay); _evaluateColdRestore(); } catch (_) { /* no change */ }`; complete decision with `adsRemoved` if still pending; then `await reloadProduct()`.

`_evaluateColdRestore()`: if `_sawEntitlement` → nothing (grant already persisted and reset the counter). Else if `removed` → `_missCount++`; if `>= 2` → `_setEntitlement(notRemoved, persist: true)`, `_missCount = 0`; persist counter. Else (unknown or notRemoved) → `_setEntitlement(notRemoved, persist: true)`.

`_onPurchases(List<PurchaseDetails> list)`: for each with `productID == productId`: `pending` → `purchasePending = true`; `purchased`/`restored` → if `verificationData.serverVerificationData.isNotEmpty` → `_grant(restored: status == restored)`; then if `pendingCompletePurchase` → `await store.completePurchase(p)`; `error` → `purchasePending = false`, `lastErrorKey = 'purchase_failed'`, `removeAdsPurchaseFailed(p.error?.code ?? 'unknown')`; `canceled` → `purchasePending = false`. `notifyListeners()` once per batch.

`_grant({required bool restored})`: `_sawEntitlement = true; _missCount = 0; purchasePending = false; _setEntitlement(removed, persist: true)`; persist counter; log purchased/restored; complete decision true.

`_setEntitlement(AdsEntitlement e, {required bool persist})`: assign, `if (persist) prefs.setBool(prefsKey, e == removed)`, `_syncAdService()` (`_adService.adsDisabled = adsRemoved`), notify.

`waitForAdsDecision()`: `if (_entitlement != unknown) return adsRemoved; return _decision.future.timeout(firstLaunchTimeout, onTimeout: () => false);`

`buy()`: `if (product == null || _buying) return; _buying = true; lastErrorKey = null; removeAdsPurchaseStarted(); try { await store.buyNonConsumable(product!); } catch (_) { lastErrorKey = 'purchase_failed'; } finally { _buying = false; notify; }`

`restoreManually()`: `_sawEntitlement = false; try { await store.restorePurchases(); await delay; return _sawEntitlement ? restored : nothingFound; } catch (_) { return failed; }`

`reloadProduct()`: `productLoadFailed = false; final r = await store.queryProductDetails({productId}); product = r.productDetails.where((p) => p.id == productId).firstOrNull; productLoadFailed = product == null; notify;` wrapped in try/catch → `productLoadFailed = true`.

`dispose()`: cancel the subscription.

- [ ] **Step 8: Extend `test/ad_service_test.dart`**

```dart
group('ads disabled', () {
  test('ensureAdsEnabled is false and createInterstitialAd/loadRewardedAd return without platform calls', () async {
    final ads = AdService()..adsDisabled = true..adsAllowed = () async => false;
    expect(await ads.ensureAdsEnabled(), isFalse);
    await expectLater(ads.createInterstitialAd(), completes); // would throw MissingPluginException if it reached MobileAds
    await expectLater(ads.loadRewardedAd(), completes);
  });
  test('showInterstitialAd calls onAdClosed immediately when disabled', () { var closed = false; (AdService()..adsDisabled = true).showInterstitialAd(onAdClosed: () => closed = true); expect(closed, isTrue); });
  test('showRewardedAd calls onAdNotReady when disabled', ...);
});
```
Reset the singleton's `adsDisabled = false; adsAllowed = () async => true;` in `tearDown`.

- [ ] **Step 9: Run all three test files**

Run: `flutter test test/purchase_provider_test.dart test/ad_service_test.dart test/analytics_service_test.dart`
Expected: all PASS.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/purchase_service.dart lib/providers/purchase_provider.dart lib/services/ad_service.dart lib/services/analytics_service.dart test/fakes/fake_purchase_store.dart test/purchase_provider_test.dart test/ad_service_test.dart test/analytics_service_test.dart
git commit -m "feat: Add the remove-ads entitlement provider and ad switches"
```

---

### Task 5: Hide banners and make rewarded perks free

**Files:**
- Modify: `lib/widgets/banner_ad_widget.dart`
- Modify: `lib/pages/animal_info_page.dart:33-52,141`, `lib/pages/favorites_page.dart:21-38,170`, `lib/pages/quiz_start_page.dart:25-42,311`
- Modify: `lib/widgets/rewarded_ad_button.dart`
- Test: `test/banner_ad_widget_test.dart`, `test/rewarded_ad_button_test.dart`

**Interfaces:**
- Consumes: `PurchaseProvider.adsRemoved`, `AdService.ensureAdsEnabled()`, `AnalyticsService.rewardGrantedPremium`.
- Produces: `static String premiumLabelKey(String placement)` on `RewardedAdButton`: `quiz_hint→premium_hint`, `quiz_extra_life→premium_extra_life`, `quiz_double_score→premium_double_score`, `achievement_hint→premium_achievement_hint`, `fun_fact→premium_fun_fact`, anything else → `premium_reward`.

- [ ] **Step 1: Write the failing widget tests**

```dart
// test/banner_ad_widget_test.dart
testWidgets('renders nothing and never loads when ads are removed', (tester) async {
  SharedPreferences.setMockInitialValues({'ads_removed': true});
  final provider = PurchaseProvider(prefs: await SharedPreferences.getInstance());
  await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: const MaterialApp(home: Scaffold(body: BannerAdWidget()))));
  await tester.pump();
  expect(find.byType(AdWidget), findsNothing);
  expect(tester.takeException(), isNull); // a load attempt would surface MissingPluginException here
});
```

```dart
// test/rewarded_ad_button_test.dart
testWidgets('premium mode grants the reward on tap without an ad', (tester) async {
  SharedPreferences.setMockInitialValues({'ads_removed': true});
  final provider = PurchaseProvider(prefs: await SharedPreferences.getInstance());
  int? earned;
  await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: MaterialApp(home: Scaffold(body: RewardedAdButton(
          rewardDescription: 'watch_ad_hint', placement: 'quiz_hint',
          onRewardEarned: (a) => earned = a)))));
  expect(find.text('premium_hint'), findsOneWidget);     // .tr() returns the key under test
  expect(find.text('watch_ad_hint'), findsNothing);
  expect(find.byIcon(Icons.play_circle_filled_rounded), findsNothing);
  await tester.tap(find.byType(GestureDetector).first);
  await tester.pump();
  expect(earned, 1);
  expect(tester.takeException(), isNull);
});
test('premiumLabelKey maps every placement', () {
  expect(RewardedAdButton.premiumLabelKey('quiz_hint'), 'premium_hint');
  expect(RewardedAdButton.premiumLabelKey('quiz_extra_life'), 'premium_extra_life');
  expect(RewardedAdButton.premiumLabelKey('quiz_double_score'), 'premium_double_score');
  expect(RewardedAdButton.premiumLabelKey('achievement_hint'), 'premium_achievement_hint');
  expect(RewardedAdButton.premiumLabelKey('fun_fact'), 'premium_fun_fact');
  expect(RewardedAdButton.premiumLabelKey('x'), 'premium_reward');
});
```

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/banner_ad_widget_test.dart test/rewarded_ad_button_test.dart` → FAIL.

- [ ] **Step 3: Gate `BannerAdWidget`**

`_loadBannerAd()`: replace `await AdService().initialize();` with `if (!await AdService().ensureAdsEnabled()) return;` (then `initialize()`). `build()`: `if (context.watch<PurchaseProvider>().adsRemoved) return const SizedBox.shrink();` before the existing logic. Also in `initState`, skip `_loadBannerAd()` when `context.read<PurchaseProvider>().adsRemoved`. Delete the two `print` calls (use `debugPrint`).

- [ ] **Step 4: Gate the three page-owned banners**

In each of `animal_info_page.dart`, `favorites_page.dart`, `quiz_start_page.dart`: make the field `BannerAd? _bannerAd`; in `initState` only create and load when `!context.read<PurchaseProvider>().adsRemoved`, and route the load through `AdService().ensureAdsEnabled()` (`quiz_start_page` already awaits `initialize()`; replace with the gate then `initialize()`); guard `setState` with `mounted`; `dispose()` uses `_bannerAd?.dispose()`; the `if (_isBannerAdReady)` rendering becomes `if (_isBannerAdReady && _bannerAd != null && !context.watch<PurchaseProvider>().adsRemoved)` with `_bannerAd!`.

- [ ] **Step 5: Premium mode in `RewardedAdButton`**

Add `static String premiumLabelKey(String placement)` with the mapping from Interfaces. In `build()`: `final premium = context.watch<PurchaseProvider>().adsRemoved;` pass it to both builders. Premium: label `premiumLabelKey(widget.placement).tr()`, icons: only `Icons.card_giftcard_rounded` (no play icon), no shimmer (`AnimatedBuilder` replaced by the plain container when premium), `onTap` → `_grantPremium()`: `AnalyticsService().rewardGrantedPremium(widget.placement); widget.onRewardEarned(1); _showRewardSnackBar();`. In `initState`, skip `loadRewardedAd()` when `context.read<PurchaseProvider>().adsRemoved`. Compact mode keeps its circle; tooltip shows the premium label.

- [ ] **Step 6: Run the tests and the analyzer**

Run: `flutter test test/banner_ad_widget_test.dart test/rewarded_ad_button_test.dart && flutter analyze` → PASS, 0 errors.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/banner_ad_widget.dart lib/widgets/rewarded_ad_button.dart lib/pages/animal_info_page.dart lib/pages/favorites_page.dart lib/pages/quiz_start_page.dart test/banner_ad_widget_test.dart test/rewarded_ad_button_test.dart
git commit -m "feat: Hide banners and grant rewards for free when ads are removed"
```

---

### Task 6: Translations and the Remove Ads page

**Files:**
- Modify: all 8 files in `assets/translations/`
- Create: `lib/pages/remove_ads_page.dart`
- Test: `test/translations_test.dart`, `test/remove_ads_page_test.dart`

**Interfaces:**
- Consumes: `PurchaseProvider` (`product`, `productLoadFailed`, `storeAvailable`, `purchasePending`, `lastErrorKey`, `adsRemoved`, `buy()`, `restoreManually()`, `reloadProduct()`), `ParentGateWidget.showAsDialog`, `AnalyticsService.removeAdsOfferShown`.
- Produces:
  ```dart
  class RemoveAdsPage extends StatelessWidget { const RemoveAdsPage({super.key}); }
  /// Logs the offer, shows the parent gate, pushes RemoveAdsPage. Returns after the page closes.
  Future<void> openRemoveAds(BuildContext context, {required String source});
  ```

- [ ] **Step 1: Extend the translations test**

Add to `test/translations_test.dart`:

```dart
test('remove-ads keys exist and buy_for_price carries the placeholder', () {
  for (final key in [
    'remove_ads', 'remove_ads_short', 'remove_ads_title', 'benefit_no_banners',
    'benefit_no_interstitials', 'benefit_free_rewards', 'buy_for_price', 'one_time_note',
    'restore_purchases', 'restore_success', 'restore_nothing_found', 'store_unavailable',
    'purchase_pending', 'purchase_failed', 'ads_removed_thanks', 'purchases', 'promo_title',
    'promo_body', 'retry', 'premium_hint', 'premium_extra_life', 'premium_double_score',
    'premium_fun_fact', 'premium_achievement_hint', 'premium_reward',
  ]) {
    expect(reference, containsPair(key, isNotEmpty), reason: key);
  }
  expect(reference['buy_for_price'], contains('{price}'));
});
```

Run: `flutter test test/translations_test.dart` → FAIL (keys missing).

- [ ] **Step 2: Add the 25 keys to all 8 files**

English copy (spec-fixed; the other seven are faithful translations, written by the implementer; Turkish shown because the owner reviews it):

| key | en-US | tr-TR |
|---|---|---|
| remove_ads | Remove ads | Reklamları kaldır |
| remove_ads_short | Remove ads | Reklamsız |
| remove_ads_title | Ad-free for the whole family | Tüm aile için reklamsız |
| benefit_no_banners | No more banner ads | Afiş reklamlar kalkar |
| benefit_no_interstitials | No full-screen ads between sounds | Sesler arasında tam ekran reklam çıkmaz |
| benefit_free_rewards | Hints and extra chances are free | İpuçları ve ekstra şanslar ücretsiz olur |
| buy_for_price | Remove ads · {price} | Reklamları kaldır · {price} |
| one_time_note | One-time payment. Works on every device signed in with the same Google account. | Tek seferlik ödeme. Aynı Google hesabıyla giriş yapılan her cihazda geçerlidir. |
| restore_purchases | Restore purchases | Satın alımları geri yükle |
| restore_success | Your purchase was restored. Ads are off. | Satın alımınız geri yüklendi. Reklamlar kapalı. |
| restore_nothing_found | No previous purchase was found for this Google account. | Bu Google hesabında önceki bir satın alım bulunamadı. |
| store_unavailable | Google Play is not available right now. Please try again later. | Google Play şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin. |
| purchase_pending | Waiting for Google Play to confirm… | Google Play onayı bekleniyor… |
| purchase_failed | The purchase could not be completed. | Satın alma tamamlanamadı. |
| ads_removed_thanks | Thank you! Ads are off for good. | Teşekkürler! Reklamlar kalıcı olarak kapatıldı. |
| purchases | Purchases | Satın alımlar |
| promo_title | Ad-free version for parents | Ebeveynler için reklamsız sürüm |
| promo_body | One-time purchase removes all ads. Hints and extra chances become free. | Tek seferlik satın alma tüm reklamları kaldırır. İpuçları ve ekstra şanslar ücretsiz olur. |
| retry | Try again | Tekrar dene |
| premium_hint | Get a hint | İpucu al |
| premium_extra_life | Get another chance | Başka bir şans al |
| premium_double_score | Double your score | Puanını ikiye katla |
| premium_fun_fact | Hear a fun fact | Eğlenceli bir bilgi dinle |
| premium_achievement_hint | Get a hint | İpucu al |
| premium_reward | Get reward | Ödülü al |

Keep each file valid JSON with the same indentation; add the keys as a block after `watch_ad_achievement_hint`.

Run: `flutter test test/translations_test.dart` → PASS (parity across 8 files).

- [ ] **Step 3: Write the failing page tests**

`test/remove_ads_page_test.dart`, pumping `ChangeNotifierProvider<PurchaseProvider>.value(value: provider, child: const MaterialApp(home: RemoveAdsPage()))` with the `FakePurchaseStore` from `test/fakes/fake_purchase_store.dart` (Task 4):

```dart
testWidgets('shows the store price on the buy button', ...)        // product price '₺89,99' → find.textContaining('₺89,99'); find.text('one_time_note'); find.text('restore_purchases')
testWidgets('shows store_unavailable with retry when the product is missing', ...) // productLoadFailed → find.text('store_unavailable'), find.text('retry'), no buy button
testWidgets('tapping buy calls the store once', ...)                 // tap button → fake.buyCalls == 1
testWidgets('purchased state shows thanks and keeps restore', ...)  // prefs ads_removed true → find.text('ads_removed_thanks'), find.text('restore_purchases'), find.textContaining('{price}') nothing
testWidgets('pending shows purchase_pending', ...)                   // emit pending → find.text('purchase_pending')
testWidgets('restore with nothing found shows restore_nothing_found snackbar', ...)
```

Run: `flutter test test/remove_ads_page_test.dart` → FAIL (file missing).

- [ ] **Step 4: Implement `lib/pages/remove_ads_page.dart`**

`RemoveAdsPage`: `Scaffold` with transparent `AppBar` (same style as `settings.dart`), scrollable column: header illustration (`assets/animal_images/` any existing friendly animal, 120 px, inside a soft circle using `AppColors.secondary` at 15 % alpha), `remove_ads_title` in `AppTextStyles.headingMedium`, three benefit rows (`Icons.check_circle_rounded` in `AppColors.success` + text), then a state area driven by `context.watch<PurchaseProvider>()`:
- `adsRemoved` → big check icon, `ads_removed_thanks`, `TextButton` `restore_purchases`.
- `productLoadFailed || !storeAvailable` → `store_unavailable` text, `OutlinedButton` `retry` → `reloadProduct()`.
- `product == null` → `CircularProgressIndicator`.
- else `FilledButton` with `'buy_for_price'.tr(namedArgs: {'price': product.price})`, disabled while `purchasePending`; below it `purchase_pending` when pending, `lastErrorKey!.tr()` in `AppColors.error` when set; `TextButton` `restore_purchases`; footnote `one_time_note` in `AppTextStyles.bodySmall`.
`restore_purchases` → `final r = await provider.restoreManually();` → snackbar `restore_success` / `restore_nothing_found` / `purchase_failed`.

`openRemoveAds(context, {required source})`: `AnalyticsService().removeAdsOfferShown(source); final passed = await ParentGateWidget.showAsDialog(context); if (!passed || !context.mounted) return; await Navigator.push(context, MaterialPageRoute(builder: (_) => const RemoveAdsPage()));`

- [ ] **Step 5: Run tests and analyzer**

Run: `flutter test test/remove_ads_page_test.dart test/translations_test.dart && flutter analyze` → PASS, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add assets/translations lib/pages/remove_ads_page.dart test/remove_ads_page_test.dart test/translations_test.dart
git commit -m "feat: Add the Remove Ads page with translations in 8 languages"
```

---

### Task 7: Entry points — profile card and tile, home caption, settings section

**Files:**
- Modify: `lib/pages/tabs/profile_tab.dart` (`build` list at :55-65, `_buildQuickLinks` at :607)
- Modify: `lib/pages/tabs/animals_tab.dart:101`
- Modify: `lib/pages/settings.dart` (before the `App Info` section at :466)
- Create: `lib/widgets/remove_ads_promo_card.dart`

**Interfaces:**
- Consumes: `openRemoveAds(context, source:)`, `PurchaseProvider.adsRemoved`, `restoreManually()`, `ParentGateWidget.showAsDialog`.
- Produces: `class RemoveAdsPromoCard extends StatelessWidget` (renders `SizedBox.shrink()` when `adsRemoved`).

- [ ] **Step 1: Promo card widget**

`lib/widgets/remove_ads_promo_card.dart`: container in the profile card style (`AppColors.surfaceContainerLowest`, radius 20, soft shadow as in `_buildQuickLinks`), left `Icons.block_rounded` on `AppColors.secondary`, `promo_title` (`bodyLarge` w700), `promo_body` (`bodySmall`), trailing `FilledButton.tonal` `remove_ads` → `openRemoveAds(context, source: 'profile_card')`. Returns `SizedBox.shrink()` when `context.watch<PurchaseProvider>().adsRemoved`.

- [ ] **Step 2: Profile tab**

In `build`, insert `const RemoveAdsPromoCard(), const SizedBox(height: 20),` as the first items of the `SliverChildListDelegate` list. In `_buildQuickLinks`, insert before the `parent_dashboard` tile: when `!adsRemoved` → `_QuickLinkTile(icon: Icons.block_rounded, iconColor: AppColors.secondary, title: 'remove_ads'.tr(), onTap: () => openRemoveAds(context, source: 'profile'))`; when `adsRemoved` → the same tile with `Icons.check_circle_rounded`, `AppColors.success`, title `ads_removed_thanks`, onTap pushing `RemoveAdsPage` directly (no gate needed: nothing to buy); followed by the existing `Divider`.

- [ ] **Step 3: Home caption under the banner**

In `animals_tab.dart` replace `const BannerAdWidget(),` with a `Consumer<PurchaseProvider>` that renders `const BannerAdWidget()` plus, when `!adsRemoved`, an `Align(alignment: Alignment.centerRight, child: TextButton.icon(icon: Icon(Icons.block_rounded, size: 14), label: Text('remove_ads_short'.tr(), style: 12 sp), onPressed: () => openRemoveAds(context, source: 'home_banner')))` with compact padding. Designer's call, deviating from the spec's "only while a banner is loaded": the caption is shown whenever ads are not removed, so a parent finds it even when no ad happened to be served; it disappears after purchase.

- [ ] **Step 4: Settings section**

Before the `App Info` section add `_SectionHeader(title: 'purchases'.tr())`, `_SettingsCard(children: [...])` with: when `!adsRemoved` a `ListTile` `remove_ads` (leading `Icons.block_rounded`) → gate via `openRemoveAds(context, source: 'settings')`, a divider, and always a `ListTile` `restore_purchases` (leading `Icons.restore_rounded`) → `ParentGateWidget.showAsDialog` then `restoreManually()` → snackbar `restore_success` / `restore_nothing_found` / `purchase_failed`. Then `const SizedBox(height: 28)`.

- [ ] **Step 5: Analyzer and existing tests**

Run: `flutter analyze && flutter test` → 0 errors, all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/remove_ads_promo_card.dart lib/pages/tabs/profile_tab.dart lib/pages/tabs/animals_tab.dart lib/pages/settings.dart
git commit -m "feat: Offer Remove Ads from the profile, home banner and settings"
```

---

### Task 8: App wiring, version, release notes, full build

**Files:**
- Modify: `lib/main.dart` (`main()`, `MyApp`, `_AppWithDependenciesState.initState`)
- Modify: `pubspec.yaml` (version)
- Create: `docs/release-notes/1.4.0.md`
- Test: `test/parent_alert_test.dart` (must still pass unchanged)

**Interfaces:**
- Consumes: `PurchaseProvider(store:, prefs:)`, `InAppPurchaseStore`, `initialize()`.
- Produces: `MyApp({super.key, this.purchaseProvider})` with `final PurchaseProvider? purchaseProvider;`.

- [ ] **Step 1: Wire the provider**

`main()`: after `_initFirebase()`, `final prefs = await SharedPreferences.getInstance(); final purchases = PurchaseProvider(store: InAppPurchaseStore(), prefs: prefs);` and pass `MyApp(purchaseProvider: purchases)`. In `MyApp.build` add `ChangeNotifierProvider<PurchaseProvider>(create: (_) => purchaseProvider ?? PurchaseProvider())` to the `MultiProvider` list. In `_AppWithDependenciesState.initState`'s post-frame callback, call `context.read<PurchaseProvider>().initialize();` before `AdService().loadRewardedAd();` (the latter now self-gates).

- [ ] **Step 2: Version and notes**

`pubspec.yaml`: `version: 1.4.0+12`. Create `docs/release-notes/1.4.0.md` following `docs/release-notes/1.3.1.md`'s format, 8 blocks (`<en-US>`, `<ar>`, `<de-DE>`, `<es-ES>`, `<hi-IN>`, `<pt-BR>`, `<ru-RU>`, `<tr-TR>`), each under 500 characters, en-US:

```
What's new in 1.4.0
• New for parents: a one-time purchase removes all ads. Hints and extra chances become free.
• Fonts are now built in, so the app looks right offline
• Fixed a rare error when leaving the quiz quickly
• Stability improvements
```

- [ ] **Step 3: Full verification**

Run, in order, and record each result:
```bash
flutter analyze            # 0 errors
flutter test               # all pass (expect ~100)
flutter build appbundle --release
```
Expected: `build/app/outputs/bundle/release/app-release.aab` written. Confirm R8 kept the billing classes: `grep -c "com.android.billingclient" build/app/outputs/mapping/release/seeds.txt` > 0 (the plugin ships its own consumer rules; this only confirms them).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart pubspec.yaml docs/release-notes/1.4.0.md
git commit -m "feat: Wire the remove-ads purchase into the app and bump to 1.4.0+12"
```

- [ ] **Step 5: Hand over**

Report to the owner, in Turkish: the AAB path, the filled Play Console release-notes template (owner rule), and the Play Console checklist from the spec (create and activate `remove_ads` at the USD 1.99 tier, add the licence tester account, upload to the internal testing track, test buy / kill-reopen / reinstall-restore / refund). Note explicitly that the purchase flow was verified with a fake store only; the real Play flow can only be exercised from an internal-testing install.
