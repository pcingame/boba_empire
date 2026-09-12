import 'dart:math';

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

  group('maxAffordableLevels', () {
    test('đúng số cấp mua nổi', () {
      // Từ cấp 0, tiền = giá 3 cấp đầu → mua được đúng 3.
      final money = bulkCost(_g, 0, 3);
      expect(maxAffordableLevels(_g, 0, money, 1.0), 3);
      expect(maxAffordableLevels(_g, 0, money - 0.01, 1.0), 2);
    });

    test('không đủ 1 cấp → 0', () {
      expect(maxAffordableLevels(_g, 0, nextLevelCost(_g, 0) - 1, 1.0), 0);
    });

    test('perk "Mua sỉ" (costMult < 1) cho mua nhiều hơn', () {
      final money = bulkCost(_g, 0, 3);
      expect(maxAffordableLevels(_g, 0, money, 0.5), greaterThan(3));
    });

    test('money không hữu hạn (NaN/Infinity, save hỏng) → 0, không crash', () {
      // log()/.floor() ném lỗi với NaN/Infinity — money phải hợp lệ trước đó,
      // nhưng hàm thuần này vẫn cần tự vệ nếu lỡ nhận input hỏng.
      expect(maxAffordableLevels(_g, 0, double.infinity, 1.0), 0);
      expect(maxAffordableLevels(_g, 0, double.nan, 1.0), 0);
    });

    test('cấp đã ở/vượt trần cứng (Balance.maxGeneratorLevel) → luôn 0, '
        'kể cả tiền cực lớn — không crash', () {
      expect(maxAffordableLevels(_g, Balance.maxGeneratorLevel, 10, 1.0), 0);
      expect(
        maxAffordableLevels(_g, Balance.maxGeneratorLevel, 1e300, 1.0),
        0,
      );
      expect(
        maxAffordableLevels(_g, Balance.maxGeneratorLevel + 500, 1e300, 1.0),
        0,
      );
    });

    test('gần trần cứng + tiền cực lớn → chỉ mua tới ĐÚNG trần, không hơn '
        '(hồi quy: maxAffordableLevels từng tự tính giá thô bỏ qua trần ở '
        'nextLevelCost, và trước khi có trần cứng thì count lớn tuỳ tiện có '
        'thể phá vỡ tính đơn điệu giá của bulkCost)', () {
      final fromLevel = Balance.maxGeneratorLevel - 5;
      final n = maxAffordableLevels(_g, fromLevel, 1e300, 1.0);
      expect(n, 5); // đúng bằng số cấp còn lại tới trần, không vượt
      expect(fromLevel + n, Balance.maxGeneratorLevel);
    });
  });

  group('trần chống tràn số (economyOverflowGuardCap)', () {
    // Gốc rễ bug "Xu âm" cũ: nextLevelCost/bulkCost/generatorMilestoneMultiplier
    // dùng pow() không giới hạn, tràn thành Infinity ở cấp cực cao (đủ đạt
    // được qua chơi dài hạn, không phải chỉ lý thuyết). Test này khoá lại:
    // (a) không đổi gì ở dải cấp người chơi bình thường chạm tới,
    // (b) không bao giờ vượt/bằng Infinity dù cấp cực đoan tới đâu.
    test('cấp bình thường (0..200): không bị ảnh hưởng bởi trần', () {
      for (final level in [0, 1, 25, 50, 100, 200]) {
        expect(nextLevelCost(_g, level), lessThan(Balance.economyOverflowGuardCap));
        expect(generatorMilestoneMultiplier(level),
            pow(Balance.milestoneFactor, level ~/ Balance.milestoneStep).toDouble());
      }
    });

    test('nextLevelCost không bao giờ vượt trần, dù cấp cực cao', () {
      for (final level in [5000, 10000, 100000, 10000000]) {
        final cost = nextLevelCost(_g, level);
        expect(cost.isFinite, isTrue, reason: 'level $level');
        expect(cost, lessThanOrEqualTo(Balance.economyOverflowGuardCap));
      }
    });

    test('bulkCost không bao giờ vượt trần, dù mua số lượng cực lớn', () {
      final cost = bulkCost(_g, 100000, 1000000);
      expect(cost.isFinite, isTrue);
      expect(cost, lessThanOrEqualTo(Balance.economyOverflowGuardCap));
    });

    test('generatorMilestoneMultiplier không bao giờ vượt trần', () {
      final m = generatorMilestoneMultiplier(1000000000);
      expect(m.isFinite, isTrue);
      expect(m, lessThanOrEqualTo(Balance.economyOverflowGuardCap));
    });
  });

  group('bulkIncomeGain', () {
    test('= chênh lệch thu nhập giữa 2 cấp (có mốc)', () {
      final s = GameState.newGame(nowMillis: 0);
      s.levels['x'] = 0;
      final before = baseIncomePerSecond(s, const [_g]);
      s.levels['x'] = 10;
      final after = baseIncomePerSecond(s, const [_g]);
      expect(bulkIncomeGain(_g, 0, 10), closeTo(after - before, 1e-6));
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

  group('mốc nhân bội (milestone)', () {
    test('cấp 0..49 = ×1 (không đổi cân bằng đầu game)', () {
      expect(generatorMilestoneMultiplier(0), 1);
      expect(generatorMilestoneMultiplier(49), 1);
    });

    test('mỗi 50 cấp ×2 (50→×2, 100→×4, 150→×8)', () {
      expect(generatorMilestoneMultiplier(50), 2);
      expect(generatorMilestoneMultiplier(100), 4);
      expect(generatorMilestoneMultiplier(150), 8);
    });

    test('levelsToNextMilestone đếm ngược đúng', () {
      expect(levelsToNextMilestone(0), 50);
      expect(levelsToNextMilestone(49), 1);
      expect(levelsToNextMilestone(50), 50);
      expect(levelsToNextMilestone(51), 49);
    });

    test('baseIncome áp mốc nhân bội vào từng nguồn', () {
      final at50 = GameState.newGame(nowMillis: 0)..levels['x'] = 50;
      expect(baseIncomePerSecond(at50, const [_g]), closeTo(2 * 50 * 2, 1e-9));
      final at100 = GameState.newGame(nowMillis: 0)..levels['x'] = 100;
      expect(
          baseIncomePerSecond(at100, const [_g]), closeTo(2 * 100 * 4, 1e-9));
    });
  });

  group('mốc vàng (global milestone)', () {
    test('mốc đầu (cấp 50) miễn phí — chưa cộng toàn cục', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 50;
      expect(globalMilestoneTiers(s, const [_g]), 0);
      expect(globalMilestoneMultiplier(s, const [_g]), 1.0);
    });

    test('từ mốc 2 (cấp 100) trở đi cộng dồn +bonus/mốc', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 100;
      expect(globalMilestoneTiers(s, const [_g]), 1);
      expect(globalMilestoneMultiplier(s, const [_g]),
          closeTo(1 + Balance.milestoneGlobalBonus, 1e-9));
      s.levels['x'] = 200; // 4 mốc → 3 tính điểm
      expect(globalMilestoneTiers(s, const [_g]), 3);
    });

    test('cộng qua nhiều nguồn thu', () {
      const g2 = GeneratorConfig(
          id: 'y', name: 'Y', baseCost: 1, costGrowth: 1.1,
          incomePerLevelPerSecond: 1);
      final s = GameState.newGame(nowMillis: 0)
        ..levels['x'] = 100 // 1 điểm
        ..levels['y'] = 150; // 2 điểm
      expect(globalMilestoneTiers(s, const [_g, g2]), 3);
    });

    test('nhân vào effectiveIncomePerSecond', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 100;
      final base = baseIncomePerSecond(s, const [_g]);
      expect(
        effectiveIncomePerSecond(s, const [_g], bonusPerStar: 0.02),
        closeTo(base * (1 + Balance.milestoneGlobalBonus), 1e-6),
      );
    });
  });

  group('perk lựa chọn cốt truyện', () {
    test('mặc định không có perk → hệ số 1.0', () {
      final s = GameState.newGame(nowMillis: 0);
      expect(storyChoiceTapMultiplier(s), 1.0);
      expect(storyChoiceIncomeMultiplier(s), 1.0);
    });

    test('"craft"/"identity" cộng vào trục chạm; "scale"/"acquire" vào thu nhập',
        () {
      final s = GameState.newGame(nowMillis: 0)
        ..storyChoiceA = 'craft'
        ..storyChoiceB = 'acquire';
      expect(storyChoiceTapMultiplier(s), 1 + Balance.storyPerkBonus);
      expect(storyChoiceIncomeMultiplier(s), 1 + Balance.storyPerkBonus);
      s
        ..storyChoiceA = 'scale'
        ..storyChoiceB = 'identity';
      expect(storyChoiceTapMultiplier(s), 1 + Balance.storyPerkBonus);
      expect(storyChoiceIncomeMultiplier(s), 1 + Balance.storyPerkBonus);
    });

    test('cả hai nhánh cùng trục → cộng dồn', () {
      final s = GameState.newGame(nowMillis: 0)
        ..storyChoiceA = 'scale'
        ..storyChoiceB = 'acquire';
      expect(storyChoiceIncomeMultiplier(s),
          closeTo(1 + 2 * Balance.storyPerkBonus, 1e-9));
    });

    test('fold vào effectiveIncomePerSecond', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 3;
      final before = effectiveIncomePerSecond(s, const [_g], bonusPerStar: 0.02);
      s.storyChoiceA = 'scale';
      final after = effectiveIncomePerSecond(s, const [_g], bonusPerStar: 0.02);
      expect(after, closeTo(before * (1 + Balance.storyPerkBonus), 1e-6));
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
