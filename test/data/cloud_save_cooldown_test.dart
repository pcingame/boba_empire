import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resendCooldownRemaining', () {
    test('chưa gửi lần nào -> gửi được ngay', () {
      expect(resendCooldownRemaining(0, 123456), 0);
    });

    test('vừa gửi xong -> phải chờ đủ cooldown', () {
      expect(resendCooldownRemaining(1000, 1000), resendCodeCooldownSeconds);
    });

    test('đếm ngược theo thời gian trôi', () {
      const start = 1000;
      expect(resendCooldownRemaining(start, start + 10 * 1000),
          resendCodeCooldownSeconds - 10);
      expect(resendCooldownRemaining(start, start + 59 * 1000), 1);
    });

    test('hết cooldown -> 0, và không âm khi trôi quá lâu', () {
      const start = 1000;
      expect(
          resendCooldownRemaining(
              start, start + resendCodeCooldownSeconds * 1000),
          0);
      expect(resendCooldownRemaining(start, start + 9999 * 1000), 0);
    });

    test('đồng hồ máy bị lùi -> 0, không khoá kẹt nút', () {
      expect(resendCooldownRemaining(10 * 1000, 1000), 0);
    });
  });
}
