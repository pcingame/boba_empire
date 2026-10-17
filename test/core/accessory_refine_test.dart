/// Tinh luyện phụ kiện: giá/hệ số, mọi nhánh thất bại không đổi gì, điểm tăng nhưng TRẦN HỌ KHÔNG ĐỔI,
/// giữ qua Nhượng quyền/Kỷ Nguyên, save cũ/hỏng, tiến độ so cloud. Xem PROPOSAL_ACCESSORY_REFINE.md.
library;

import 'dart:convert';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/accessory_loadout.dart';
import 'package:boba_empire/core/accessory_refine.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/essence.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

String _id(AccessoryFamily f, AccessoryRarity r, [int skip = 0]) => [
      for (final a in [...accessories, ...limitedAccessories])
        if (a.rarity == r && accessoryFamilyOf(a.id) == f) a.id,
    ][skip];

GameState _g(String id, {int spares = 0, int essence = 0}) => GameState.newGame(nowMillis: 0)
  ..ownedAccessories.add(id)
  ..accessorySpares[id] = spares
  ..essence = essence;

void main() {
  deepTests();
  final rare = _id(AccessoryFamily.income, AccessoryRarity.rare);

  test('giá 1/2/3 bản dư + 15/40/100 🧪; đầy cấp thì null; hệ số 1 → 1.75', () {
    expect([for (var l = 0; l < 3; l++) refineNextCost(l)!.spares], [1, 2, 3]);
    expect([for (var l = 0; l < 3; l++) refineNextCost(l)!.essence], [15, 40, 100]);
    expect(refineNextCost(3), isNull);
    expect(refineNextCost(-1), isNull);
    expect(refineMultiplier({rare: 3}, rare), closeTo(1.75, 1e-12));
    expect(refineMultiplier({}, rare), 1);
    expect(refineMultiplier({rare: 99}, rare), closeTo(1.75, 1e-12), reason: 'cấp lạ bị kẹp');
    expect(refineMultiplier({rare: -2}, rare), 1);
  });

  test('tryRefine: đi hết 3 cấp, trừ đúng bản dư + 🧪, xoá hẳn khoá bản dư khi về 0', () {
    final s = _g(rare, spares: 6, essence: 155);
    expect(tryRefine(s, rare), RefineResult.ok);
    expect((s.accessorySpares[rare], s.essence, s.refineLevels[rare]), (5, 140, 1));
    expect(tryRefine(s, rare), RefineResult.ok);
    expect((s.accessorySpares[rare], s.essence, s.refineLevels[rare]), (3, 100, 2));
    expect(tryRefine(s, rare), RefineResult.ok);
    expect(s.accessorySpares.containsKey(rare), isFalse);
    expect((s.essence, s.refineLevels[rare]), (0, 3));
    expect(tryRefine(s, rare), RefineResult.maxed);
  });

  test('thất bại không đổi gì: thiếu bản dư, thiếu 🧪, chưa sở hữu, id lạ', () {
    final s = _g(rare, spares: 0, essence: 1000);
    expect(tryRefine(s, rare), RefineResult.notEnoughSpares);
    s
      ..accessorySpares[rare] = 5
      ..essence = 14;
    expect(tryRefine(s, rare), RefineResult.notEnoughEssence);
    expect((s.accessorySpares[rare], s.essence), (5, 14));
    expect(s.refineLevels, isEmpty);
    final other = _id(AccessoryFamily.tap, AccessoryRarity.rare);
    s.accessorySpares[other] = 9;
    expect(tryRefine(s, other), RefineResult.notOwned);
    expect(tryRefine(s, 'item_from_the_future'), RefineResult.unknown);
    expect(s.accessorySpares[other], 9);
  });

  test('tinh luyện tăng điểm (×1.25/×1.5/×1.75) nhưng TRẦN HỌ KHÔNG ĐỔI', () {
    final one = loadoutBuffs([rare]).income;
    for (var l = 1; l <= 3; l++) {
      expect(loadoutBuffs([rare], refine: {rare: l}).income, closeTo(one * (1 + 0.25 * l), 1e-12));
    }
    // 4 món huyền thoại đã chạm trần: tinh luyện thêm không vượt trần.
    final legs = [for (var i = 0; i < 4; i++) _id(AccessoryFamily.income, AccessoryRarity.legendary, i)];
    expect(loadoutBuffs(legs).income, Balance.loadoutIncomeCap);
    expect(loadoutBuffs(legs, refine: {for (final id in legs) id: 3}).income, Balance.loadoutIncomeCap);
    // Mọi họ: dù tinh luyện tối đa mọi món, không họ nào vượt trần.
    final all = [...accessories, ...limitedAccessories];
    final ids = [for (final a in all) a.id];
    final b = loadoutBuffs(ids.take(4), refine: {for (final id in ids) id: 3});
    expect(b.tap, lessThanOrEqualTo(Balance.loadoutTapCap));
    expect(b.income, lessThanOrEqualTo(Balance.loadoutIncomeCap));
    expect(b.offline, lessThanOrEqualTo(Balance.loadoutOfflineCap));
    expect(b.discount, lessThanOrEqualTo(Balance.loadoutDiscountCap));
  });

  test('giữ qua Nhượng quyền và Kỷ Nguyên; hữu hạn với save cực lớn', () {
    final s = _g(rare, spares: 1, essence: 15)
      ..lifetimeEarnings = 1e300
      ..money = 1e300;
    tryRefine(s, rare);
    prestige(s);
    expect(s.refineLevels[rare], 1);
    ascend(s);
    expect(s.refineLevels[rare], 1);
  });

  test('save: round-trip, save cũ = rỗng, cấp hỏng bị kẹp / bỏ', () {
    final s = _g(rare)..refineLevels[rare] = 2;
    final back = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.refineLevels, {rare: 2});
    final old = s.toJson()..remove('refineLevels');
    expect(GameState.fromJson(jsonDecode(jsonEncode(old)) as Map<String, dynamic>).refineLevels, isEmpty);
    final bad = s.toJson()..['refineLevels'] = {rare: 99, 'x': 'oops', 'y': 0, 'z': -3};
    final b = GameState.fromJson(jsonDecode(jsonEncode(bad)) as Map<String, dynamic>);
    expect(b.refineLevels, {rare: 3});
    final worse = s.toJson()..['refineLevels'] = 'not a map';
    expect(GameState.fromJson(jsonDecode(jsonEncode(worse)) as Map<String, dynamic>).refineLevels, isEmpty);
  });

  test('tiến độ so cloud tính cả 🧪 đã đổ vào tinh luyện', () {
    expect(refineEssenceSpent({rare: 3}), 155);
    expect(refineEssenceSpent({rare: 1, 'b': 2}), 15 + 15 + 40);
    expect(refineEssenceSpent({rare: 99}), 155);
    expect(essenceProgressFromJson({'essence': 5, 'refineLevels': {rare: 2}}), 5 + 55);
    expect(essenceProgressFromJson({'refineLevels': 7}), 0);
  });

  test('chữ ký cấp: ổn định theo giá trị, parse lại đúng', () {
    expect(refineSignature({}), '');
    final m = {'b': 2, 'a': 1, 'c': 0};
    expect(refineSignature(m), 'a=1,b=2');
    expect(refineFromSignature('a=1,b=2'), {'a': 1, 'b': 2});
    expect(refineFromSignature(''), isEmpty);
  });
}

// ===== Kiểm sâu hơn: nối vào công thức kinh tế thật + ngẫu nhiên =====
void deepTests() {
  final rare = _id(AccessoryFamily.income, AccessoryRarity.rare);
  final incomeItem = _id(AccessoryFamily.income, AccessoryRarity.rare);
  final tapItem = _id(AccessoryFamily.tap, AccessoryRarity.rare);
  final offItem = _id(AccessoryFamily.offline, AccessoryRarity.rare);
  final discItem = _id(AccessoryFamily.discount, AccessoryRarity.rare);
  final gen = Balance.generators.first;

  GameState base(String id, {int level = 0}) {
    final s = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.add(id)
      ..equippedAccessories.add(id)
      ..levels[gen.id] = 25
      ..money = 1e12;
    if (level > 0) s.refineLevels[id] = level;
    return s;
  }

  test('thu nhập thật: cấp tinh luyện nhân đúng phần BUFF của họ ✨ (không nhân cả thu nhập)', () {
    final i0 = effectiveIncomePerSecond(base(incomeItem), Balance.generators, bonusPerStar: Balance.bonusPerStar);
    final i3 = effectiveIncomePerSecond(base(incomeItem, level: 3), Balance.generators, bonusPerStar: Balance.bonusPerStar);
    final noItem = effectiveIncomePerSecond(
        GameState.newGame(nowMillis: 0)..levels[gen.id] = 25, Balance.generators, bonusPerStar: Balance.bonusPerStar);
    final buff0 = i0 / noItem - 1;
    final buff3 = i3 / noItem - 1;
    expect(buff0, closeTo(loadoutBuffs([incomeItem]).income, 1e-9));
    expect(buff3, closeTo(buff0 * 1.75, 1e-9));
    expect(buff3, lessThanOrEqualTo(Balance.loadoutIncomeCap));
  });

  test('chạm / offline / giá nâng cấp đều theo cấp tinh luyện của họ tương ứng', () {
    expect(tapGain(base(tapItem, level: 3)), greaterThan(tapGain(base(tapItem))));
    expect(tapGain(base(incomeItem, level: 3)), closeTo(tapGain(base(incomeItem)), 1e-9),
        reason: 'tinh luyện món họ ✨ không đổi giá trị chạm');
    final off0 = base(offItem)..lastSeenMillis = 0;
    final off3 = base(offItem, level: 3)..lastSeenMillis = 0;
    final e0 = applyOfflineEarnings(off0, 3600 * 1000);
    final e3 = applyOfflineEarnings(off3, 3600 * 1000);
    expect(e3, greaterThan(e0));
    expect(upgradeCostMultiplierFor(base(discItem, level: 3)), lessThan(upgradeCostMultiplierFor(base(discItem))));
  });

  test('NGẪU NHIÊN: chuỗi thao tác bất kỳ giữ bất biến (không âm, cấp 0–3, buff ≤ trần)', () {
    final rnd = _Rnd(7);
    final ids = [for (final a in accessories.take(30)) a.id];
    final s = GameState.newGame(nowMillis: 0);
    for (final id in ids) {
      s.ownedAccessories.add(id);
    }
    for (var step = 0; step < 4000; step++) {
      final id = ids[rnd.next(ids.length)];
      switch (rnd.next(3)) {
        case 0:
          s.accessorySpares[id] = (s.accessorySpares[id] ?? 0) + rnd.next(3);
        case 1:
          s.essence += rnd.next(60);
        default:
          final before = (s.essence, s.accessorySpares[id] ?? 0, refineLevel(s.refineLevels, id));
          final r = tryRefine(s, id);
          if (r != RefineResult.ok) {
            expect((s.essence, s.accessorySpares[id] ?? 0, refineLevel(s.refineLevels, id)), before,
                reason: 'thất bại ($r) phải không đổi gì');
          }
      }
      expect(s.essence, greaterThanOrEqualTo(0));
      for (final v in s.accessorySpares.values) {
        expect(v, greaterThanOrEqualTo(0));
      }
      for (final v in s.refineLevels.values) {
        expect(v, inInclusiveRange(1, 3));
      }
    }
    final b = loadoutBuffs(ids.take(5), refine: s.refineLevels);
    expect(b.tap, lessThanOrEqualTo(Balance.loadoutTapCap));
    expect(b.income, lessThanOrEqualTo(Balance.loadoutIncomeCap));
    expect(b.offline, lessThanOrEqualTo(Balance.loadoutOfflineCap));
    expect(b.discount, lessThanOrEqualTo(Balance.loadoutDiscountCap));
  });

  test('bảo toàn: tổng 🧪 đã tiêu = giá đúng các cấp đã đạt; bản dư đã tiêu = 1+2+3 cho cấp 3', () {
    final s = _g(rare, spares: 10, essence: 500);
    while (tryRefine(s, rare) == RefineResult.ok) {}
    expect(500 - s.essence, refineEssenceSpent(s.refineLevels));
    expect(10 - (s.accessorySpares[rare] ?? 0), 6);
  });
}

/// Bộ sinh số giả ngẫu nhiên xác định (kết quả test lặp lại được).
class _Rnd {
  _Rnd(this._s);
  int _s;
  int next(int n) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s % n;
  }
}
