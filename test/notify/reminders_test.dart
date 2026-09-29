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

  // --- D3 / D7: lấp khoảng trống "rời app > 1 ngày thì không bao giờ nhận
  // thêm thông báo nào nữa" — lịch cũ chỉ có 2 mốc trong vòng ~24-30h. ---

  test('D3/D7 đúng cách nhau đúng số ngày và luôn ở tương lai', () {
    for (var h = 0; h < 24; h++) {
      final now = DateTime.utc(2026, 9, 28, h, 30);
      final d3 = d3ReminderAt(now);
      final d7 = d7ReminderAt(now);

      expect(d3.isAfter(now), isTrue, reason: 'D3, giờ UTC $h');
      expect(d7.isAfter(d3), isTrue, reason: 'D7 phải sau D3, giờ UTC $h');

      // Cho phép dời tới 10h sáng (né đêm) nhưng không được trôi quá 1 ngày
      // so với đúng 3/7 ngày sau.
      expect(d3.difference(now).inHours, inInclusiveRange(72 - 2, 72 + 26),
          reason: 'D3, giờ UTC $h');
      expect(d7.difference(now).inHours, inInclusiveRange(168 - 2, 168 + 26),
          reason: 'D7, giờ UTC $h');
    }
  });

  test('D3/D7 không rơi vào đêm giờ máy (22:00-08:00)', () {
    for (var h = 0; h < 24; h++) {
      final now = DateTime.utc(2026, 9, 28, h, 30);
      for (final at in [d3ReminderAt(now), d7ReminderAt(now)]) {
        final local = at.toLocal().hour;
        expect(local >= 8 && local < 22, isTrue,
            reason: 'giờ UTC $h → giờ máy $local (rơi vào đêm)');
      }
    }
  });

  test('D7 xa hơn D3 đúng 4 ngày khi không phải né đêm', () {
    // 10h sáng UTC: cả hai mốc (13h/17h sáng UTC tương ứng) đều ban ngày ở
    // hầu hết múi giờ thông thường nên không bị _avoidNight dời — phép trừ
    // phải khớp CHÍNH XÁC 4 ngày, không chỉ "trong khoảng".
    final now = DateTime.utc(2026, 9, 28, 10);
    final d3 = d3ReminderAt(now);
    final d7 = d7ReminderAt(now);
    if (d3.toLocal().hour == now.toLocal().hour &&
        d7.toLocal().hour == now.toLocal().hour) {
      expect(d7.difference(d3), const Duration(days: 4));
    }
  });
}
