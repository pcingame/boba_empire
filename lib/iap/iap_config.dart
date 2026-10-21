/// Cấu hình IAP phía client.
///
/// [receiptVerifyEndpoint] rỗng = TẮT xác thực server (client-only, hành vi cũ).
/// Mặc định trỏ server production để MỌI bản build (kể cả Android, hay lúc quên tham số) đều qua xác thực;
/// muốn tắt hẳn khi dev: `--dart-define=IAP_VERIFY_ENDPOINT=` (rỗng) hoặc trỏ server local.
library;

class IapConfig {
  const IapConfig._();

  /// Endpoint POST /verify của backend xác thực biên nhận. Rỗng → app dùng [NoopReceiptVerifier].
  ///
  /// Trước đây mặc định rỗng và chỉ lệnh build iOS truyền URL → bản Android phát hành chạy client-only (không xác
  /// thực). Server trả 500 (không phải `valid:false`) khi thiếu credential của store → client fail-open, nên mặc
  /// định này an toàn kể cả khi server chưa có credential Google Play; có credential là Android được bảo vệ ngay.
  static const String receiptVerifyEndpoint = String.fromEnvironment(
    'IAP_VERIFY_ENDPOINT',
    defaultValue:
        'https://boba-receipt-server-411559711815.asia-southeast1.run.app/verify',
  );
}
