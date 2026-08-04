import 'package:boba_empire/core/balance.dart';
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

    test('nhận sao, reset tiền+cấp, giữ lifetime và sao', () {
      final s = GameState.newGame(nowMillis: 0)
        ..money = 9999
        ..levels['x'] = 7
        ..lifetimeEarnings = 1000000; // -> 50 sao
      expect(prestigeStarsAvailable(s), 50);
      expect(prestige(s), 50);
      expect(s.prestigeStars, 50);
      expect(s.money, 0);
      expect(s.levels, isEmpty);
      expect(s.lifetimeEarnings, 1000000); // KHÔNG reset
    });

    test('prestige lần 2 chỉ nhận phần sao chênh lệch', () {
      final s = GameState.newGame(nowMillis: 0)
        ..prestigeStars = 50
        ..lifetimeEarnings = 4000000; // 0.05*2000=100 -> còn 50 sao mới
      expect(prestigeStarsAvailable(s), 50);
      expect(prestige(s), 50);
      expect(s.prestigeStars, 100);
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
        ..prestigeStars = 7;
      final round = GameState.fromJson(s.toJson());
      expect(round.money, 42.5);
      expect(round.gems, 3);
      expect(round.tapValue, 2);
      expect(round.levels['x'], 4);
      expect(round.lifetimeEarnings, 999.5);
      expect(round.prestigeStars, 7);
      expect(round.lastSeenMillis, 1234);
    });
  });

  test('Balance.generators không rỗng và id không trùng', () {
    final ids = Balance.generators.map((g) => g.id).toSet();
    expect(Balance.generators, isNotEmpty);
    expect(ids.length, Balance.generators.length);
  });
}
