import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/daily_item.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/season.dart';
import 'package:flutter_test/flutter_test.dart';

const _day = 24 * 60 * 60 * 1000;
GameState _g() => GameState.newGame(nowMillis: 0);

void main() {
  group('Thẻ Mùa', () {
    test('mùa 28 ngày: id đổi đúng ranh giới, ngày còn lại 28..1', () {
      expect(seasonIdFor(0), 0);
      expect(seasonIdFor(27 * _day + 5), 0);
      expect(seasonIdFor(28 * _day), 1);
      expect(seasonDaysLeft(28 * _day), 28);
      expect(seasonDaysLeft(55 * _day), 1);
    });

    test('XP: cộng theo nguồn, trần 150/ngày, sang ngày reset trần', () {
      final s = _g();
      for (var i = 0; i < 40; i++) {
        seasonEarn(s, SeasonSource.dungeon, 28 * _day); // 40 XP mỗi lần
      }
      expect(s.seasonXp, seasonXpDailyCap);
      expect(seasonEarn(s, SeasonSource.login, 28 * _day), 0);
      expect(seasonEarn(s, SeasonSource.login, 29 * _day), 10);
      expect(s.seasonXp, seasonXpDailyCap + 10);
      // Còn dư chỗ ít hơn một lần: chỉ nhận phần còn lại.
      final t = _g();
      seasonEarn(t, SeasonSource.weeklyChest, 28 * _day); // 60
      seasonEarn(t, SeasonSource.weeklyChest, 28 * _day); // 120
      expect(seasonEarn(t, SeasonSource.weeklyChest, 28 * _day), 30);
    });

    test('bậc: 100 XP/bậc, kẹp ở 30', () {
      final s = _g()..seasonXp = 250;
      expect(seasonTier(s), 2);
      s.seasonXp = 99999;
      expect(seasonTier(s), seasonTiers);
    });

    test('sang mùa mới: xoá XP, quyền Cao cấp, thưởng đã nhận, bộ đếm ngày', () {
      final s = _g();
      seasonSync(s, 0);
      s
        ..seasonXp = 900
        ..seasonPremium = true
        ..seasonFreeClaimed.add(3)
        ..seasonPremiumClaimed.add(3)
        ..seasonXpToday = 100
        ..seasonXpDay = 5;
      seasonSync(s, 10 * _day);
      expect(s.seasonXp, 900, reason: 'cùng mùa: giữ nguyên');
      seasonSync(s, 28 * _day);
      expect([s.seasonXp, s.seasonPremium, s.seasonFreeClaimed, s.seasonPremiumClaimed, s.seasonXpToday],
          [0, false, isEmpty, isEmpty, 0]);
      expect(s.seasonId, 1);
    });

    test('nhận thưởng: cần đủ bậc, đường Cao cấp cần mua, không nhận hai lần', () {
      final s = _g()..seasonXp = 300;
      expect(seasonCanClaim(s, 3, premium: false), isTrue);
      expect(seasonCanClaim(s, 4, premium: false), isFalse);
      expect(seasonCanClaim(s, 3, premium: true), isFalse);
      s.seasonPremium = true;
      expect(seasonCanClaim(s, 3, premium: true), isTrue);
      s.seasonFreeClaimed.add(3);
      expect(seasonCanClaim(s, 3, premium: false), isFalse);
      expect(seasonCanClaim(s, 0, premium: false), isFalse);
      expect(seasonCanClaim(s, 31, premium: true), isFalse);
      expect(seasonClaimable(s), 3 + 3 - 1);
    });

    test('bảng thưởng: Cao cấp trả 💎 ÍT HƠN giá mua; bậc cuối Cao cấp = món độc quyền; không số âm', () {
      var premium = 0, free = 0;
      for (var t = 1; t <= seasonTiers; t++) {
        final p = seasonPremiumReward(t), f = seasonFreeReward(t);
        premium += p.gems;
        free += f.gems;
        expect([p.gems, p.essence, f.gems, f.essence].every((v) => v >= 0), isTrue);
        expect(p.gems + p.essence + (p.accessory == null ? 0 : 1), greaterThan(0), reason: 'bậc Cao cấp $t có thưởng');
      }
      expect(premium, lessThan(seasonPremiumGems));
      expect(free, 50 + 29 * 5);
      expect(seasonPremiumReward(seasonTiers).exclusive, isTrue);
      expect(seasonFreeReward(20).exclusive, isTrue);
      expect(seasonFreeReward(seasonTiers).accessory, AccessoryRarity.epic);
    });

    test('save: round-trip; save cũ = mặc định; dữ liệu hỏng được dọn', () {
      final s = _g()
        ..seasonId = 2
        ..seasonXp = 777
        ..seasonPremium = true
        ..seasonFreeClaimed.addAll([2, 1])
        ..seasonPremiumClaimed.add(5)
        ..dailyItemDay = 9;
      final r = GameState.fromJson(s.toJson());
      expect([r.seasonId, r.seasonXp, r.seasonPremium, r.dailyItemDay], [2, 777, true, 9]);
      expect(r.seasonFreeClaimed, [1, 2], reason: 'sắp xếp khi nạp');
      expect(r.seasonPremiumClaimed, [5]);
      final old = s.toJson()
        ..remove('seasonXp')
        ..remove('seasonFreeClaimed')
        ..remove('dailyItemDay');
      final o = GameState.fromJson(old);
      expect([o.seasonXp, o.seasonFreeClaimed, o.dailyItemDay], [0, isEmpty, 0]);
      final bad = s.toJson()
        ..['seasonXp'] = -50
        ..['seasonFreeClaimed'] = [0, 31, 7, 7, 'x', null, 2.5]
        ..['seasonPremiumClaimed'] = 'nope';
      final b = GameState.fromJson(bad);
      expect(b.seasonXp, 0);
      expect(b.seasonFreeClaimed, [2, 7]);
      expect(b.seasonPremiumClaimed, isEmpty);
    });
  });

  group('Món của ngày', () {
    test('xác định theo ngày, đúng độ hiếm theo chu kỳ 7 ngày', () {
      for (var d = 100; d < 114; d++) {
        final a = dailyItemFor(d, {}), b = dailyItemFor(d, {});
        expect(a.id, b.id);
        expect(a.rarity, dailyItemRarityCycle[d % 7]);
      }
      expect({for (var d = 100; d < 130; d++) dailyItemFor(d, {}).id}.length, greaterThan(15), reason: 'xoay vòng nhiều món');
    });

    test('ưu tiên món CHƯA CÓ; có hết thì lấy món đầu (bản dư)', () {
      final first = dailyItemFor(200, {});
      final second = dailyItemFor(200, {first.id});
      expect(second.id, isNot(first.id));
      expect(second.rarity, first.rarity);
      final all = {for (final a in accessories) a.id};
      expect(dailyItemFor(200, all).id, first.id);
    });

    test('giá tăng theo độ hiếm và cao hơn gói cùng độ hiếm', () {
      expect(dailyItemPrice(AccessoryRarity.common), lessThan(dailyItemPrice(AccessoryRarity.rare)));
      expect(dailyItemPrice(AccessoryRarity.rare), lessThan(dailyItemPrice(AccessoryRarity.epic)));
      expect(dailyItemPrice(AccessoryRarity.epic), lessThan(dailyItemPrice(AccessoryRarity.legendary)));
      expect(dailyItemPrice(AccessoryRarity.rare), greaterThan(AccessoryPack.rare.baseGems));
      expect(dailyItemPrice(AccessoryRarity.epic), greaterThan(AccessoryPack.epic.baseGems));
    });
  });
}
