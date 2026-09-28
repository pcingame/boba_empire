import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const _min = Balance.ascensionMinLifetime;

GameState _ready({double lifetimeMul = 1}) => GameState.newGame(nowMillis: 0)
  ..lifetimeEarnings = _min * lifetimeMul
  ..stage = 18
  ..money = 12345
  ..levels['tra_den'] = 50
  ..prestigeStars = 500
  ..prestigeIncomeLevel = 2
  ..prestigeTapLevel = 1
  ..prestigeOfflineLevel = 1
  ..prestigeStartCashLevel = 1
  ..prestigeKeepStageLevel = 2
  ..prestigeDiscountLevel = 1
  ..prestigeAutoBuyLevel = 1
  ..gems = 77
  ..gemBoostLevel = 3
  ..storyChapter = 28;

void main() {
  group('điều kiện & điểm', () {
    test('chưa đủ ngưỡng -> 0 điểm, ascend() không đổi gì', () {
      final s = _ready(lifetimeMul: 0.99);
      expect(ascensionPointsAvailable(s), 0);
      expect(ascend(s), 0);
      expect(s.stage, 18);
      expect(s.prestigeStars, 500);
      expect(s.ascensionCount, 0);
    });

    test('đúng ngưỡng = 1 điểm; ×100 lifetime = ×10 điểm', () {
      expect(ascensionPointsAvailable(_ready()), 1);
      expect(ascensionPointsAvailable(_ready(lifetimeMul: 100)), 10);
      expect(ascensionPointsAvailable(_ready(lifetimeMul: 10000)), 100);
    });

    test('sau khi từng Kỷ Nguyên hoá: chỉ đếm lifetime mới, không đếm lại cũ', () {
      final s = _ready(lifetimeMul: 100)
        ..ascensionCount = 1
        ..ascensionLifetime = _min * 2;
      expect(ascensionPointsAvailable(s), 1); // sqrt(2) -> 1, dù lifetime tổng rất lớn
    });
  });

  group('ascend()', () {
    test('reset đúng những gì cần reset', () {
      final s = _ready(lifetimeMul: 100);
      final gained = ascend(s);
      expect(gained, 10);
      expect(s.ascensionPointsEarned, 10);
      expect(s.ascensionCount, 1);
      expect(s.stage, 1);
      expect(s.money, 0);
      expect(s.levels, isEmpty);
      expect(s.prestigeStars, 0);
      for (final lv in [
        s.prestigeIncomeLevel,
        s.prestigeTapLevel,
        s.prestigeOfflineLevel,
        s.prestigeStartCashLevel,
        s.prestigeKeepStageLevel,
        s.prestigeDiscountLevel,
      ]) {
        expect(lv, 0);
      }
    });

    test('giữ đúng những gì cần giữ', () {
      final s = _ready(lifetimeMul: 100);
      final lifetime = s.lifetimeEarnings;
      ascend(s);
      expect(s.lifetimeEarnings, lifetime); // bảng xếp hạng dựa vào đây
      expect(s.gems, 77);
      expect(s.gemBoostLevel, 3);
      expect(s.storyChapter, 28);
      expect(s.prestigeAutoBuyLevel, 1); // tiện ích, không mất
      expect(s.ascensionLifetime, 0);
    });

    test('HỒI QUY CHÍNH: Sao KHÔNG được trả lại nguyên vẹn sau Kỷ Nguyên', () {
      // Nếu Sao vẫn tính từ toàn bộ lifetime thì ngay sau khi reset về 0,
      // Nhượng quyền kế tiếp trả lại tất cả → Kỷ Nguyên vô nghĩa.
      final s = _ready(lifetimeMul: 100)..prestigeStars = 0;
      final before = prestigeStarsAvailable(s);
      expect(before, greaterThan(0));
      ascend(s);
      expect(prestigeStarsAvailable(s), 0);
    });

    test('Sao tích lại được từ đầu dù lifetime tổng đã cực lớn', () {
      final s = _ready(lifetimeMul: 100);
      ascend(s);
      // Chơi tiếp qua đường thật (grantBonus -> _credit): lifetime tổng ~5e37 nên
      // phép cộng thẳng vào nó bị double nuốt — bộ tích lũy riêng phải vẫn tăng.
      for (var i = 0; i < 1000; i++) {
        grantBonus(s, 1e7);
      }
      expect(s.ascensionLifetime, closeTo(1e10, 1));
      expect(prestigeStarsAvailable(s), greaterThan(0));
      // ...nhưng ít hơn nhiều so với tính từ toàn bộ lifetime
      final full = starsForLifetimeEarnings(s.lifetimeEarnings, Balance.prestigeK);
      expect(prestigeStarsAvailable(s), lessThan(full ~/ 1000));
    });

    test('Kỷ Nguyên lần 2 chỉ tính lifetime mới', () {
      final s = _ready(lifetimeMul: 100);
      ascend(s);
      expect(ascensionPointsAvailable(s), 0);
      s.ascensionLifetime += _min * 4;
      expect(ascensionPointsAvailable(s), 2);
    });
  });

  group('perk', () {
    GameState withPoints(int p) =>
        GameState.newGame(nowMillis: 0)..ascensionPointsEarned = p;

    test('mua tốn base·2^cấp, thiếu điểm thì false', () {
      final s = withPoints(3);
      expect(buyAscensionIncome(s), isTrue); // 1
      expect(buyAscensionIncome(s), isTrue); // 2 (còn 0)
      expect(s.ascensionIncomeLevel, 2);
      expect(ascensionPointsSpendable(s), 0);
      expect(buyAscensionIncome(s), isFalse); // cần 4
      expect(s.ascensionIncomeLevel, 2);
    });

    test('bị kẹp trần cấp dù thừa điểm', () {
      final s = withPoints(1 << 40);
      for (var i = 0; i < 100; i++) {
        buyAscensionStarGain(s);
        buyAscensionIncome(s);
        buyAscensionStarBonus(s);
      }
      expect(s.ascensionStarGainLevel, Balance.ascensionStarGainMaxLevel);
      expect(s.ascensionIncomeLevel, Balance.ascensionIncomeMaxLevel);
      expect(s.ascensionStarBonusLevel, Balance.ascensionStarBonusMaxLevel);
    });

    test('perk "Nguồn năng lượng" nhân thu nhập; 0 cấp = không đổi', () {
      final base = GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10;
      final boosted = GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 10
        ..ascensionIncomeLevel = 2;
      final a = effectiveIncomePerSecond(base, Balance.generators,
          bonusPerStar: Balance.bonusPerStar);
      final b = effectiveIncomePerSecond(boosted, Balance.generators,
          bonusPerStar: Balance.bonusPerStar);
      expect(b, closeTo(a * 2, 1e-9)); // 1 + 2·0.5
    });

    test('perk "Ngôi sao rực rỡ" chỉ có tác dụng khi có Sao', () {
      final noStars = GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 10
        ..ascensionStarBonusLevel = 4;
      final ref = GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10;
      double inc(GameState s) => effectiveIncomePerSecond(s, Balance.generators,
          bonusPerStar: Balance.bonusPerStar);
      expect(inc(noStars), closeTo(inc(ref), 1e-9));

      final withStars = GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 10
        ..prestigeStars = 100
        ..ascensionStarBonusLevel = 4; // bonus/Sao ×2
      final plain = GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 10
        ..prestigeStars = 100;
      // (1+100·0.04) / (1+100·0.02) = 5/3
      expect(inc(withStars) / inc(plain), closeTo(5 / 3, 1e-9));
    });
  });

  group('ràng buộc server & tràn số', () {
    test('k hiệu dụng ở cấp tối đa <= 0.05 (server chặn Sao > floor(0.05·√lifetime))',
        () {
      final k = Balance.prestigeK *
          ascensionStarGainFactor(Balance.ascensionStarGainMaxLevel);
      expect(k, lessThanOrEqualTo(0.05));
    });

    test('Sao luôn <= floor(0.05·√lifetime) dù đã max perk & đã Kỷ Nguyên hoá',
        () {
      final s = GameState.newGame(nowMillis: 0)
        ..ascensionStarGainLevel = Balance.ascensionStarGainMaxLevel
        ..ascensionCount = 1
        ..ascensionLifetime = 1e30
        ..lifetimeEarnings = 1e40;
      final stars = prestigeStarsAvailable(s);
      final serverMax = starsForLifetimeEarnings(s.lifetimeEarnings, 0.05);
      expect(stars, lessThanOrEqualTo(serverMax));
    });

    test('thu nhập ở cấp perk tối đa vẫn hữu hạn và dưới trần chống tràn', () {
      final s = GameState.newGame(nowMillis: 0)
        ..levels['eternal_tea'] = Balance.maxGeneratorLevel
        ..prestigeStars = (1 << 40).toDouble()
        ..ascensionIncomeLevel = Balance.ascensionIncomeMaxLevel
        ..ascensionStarBonusLevel = Balance.ascensionStarBonusMaxLevel;
      final inc = effectiveIncomePerSecond(s, Balance.generators,
          bonusPerStar: Balance.bonusPerStar);
      expect(inc.isFinite, isTrue);
      expect(inc, lessThan(Balance.economyOverflowGuardCap));
    });
  });

  group('save', () {
    test('round-trip JSON giữ nguyên các field Kỷ Nguyên', () {
      final s = GameState.newGame(nowMillis: 0)
        ..ascensionCount = 2
        ..ascensionPointsEarned = 17
        ..ascensionLifetime = 1.5e36
        ..ascensionIncomeLevel = 3
        ..ascensionStarBonusLevel = 2
        ..ascensionStarGainLevel = 1;
      final b = GameState.fromJson(s.toJson());
      expect(b.ascensionCount, 2);
      expect(b.ascensionPointsEarned, 17);
      expect(b.ascensionLifetime, 1.5e36);
      expect(b.ascensionIncomeLevel, 3);
      expect(b.ascensionStarBonusLevel, 2);
      expect(b.ascensionStarGainLevel, 1);
    });

    test('save cũ thiếu field -> mặc định 0, không đổi cách tính Sao', () {
      final json = GameState.newGame(nowMillis: 0).toJson()
        ..removeWhere((k, _) => k.startsWith('ascension'));
      final s = GameState.fromJson(json)..lifetimeEarnings = 1e12;
      expect(s.ascensionCount, 0);
      expect(s.ascensionLifetime, 0);
      expect(prestigeStarsAvailable(s),
          starsForLifetimeEarnings(1e12, Balance.prestigeK));
    });
  });
}
