import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recap.dart';
import 'package:boba_empire/core/weekly_quests.dart' show weekIndex;
import 'package:flutter_test/flutter_test.dart';

int _ms(int y, int m, int d) => DateTime.utc(y, m, d).millisecondsSinceEpoch;

void main() {
  group('Tổng kết tuần', () {
    test('lần đầu (chưa có mốc) chỉ chụp mốc, không có gì để tổng kết', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 500;
      expect(rollRecap(s, _ms(2026, 10, 28)), isTrue);
      expect(s.recapPending, isFalse);
      expect(s.recapBase['taps'], 500);
      expect(rollRecap(s, _ms(2026, 10, 29)), isFalse, reason: 'cùng tuần');
    });

    test('sang tuần mới: chốt phần tăng thêm của tuần trước, chụp mốc mới', () {
      final s = GameState.newGame(nowMillis: 0);
      rollRecap(s, _ms(2026, 10, 28)); // thứ Tư
      s
        ..tapCount += 120
        ..buyCount += 7
        ..lifetimeEarnings += 5000
        ..ownedAccessories.add('a');
      expect(rollRecap(s, _ms(2026, 11, 2)), isTrue); // thứ Hai tuần sau
      expect(s.recapPending, isTrue);
      expect(s.recapData, {'earned': 5000, 'taps': 120, 'buys': 7, 'items': 1, 'achievements': 0});
      expect(s.recapWeek, weekIndex(_ms(2026, 11, 2)));
      expect(s.recapBase['taps'], s.tapCount);
    });

    test('tuần không làm gì: không bật popup; bộ đếm không bao giờ cho số âm', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 10;
      rollRecap(s, _ms(2026, 10, 28));
      expect(rollRecap(s, _ms(2026, 11, 2)), isTrue);
      expect(s.recapPending, isFalse);
      s.tapCount = 0; // bộ đếm lùi bất thường
      rollRecap(s, _ms(2026, 11, 9));
      expect(s.recapData.values.every((v) => v >= 0), isTrue);
    });

    test('lưu/đọc giữ nguyên; save cũ thiếu trường nạp được', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 3;
      rollRecap(s, _ms(2026, 10, 28));
      s.recapPending = true;
      final back = GameState.fromJson(s.toJson());
      expect(back.recapWeek, s.recapWeek);
      expect(back.recapBase, s.recapBase);
      expect(back.recapPending, isTrue);
      final old = s.toJson()
        ..remove('recapWeek')
        ..remove('recapBase')
        ..remove('recapData')
        ..remove('recapPending');
      final o = GameState.fromJson(old);
      expect(o.recapWeek, 0);
      expect(o.recapPending, isFalse);
    });
  });
}
