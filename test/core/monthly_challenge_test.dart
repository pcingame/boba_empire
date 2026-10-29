import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/monthly_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

int _ms(int y, int m, int d, [int h = 0]) => DateTime.utc(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('Thử thách tháng', () {
    test('chỉ số tháng và giây còn lại (kể cả qua năm)', () {
      expect(monthIndex(_ms(2026, 10, 31, 23)), 2026 * 12 + 9);
      expect(monthIndex(_ms(2026, 11, 1)), 2026 * 12 + 10);
      expect(monthlySecondsLeft(_ms(2026, 12, 31, 23)), 3600);
      expect(monthlySecondsLeft(_ms(2026, 2, 28, 12)), 12 * 3600);
    });

    test('lần đầu chụp mốc nên tiến độ bắt đầu từ 0, rồi tính phần tăng thêm', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 500..buyCount = 70;
      final t0 = _ms(2026, 10, 29);
      expect(rollMonthlyChallenge(s, t0), isTrue);
      expect(rollMonthlyChallenge(s, t0 + 1000), isFalse);
      expect(monthlyProgress(s, MonthlyKind.tap), 0);
      s.tapCount += 3000;
      expect(monthlyProgress(s, MonthlyKind.tap), 3000);
      expect(monthlyDone(s, MonthlyKind.tap), isTrue);
      s.ownedAccessories.addAll(['a', 'b']);
      s.ownedLimited.add('c');
      expect(monthlyProgress(s, MonthlyKind.collect), 3);
    });

    test('nhận từng mục một lần, đủ 3 mới mở rương, rương một lần', () {
      final s = GameState.newGame(nowMillis: 0);
      rollMonthlyChallenge(s, _ms(2026, 10, 1));
      expect(claimMonthly(s, MonthlyKind.tap), 0);
      s.tapCount += 3000;
      s.buyCount += 1000;
      s.ownedAccessories.addAll(['a', 'b', 'c', 'd']);
      expect(monthlyClaimableCount(s), 3);
      final g0 = s.gems;
      for (final k in MonthlyKind.values) {
        expect(claimMonthly(s, k), monthlyQuestRewardGems);
        expect(claimMonthly(s, k), 0);
      }
      expect(s.gems, g0 + 3 * monthlyQuestRewardGems);
      expect(monthlyClaimableCount(s), 1);
      expect(claimMonthlyChest(s), monthlyChestGems);
      expect(claimMonthlyChest(s), 0);
      expect(monthlyClaimableCount(s), 0);
    });

    test('sang tháng mới: chụp lại mốc, xoá cờ nhận và rương', () {
      final s = GameState.newGame(nowMillis: 0);
      rollMonthlyChallenge(s, _ms(2026, 10, 1));
      s.tapCount += 3000;
      claimMonthly(s, MonthlyKind.tap);
      s.monthlyChestClaimed = true;
      expect(rollMonthlyChallenge(s, _ms(2026, 11, 1)), isTrue);
      expect(s.monthlyClaimed, isEmpty);
      expect(s.monthlyChestClaimed, isFalse);
      expect(monthlyProgress(s, MonthlyKind.tap), 0);
    });

    test('lưu/đọc giữ nguyên; save cũ thiếu trường vẫn nạp được', () {
      final s = GameState.newGame(nowMillis: 0);
      rollMonthlyChallenge(s, _ms(2026, 10, 1));
      s.monthlyClaimed.add('tap');
      final back = GameState.fromJson(s.toJson());
      expect(back.monthlyMonth, s.monthlyMonth);
      expect(back.monthlyBase, s.monthlyBase);
      expect(back.monthlyClaimed, ['tap']);
      final old = s.toJson()
        ..remove('monthlyMonth')
        ..remove('monthlyBase')
        ..remove('monthlyClaimed')
        ..remove('monthlyChestClaimed');
      final o = GameState.fromJson(old);
      expect(o.monthlyMonth, 0);
      expect(o.monthlyBase, isEmpty);
    });
  });
}
