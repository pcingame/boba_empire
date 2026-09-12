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

  /// Phát ra khi 1 lượt mua KẾT THÚC mà KHÔNG thành công (lỗi hoặc người
  /// chơi tự huỷ ở màn thanh toán) — TÁCH RIÊNG khỏi [purchases] (chỉ báo
  /// giao hàng thành công) vì mục đích khác hẳn: cái này chỉ để UI tắt
  /// trạng thái "đang xử lý" cục bộ (VD gem_shop.dart), không phải để trao
  /// thưởng. Từ lúc gọi [buy] tới lúc CÓ 1 TRONG 2 stream này phát ra là
  /// khoảng chờ mở màn thanh toán của store — trước đây UI im lặng suốt
  /// khoảng này, trông như treo máy.
  Stream<IapProduct> get purchaseFailed;

  /// Bắt đầu luồng mua một sản phẩm (kết quả về qua [purchases]/[purchaseFailed]).
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
  Stream<IapProduct> get purchaseFailed => const Stream.empty();

  @override
  void buy(IapProduct product) {}

  @override
  Future<void> restore() async {}
}

/// Mặc định stub; override trong `main()` bằng RealIapService.
final iapServiceProvider =
    Provider<IapService>((ref) => const StubIapService());
