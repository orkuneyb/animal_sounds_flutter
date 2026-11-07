import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';

/// Whether the one-time "remove ads" purchase is owned.
///
/// `unknown` means no cached answer exists yet (fresh install or reinstall);
/// the first successful store query turns it into `removed` or `notRemoved`.
enum AdsEntitlement { unknown, removed, notRemoved }

/// Outcome of the parent-triggered "Restore purchases" action.
enum RestoreResult { restored, nothingFound, failed }

/// Owns the `remove_ads` entitlement: reads the cached flag, syncs with the
/// store on every cold start, drives [AdService]'s switches, and exposes the
/// state the Remove Ads screen renders.
///
/// Revocation (a Play refund) is applied only after two consecutive cold
/// starts whose restore completed without the purchase; a manual restore
/// never revokes. See docs/superpowers/specs/2026-11-07-remove-ads-design.md.
class PurchaseProvider extends ChangeNotifier {
  static const String productId = 'remove_ads';
  static const String prefsKey = 'ads_removed';
  static const String missCountKey = 'ads_removed_miss_count';

  PurchaseProvider({
    PurchaseStore? store,
    SharedPreferences? prefs,
    AdService? adService,
    this.firstLaunchTimeout = const Duration(seconds: 3),
    this.restoreSettleDelay = const Duration(seconds: 1),
  })  : _store = store ?? NoopPurchaseStore(),
        _prefs = prefs,
        _adService = adService ?? AdService() {
    _readCache();
    _adService.adsRemovedDecision = waitForAdsDecision;
    _syncAdService();
  }

  final PurchaseStore _store;
  final AdService _adService;
  final Duration firstLaunchTimeout;
  final Duration restoreSettleDelay;

  SharedPreferences? _prefs;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Completer<bool> _decision = Completer<bool>();

  AdsEntitlement _entitlement = AdsEntitlement.unknown;
  int _missCount = 0;
  bool _initialized = false;
  bool _coldSyncDone = false;
  bool _storeAvailable = false;
  bool _sawEntitlement = false;
  bool _buying = false;

  ProductDetails? _product;
  bool _productLoadFailed = false;
  bool _purchasePending = false;
  String? _lastErrorKey;

  AdsEntitlement get entitlement => _entitlement;
  bool get adsRemoved => _entitlement == AdsEntitlement.removed;
  bool get storeAvailable => _storeAvailable;
  ProductDetails? get product => _product;
  bool get productLoadFailed => _productLoadFailed;
  bool get purchasePending => _purchasePending;

  /// Translation key of the last failure shown on the offer screen, or null.
  String? get lastErrorKey => _lastErrorKey;

  // ---------------------------------------------------------------------------
  // Startup
  // ---------------------------------------------------------------------------

  void _readCache() {
    final prefs = _prefs;
    if (prefs == null) return;
    final cached = prefs.getBool(prefsKey);
    if (cached != null) {
      _entitlement =
          cached ? AdsEntitlement.removed : AdsEntitlement.notRemoved;
      _completeDecision();
    }
    _missCount = prefs.getInt(missCountKey) ?? 0;
  }

  /// Subscribes to the store, syncs the entitlement with the account's
  /// purchases, then loads the product for sale. Safe to call once per app
  /// start; later calls are ignored.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      _readCache();
      _syncAdService();
    }

    _subscription = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => debugPrint('Purchase stream error: $error'),
    );

    _storeAvailable = await _store.isAvailable();
    if (!_storeAvailable) {
      if (_entitlement == AdsEntitlement.unknown) {
        // Behave as free for this session; do not persist a guess.
        _entitlement = AdsEntitlement.notRemoved;
        _syncAdService();
      }
      _completeDecision();
      _productLoadFailed = true;
      notifyListeners();
      return;
    }

    await _syncWithStore();
    _completeDecision();
    notifyListeners();

    await reloadProduct();
  }

  /// The once-per-launch sync with the account's purchases (the "cold
  /// restore"). Runs on startup when the store is reachable, or later from
  /// [reloadProduct] when the app started offline.
  Future<void> _syncWithStore() async {
    if (_coldSyncDone) return;
    _sawEntitlement = false;
    try {
      await _store.restorePurchases();
      await Future<void>.delayed(restoreSettleDelay);
      await _evaluateColdRestore();
      _coldSyncDone = true;
    } catch (error) {
      debugPrint('Restoring purchases failed: $error');
    }
  }

  Future<void> _evaluateColdRestore() async {
    if (_sawEntitlement) return;
    if (_entitlement == AdsEntitlement.removed) {
      _missCount++;
      if (_missCount >= 2) {
        _missCount = 0;
        await _setEntitlement(AdsEntitlement.notRemoved, persist: true);
      }
      await _prefs?.setInt(missCountKey, _missCount);
      return;
    }
    await _setEntitlement(AdsEntitlement.notRemoved, persist: true);
  }

  /// Resolves to whether ads are removed. Immediate when the answer is
  /// cached; otherwise waits for the first store sync, falling back to
  /// `false` (ads on) after [firstLaunchTimeout].
  Future<bool> waitForAdsDecision() {
    if (_entitlement != AdsEntitlement.unknown) {
      return Future<bool>.value(adsRemoved);
    }
    return _decision.future
        .timeout(firstLaunchTimeout, onTimeout: () => false);
  }

  void _completeDecision() {
    if (!_decision.isCompleted) _decision.complete(adsRemoved);
  }

  // ---------------------------------------------------------------------------
  // Store events
  // ---------------------------------------------------------------------------

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.verificationData.serverVerificationData.isNotEmpty) {
            await _grant(restored: purchase.status == PurchaseStatus.restored);
          }
          if (purchase.pendingCompletePurchase) {
            try {
              await _store.completePurchase(purchase);
            } catch (error) {
              debugPrint('Completing the purchase failed: $error');
            }
          }
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _lastErrorKey = 'purchase_failed';
          AnalyticsService()
              .removeAdsPurchaseFailed(purchase.error?.code ?? 'unknown');
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _grant({required bool restored}) async {
    _sawEntitlement = true;
    _purchasePending = false;
    _lastErrorKey = null;
    _missCount = 0;
    await _prefs?.setInt(missCountKey, 0);
    await _setEntitlement(AdsEntitlement.removed, persist: true);
    if (restored) {
      AnalyticsService().removeAdsRestored();
    } else {
      AnalyticsService().removeAdsPurchased();
    }
    _completeDecision();
  }

  Future<void> _setEntitlement(
    AdsEntitlement value, {
    required bool persist,
  }) async {
    _entitlement = value;
    if (persist) {
      await _prefs?.setBool(prefsKey, value == AdsEntitlement.removed);
    }
    _syncAdService();
    notifyListeners();
  }

  void _syncAdService() {
    _adService.adsDisabled = adsRemoved;
  }

  // ---------------------------------------------------------------------------
  // Parent actions
  // ---------------------------------------------------------------------------

  /// Opens the store's purchase sheet. Ignored while the product is unknown
  /// or another attempt is in flight.
  Future<void> buy() async {
    final product = _product;
    if (product == null || _buying) return;
    _buying = true;
    _lastErrorKey = null;
    AnalyticsService().removeAdsPurchaseStarted();
    try {
      await _store.buyNonConsumable(product);
    } catch (error) {
      debugPrint('Starting the purchase failed: $error');
      _lastErrorKey = 'purchase_failed';
    } finally {
      _buying = false;
      notifyListeners();
    }
  }

  /// Asks the store for the account's purchases on the parent's request.
  /// Finding nothing only reports it; the entitlement is never revoked here.
  Future<RestoreResult> restoreManually() async {
    _sawEntitlement = false;
    try {
      await _store.restorePurchases();
      await Future<void>.delayed(restoreSettleDelay);
      return _sawEntitlement ? RestoreResult.restored : RestoreResult.nothingFound;
    } catch (error) {
      debugPrint('Manual restore failed: $error');
      return RestoreResult.failed;
    }
  }

  /// Loads the product for sale (price in the user's currency). Re-checks
  /// store availability first, and runs the once-per-launch purchase sync if
  /// the app started offline, so the Retry button is never a dead end.
  Future<void> reloadProduct() async {
    _productLoadFailed = false;
    notifyListeners();
    _storeAvailable = await _store.isAvailable();
    if (!_storeAvailable) {
      _productLoadFailed = true;
      notifyListeners();
      return;
    }
    await _syncWithStore();
    _completeDecision();
    try {
      final response = await _store.queryProductDetails({productId});
      _product = response.productDetails
          .where((details) => details.id == productId)
          .firstOrNull;
    } catch (error) {
      debugPrint('Loading the product failed: $error');
      _product = null;
    }
    _productLoadFailed = _product == null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
