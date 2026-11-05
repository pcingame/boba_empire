/// Cấu hình nạp tiền bằng chuyển khoản (bản Android tải APK, không có Google Play).
///
/// Thông tin tài khoản nhận tiền truyền lúc build, KHÔNG commit:
///   --dart-define=BANK_ID=MB --dart-define=BANK_ACCOUNT=0123456789 --dart-define=BANK_NAME="NGUYEN VAN A"
/// [BANK_ID] là mã/BIN ngân hàng theo VietQR (https://api.vietqr.io/v2/banks, cột `code` hoặc `bin`).
/// Thiếu một trong ba thì [BankConfig.configured] = false và cửa hàng ẩn nút mua.
library;

class BankConfig {
  const BankConfig._();

  static const String bankId = String.fromEnvironment('BANK_ID');
  static const String account = String.fromEnvironment('BANK_ACCOUNT');
  static const String accountName = String.fromEnvironment('BANK_NAME');

  static bool get configured =>
      bankId.isNotEmpty && account.isNotEmpty && accountName.isNotEmpty;

  /// Ảnh QR VietQR đã điền sẵn số tiền + nội dung chuyển khoản.
  static String qrUrl(String code, int amount) =>
      Uri.https('img.vietqr.io', '/image/$bankId-$account-compact2.png', {
        'amount': '$amount',
        'addInfo': code,
        'accountName': accountName,
      }).toString();
}

/// Giá hiển thị (VND) theo product id. Nguồn sự thật là bảng `bank_prices` trong
/// supabase/bank_orders_schema.sql — đổi ở đâu phải đổi cả hai (có test so khớp). Giá là ước lượng.
const Map<String, int> bankPriceVnd = {
  'boba_gems_small': 20000,
  'boba_gems_medium': 100000,
  'boba_gems_large': 200000,
  'boba_gems_huge': 300000,
  'boba_gems_mega': 400000,
  'boba_remove_ads': 60000,
  'boba_double_income': 100000,
  'boba_piggy': 40000,
  'boba_vip30': 100000,
  'boba_starter_pack': 40000,
  'boba_cold_storage': 60000,
  'boba_combo_noads_x2': 120000,
};

/// 100000 → "100.000đ".
String formatVnd(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
