import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const _configs = [
  GeneratorConfig(
    id: 'x',
    name: 'X',
    baseCost: 100,
    costGrowth: 1.15,
    incomePerLevelPerSecond: 10,
  ),
];

void main() {
  group('tap', () {
    test('cộng tapValue và ghi vào lifetime', () {
      final s = GameState.newGame(nowMillis: 0)..tapValue = 3;
      final gain = tap(s);
      expect(gain, 3);
      expect(s.money, 3);
      expect(s.lifetimeEarnings, 3);
    });

    test('được nhân bởi prestige', () {
      final s = GameState.newGame(nowMillis: 0)
        ..tapValue = 5
        ..prestigeStars = 10; // +20%
      expect(tap(s), closeTo(6, 1e-9));
    });
  });

  group('tick', () {
    test('cộng thu nhập = rate * dt', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 2; // 20/s
      tick(s, 3, configs: _configs);
      expect(s.money, closeTo(60, 1e-9));
      expect(s.lifetimeEarnings, closeTo(60, 1e-9));
    });

    test('dt <= 0 không làm gì', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 2;
      tick(s, 0, configs: _configs);
      tick(s, -5, configs: _configs);
      expect(s.money, 0);
    });
  });

  group('grantBonus', () {
    test('money đã ở double.maxFinite: cộng thêm tràn thành Infinity → bỏ qua, giữ nguyên', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = double.maxFinite
        ..lifetimeEarnings = double.maxFinite;
      grantBonus(s, double.maxFinite); // maxFinite + maxFinite = Infinity
      expect(s.money, double.maxFinite);
      expect(s.lifetimeEarnings, double.maxFinite);
    });
  });

  group('buyUpgrade', () {
    test('mua được khi đủ tiền, trừ đúng giá, lên cấp', () {
      final s = GameState.newGame(nowMillis: 0)..money = 100;
      expect(buyUpgrade(s, 'x', configs: _configs), isTrue);
      expect(s.money, closeTo(0, 1e-9));
      expect(s.levels['x'], 1);
    });

    test('không mua khi thiếu tiền, trạng thái không đổi', () {
      final s = GameState.newGame(nowMillis: 0)..money = 99;
      expect(buyUpgrade(s, 'x', configs: _configs), isFalse);
      expect(s.money, 99);
      expect(s.levels['x'], isNull);
    });

    test('giá tăng theo cấp sau mỗi lần mua', () {
      final s = GameState.newGame(nowMillis: 0)..money = 215;
      expect(buyUpgrade(s, 'x', configs: _configs), isTrue); // -100 -> 115
      expect(buyUpgrade(s, 'x', configs: _configs), isTrue); // -115 -> 0
      expect(s.levels['x'], 2);
      expect(s.money, closeTo(0, 1e-9));
    });

    test('không mua khi giá tràn số (Infinity) dù money cũng là Infinity', () {
      // Cấp cực cao khiến pow(costGrowth, level) tràn double -> Infinity.
      // Trước đây `money < cost` (Infinity < Infinity = false) khiến lệnh mua
      // vẫn "thành công" và trừ Infinity vào money, để lại NaN/số âm sai lệch.
      final s = GameState.newGame(nowMillis: 0)
        ..money = double.infinity
        ..levels['x'] = 100000;
      expect(buyUpgrade(s, 'x', configs: _configs), isFalse);
      expect(s.money, double.infinity);
      expect(s.levels['x'], 100000);
    });
  });

  group('applyOfflineEarnings', () {
    test('cộng rate * thời_gian_vắng và cập nhật mốc', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 1; // 10/s
      final earned = applyOfflineEarnings(s, 5000, configs: _configs); // 5s
      expect(earned, closeTo(50, 1e-9));
      expect(s.money, closeTo(50, 1e-9));
      expect(s.lastSeenMillis, 5000);
    });

    test('bị cap theo maxOfflineSeconds', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 1; // 10/s
      final earned = applyOfflineEarnings(
        s,
        1000 * 1000000, // rất lâu
        configs: _configs,
        maxOfflineSeconds: 60,
      );
      expect(earned, closeTo(600, 1e-9)); // chỉ tính 60s
    });

    test('chống lùi đồng hồ: now < lastSeen -> 0, vẫn cập nhật mốc', () {
      final s = GameState.newGame(nowMillis: 10000)..levels['x'] = 1;
      final earned = applyOfflineEarnings(s, 5000, configs: _configs);
      expect(earned, 0);
      expect(s.money, 0);
      expect(s.lastSeenMillis, 5000);
    });

    test('cũng tích heo đất cho khoảng vắng', () {
      final s = GameState.newGame(nowMillis: 0)..levels['x'] = 1;
      applyOfflineEarnings(s, 3600 * 1000, configs: _configs); // 1 giờ
      expect(s.piggyGems, greaterThan(0));
    });

    test('perk "Siêu offline" nhân thu nhập lúc vắng', () {
      final base = GameState.newGame(nowMillis: 0)..levels['x'] = 1; // 10/s
      final e0 = applyOfflineEarnings(base, 5000, configs: _configs);
      final s = GameState.newGame(nowMillis: 0)
        ..levels['x'] = 1
        ..prestigeOfflineLevel = 2; // +50%
      final e1 = applyOfflineEarnings(s, 5000, configs: _configs);
      expect(e1, closeTo(e0 * 1.5, 1e-6));
    });

    test('VIP ×2 áp cho thu nhập offline', () {
      final s = GameState.newGame(nowMillis: 0)
        ..levels['x'] = 1
        ..vipUntilMillis = 999999999;
      final earned = applyOfflineEarnings(s, 5000, configs: _configs);
      expect(earned, closeTo(50 * 2, 1e-6)); // 10/s * 5s * VIP ×2
    });
  });

  group('fillPiggy', () {
    test('tích theo giây trôi, tới trần thì dừng', () {
      final s = GameState.newGame(nowMillis: 0);
      fillPiggy(s, 3600);
      expect(s.piggyGems, closeTo(Balance.piggyGemsPerSecond * 3600, 1e-6));
      fillPiggy(s, 1000000);
      expect(s.piggyGems, Balance.piggyMaxGems);
    });

    test('dt <= 0 -> không đổi', () {
      final s = GameState.newGame(nowMillis: 0)..piggyGems = 5;
      fillPiggy(s, 0);
      fillPiggy(s, -10);
      expect(s.piggyGems, 5);
    });
  });

  group('buyInstantStageUnlock', () {
    test('trừ 💎, lên giai đoạn, không đụng Xu', () {
      final s = GameState.newGame(nowMillis: 0)
        ..gems = 100
        ..money = 5;
      expect(buyInstantStageUnlock(s), isTrue);
      expect(s.stage, 2);
      expect(s.money, 5);
      expect(s.gems, 100 - Balance.instantStageGemCost[0]);
    });

    test('thiếu 💎 -> false, không đổi', () {
      final s = GameState.newGame(nowMillis: 0)..gems = 1;
      expect(buyInstantStageUnlock(s), isFalse);
      expect(s.stage, 1);
    });

    test('giai đoạn cuối -> false', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 6
        ..gems = 99999;
      expect(buyInstantStageUnlock(s), isFalse);
    });
  });

  group('buyGemTimeSkip', () {
    test('trừ 💎 + cộng income × thời lượng', () {
      final s = GameState.newGame(nowMillis: 0)
        ..levels['x'] = 1 // 10/s
        ..gems = 100;
      final r = buyGemTimeSkip(s, configs: _configs);
      expect(r, closeTo(10 * Balance.gemTimeSkipSeconds, 1e-3));
      expect(s.gems, 100 - Balance.gemTimeSkipCost);
      expect(s.money, closeTo(r, 1e-3));
    });

    test('chưa có thu nhập -> 0, không trừ 💎', () {
      final s = GameState.newGame(nowMillis: 0)..gems = 100;
      expect(buyGemTimeSkip(s, configs: _configs), 0);
      expect(s.gems, 100);
    });
  });

  group('autoBuyBest', () {
    const cfgs = [
      GeneratorConfig(
          id: 'a', name: 'A', baseCost: 10, costGrowth: 1.1,
          incomePerLevelPerSecond: 1),
      GeneratorConfig(
          id: 'b', name: 'B', baseCost: 10, costGrowth: 1.1,
          incomePerLevelPerSecond: 5),
    ];

    test('không perk / tắt cờ → không mua', () {
      final s = GameState.newGame(nowMillis: 0)..money = 1e9;
      expect(autoBuyBest(s, configs: cfgs), 0);
      s.prestigeAutoBuyLevel = 1; // có perk nhưng chưa bật
      expect(autoBuyBest(s, configs: cfgs), 0);
    });

    test('bật → mua tới khi hết tiền, ưu tiên nguồn đáng mua nhất', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = 100
        ..prestigeAutoBuyLevel = 1
        ..autoBuyEnabled = true;
      final n = autoBuyBest(s, configs: cfgs);
      expect(n, greaterThan(0));
      expect(s.money, lessThan(10)); // gần cạn (cấp rẻ nhất giá 10)
      // B thu nhập/giá tốt hơn → được mua nhiều hơn.
      expect((s.levels['b'] ?? 0), greaterThan(s.levels['a'] ?? 0));
    });
  });

  group('buyUpgradeBulk', () {
    test('mua đúng count cấp, trừ tổng chi phí chuỗi', () {
      final s = GameState.newGame(nowMillis: 0)..money = 100000;
      final cost = bulkCost(_configs.first, 0, 10);
      final bought = buyUpgradeBulk(s, 'x', 10, configs: _configs);
      expect(bought, 10);
      expect(s.levels['x'], 10);
      expect(s.money, closeTo(100000 - cost, 1e-6));
    });

    test('thiếu tiền cho trọn count → huỷ, không mua từng phần', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = bulkCost(_configs.first, 0, 5) - 1;
      expect(buyUpgradeBulk(s, 'x', 5, configs: _configs), 0);
      expect(s.levels['x'] ?? 0, 0);
    });

    test('chưa mở khoá giai đoạn → 0', () {
      final s = GameState.newGame(nowMillis: 0)..money = 1e9;
      const locked = [
        GeneratorConfig(
            id: 'z', name: 'Z', baseCost: 1, costGrowth: 1.1,
            incomePerLevelPerSecond: 1, stage: 3),
      ];
      expect(buyUpgradeBulk(s, 'z', 3, configs: locked), 0);
    });
  });

  group('prestige', () {
    test('chưa đủ lifetime -> không nhận sao, không reset', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = 500
        ..lifetimeEarnings = 100; // 0.05*sqrt(100)=0.5 -> floor 0
      expect(prestigeStarsAvailable(s), 0);
      expect(prestige(s), 0);
      expect(s.money, 500);
    });

    test('nhận sao, reset tiền+cấp+giai đoạn, giữ lifetime và sao', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = 9999
        ..stage = 5
        ..levels['x'] = 7
        ..lifetimeEarnings = 1000000; // -> 50 sao
      expect(prestigeStarsAvailable(s), 50);
      expect(prestige(s), 50);
      expect(s.prestigeStars, 50);
      expect(s.money, 0);
      expect(s.levels, isEmpty);
      expect(s.stage, 1); // hard reset về giai đoạn 1
      expect(s.lifetimeEarnings, 1000000); // KHÔNG reset
    });

    test('perk "Giữ giai đoạn" chặn reset stage', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 5
        ..prestigeKeepStageLevel = 2 // giữ tới GĐ 3
        ..lifetimeEarnings = 1000000;
      prestige(s);
      expect(s.stage, 3);
    });

    test('perk "Vốn khởi nghiệp" cấp Xu sau prestige', () {
      final s = GameState.newGame(nowMillis: 0)
        ..prestigeStartCashLevel = 1
        ..lifetimeEarnings = 1000000;
      prestige(s);
      expect(s.money, startCashAfterPrestige(1));
      expect(s.money, greaterThan(0));
    });

    test('prestige lần 2 chỉ nhận phần sao chênh lệch', () {
      final s = GameState.newGame(nowMillis: 0)
        ..prestigeStars = 50
        ..lifetimeEarnings = 4000000; // 0.05*2000=100 -> còn 50 sao mới
      expect(prestigeStarsAvailable(s), 50);
      expect(prestige(s), 50);
      expect(s.prestigeStars, 100);
    });

    test('cốt truyện & đối thủ KHÔNG reset khi prestige', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 6
        ..levels['x'] = 9
        ..lifetimeEarnings = 1000000
        ..storyChapter = 7
        ..storyChoiceA = 'craft'
        ..storyChoiceB = 'acquire'
        ..rivalDefeated = true
        ..rivalPressureSeconds = 1234;
      prestige(s);
      expect(s.stage, 1); // vẫn hard reset
      expect(s.levels, isEmpty);
      expect(s.storyChapter, 7);
      expect(s.storyChoiceA, 'craft');
      expect(s.storyChoiceB, 'acquire');
      expect(s.rivalDefeated, isTrue);
      expect(s.rivalPressureSeconds, 1234);
    });
  });

  group('serialize', () {
    test('toJson/fromJson giữ nguyên trạng thái', () {
      final s = GameState.newGame(nowMillis: 1234)
        ..money = 42.5
        ..gems = 3
        ..tapValue = 2
        ..levels['x'] = 4
        ..lifetimeEarnings = 999.5
        ..prestigeStars = 7
        ..prestigeOfflineLevel = 2
        ..prestigeStartCashLevel = 1
        ..prestigeKeepStageLevel = 3
        ..prestigeDiscountLevel = 4
        ..prestigeAutoBuyLevel = 1
        ..autoBuyEnabled = true
        ..storyChapter = 6
        ..storyChoiceA = 'scale'
        ..rivalDefeated = true
        ..rivalPressureSeconds = 777.5
        ..repeatQuestBaseline = 12345.0;
      final round = GameState.fromJson(s.toJson());
      expect(round.money, 42.5);
      expect(round.gems, 3);
      expect(round.tapValue, 2);
      expect(round.levels['x'], 4);
      expect(round.lifetimeEarnings, 999.5);
      expect(round.prestigeStars, 7);
      expect(round.lastSeenMillis, 1234);
      expect(round.prestigeOfflineLevel, 2);
      expect(round.prestigeStartCashLevel, 1);
      expect(round.prestigeKeepStageLevel, 3);
      expect(round.prestigeDiscountLevel, 4);
      expect(round.prestigeAutoBuyLevel, 1);
      expect(round.autoBuyEnabled, isTrue);
      expect(round.storyChapter, 6);
      expect(round.storyChoiceA, 'scale');
      expect(round.storyChoiceB, isNull);
      expect(round.rivalDefeated, isTrue);
      expect(round.rivalPressureSeconds, 777.5);
      expect(round.repeatQuestBaseline, 12345.0);
    });

    test('save hỏng có money âm/NaN → vá về 0 thay vì hiển thị số âm', () {
      final negative = GameState.newGame(nowMillis: 0).toJson()
        ..['money'] = -87420000000000000000.0;
      expect(GameState.fromJson(negative).money, 0);

      final nan = GameState.newGame(nowMillis: 0).toJson()..['money'] = double.nan;
      expect(GameState.fromJson(nan).money, 0);
    });

    test('save cũ (thiếu field cốt truyện) → mặc định', () {
      final old = GameState.newGame(nowMillis: 0).toJson()
        ..remove('storyChapter')
        ..remove('storyChoiceA')
        ..remove('storyChoiceB')
        ..remove('rivalDefeated')
        ..remove('rivalPressureSeconds');
      final s = GameState.fromJson(old);
      expect(s.storyChapter, 0);
      expect(s.storyChoiceA, isNull);
      expect(s.rivalDefeated, isFalse);
      expect(s.rivalPressureSeconds, 0);
    });
  });

  test('Balance.generators không rỗng và id không trùng', () {
    final ids = Balance.generators.map((g) => g.id).toSet();
    expect(Balance.generators, isNotEmpty);
    expect(ids.length, Balance.generators.length);
  });
}
