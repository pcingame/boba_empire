/// Tinh chất 🧪 & Bí quyết: giá/hệ số, trần ngày (đơn + chung), thu nhập theo giai đoạn, giữ qua
/// Nhượng quyền/Kỷ Nguyên, tương thích save. Xem PROPOSAL_ESSENCE_MASTERY.md.
library;

import 'dart:convert';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/essence.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _g() => GameState.newGame(nowMillis: 0);

void main() {
  test('giá bậc 10/20/40/80/160, đầy bậc thì null; hệ số 1 → 1.4', () {
    expect([for (var t = 0; t < 5; t++) masteryNextCost(t)], [10, 20, 40, 80, 160]);
    expect(masteryNextCost(5), isNull);
    expect(masteryMultiplier({1: 5}, 1), closeTo(1.4, 1e-12));
    expect(masteryMultiplier({}, 1), 1);
    expect(masteryMultiplier({1: 99}, 1), closeTo(1.4, 1e-12), reason: 'bậc lạ bị kẹp');
    expect(masteryMultiplier({1: -3}, 1), 1);
  });

  test('buyMastery: thiếu Tinh chất / đầy bậc / giai đoạn lạ đều từ chối, không đổi gì', () {
    final s = _g()..essence = 9;
    expect(buyMastery(s, 1), isFalse);
    expect(s.essence, 9);
    expect(s.masteryTiers, isEmpty);
    s.essence = 10;
    expect(buyMastery(s, 1), isTrue);
    expect((s.essence, s.masteryTiers[1]), (0, 1));
    expect(buyMastery(s, 0), isFalse);
    expect(buyMastery(s, Balance.stages.length + 1), isFalse);
    s.essence = 100000;
    for (var i = 0; i < 4; i++) {
      expect(buyMastery(s, 1), isTrue);
    }
    expect(buyMastery(s, 1), isFalse, reason: 'đã đầy 5 bậc');
    expect(s.essence, 100000 - 10 - 20 - 40 - 80 - 160 + 10);
  });

  test('trần ngày: đơn ≤10, chung ≤20; thử thách/QC chỉ chịu trần chung; sang ngày reset', () {
    final s = _g();
    var got = 0;
    for (var i = 0; i < 15; i++) {
      got += grantEssenceOrder(s, 5, 1);
    }
    expect(got, 10);
    expect(grantEssenceRepeatable(s, 5, 5), 5);
    expect(grantEssenceRepeatable(s, 5, 99), 5, reason: 'còn 20 − 10 − 5 = 5');
    expect(grantEssenceRepeatable(s, 5, 1), 0);
    expect(s.essence, 20);
    expect(grantEssenceOrder(s, 6, 1), 1, reason: 'ngày mới');
    expect(grantEssenceOrder(s, 6, 0), 0);
    expect(grantEssenceOrder(s, 6, -4), 0);
    // Thử thách trước, rồi đơn bị trần chung chặn dù chưa chạm trần đơn.
    final t = _g();
    expect(grantEssenceRepeatable(t, 5, 18), 18);
    expect(grantEssenceOrder(t, 5, 5), 2);
    expect(t.essence, 20);
  });

  test('nguồn một-lần không trần ngày', () {
    final s = _g();
    expect(grantEssenceOnce(s, 50), 50);
    expect(grantEssenceOnce(s, 0), 0);
    expect(s.essence, 50);
  });

  test('thu nhập: Bí quyết chỉ nhân giai đoạn hiện tại', () {
    final base = _g()..levels[Balance.generators.first.id] = 10;
    final boosted = _g()
      ..levels[Balance.generators.first.id] = 10
      ..masteryTiers[1] = 5;
    final other = _g()
      ..levels[Balance.generators.first.id] = 10
      ..masteryTiers[2] = 5;
    final a = baseIncomePerSecond(base, Balance.generators);
    expect(a, greaterThan(0));
    expect(baseIncomePerSecond(boosted, Balance.generators), closeTo(a * 1.4, a * 1e-9));
    expect(baseIncomePerSecond(other, Balance.generators), closeTo(a, a * 1e-12));
  });

  test('giữ qua Nhượng quyền và Kỷ Nguyên; hữu hạn với save cực lớn', () {
    final s = _g()
      ..essence = 77
      ..masteryTiers[3] = 2
      ..lifetimeEarnings = 1e300
      ..money = 1e300;
    prestige(s);
    expect((s.essence, s.masteryTiers[3]), (77, 2));
    ascend(s);
    expect((s.essence, s.masteryTiers[3]), (77, 2));
    expect(baseIncomePerSecond(s, Balance.generators).isFinite, isTrue);
  });

  test('save: round-trip, save cũ thiếu field = 0, dữ liệu hỏng bị kẹp', () {
    final s = _g()
      ..essence = 12
      ..essenceDay = 7
      ..essenceOrdersToday = 3
      ..essenceRepeatableToday = 4
      ..masteryTiers[2] = 3;
    final back = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect((back.essence, back.essenceDay, back.essenceOrdersToday, back.essenceRepeatableToday),
        (12, 7, 3, 4));
    expect(back.masteryTiers, {2: 3});
    final old = s.toJson()
      ..remove('essence')
      ..remove('masteryTiers');
    final o = GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>);
    expect(o.essence, 0);
    expect(o.masteryTiers, isEmpty);
    final bad = s.toJson()
      ..['essence'] = -50
      ..['masteryTiers'] = {'2': 99, 'x': 1};
    final b = GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>);
    expect(b.essence, 0);
    expect(masteryTier(b.masteryTiers, 2), 5);
  });

  test('essenceProgress: đang có + đã tiêu; từ JSON thiếu/sai = 0', () {
    expect(essenceProgress(essence: 5, tiers: {1: 2, 2: 1}), 5 + 10 + 20 + 10);
    expect(essenceProgressFromJson({}), 0);
    expect(essenceProgressFromJson({'essence': 'x', 'masteryTiers': 3}), 0);
    expect(essenceProgressFromJson({'essence': 4, 'masteryTiers': {'1': 1}}), 14);
  });
}
