// lib/widgets/in_app_purchase_stub.dart
// ════════════════════════════════════════════════════════════════
// STUB POUR LE PACKAGE in_app_purchase
// Utilisé quand le package n'est pas disponible (web / tests)
// ════════════════════════════════════════════════════════════════

// Stub pour InAppPurchase
class InAppPurchase {
  static InAppPurchase get instance => InAppPurchase._();
  InAppPurchase._();

  Future<bool> isAvailable() async => false;
  Stream get purchaseStream => Stream.empty();
  Future<void> buyConsumable({required dynamic purchaseParam}) async {}
  Future<void> completePurchase(dynamic purchase) async {}
  Future<dynamic> queryProductDetails(Set<String> skus) async {
    return _ProductDetailsResponse();
  }
}

// Stub pour ProductDetailsResponse
class _ProductDetailsResponse {
  final Set<String> notFoundIDs = {};
  final List<dynamic> productDetails = [];
}

// Stub pour PurchaseDetails
class PurchaseDetails {
  final String? productID;
  final dynamic verificationData;
  final dynamic status;

  PurchaseDetails({this.productID, this.verificationData, this.status});
}

// Stub pour PurchaseStatus
enum PurchaseStatus {
  purchased,
  restored,
  error,
}