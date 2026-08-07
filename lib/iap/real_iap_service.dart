/// IapService thật dùng in_app_purchase. Chỉ main.dart import file này để giữ
/// phụ thuộc plugin ở rìa — tầng UI/test chỉ biết [IapService].
///
/// ⚠️ MVP client-only: trao thưởng NGAY khi store báo "purchased" mà CHƯA xác
/// thực biên nhận phía server. Trước khi phát hành nên thêm bước verify receipt
/// (Play/App Store) ở backend rồi mới trao — xem SETUP.md.
library;

import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'iap_products.dart';
import 'iap_service.dart';

class RealIapService implements IapService {
  RealIapService() {
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<IapProduct> _delivered =
      StreamController<IapProduct>.broadcast();
  final Map<IapProduct, ProductDetails> _details = {};
  late final StreamSubscription<List<PurchaseDetails>> _sub;

  @override
  Stream<IapProduct> get purchases => _delivered.stream;

  @override
  Future<Map<IapProduct, String>> loadPrices() async {
    if (!await _iap.isAvailable()) return const {};
    final response = await _iap.queryProductDetails(
      IapProduct.values.map((p) => p.id).toSet(),
    );
    final prices = <IapProduct, String>{};
    for (final d in response.productDetails) {
      final product = IapProduct.byId(d.id);
      if (product != null) {
        _details[product] = d;
        prices[product] = d.price;
      }
    }
    return prices;
  }

  @override
  void buy(IapProduct product) {
    final details = _details[product];
    if (details == null) return; // chưa loadPrices hoặc store không có sp này.
    final param = PurchaseParam(productDetails: details);
    if (product.kind == IapKind.consumable) {
      _iap.buyConsumable(purchaseParam: param);
    } else {
      _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      if (pd.status == PurchaseStatus.purchased ||
          pd.status == PurchaseStatus.restored) {
        final product = IapProduct.byId(pd.productID);
        if (product != null) _delivered.add(product);
      }
      // Luôn hoàn tất giao dịch đang chờ, nếu không store sẽ gửi lại mãi.
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }

  void dispose() {
    _sub.cancel();
    _delivered.close();
  }
}
