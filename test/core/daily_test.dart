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
}
