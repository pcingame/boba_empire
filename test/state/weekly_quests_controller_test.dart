import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayMs = 24 * 60 * 60 * 1000;

/// Giữa tuần (thứ Tư) đầu tiên (từ tuần 2900) có [kind] trong bộ nhiệm vụ tuần.
int _nowWith(WeeklyQuestKind kind) {
  for (var w = 2900; ; w++) {
    if (weeklyQuestsFor(w).any((q) => q.kind == kind)) {
      return ((w * 7 - 3) + 2) * _dayMs + 1000;
    }
  }
}

class _H {
  _H(this.container);
  final ProviderContainer container;
  GameSnapshot get snap => container.read(gameControllerProvider);
  dynamic get ctrl => container.read(gameControllerProvider.notifier);
  int progress(WeeklyQuestKind k) =>
      snap.weeklyQuests.firstWhere((q) => q.kind == k).progress;
}

Future<_H> _harness(int now, {GameState Function(int)? seed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(
    prefs,
  ).save(seed?.call(now) ?? GameState.newGame(nowMillis: now), nowMillis: now);
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  addTearDown(c.dispose);
  return _H(c);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'mở app: có 3 nhiệm vụ của tuần này, tiến độ 0, chưa có gì để nhận',
    () async {
      final h = await _harness(_nowWith(WeeklyQuestKind.spin));
      expect(h.snap.weeklyQuests.length, 3);
      expect(
        h.snap.weeklyQuests.every((q) => q.progress == 0 && !q.claimed),
        isTrue,
      );
      expect(h.snap.weeklyChestAvailable, isFalse);
      expect(h.snap.dailyClaimableCount, 0);
    },
  );

  test(
    'Nhượng quyền thành công +1; thất bại (chưa đủ điều kiện) thì không',
    () async {
      final now = _nowWith(WeeklyQuestKind.prestige);
      final fail = await _harness(now);
      expect(fail.ctrl.doPrestige(), 0);
      expect(fail.progress(WeeklyQuestKind.prestige), 0);

      final h = await _harness(
        now,
        seed: (n) => GameState.newGame(nowMillis: n)
          ..stage = 3
          ..lifetimeEarnings = 1e12
          ..levels.addAll({'tra_den': 50}),
      );
      expect(h.ctrl.doPrestige(), greaterThan(0));
      expect(h.progress(WeeklyQuestKind.prestige), 1);
    },
  );

  test('thắng màn Ghép 3 +1; thua (0 sao) thì không', () async {
    final h = await _harness(_nowWith(WeeklyQuestKind.m3Win));
    h.ctrl.grantMatch3Result(1, 0);
    expect(h.progress(WeeklyQuestKind.m3Win), 0);
    h.ctrl.grantMatch3Result(1, 2);
    h.ctrl.grantMatch3Result(1, 3); // phá kỷ lục cũng là một lần thắng
    expect(h.progress(WeeklyQuestKind.m3Win), 2);
  });

  test('giao dịch ở Chợ, quay vòng quay, mua nâng cấp đều được đếm', () async {
    final t = await _harness(_nowWith(WeeklyQuestKind.trade));
    t.ctrl.recordMarketTrade();
    t.ctrl.recordMarketTrade();
    expect(t.progress(WeeklyQuestKind.trade), 2);

    final s = await _harness(_nowWith(WeeklyQuestKind.spin));
    s.ctrl.spin(free: true);
    expect(s.progress(WeeklyQuestKind.spin), 1);

    final b = await _harness(
      _nowWith(WeeklyQuestKind.buy),
      seed: (n) => GameState.newGame(nowMillis: n)..money = 1e6,
    );
    b.ctrl.buy('tra_den');
    final n = b.ctrl.buyBulk('tra_den', 5) as int;
    expect(b.progress(WeeklyQuestKind.buy), 1 + n);
  });

  test(
    'nhận thưởng nhiệm vụ → rương: cộng 💎, rớt phụ kiện ≥ Hiếm, mở một lần',
    () async {
      final now = _nowWith(WeeklyQuestKind.spin);
      final week = weekIndex(now);
      final h = await _harness(
        now,
        seed: (n) {
          final s = GameState.newGame(nowMillis: n)
            ..weeklyQuestWeek = week
            ..gems = 0;
          for (final q in weeklyQuestsFor(week)) {
            s.weeklyProgress[q.kind.name] = q.target.toDouble();
          }
          return s;
        },
      );
      expect(h.snap.dailyClaimableCount, 3);
      expect(h.ctrl.claimWeeklyChestReward(), 0); // chưa nhận đủ
      for (var i = 0; i < 3; i++) {
        expect(h.ctrl.claimWeeklyQuestReward(i), weeklyQuestRewardGems);
      }
      expect(h.snap.weeklyChestAvailable, isTrue);
      expect(h.snap.dailyClaimableCount, 1);
      final before = h.snap.gems;
      expect(h.ctrl.claimWeeklyChestReward(), weeklyChestGems);
      final drop = h.ctrl.lastAccessoryDrop as AccessoryDrop?;
      expect(drop, isNotNull);
      expect(
        drop!.accessory.rarity.index,
        greaterThanOrEqualTo(AccessoryRarity.rare.index),
      );
      // trùng món thì được quy đổi thêm 💎 → chỉ cần tối thiểu bằng thưởng rương
      expect(h.snap.gems, greaterThanOrEqualTo(before + weeklyChestGems));
      expect(h.snap.weeklyChestClaimed, isTrue);
      expect(h.snap.dailyClaimableCount, 0);
      expect(h.ctrl.claimWeeklyChestReward(), 0);
    },
  );

  test(
    'HỒI QUY: tiến độ tuần sống sót qua lưu/mở lại app trong cùng tuần',
    () async {
      final now = _nowWith(WeeklyQuestKind.trade);
      final h = await _harness(now);
      h.ctrl.recordMarketTrade();
      h.container.dispose();
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now + _dayMs),
        ],
      );
      addTearDown(c.dispose);
      final again = _H(c);
      expect(again.progress(WeeklyQuestKind.trade), 1);
    },
  );

  test('sang tuần mới: bộ đổi, tiến độ về 0', () async {
    final now = _nowWith(WeeklyQuestKind.trade);
    final h = await _harness(now);
    h.ctrl.recordMarketTrade();
    h.container.dispose();
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now + 7 * _dayMs),
      ],
    );
    addTearDown(c.dispose);
    final next = _H(c);
    expect(next.snap.weeklyQuests.every((q) => q.progress == 0), isTrue);
  });
}
