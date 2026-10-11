import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _day = 24 * 60 * 60 * 1000;

void main() {
  group('daily reward', () {
    test('lần đầu có thưởng, streak = 1', () {
      final s = GameState.newGame(nowMillis: 0);
      expect(dailyAvailable(s, 5 * _day), isTrue);
      final g = claimDaily(s, 5 * _day);
      expect(s.dailyStreak, 1);
      expect(g, dailyRewardGems[0]);
      expect(s.gems, dailyRewardGems[0].toDouble());
      expect(s.lastDailyDay, 5);
    });

    test('cùng ngày không nhận lại', () {
      final s = GameState.newGame(nowMillis: 0);
      claimDaily(s, 5 * _day);
      expect(dailyAvailable(s, 5 * _day + 3600 * 1000), isFalse);
      expect(claimDaily(s, 5 * _day + 3600 * 1000), 0);
    });

    test('ngày liên tiếp tăng streak', () {
      final s = GameState.newGame(nowMillis: 0);
      claimDaily(s, 5 * _day);
      final g = claimDaily(s, 6 * _day);
      expect(s.dailyStreak, 2);
      expect(g, dailyRewardGems[1]);
    });

    test('bỏ lỡ ≥1 ngày reset streak về 1', () {
      final s = GameState.newGame(nowMillis: 0);
      claimDaily(s, 5 * _day);
      claimDaily(s, 6 * _day); // streak 2
      final g = claimDaily(s, 9 * _day); // nhảy 3 ngày
      expect(s.dailyStreak, 1);
      expect(g, dailyRewardGems[0]);
    });

    test('streak quay vòng theo chu kỳ 7', () {
      expect(dailyGemsForStreak(1), dailyRewardGems[0]);
      expect(dailyGemsForStreak(7), dailyRewardGems[6]);
      expect(dailyGemsForStreak(8), dailyRewardGems[0]);
    });
  });

  group('cứu streak', () {
    GameState streak2() {
      final s = GameState.newGame(nowMillis: 0);
      claimDaily(s, 5 * _day);
      claimDaily(s, 6 * _day); // streak 2
      return s;
    }

    test('chỉ cứu được khi bỏ lỡ đúng 1 ngày và streak ≥ 2', () {
      final s = streak2();
      expect(streakRestorable(s, 7 * _day), isFalse); // liên tiếp, không cần cứu
      expect(streakRestorable(s, 8 * _day), isTrue);
      expect(streakRestorable(s, 9 * _day), isFalse); // lỡ 2 ngày: muộn
      final one = GameState.newGame(nowMillis: 0);
      claimDaily(one, 5 * _day);
      expect(streakRestorable(one, 7 * _day), isFalse); // streak 1 không đáng cứu
    });

    test('restore giữ chuỗi +1; không restore thì reset', () {
      final a = streak2();
      claimDaily(a, 8 * _day, restore: true);
      expect(a.dailyStreak, 3);
      final b = streak2();
      claimDaily(b, 8 * _day);
      expect(b.dailyStreak, 1);
    });

    test('restore bị bỏ qua khi không đủ điều kiện', () {
      final s = streak2();
      claimDaily(s, 10 * _day, restore: true);
      expect(s.dailyStreak, 1);
    });
  });

  group('thưởng mốc chuỗi + VIP', () {
    GameState streakAt(int n) {
      final s = GameState.newGame(nowMillis: 0)
        ..dailyStreak = n - 1
        ..lastDailyDay = 4;
      return s;
    }

    test('chạm mốc chuỗi nhận thêm đúng thưởng mốc, ngày thường thì không', () {
      for (final e in dailyStreakMilestoneGems.entries) {
        final s = streakAt(e.key);
        expect(claimDaily(s, 5 * _day), dailyGemsForStreak(e.key) + e.value,
            reason: 'chuỗi ${e.key}');
      }
      final s = streakAt(8);
      expect(claimDaily(s, 5 * _day), dailyGemsForStreak(8));
    });

    test('VIP cộng % 💎 ngày (làm tròn xuống), không cộng vào thưởng mốc', () {
      final s = streakAt(7);
      final base = dailyGemsForStreak(7); // 60
      expect(claimDaily(s, 5 * _day, vipLevel: 10),
          base + base * 50 ~/ 100 + dailyStreakMilestoneGems[7]!);
      expect(s.gems, base + 30 + 50);
      expect(dailyVipBonusPercent(0), 0);
      final t = streakAt(1);
      expect(claimDaily(t, 5 * _day, vipLevel: 3), 10 + 1); // 10 + 15% = 11
    });

    test('mốc chỉ nhận một lần: cùng ngày nhận lại = 0', () {
      final s = streakAt(7);
      claimDaily(s, 5 * _day);
      final gems = s.gems;
      expect(claimDaily(s, 5 * _day), 0);
      expect(s.gems, gems);
    });
  });
}
