/// Bộ trang bị phụ kiện: bảng họ phủ đủ danh mục, điểm/combo/trần, và các điểm nối vào công thức
/// (chạm, thu nhập, offline, giá nâng cấp). Xem PROPOSAL_ACCESSORY_LOADOUT.md.
library;

import 'dart:math';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/accessory_loadout.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nguồn thu đầu tiên (mở ngay từ đầu) — để cấp độ thật sự cho ra thu nhập.
final String _gen = Balance.generators.first.id;

/// Mọi món mà game có thể trao: bộ chính + lễ hội + cửa hàng Hội + cửa hàng VIP.
List<Accessory> get _all => [...accessories, ...limitedAccessories];

/// [n] món (độ hiếm [r], họ [f]) theo thứ tự danh mục.
List<String> _pick(AccessoryFamily f, AccessoryRarity r, int n) {
  final ids = [
    for (final a in _all)
      if (a.rarity == r && accessoryFamilyOf(a.id) == f) a.id,
  ];
  expect(ids.length, greaterThanOrEqualTo(n), reason: 'không đủ món $f/$r');
  return ids.take(n).toList();
}

void main() {
  group('bảng họ', () {
    test('mọi món trong game có ĐÚNG một họ (thêm món mới mà quên gán họ sẽ đỏ ở đây)', () {
      final ids = _all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'id món bị trùng');
      for (final id in ids) {
        expect(accessoryFamilyOf(id), isNotNull, reason: '$id chưa có họ');
      }
    });

    test('mỗi họ có đủ cả 4 độ hiếm (không họ nào bị cụt đầu trên)', () {
      for (final f in AccessoryFamily.values) {
        for (final r in AccessoryRarity.values) {
          expect(_pick(f, r, 1), hasLength(1), reason: '$f thiếu $r');
        }
      }
    });

    test('4 họ cân nhau: lệch tối đa 3 món trong bộ chính cùng độ hiếm', () {
      for (final r in AccessoryRarity.values) {
        final counts = [
          for (final f in AccessoryFamily.values)
            accessories.where((a) => a.rarity == r && accessoryFamilyOf(a.id) == f).length,
        ];
        expect(counts.reduce(max) - counts.reduce(min), lessThanOrEqualTo(1), reason: '$r: $counts');
      }
    });

    test('id lạ (món của bản app mới hơn) không có họ và không làm sập tra cứu', () {
      expect(accessoryFamilyOf('item_from_the_future'), isNull);
      expect(accessoryOrNull('item_from_the_future'), isNull);
    });
  });

  group('loadoutBuffs', () {
    test('không mang gì → không buff', () {
      final b = loadoutBuffs(const []);
      expect(b.isEmpty, isTrue);
      expect(b.tapMultiplier, 1);
      expect(b.incomeMultiplier, 1);
      expect(b.offlineMultiplier, 1);
    });

    test('điểm theo độ hiếm: 1 / 2.5 / 5 / 10', () {
      expect(accessoryPoints(AccessoryRarity.common), 1);
      expect(accessoryPoints(AccessoryRarity.rare), 2.5);
      expect(accessoryPoints(AccessoryRarity.epic), 5);
      expect(accessoryPoints(AccessoryRarity.legendary), 10);
    });

    test('mỗi họ chỉ cho đúng buff của họ đó', () {
      for (final f in AccessoryFamily.values) {
        final b = loadoutBuffs(_pick(f, AccessoryRarity.rare, 1));
        for (final other in AccessoryFamily.values) {
          if (other == f) {
            expect(b.of(other), greaterThan(0), reason: '$f phải có buff');
          } else {
            expect(b.of(other), 0, reason: '$f không được cho buff của $other');
          }
        }
      }
    });

    test('ví dụ trong đề xuất: 2 hiếm + 1 sử thi cùng họ Lấp lánh = +12.5% (combo ×1.25)', () {
      final ids = [
        ..._pick(AccessoryFamily.income, AccessoryRarity.rare, 2),
        ..._pick(AccessoryFamily.income, AccessoryRarity.epic, 1),
      ];
      final b = loadoutBuffs(ids);
      expect(b.income, closeTo(0.125, 1e-9));
      expect(b.combo[AccessoryFamily.income], 1.25);
    });

    test('ví dụ: 1 huyền thoại + 2 sử thi cùng họ = +25%', () {
      final ids = [
        ..._pick(AccessoryFamily.income, AccessoryRarity.legendary, 1),
        ..._pick(AccessoryFamily.income, AccessoryRarity.epic, 2),
      ];
      expect(loadoutBuffs(ids).income, closeTo(0.25, 1e-9));
    });

    test('3 món thường trộn 3 họ: mỗi mặt +1% (đa dạng thì không có combo)', () {
      final ids = [
        ..._pick(AccessoryFamily.tap, AccessoryRarity.common, 1),
        ..._pick(AccessoryFamily.income, AccessoryRarity.common, 1),
        ..._pick(AccessoryFamily.offline, AccessoryRarity.common, 1),
      ];
      final b = loadoutBuffs(ids);
      expect(b.tap, closeTo(0.02, 1e-9));
      expect(b.income, closeTo(0.01, 1e-9));
      expect(b.offline, closeTo(0.02, 1e-9));
      expect(b.combo, isEmpty);
    });

    test('hệ số combo: 1 món ×1, 2 ×1.1, 3 ×1.25, 4+ ×1.5', () {
      expect(loadoutComboMultiplier(0), 1);
      expect(loadoutComboMultiplier(1), 1);
      expect(loadoutComboMultiplier(2), 1.10);
      expect(loadoutComboMultiplier(3), 1.25);
      expect(loadoutComboMultiplier(4), 1.50);
      expect(loadoutComboMultiplier(99), 1.50);
    });

    test('kẹp trần: dù mang rất nhiều món huyền thoại cùng họ', () {
      for (final f in AccessoryFamily.values) {
        final legs = _pick(f, AccessoryRarity.legendary, 4);
        final b = loadoutBuffs(legs);
        final cap = switch (f) {
          AccessoryFamily.tap => Balance.loadoutTapCap,
          AccessoryFamily.income => Balance.loadoutIncomeCap,
          AccessoryFamily.offline => Balance.loadoutOfflineCap,
          AccessoryFamily.discount => Balance.loadoutDiscountCap,
        };
        expect(b.of(f), lessThanOrEqualTo(cap), reason: '$f vượt trần');
      }
      // 4 huyền thoại Lấp lánh: 40 điểm × 1% × 1.5 = 60% → kẹp 40%.
      expect(loadoutBuffs(_pick(AccessoryFamily.income, AccessoryRarity.legendary, 4)).income,
          Balance.loadoutIncomeCap);
      // Danh sách vượt số ô (dữ liệu hỏng): vẫn kẹp trần, không vượt.
      final many = [for (final a in _all) if (accessoryFamilyOf(a.id) == AccessoryFamily.discount) a.id];
      expect(loadoutBuffs(many).discount, Balance.loadoutDiscountCap);
    });

    test('món trùng id chỉ tính một lần; id lạ bị bỏ qua', () {
      final one = _pick(AccessoryFamily.tap, AccessoryRarity.epic, 1).single;
      final b = loadoutBuffs([one, one, one, 'item_from_the_future']);
      expect(b.tap, closeTo(5 * Balance.loadoutTapPerPoint, 1e-9));
      expect(b.combo, isEmpty);
    });

    test('mọi buff hữu hạn và nằm trong [0, trần] với bất kỳ tổ hợp nào', () {
      final rnd = Random(7);
      final ids = _all.map((a) => a.id).toList();
      for (var i = 0; i < 500; i++) {
        final n = rnd.nextInt(9);
        final b = loadoutBuffs([for (var k = 0; k < n; k++) ids[rnd.nextInt(ids.length)]]);
        for (final v in [b.tap, b.income, b.offline, b.discount]) {
          expect(v.isFinite, isTrue);
          expect(v, greaterThanOrEqualTo(0));
        }
        expect(b.tap, lessThanOrEqualTo(Balance.loadoutTapCap));
        expect(b.income, lessThanOrEqualTo(Balance.loadoutIncomeCap));
        expect(b.offline, lessThanOrEqualTo(Balance.loadoutOfflineCap));
        expect(b.discount, lessThanOrEqualTo(Balance.loadoutDiscountCap));
      }
    });
  });

  group('nối vào công thức', () {
    GameState seed(List<String> equipped) =>
        GameState.newGame(nowMillis: 0)..equippedAccessories.addAll(equipped);

    test('chạm: tapGain nhân đúng hệ số họ Nhiệt huyết', () {
      final ids = _pick(AccessoryFamily.tap, AccessoryRarity.epic, 1); // 5 điểm → +10%
      final base = tapGain(seed(const []));
      expect(tapGain(seed(ids)), closeTo(base * 1.10, base * 1e-9));
    });

    test('thu nhập: effectiveIncomePerSecond nhân đúng hệ số họ Lấp lánh', () {
      final plain = seed(const [])..levels[_gen] = 10;
      final ids = _pick(AccessoryFamily.income, AccessoryRarity.epic, 1); // +5%
      final geared = seed(ids)..levels[_gen] = 10;
      final a = effectiveIncomePerSecond(plain, Balance.generators, bonusPerStar: Balance.bonusPerStar);
      final b = effectiveIncomePerSecond(geared, Balance.generators, bonusPerStar: Balance.bonusPerStar);
      expect(a, greaterThan(0));
      expect(b, closeTo(a * 1.05, a * 1e-9));
    });

    test('họ khác không làm đổi thu nhập (Nhiệt huyết chỉ ảnh hưởng chạm)', () {
      final plain = seed(const [])..levels[_gen] = 10;
      final geared = seed(_pick(AccessoryFamily.tap, AccessoryRarity.legendary, 1))..levels[_gen] = 10;
      expect(
        effectiveIncomePerSecond(geared, Balance.generators, bonusPerStar: Balance.bonusPerStar),
        effectiveIncomePerSecond(plain, Balance.generators, bonusPerStar: Balance.bonusPerStar),
      );
    });

    test('offline: tính theo bộ ĐANG mang lúc tính (họ Yên bình), không đụng thu nhập khi chơi', () {
      GameState s(List<String> eq) => seed(eq)
        ..levels[_gen] = 10
        ..lastSeenMillis = 0;
      final ids = _pick(AccessoryFamily.offline, AccessoryRarity.epic, 1); // 5 điểm → +10%
      final plainEarned = applyOfflineEarnings(s(const []), 3600 * 1000);
      final gearedEarned = applyOfflineEarnings(s(ids), 3600 * 1000);
      expect(plainEarned, greaterThan(0));
      expect(gearedEarned, closeTo(plainEarned * 1.10, plainEarned * 1e-9));
    });

    test('giá nâng cấp: giảm cộng chung với Mua sỉ rồi mới kẹp sàn', () {
      final ids = _pick(AccessoryFamily.discount, AccessoryRarity.epic, 1); // 5 × 0.4% = 2%
      final s = seed(ids)..prestigeDiscountLevel = 5; // −15% từ perk
      expect(upgradeCostMultiplierFor(s), closeTo(1 - 0.15 - 0.02, 1e-9));
      expect(upgradeCostMultiplierFor(seed(const [])), 1.0);
    });

    test('giá nâng cấp: không bao giờ thấp hơn sàn dù perk + phụ kiện cộng lại', () {
      final ids = _pick(AccessoryFamily.discount, AccessoryRarity.legendary, 4);
      final s = seed(ids)..prestigeDiscountLevel = 100;
      expect(upgradeCostMultiplierFor(s), Balance.prestigeDiscountFloor);
      expect(upgradeCostMultiplier(100, extraDiscount: 5), Balance.prestigeDiscountFloor);
    });

    test('mua nâng cấp thật sự rẻ hơn khi mang món Tinh tế', () {
      final plain = GameState.newGame(nowMillis: 0)..money = 1e12;
      final geared = GameState.newGame(nowMillis: 0)
        ..money = 1e12
        ..equippedAccessories.addAll(_pick(AccessoryFamily.discount, AccessoryRarity.legendary, 2));
      final id = Balance.generators.first.id;
      expect(buyUpgrade(plain, id), isTrue);
      expect(buyUpgrade(geared, id), isTrue);
      expect(1e12 - geared.money, lessThan(1e12 - plain.money));
    });

    test('save cực lớn (1e300) + bộ tối đa: tiền vẫn hữu hạn, không NaN/Infinity', () {
      final ids = [
        ..._pick(AccessoryFamily.income, AccessoryRarity.legendary, 4),
      ];
      final s = seed(ids)
        ..money = 1e300
        ..levels[_gen] = 1000;
      final inc = effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar);
      expect(inc.isNaN, isFalse);
      expect(tapGain(s).isNaN, isFalse);
      s.lastSeenMillis = 0;
      applyOfflineEarnings(s, 3600 * 1000);
      expect(s.money.isNaN, isFalse);
      expect(s.money, greaterThanOrEqualTo(0));
    });
  });
}
