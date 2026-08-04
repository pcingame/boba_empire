import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _g = GeneratorConfig(
  id: 'x',
  name: 'X',
  baseCost: 100,
  costGrowth: 1.15,
  incomePerLevelPerSecond: 2,
);

void main() {
  group('nextLevelCost', () {
    test('cấp 0 = giá gốc', () {
      expect(nextLevelCost(_g, 0), closeTo(100, 1e-9));
    });

    test('theo đúng công thức base * growth^level (ví dụ trong GDD)', () {
      expect(nextLevelCost(_g, 1), closeTo(115, 1e-9));
      expect(nextLevelCost(_g, 2), closeTo(132.25, 1e-9));
    });
  });

  group('bulkCost', () {
    test('mua 1 cấp == nextLevelCost', () {
      expect(bulkCost(_g, 0, 1), closeTo(nextLevelCost(_g, 0), 1e-9));
      expect(bulkCost(_g, 3, 1), closeTo(nextLevelCost(_g, 3), 1e-9));
    });

    test('mua n cấp == tổng các cấp lẻ', () {
      final manual =
          nextLevelCost(_g, 0) + nextLevelCost(_g, 1) + nextLevelCost(_g, 2);
      expect(bulkCost(_g, 0, 3), closeTo(manual, 1e-6));
    });

    test('count <= 0 trả về 0', () {
      expect(bulkCost(_g, 0, 0), 0);
    });
  });

  group('income', () {
    test('cộng dồn theo cấp của từng nguồn', () {
      final state = GameState.newGame(nowMillis: 0)..levels['x'] = 5;
      expect(baseIncomePerSecond(state, const [_g]), closeTo(10, 1e-9));
    });

    test('nguồn chưa mua (cấp 0) không sinh thu nhập', () {
      final state = GameState.newGame(nowMillis: 0);
      expect(baseIncomePerSecond(state, const [_g]), 0);
    });

    test('prestige nhân đúng hệ số', () {
      final state = GameState.newGame(nowMillis: 0)
        ..levels['x'] = 1
        ..prestigeStars = 10; // +20% với bonus 0.02
      expect(prestigeMultiplier(10, 0.02), closeTo(1.2, 1e-9));
      expect(
        effectiveIncomePerSecond(state, const [_g], bonusPerStar: 0.02),
        closeTo(2.4, 1e-9),
      );
    });
  });

  group('starsForLifetimeEarnings', () {
    test('0 khi chưa kiếm được gì', () {
      expect(starsForLifetimeEarnings(0, Balance.prestigeK), 0);
    });

    test('floor(k * sqrt(lifetime))', () {
      // k=0.05, lifetime=1_000_000 -> 0.05 * 1000 = 50
      expect(starsForLifetimeEarnings(1000000, 0.05), 50);
    });
  });
}
