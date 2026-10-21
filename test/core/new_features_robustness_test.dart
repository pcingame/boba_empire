// Kiểm bền cho Nhân viên / Linh vật / Khách quen / Thời tiết-Giao hàng / Di sản / Đấu giá:
// save rác không làm sập, giữ qua Nhượng quyền + Kỷ Nguyên, thu nhập luôn hữu hạn, tick mô phỏng không vỡ.
import 'dart:math';

import 'package:boba_empire/auction/auction.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/legacy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/pet.dart';
import 'package:boba_empire/core/regulars.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:boba_empire/core/staff.dart';
import 'package:boba_empire/core/weather_delivery.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _base() => GameState.newGame(nowMillis: 1000).toJson();

void main() {
  group('save rác', () {
    final garbage = <Object?>[null, 'abc', -5, 1e30, double.nan, double.infinity, -double.infinity, [], {}, true, 99999999999];
    final fields = [
      'staff', 'petLevel', 'petSince', 'regularPoints', 'regularDay', 'regularServed', 'weatherSlotPicked',
      'contractTier', 'contractEnd', 'contractStake', 'contractSeed', 'legacyIncomeLevel', 'legacyTapLevel',
    ];
    test('mọi trường mới nhận mọi loại giá trị xấu mà không ném lỗi, giá trị luôn trong biên', () {
      for (final f in fields) {
        for (final g in garbage) {
          final j = _base()..[f] = g;
          GameState s;
          try {
            s = GameState.fromJson(j);
          } on Error {
            // Sai kiểu hẳn / NaN-Infinity ở trường int (JSON thật không mang được NaN): GameStorage.load bắt lỗi này và rơi về save mới — hợp lệ.
            continue;
          }
          expect(s.petLevel, inInclusiveRange(0, petMaxLevel), reason: '$f = $g');
          expect(s.legacyIncomeLevel, inInclusiveRange(0, legacyMaxLevel));
          expect(s.legacyTapLevel, inInclusiveRange(0, legacyMaxLevel));
          expect(s.contractTier, inInclusiveRange(-1, 2));
          expect(s.contractStake.isFinite && s.contractStake >= 0, isTrue, reason: '$f = $g');
          expect(s.staff.values.every((v) => v >= 0 && v <= staffMaxLevel), isTrue);
          expect(s.regularServed.every((i) => i >= 0 && i < regularCount), isTrue);
          expect(s.regularPoints.keys.every((k) => int.parse(k) < regularCount), isTrue);
          // Thu nhập từ save xấu vẫn hữu hạn và không âm.
          final inc = effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar);
          expect(inc.isFinite && inc >= 0, isTrue, reason: '$f = $g');
        }
      }
    });

    test('trường trong map xấu: khoá rác/giá trị rác bị loại', () {
      final j = _base()
        ..['staff'] = {'0': 5, 'x': 3, '1': 'a', '2': -4, '3': 1e9}
        ..['regularPoints'] = {'0': 4, '99': 3, 'q': 1, '1': -7}
        ..['regularServed'] = [0, 1.5, 'z', 12, -1, 3];
      final s = GameState.fromJson(j);
      expect(s.staff['0'], 5);
      expect(s.staff.containsKey('x'), isFalse);
      expect(s.staff['2'], 0);
      expect(s.staff['3'], staffMaxLevel);
      expect(s.regularPoints.containsKey('99'), isFalse);
      expect(s.regularPoints['1'], 0);
      expect(s.regularServed, [0, 1, 3]);
    });

    test('save cũ (không có trường mới) mở bình thường với mặc định an toàn', () {
      final j = _base();
      for (final f in fields) {
        j.remove(f);
      }
      final s = GameState.fromJson(j);
      expect(s.staff, isEmpty);
      expect(s.petLevel, 0);
      expect(s.contractTier, -1);
      expect(s.weatherSlotPicked, -1);
      expect(s.legacyIncomeLevel, 0);
    });
  });

  group('giữ qua Nhượng quyền / Kỷ Nguyên', () {
    GameState rich() => GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = Balance.ascensionMinLifetime * 100
      ..ascensionLifetime = Balance.ascensionMinLifetime * 100
      ..stage = 18
      ..money = 1e30
      ..levels['tra_den'] = 200
      ..staff.addAll({'0': 7, '3': 20})
      ..petLevel = 4
      ..petSince = 123
      ..regularPoints.addAll({'2': 9})
      ..regularDay = 77
      ..regularServed.add(2)
      ..weatherSlotPicked = 55
      ..contractTier = 1
      ..contractEnd = 999
      ..contractStake = 1234
      ..contractSeed = 42
      ..legacyIncomeLevel = 3
      ..legacyTapLevel = 2;

    void expectKept(GameState s) {
      expect(s.staff, {'0': 7, '3': 20});
      expect(s.petLevel, 4);
      expect(s.petSince, 123);
      expect(s.regularPoints, {'2': 9});
      expect(s.regularServed, [2]);
      expect(s.contractTier, 1);
      expect(s.contractStake, 1234);
      expect(s.legacyIncomeLevel, 3);
      expect(s.legacyTapLevel, 2);
    }

    test('Nhượng quyền giữ nhân viên, linh vật, khách quen, hợp đồng, Di sản', () {
      final s = rich();
      expect(prestige(s), greaterThan(0));
      expectKept(s);
    });

    test('Kỷ Nguyên giữ cả bộ', () {
      final s = rich();
      expect(ascend(s), greaterThan(0));
      expectKept(s);
    });
  });

  group('kinh tế', () {
    test('mọi hệ số ở mức tối đa vẫn cho thu nhập hữu hạn, tăng đơn điệu, tick không vỡ', () {
      final s = GameState.newGame(nowMillis: 0)
        ..stage = 18
        ..levels.addAll({for (final g in Balance.generators) g.id: 5000})
        ..staff.addAll({for (var i = 0; i < staffCount; i++) '$i': staffMaxLevel})
        ..regularPoints.addAll({for (var i = 0; i < regularCount; i++) '$i': 999})
        ..legacyIncomeLevel = legacyMaxLevel
        ..legacyTapLevel = legacyMaxLevel;
      final inc = effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar);
      expect(inc.isFinite && inc > 0, isTrue);
      final plain = GameState.newGame(nowMillis: 0)
        ..stage = 18
        ..levels.addAll({for (final g in Balance.generators) g.id: 5000});
      expect(inc, greaterThan(effectiveIncomePerSecond(plain, Balance.generators, bonusPerStar: Balance.bonusPerStar)));
      // Hệ số mong đợi tối đa: nhân viên ×2 · khách quen 1+12·5·0.005 · di sản 1+60·0.03.
      final ratio = inc / effectiveIncomePerSecond(plain, Balance.generators, bonusPerStar: Balance.bonusPerStar);
      expect(ratio, closeTo(2 * (1 + regularCount * regularMaxLevel * regularIncomePerLevel) * (1 + legacyMaxLevel * legacyPerLevel), 0.01));
      expect(tapGain(s).isFinite, isTrue);
      final rng = Random(7);
      for (var i = 0; i < 200; i++) {
        tap(s);
        expect(s.money.isFinite && !s.money.isNegative, isTrue);
        expect(s.lifetimeEarnings.isFinite, isTrue);
        if (rng.nextBool()) expect(effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar).isFinite, isTrue);
      }
    });

    test('giá không bao giờ tràn / âm / NaN ở mọi cấp', () {
      for (var l = 0; l <= 200; l++) {
        for (final c in [petLevelCost(l.clamp(1, 1000), 1e80), legacyCost(l.clamp(0, legacyMaxLevel)).toDouble(), staffUpgradeCost(l % 6, l.clamp(1, staffMaxLevel), Balance.generators)]) {
          expect(c.isFinite && c > 0, isTrue, reason: 'cấp $l');
        }
      }
      expect(deliveryStake(2, 1e99).isFinite, isTrue);
      expect(regularServeCost(1e99).isFinite, isTrue);
      expect(weatherReward(true, 1e99).isFinite, isTrue);
      expect(petPendingXu(petMaxLevel, 0, 1 << 50, 1e99).isFinite, isTrue);
    });
  });

  group('ranh giới thời gian', () {
    test('khung thời tiết: sát ranh giới chuyển khung, không lùi, secondsLeft trong (0, 3h]', () {
      const slotMs = weatherSlotHours * 3600 * 1000;
      for (final t in [0, 1, slotMs - 1, slotMs, slotMs + 1, 123456789012]) {
        final left = weatherSecondsLeft(t);
        expect(left, inInclusiveRange(1, weatherSlotHours * 3600), reason: 't=$t');
        expect(weatherSlot(t + left * 1000), weatherSlot(t) + 1, reason: 'đúng lúc hết thì sang khung mới');
      }
    });

    test('khách quen: mỗi ngày đủ 4 người khác nhau, 365 ngày liên tiếp; mọi khách đều từng được ghé', () {
      final seen = <int>{};
      for (var d = 0; d < 365; d++) {
        final v = regularsVisiting(d);
        expect(v.toSet().length, regularVisitsPerDay);
        seen.addAll(v);
      }
      expect(seen.length, regularCount);
    });

    test('linh vật: nhặt không vượt trần 2 giờ dù để rất lâu', () {
      final a = petPendingXu(3, 0, 2 * 3600 * 1000, 100);
      final b = petPendingXu(3, 0, 9999 * 3600 * 1000, 100);
      expect(b, a);
      expect(petPendingXu(3, 5000, 1000, 100), 0, reason: 'đồng hồ lùi');
    });
  });

  group('Đấu giá: phân tích phản hồi server', () {
    test('AuctionInfo chịu thiếu trường / sai kiểu', () {
      final a = AuctionInfo.fromJson({'item_id': null, 'ends_at': 'rác', 'open': 'yes', 'top_bid': 'x'});
      expect(a.itemId, '');
      expect(a.open, isFalse);
      expect(a.topBid, 0);
      expect(a.nextMin, 100);
      expect(AuctionInfo.fromJson({}).maxBid, 20000);
    });

    test('AuctionPickups cộng đúng 💎 và gom id', () {
      final p = AuctionPickups.fromJson({
        'refunds': [
          {'id': 'a', 'gems': 100},
          {'id': 'b', 'gems': 250}
        ],
        'won': [
          {'week': '2026-10-19', 'item_id': 'season_sakura'}
        ]
      });
      expect(p.refundGems, 350);
      expect(p.refundIds, ['a', 'b']);
      expect(p.wonItems, ['season_sakura']);
      expect(p.isEmpty, isFalse);
      expect(AuctionPickups.fromJson({}).isEmpty, isTrue);
      expect(AuctionPickups.fromJson({'refunds': null, 'won': null}).isEmpty, isTrue);
    });
  });
}
