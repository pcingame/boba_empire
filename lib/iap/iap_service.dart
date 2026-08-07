/// Trừu tượng hoá mua hàng (IAP).
///
/// Tầng UI chỉ phụ thuộc interface này; mặc định là [StubIapService] (không
/// bán gì, an toàn ở test/desktop). `main()` override bằng RealIapService trên
/// Android/iOS — giống cách [adServiceProvider] đổi sang bản thật.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'iap_products.dart';

abstract interface class IapService {
  /// Giá hiển thị theo locale cho từng sản phẩm (rỗng nếu store chưa sẵn).
  Future<Map<IapProduct, String>> loadPrices();

  /// Các sản phẩm đã mua/khôi phục THÀNH CÔNG — nghe để trao thưởng.
  Stream<IapProduct> get purchases;

  /// Bắt đầu luồng mua một sản phẩm (kết quả về qua [purchases]).
  void buy(IapProduct product);

  /// Khôi phục sản phẩm non-consumable đã mua (Gỡ QC / Gói khởi động).
  Future<void> restore();
}

/// Không bán gì — mặc định an toàn ở test và nền tảng không hỗ trợ IAP.
class StubIapService implements IapService {
  const StubIapService();

  @override
  Future<Map<IapProduct, String>> loadPrices() async => const {};

  @override
  Stream<IapProduct> get purchases => const Stream.empty();

  @override
  void buy(IapProduct product) {}

  @override
  Future<void> restore() async {}
}

/// Mặc định stub; override trong `main()` bằng RealIapService.
final iapServiceProvider =
    Provider<IapService>((ref) => const StubIapService());
