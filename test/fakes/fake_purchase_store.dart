import 'dart:async';

import 'package:animal_sounds_flutter/services/purchase_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// In-memory stand-in for Google Play used by the purchase tests.
///
/// `restorePurchases()` mirrors the Android plugin: it throws on a store
/// error, otherwise it emits [restoreResults] (possibly empty) on the
/// purchase stream and then completes.
class FakePurchaseStore implements PurchaseStore {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();

  bool available = true;
  ProductDetails? product;
  Object? restoreError;
  bool neverCompleteRestore = false;
  List<PurchaseDetails> restoreResults = <PurchaseDetails>[];

  /// When set, `buyNonConsumable` waits for it before returning.
  Completer<bool>? buyGate;
  Object? buyError;

  int buyCalls = 0;
  int completeCalls = 0;
  int restoreCalls = 0;
  int queryCalls = 0;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queryCalls++;
    final found = product;
    return ProductDetailsResponse(
      productDetails: found == null ? const [] : [found],
      notFoundIDs: found == null ? ids.toList() : const [],
    );
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    buyCalls++;
    if (buyError != null) throw buyError!;
    if (buyGate != null) return buyGate!.future;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    if (neverCompleteRestore) await Completer<void>().future;
    if (restoreError != null) throw restoreError!;
    _controller.add(List<PurchaseDetails>.of(restoreResults));
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completeCalls++;
  }

  Future<void> close() => _controller.close();
}

PurchaseDetails ownedPurchase({
  String id = 'remove_ads',
  PurchaseStatus status = PurchaseStatus.restored,
  String token = 'tok',
  bool pendingComplete = false,
}) {
  return PurchaseDetails(
    purchaseID: 'p1',
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: token,
      serverVerificationData: token,
      source: 'google_play',
    ),
    transactionDate: '0',
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

ProductDetails removeAdsProduct({String price = '₺89,99'}) => ProductDetails(
      id: 'remove_ads',
      title: 'Remove ads',
      description: '',
      price: price,
      rawPrice: 89.99,
      currencyCode: 'TRY',
    );
