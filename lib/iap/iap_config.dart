/// Cấu hình IAP phía client.
///
/// [receiptVerifyEndpoint] rỗng = TẮT xác thực server (client-only, hành vi cũ).
/// Điền URL backend (xem server/) để bật [HttpReceiptVerifier] ở `main()`.
library;

class IapConfig {
  const IapConfig._();

  /// Endpoint POST /verify của backend xác thực biên nhận. Để rỗng khi chưa
  /// deploy server — app sẽ dùng [NoopReceiptVerifier].
  static const String receiptVerifyEndpoint =
      String.fromEnvironment('IAP_VERIFY_ENDPOINT');
}
