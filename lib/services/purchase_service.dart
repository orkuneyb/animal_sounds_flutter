import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

/// The slice of the store the app needs for the one-time `remove_ads`
/// product. [PurchaseProvider] depends on this interface so tests can run
/// the entitlement rules against an in-memory fake.
abstract class PurchaseStore {
  /// Purchase updates from the store, including restores and purchases
  /// finished while the app was closed. Subscribe before anything else.
  Stream<List<PurchaseDetails>> get purchaseStream;

  Future<bool> isAvailable();

  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);

  /// Starts the store's purchase sheet. The result arrives on
  /// [purchaseStream], not as the return value.
  Future<bool> buyNonConsumable(ProductDetails product);

  /// Asks the store for the account's owned purchases; they are emitted on
  /// [purchaseStream] as `restored`. Throws when the store reports an error.
  Future<void> restorePurchases();

  /// Acknowledges a delivered purchase. Google Play refunds purchases that
  /// are not acknowledged within three days.
  Future<void> completePurchase(PurchaseDetails purchase);
}

/// The real store, backed by the `in_app_purchase` plugin.
class InAppPurchaseStore implements PurchaseStore {
  InAppPurchaseStore([InAppPurchase? plugin])
      : _iap = plugin ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) =>
      _iap.queryProductDetails(ids);

  @override
  Future<bool> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);
}

/// A store that is never available. Used when no real store is wired in
/// (widget tests, the parent-alert test) so the app behaves as free.
class NoopPurchaseStore implements PurchaseStore {
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: const [], notFoundIDs: ids.toList());

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async => false;

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}
