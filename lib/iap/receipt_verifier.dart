/// Xác thực biên nhận mua hàng phía server (chống giả mạo IAP client-only).
///
/// Tầng này KHÔNG phụ thuộc plugin in_app_purchase để dễ test: [RealIapService]
/// dựng [PurchaseReceipt] thuần Dart từ PurchaseDetails rồi gọi verifier.
/// Mặc định [NoopReceiptVerifier] (coi mọi biên nhận là hợp lệ) giữ nguyên hành
/// vi cũ khi CHƯA cấu hình backend — bật xác thực thật bằng cách truyền
/// [HttpReceiptVerifier] ở `main()` (xem iap_config.dart + server/).
library;

/// Dữ liệu cần gửi lên server để xác thực một giao dịch.
class PurchaseReceipt {
  const PurchaseReceipt({
    required this.productId,
    required this.source,
    required this.verificationData,
  });

  /// Product id của store (khớp [IapProduct.id]).
  final String productId;

  /// Nguồn store: 'google_play' hoặc 'app_store'.
  final String source;

  /// Token/receipt store cấp để server đối chiếu (serverVerificationData).
  final String verificationData;
}

/// Kết quả xác thực. [unavailable] = không gọi được server (mạng/lỗi) — khác với
/// [invalid] để tầng gọi áp chính sách fail-open (chỉ chặn khi thực sự [invalid]).
enum VerifyResult { valid, invalid, unavailable }

abstract interface class ReceiptVerifier {
  /// Trả về kết quả xác thực cho [receipt]. KHÔNG được ném lỗi — lỗi mạng phải
  /// quy về [VerifyResult.unavailable].
  Future<VerifyResult> verify(PurchaseReceipt receipt);
}

/// Bỏ qua xác thực (coi mọi biên nhận hợp lệ) — mặc định an toàn cho test/desktop
/// và giữ hành vi client-only khi chưa dựng backend.
class NoopReceiptVerifier implements ReceiptVerifier {
  const NoopReceiptVerifier();

  @override
  Future<VerifyResult> verify(PurchaseReceipt receipt) async =>
      VerifyResult.valid;
}
