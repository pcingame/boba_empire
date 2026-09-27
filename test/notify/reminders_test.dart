// Mốc giờ của thông báo nhắc quay lại. Phần gọi plugin không test được (cần
// thiết bị thật), nhưng phép tính thời gian thì test được và là chỗ dễ sai:
// game đổi ngày theo UTC còn người chơi sống theo giờ máy.
import 'package:boba_empire/notify/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kho offline đầy = bây giờ + trần offline thật của người chơi', () {
    final now = DateTime.utc(2026, 9, 28, 10);
    expect(
      offlineFullAt(now, 8 * 60 * 60),
      DateTime.utc(2026, 9, 28, 18),
    );
    // Cấp "Kho lạnh" cao hơn → nhắc muộn hơn, không phải hằng số 8 giờ.
    expect(
      offlineFullAt(now, 12 * 60 * 60),
      DateTime.utc(2026, 9, 28, 22),
    );
  });

  test('nhắc ngày mới luôn ở tương lai và không rơi vào đêm giờ máy', () {
    for (var h = 0; h < 24; h++) {
      final now = DateTime.utc(2026, 9, 28, h, 30);
      final at = dailyResetAt(now);
      expect(at.isAfter(now), isTrue, reason: 'giờ UTC $h');

      final local = at.toLocal().hour;
      expect(
        local >= 8 && local < 22,
        isTrue,
        reason: 'giờ UTC $h → giờ máy $local (rơi vào đêm)',
      );
      // Không dời quá xa: luôn trong vòng 2 ngày.
      expect(at.difference(now).inHours, lessThan(48), reason: 'giờ UTC $h');
    }
  });

  test('mốc ngày mới là nửa đêm UTC khi giờ máy chấp nhận được', () {
    final now = DateTime.utc(2026, 9, 28, 5);
    final midnight = DateTime.utc(2026, 9, 29);
    final at = dailyResetAt(now);
    // Múi giờ chạy test quyết định: hoặc đúng nửa đêm UTC, hoặc đã dời sang
    // 10 giờ sáng giờ máy — cả hai đều hợp lệ, không được rơi ra ngoài.
    expect(at == midnight || at.toLocal().hour == 10, isTrue);
  });
}
