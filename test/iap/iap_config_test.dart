import 'package:boba_empire/iap/iap_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Lỗ hổng cũ: mặc định rỗng → bản Android build không có --dart-define chạy KHÔNG xác thực biên nhận.
  test('mặc định trỏ server xác thực (build quên tham số vẫn được xác thực)', () {
    expect(IapConfig.receiptVerifyEndpoint, startsWith('https://'));
    expect(IapConfig.receiptVerifyEndpoint, endsWith('/verify'));
  });
}
