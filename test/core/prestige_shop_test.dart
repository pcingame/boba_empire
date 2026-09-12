import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kho Sao (prestige shop)', () {
    test('spendable ban đầu = tổng Sao', () {
      final s = GameState.newGame(nowMillis: 0)..prestigeStars = 20;
      expect(prestigeStarsSpendable(s), 20);
    });

    test('mua Siêu thu nhập: trừ Sao, tăng cấp & hệ số income', () {
      final s = GameState.newGame(nowMillis: 0)..prestigeStars = 20;
      final cost = prestigeShopCost(Balance.prestigeIncomeBaseCost, 0);
      expect(buyPrestigeIncome(s), isTrue);
      expect(s.prestigeIncomeLevel, 1);
      expect(prestigeStarsSpendable(s), 20 - cost);
      expect(prestigeIncomeMultiplier(1), closeTo(1.25, 1e-9));
    });

    test('không đủ Sao thì không mua', () {
      final s = GameState.newGame(nowMillis: 0)..prestigeStars = 2;
      expect(buyPrestigeIncome(s), isFalse);
      expect(s.prestigeIncomeLevel, 0);
    });

    test('giá ×2 mỗi cấp; đã tiêu = tổng cấp số nhân', () {
      final s = GameState.newGame(nowMillis: 0)..prestigeStars = 100;
      buyPrestigeIncome(s); // 3
      buyPrestigeIncome(s); // 6
      buyPrestigeIncome(s); // 12
      expect(s.prestigeIncomeLevel, 3);
      expect(prestigeStarsSpent(s), 3 + 6 + 12);
      expect(prestigeStarsSpendable(s), 100 - 21);
    });

    test('tiêu Sao KHÔNG đổi prestigeStars (không exploit qua prestige)', () {
      final s = GameState.newGame(nowMillis: 0)
        ..prestigeStars = 20
        ..lifetimeEarnings = 160000;
      final availableBefore = prestigeStarsAvailable(s);
      buyPrestigeIncome(s);
      expect(s.prestigeStars, 20);
      expect(prestigeStarsAvailable(s), availableBefore);
    });

    test('Siêu chạm nhân giá trị mỗi lần chạm', () {
      // prestigeStars=0 để cô lập hệ số chạm (không dính passive +2%/sao).
      final s = GameState.newGame(nowMillis: 0)..prestigeTapLevel = 1; // ×2
      expect(tap(s), closeTo(2, 1e-9));
    });

    test('Mua sỉ giảm giá nâng cấp (sàn ×0.4)', () {
      expect(upgradeCostMultiplier(0), 1.0);
      expect(upgradeCostMultiplier(5), closeTo(0.85, 1e-9)); // -15%
      expect(upgradeCostMultiplier(100), Balance.prestigeDiscountFloor);
    });

    test('Giữ giai đoạn: tối đa maxLevel, kẹp theo stage hiện tại', () {
      final s = GameState.newGame(nowMillis: 0)
        ..prestigeStars = 9999
        ..prestigeKeepStageLevel = Balance.prestigeKeepStageMaxLevel;
      expect(buyPrestigeKeepStage(s), isFalse); // đã tối đa
      expect(keptStageAfterPrestige(3, 5), 3); // kẹp theo stage
    });

    test('perk mới đều trừ Sao & tăng cấp', () {
      GameState fresh() =>
          GameState.newGame(nowMillis: 0)..prestigeStars = 9999;
      var s = fresh();
      expect(buyPrestigeOffline(s), isTrue);
      expect(s.prestigeOfflineLevel, 1);
      s = fresh();
      expect(buyPrestigeStartCash(s), isTrue);
      expect(s.prestigeStartCashLevel, 1);
      s = fresh();
      expect(buyPrestigeKeepStage(s), isTrue);
      expect(s.prestigeKeepStageLevel, 1);
      s = fresh();
      expect(buyPrestigeDiscount(s), isTrue);
      expect(s.prestigeDiscountLevel, 1);
      s = fresh();
      expect(buyPrestigeAutoBuy(s), isTrue);
      expect(s.prestigeAutoBuyLevel, 1);
      expect(buyPrestigeAutoBuy(s), isFalse); // tối đa 1 cấp
    });

    test(
        'giá không lật dấu ở cấp cực cao (từng dùng 1 << level, bit-shift '
        'int 64-bit lật âm quanh cấp 63 → mua miễn phí/vô hạn)', () {
      // Bug thật phát hiện lúc audit lib/ui cho lớp bug tràn số 2026-09-12:
      // 1 << 63 tràn dấu int64, ra số ÂM → `spendable >= cost` luôn đúng.
      // Chưa khai thác được trong game thật (cần ~9.2e18 Sao), nhưng công
      // thức phải an toàn bất kể cấp bao nhiêu, không tin vào "chưa ai đạt
      // tới" — cùng triết lý với Balance.economyOverflowGuardCap.
      expect(prestigeShopCost(3, 63), greaterThan(0));
      expect(prestigeShopCost(3, 70), greaterThan(0));
      expect(prestigeShopCost(3, 1000), greaterThan(0));

      // Cấp thực tế vẫn ra đúng số như công thức cũ (base * 2^level).
      expect(prestigeShopCost(3, 0), 3);
      expect(prestigeShopCost(3, 10), 3 * 1024);
    });
  });
}
