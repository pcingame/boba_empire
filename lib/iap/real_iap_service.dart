/// IapService thật dùng in_app_purchase. Chỉ main.dart import file này để giữ
/// phụ thuộc plugin ở rìa — tầng UI/test chỉ biết [IapService].
///
/// Xác thực biên nhận phía server (nếu truyền [ReceiptVerifier] khác Noop) chạy
/// TRƯỚC khi trao thưởng — xem receipt_verifier.dart + server/. Mặc định
/// [NoopReceiptVerifier] giữ hành vi client-only cũ.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:in_app_purchase/in_app_purchase.dart';

import 'iap_products.dart';
import 'iap_service.dart';
import 'receipt_verifier.dart';

class RealIapService implements IapService {
  /// [iap] chỉ để test chèn bản giả; mặc định là plugin thật.
  RealIapService({
    ReceiptVerifier verifier = const NoopReceiptVerifier(),
    InAppPurchase? iap,
  })  : _verifier = verifier,
        _iap = iap ?? InAppPurchase.instance {
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );
  }

  final InAppPurchase _iap;
  final ReceiptVerifier _verifier;
  final StreamController<IapProduct> _delivered =
      StreamController<IapProduct>.broadcast();
  final StreamController<IapProduct> _failed =
      StreamController<IapProduct>.broadcast();
  final Map<IapProduct, ProductDetails> _details = {};
  late final StreamSubscription<List<PurchaseDetails>> _sub;

  @override
  Stream<IapProduct> get purchases => _delivered.stream;

  @override
  Stream<IapProduct> get purchaseFailed => _failed.stream;

  @override
  Future<Map<IapProduct, String>> loadPrices() async {
    try {
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
    } catch (e) {
      // Store lỗi (mạng/StoreKit): coi như chưa có giá, không văng lỗi chưa bắt.
      developer.log('loadPrices: $e', name: 'Iap');
      return const {};
    }
  }

  @override
  void buy(IapProduct product) {
    final details = _details[product];
    if (details == null) return; // chưa loadPrices hoặc store không có sp này.
    unawaited(_startPurchase(product, PurchaseParam(productDetails: details)));
  }

  /// Plugin trả Future: StoreKit 2 NÉM PlatformException khi mua lỗi (không phải qua
  /// purchaseStream). Không bắt thì thành lỗi bất đồng bộ chưa bắt → Crashlytics ghi
  /// FATAL và nút mua kẹt "đang xử lý". Mọi lỗi → báo [purchaseFailed] cho UI.
  Future<void> _startPurchase(IapProduct product, PurchaseParam param) async {
    try {
      final started = product.kind == IapKind.consumable
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) _failed.add(product);
    } catch (e) {
      developer.log('buy ${product.id}: $e', name: 'Iap');
      if (!_failed.isClosed) _failed.add(product);
    }
  }

  @override
  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      // Khôi phục lỗi (mạng/chưa đăng nhập store) không được làm văng app.
      developer.log('restore: $e', name: 'Iap');
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      // Một giao dịch lỗi (xác thực/hoàn tất ném ngoại lệ) không được làm hỏng cả luồng:
      // lỗi bất đồng bộ trong listener chưa bắt → Crashlytics FATAL.
      try {
        final product = IapProduct.byId(pd.productID);
        if (pd.status == PurchaseStatus.purchased ||
            pd.status == PurchaseStatus.restored) {
          if (product != null && await _verified(pd)) {
            _delivered.add(product);
          }
        } else if (pd.status == PurchaseStatus.error ||
            pd.status == PurchaseStatus.canceled) {
          // Lỗi hoặc người chơi tự huỷ ở màn thanh toán — báo cho UI tắt
          // trạng thái "đang xử lý" (xem [purchaseFailed]), không trao thưởng.
          if (product != null) _failed.add(product);
        }
      } catch (e) {
        developer.log('purchase ${pd.productID}: $e', name: 'Iap');
      }
      // Luôn hoàn tất giao dịch đang chờ, nếu không store sẽ gửi lại mãi.
      try {
        if (pd.pendingCompletePurchase) {
          await _iap.completePurchase(pd);
        }
      } catch (e) {
        developer.log('completePurchase ${pd.productID}: $e', name: 'Iap');
      }
    }
  }

  /// FAIL-OPEN: chỉ chặn khi server phán quyết dứt khoát biên nhận không hợp lệ;
  /// lỗi mạng ([VerifyResult.unavailable]) vẫn cho trao thưởng.
  Future<bool> _verified(PurchaseDetails pd) async {
    final product = IapProduct.byId(pd.productID);
    final result = await _verifier.verify(PurchaseReceipt(
      productId: pd.productID,
      source: pd.verificationData.source,
      verificationData: pd.verificationData.serverVerificationData,
      isConsumable: product?.kind == IapKind.consumable,
    ));
    return result != VerifyResult.invalid;
  }

  void dispose() {
    _sub.cancel();
    _delivered.close();
    _failed.close();
  }
}
