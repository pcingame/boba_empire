// RealIapService: lỗi do store NÉM RA (StoreKit 2 ném PlatformException từ purchase) không
// được thành lỗi bất đồng bộ chưa bắt (Crashlytics ghi FATAL, crash iOS 2026-10) mà phải
// báo purchaseFailed cho UI; restore/loadPrices/luồng giao dịch cũng không được văng.
import 'dart:async';

import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/iap/real_iap_service.dart';
import 'package:boba_empire/iap/receipt_verifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// InAppPurchase giả: chỉ các phương thức RealIapService dùng; mọi lệnh có thể ép ném lỗi.
class _FakeIap implements InAppPurchase {
  final purchaseController = StreamController<List<PurchaseDetails>>.broadcast();
  Object? buyError;
  Object? restoreError;
  Object? queryError;
  Object? completeError;
  bool buyResult = true;
  bool available = true;
  final calls = <String>[];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchaseController.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    if (queryError != null) throw queryError!;
    return ProductDetailsResponse(
      productDetails: [
        for (final id in ids)
          ProductDetails(
              id: id, title: id, description: '', price: '1', rawPrice: 1, currencyCode: 'USD'),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    calls.add('buyNonConsumable:${purchaseParam.productDetails.id}');
    if (buyError != null) throw buyError!;
    return buyResult;
  }

  @override
  Future<bool> buyConsumable({required PurchaseParam purchaseParam, bool autoConsume = true}) async {
    calls.add('buyConsumable:${purchaseParam.productDetails.id}');
    if (buyError != null) throw buyError!;
    return buyResult;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    calls.add('restore');
    if (restoreError != null) throw restoreError!;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    calls.add('complete:${purchase.productID}');
    if (completeError != null) throw completeError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Verifier implements ReceiptVerifier {
  _Verifier(this.result);
  final Object result; // VerifyResult hoặc ngoại lệ để ném
  @override
  Future<VerifyResult> verify(PurchaseReceipt receipt) async {
    if (result is VerifyResult) return result as VerifyResult;
    throw result;
  }
}

PurchaseDetails _purchase(IapProduct p, PurchaseStatus s, {bool pending = true}) {
  final d = PurchaseDetails(
    productID: p.id,
    verificationData: PurchaseVerificationData(
        localVerificationData: 'l', serverVerificationData: 's', source: 'app_store'),
    transactionDate: '0',
    status: s,
  )..pendingCompletePurchase = pending;
  return d;
}

Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _FakeIap iap;
  late RealIapService svc;
  late List<IapProduct> failed;
  late List<IapProduct> delivered;

  Future<void> setUpSvc({ReceiptVerifier? verifier}) async {
    iap = _FakeIap();
    svc = RealIapService(iap: iap, verifier: verifier ?? const NoopReceiptVerifier());
    failed = [];
    delivered = [];
    svc.purchaseFailed.listen(failed.add);
    svc.purchases.listen(delivered.add);
    await svc.loadPrices(); // nạp ProductDetails để buy() không bỏ qua
  }

  tearDown(() => svc.dispose());

  group('mua', () {
    test('StoreKit ném PlatformException (non-consumable): báo purchaseFailed, KHÔNG lỗi chưa bắt',
        () async {
      await setUpSvc();
      iap.buyError = PlatformException(code: 'storekit2_failed_to_fetch_product', message: 'x');
      await runZonedGuarded(() async {
        svc.buy(IapProduct.removeAds);
        await _tick();
      }, (e, s) => fail('lỗi bất đồng bộ chưa bắt: $e'));
      expect(failed, [IapProduct.removeAds]);
      expect(delivered, isEmpty);
    });

    test('consumable cũng vậy (gói 💎)', () async {
      await setUpSvc();
      iap.buyError = PlatformException(code: 'x');
      await runZonedGuarded(() async {
        svc.buy(IapProduct.gemsSmall);
        await _tick();
      }, (e, s) => fail('lỗi chưa bắt: $e'));
      expect(failed, [IapProduct.gemsSmall]);
      expect(iap.calls.any((c) => c.startsWith('buyConsumable')), isTrue);
    });

    test('lỗi không phải PlatformException (vd StateError) cũng được bắt', () async {
      await setUpSvc();
      iap.buyError = StateError('boom');
      await runZonedGuarded(() async {
        svc.buy(IapProduct.vip30);
        await _tick();
      }, (e, s) => fail('lỗi chưa bắt: $e'));
      expect(failed, [IapProduct.vip30]);
    });

    test('plugin trả false (không khởi động được luồng mua) → purchaseFailed', () async {
      await setUpSvc();
      iap.buyResult = false;
      svc.buy(IapProduct.removeAds);
      await _tick();
      expect(failed, [IapProduct.removeAds]);
    });

    test('mua bình thường: không báo lỗi', () async {
      await setUpSvc();
      svc.buy(IapProduct.removeAds);
      await _tick();
      expect(failed, isEmpty);
      expect(iap.calls, contains('buyNonConsumable:boba_remove_ads'));
    });

    test('chưa loadPrices (không có chi tiết sản phẩm): bỏ qua, không gọi store, không văng', () async {
      iap = _FakeIap();
      svc = RealIapService(iap: iap);
      svc.buy(IapProduct.removeAds);
      await _tick();
      expect(iap.calls, isEmpty);
    });
  });

  group('luồng giao dịch', () {
    test('purchased → trao thưởng + hoàn tất giao dịch', () async {
      await setUpSvc();
      iap.purchaseController.add([_purchase(IapProduct.gemsSmall, PurchaseStatus.purchased)]);
      await _tick();
      expect(delivered, [IapProduct.gemsSmall]);
      expect(iap.calls, contains('complete:boba_gems_small'));
    });

    test('error / canceled → purchaseFailed, không trao thưởng, vẫn hoàn tất', () async {
      await setUpSvc();
      iap.purchaseController.add([
        _purchase(IapProduct.gemsSmall, PurchaseStatus.error),
        _purchase(IapProduct.removeAds, PurchaseStatus.canceled),
      ]);
      await _tick();
      expect(failed, [IapProduct.gemsSmall, IapProduct.removeAds]);
      expect(delivered, isEmpty);
      expect(iap.calls.where((c) => c.startsWith('complete:')).length, 2);
    });

    test('completePurchase ném lỗi: không văng, giao dịch kế tiếp vẫn được xử lý', () async {
      await setUpSvc();
      iap.completeError = PlatformException(code: 'x');
      await runZonedGuarded(() async {
        iap.purchaseController.add([
          _purchase(IapProduct.gemsSmall, PurchaseStatus.purchased),
          _purchase(IapProduct.removeAds, PurchaseStatus.purchased),
        ]);
        await _tick();
      }, (e, s) => fail('lỗi chưa bắt: $e'));
      expect(delivered, [IapProduct.gemsSmall, IapProduct.removeAds]);
    });

    test('xác thực biên nhận ném lỗi: giao dịch đó không trao thưởng, không văng, vẫn hoàn tất',
        () async {
      await setUpSvc(verifier: _Verifier(StateError('mạng chết')));
      await runZonedGuarded(() async {
        iap.purchaseController.add([_purchase(IapProduct.gemsSmall, PurchaseStatus.purchased)]);
        await _tick();
      }, (e, s) => fail('lỗi chưa bắt: $e'));
      expect(delivered, isEmpty);
      expect(iap.calls, contains('complete:boba_gems_small'));
    });

    test('server báo biên nhận KHÔNG hợp lệ: không trao thưởng', () async {
      await setUpSvc(verifier: _Verifier(VerifyResult.invalid));
      iap.purchaseController.add([_purchase(IapProduct.gemsSmall, PurchaseStatus.purchased)]);
      await _tick();
      expect(delivered, isEmpty);
    });
  });

  group('restore / loadPrices', () {
    test('restore ném lỗi: nuốt (không văng ra ngoài)', () async {
      await setUpSvc();
      iap.restoreError = PlatformException(code: 'x');
      await svc.restore(); // không được ném
      expect(iap.calls, contains('restore'));
    });

    test('loadPrices: store lỗi → rỗng; store không khả dụng → rỗng; bình thường → có giá', () async {
      await setUpSvc();
      expect((await svc.loadPrices()).length, IapProduct.values.length);
      iap.queryError = PlatformException(code: 'x');
      expect(await svc.loadPrices(), isEmpty);
      iap.queryError = null;
      iap.available = false;
      expect(await svc.loadPrices(), isEmpty);
    });
  });
}
