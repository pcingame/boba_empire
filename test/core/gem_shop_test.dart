import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const _g = GeneratorConfig(
  id: 'x',
  name: 'X',
  baseCost: 100,
  costGrowth: 1.15,
  incomePerLevelPerSecond: 10,
);

void main() {
  group('công thức gems', () {
    test('gemBoostCost tăng lũy thừa 2x', () {
      expect(gemBoostCost(0), Balance.gemBoostBaseCost); // 5
      expect(gemBoostCost(1), 10);
      expect(gemBoostCost(2), 20);
    });

    test('offlineCapCost tăng lũy thừa 2x', () {
      expect(offlineCapCost(0), Balance.offlineCapBaseCost); // 10
      expect(offlineCapCost(1), 20);
    });

    test('permanentMultiplier = 1 + level*10%', () {
      expect(permanentMultiplier(0), 1.0);
      expect(permanentMultiplier(3), closeTo(1.3, 1e-9));
    });

    test('offlineCapSeconds cộng thêm giờ theo cấp', () {
      expect(offlineCapSeconds(0), Balance.maxOfflineSeconds);
      expect(
        offlineCapSeconds(2),
        Balance.maxOfflineSeconds + 2 * Balance.offlineCapPerLevelSeconds,
      );
    });
  });

  group('mua bằng gems', () {
    test('buyGemBoost: đủ gems thì trừ đúng giá + lên cấp', () {
      final s = GameState.newGame(nowMillis: 0)..gems = 5;
      expect(buyGemBoost(s), isTrue);
      expect(s.gems, 0);
      expect(s.gemBoostLevel, 1);
      // Cấp 2 giá 10, chỉ còn 0 → thất bại.
      expect(buyGemBoost(s), isFalse);
      expect(s.gemBoostLevel, 1);
    });

    test('buyOfflineCap: thiếu gems thì không đổi', () {
      final s = GameState.newGame(nowMillis: 0)..gems = 9; // giá 10
      expect(buyOfflineCap(s), isFalse);
      expect(s.offlineCapLevel, 0);
      expect(s.gems, 9);
    });
  });

  test('gemBoostLevel làm tăng thu nhập thực tế', () {
    final s = GameState.newGame(nowMillis: 0)
      ..levels['x'] = 1 // base 10/s
      ..gemBoostLevel = 5; // +50%
    expect(
      effectiveIncomePerSecond(s, const [_g], bonusPerStar: 0.02),
      closeTo(15, 1e-9),
    );
  });
}
