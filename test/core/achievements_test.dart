import 'package:boba_empire/core/achievements.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('achievements', () {
    test('đạt mốc lifetimeEarnings → trao & ghi claimed, không trùng', () {
      final s = GameState.newGame(nowMillis: 0)..lifetimeEarnings = 1500;
      final n = grantNewAchievements(s);
      expect(n.map((a) => a.id), contains('earn_1k'));
      expect(s.achievementsClaimed, contains('earn_1k'));

      final gemsAfter = s.gems;
      final n2 = grantNewAchievements(s); // gọi lại
      expect(n2.where((a) => a.id == 'earn_1k'), isEmpty);
      expect(s.gems, gemsAfter);
    });

    test('cộng đúng gems thưởng', () {
      final s = GameState.newGame(nowMillis: 0)..lifetimeEarnings = 1500;
      final before = s.gems;
      grantNewAchievements(s);
      final earn1k = achievements.firstWhere((a) => a.id == 'earn_1k');
      expect(s.gems, before + earn1k.rewardGems);
    });

    test('tổng cấp nâng cấp gộp mọi nguồn', () {
      final s = GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 30
        ..levels['tran_chau'] = 25; // 55 ≥ 50
      expect(grantNewAchievements(s).map((a) => a.id), contains('levels_50'));
    });

    test('stage & prestige mở đúng thành tựu', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 2
        ..prestigeStars = 1;
      final ids = grantNewAchievements(s).map((a) => a.id);
      expect(ids, containsAll(<String>['stage_2', 'prestige_1']));
    });

    test('chưa đạt ngưỡng thì không trao', () {
      final s = GameState.newGame(nowMillis: 0)..lifetimeEarnings = 500;
      expect(grantNewAchievements(s), isEmpty);
    });
  });
}
