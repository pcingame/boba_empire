import 'package:boba_empire/ads/ad_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('không truyền ADMOB_TEST_DEVICES -> không có test device nào', () {
    // Mặc định phải rỗng: người dùng thật KHÔNG được vô tình thành test device.
    expect(AdConfig.testDeviceIds, isEmpty);
  });
}
