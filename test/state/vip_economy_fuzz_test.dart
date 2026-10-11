import 'dart:convert';
import 'dart:math';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/core/vip_shop.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Khỉ gõ phím" cho TOÀN BỘ kinh tế VIP/Hội/mua hàng mới (EXP, quà theo kỳ, Xu VIP, cửa hàng VIP,
/// ưu đãi hôm nay, danh hiệu, thưởng hội, quà tặng, thưởng mua lần đầu, mời bạn) với đồng hồ nhảy
/// tiến/lùi lung tung và đầu vào bậy (id lạ, số âm, vượt trần). Chỉ cần: không ném lỗi, tiền tệ
/// không âm/NaN, các trần giữ nguyên, và lưu → tải lại giữ nguyên.
const _day = 24 * 60 * 60 * 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final seed in [11, 12, 13, 14, 15, 16]) {
    test('khỉ gõ phím kinh tế VIP seed=$seed: bất biến giữ nguyên', () async {
      final rnd = Random(seed);
      var now = 100 * _day + 1000;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
          GameState.newGame(nowMillis: now)
            ..tutorialSeen = true
            ..stage = 3
            ..lifetimeEarnings = 1e12
            ..levels['tra_den'] = 40
            ..gems = 2000
            ..guildJoined = true,
          nowMillis: now);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      final ctrl = c.read(gameControllerProvider.notifier);

      var lastExp = 0;
      var lastLevel = 0;
      final packIds = ['boba_gems_small', 'boba_gems_mega', 'x'];

      for (var i = 0; i < 600; i++) {
        switch (rnd.nextInt(5)) {
          case 0:
            now += rnd.nextInt(3 * _day);
          case 1:
            now -= rnd.nextInt(2 * _day); // lùi giờ
          case 2:
            now += rnd.nextInt(40 * _day); // qua tuần/tháng
          default:
            now += rnd.nextInt(60000);
        }
        if (now < 0) now = 1000;

        switch (rnd.nextInt(17)) {
          case 0:
            ctrl.addVipExp(rnd.nextInt(30000) - 500); // gồm số âm/0
          case 1:
            ctrl.buyVipExp();
          case 2:
            ctrl.claimTopupTier(rnd.nextInt(14) - 2); // gồm chỉ số sai
          case 3:
            ctrl.claimVipBenefit(VipPeriod.values[rnd.nextInt(3)]);
          case 4:
            final ids = [...vipShopItems.map((e) => e.id), 'id_la', ''];
            ctrl.buyVipShopItem(ids[rnd.nextInt(ids.length)]);
          case 5:
            ctrl.buyDailyDeal();
          case 6:
            ctrl.setVipTitle(rnd.nextInt(16) - 3);
          case 7:
            ctrl.applyGuildVipBonus(rnd.nextInt(120) - 20);
          case 8:
            ctrl.setGuildJoined(rnd.nextBool());
          case 9:
            ctrl.chargeGuildGift(rnd.nextInt(80) - 10);
          case 10:
            ctrl.grantGuildGift(rnd.nextInt(80) - 10);
          case 11:
            ctrl.grantGuildBossGems(rnd.nextInt(400) - 50);
          case 12:
            ctrl.grantReferralGems(rnd.nextInt(300) - 50);
          case 13:
            ctrl.grantGemsPurchase(
                [100.0, 600.0, 10000.0][rnd.nextInt(3)], packId: packIds[rnd.nextInt(3)]);
          case 14:
            ctrl.chargeGuildCreation();
          case 15:
            ctrl.markReferralRedeemed();
            ctrl.markReferralStageSent();
          default:
            ctrl.tapCup();
        }

        final s = c.read(gameControllerProvider);
        expect(s.gems.isFinite && s.gems >= 0, isTrue, reason: 'gems=${s.gems} @$i');
        expect(s.money.isFinite && s.money >= 0, isTrue, reason: 'money=${s.money} @$i');
        expect(s.vipCoins >= 0, isTrue, reason: 'vipCoins=${s.vipCoins} @$i');
        // EXP và cấp VIP không bao giờ giảm.
        expect(s.vipExp, greaterThanOrEqualTo(lastExp), reason: '@$i');
        expect(topupVipLevel(s.vipExp), greaterThanOrEqualTo(lastLevel), reason: '@$i');
        lastExp = s.vipExp;
        lastLevel = topupVipLevel(s.vipExp);
        // EXP mua bằng 💎: không vượt trần, không vượt tổng EXP.
        expect(s.vipExpFromGems, lessThanOrEqualTo(vipExpGemCap), reason: '@$i');
        expect(s.vipExpFromGems, lessThanOrEqualTo(s.vipExp), reason: '@$i');
        // Bậc đã nhận: hợp lệ, không trùng, và đã đủ EXP.
        expect(s.topupClaimed.toSet().length, s.topupClaimed.length, reason: '@$i');
        for (final idx in s.topupClaimed) {
          expect(idx, inInclusiveRange(0, topupTiers.length - 1), reason: '@$i');
          expect(s.vipExp, greaterThanOrEqualTo(topupTiers[idx].exp), reason: '@$i');
        }
        // Danh hiệu chọn: -1, 0 hoặc ≤ cấp hiện tại.
        expect(s.vipTitleChoice, inInclusiveRange(-1, topupVipLevel(s.vipExp)), reason: '@$i');
        // Thưởng VIP hội: trong trần; chỉ có ý nghĩa khi ở hội (rời hội → 0 ngay).
        expect(s.guildVipBonusPct, inInclusiveRange(0, guildVipBonusCap), reason: '@$i');
        if (!s.guildJoined) expect(s.guildVipBonusPct, 0, reason: '@$i');
        // Cửa hàng VIP: món đã có phải thuộc danh mục, không trùng, và đủ cấp (cấp không giảm).
        expect(s.ownedLimited.toSet().length, s.ownedLimited.length, reason: '@$i');
        for (final id in s.ownedLimited) {
          accessoryById(id); // tra được
          final item = vipShopItems.where((e) => e.id == id).firstOrNull;
          if (item != null) {
            expect(topupVipLevel(s.vipExp), greaterThanOrEqualTo(item.minLevel), reason: '$id @$i');
          }
        }
        // Thưởng mua lần đầu: id không trùng.
        expect(s.firstBuyClaimed.toSet().length, s.firstBuyClaimed.length, reason: '@$i');
      }

      // Lưu → tải lại giữ nguyên mọi trường mới.
      final before = c.read(gameControllerProvider);
      await ctrl.saveNow();
      final back = GameStorage(prefs).load();
      expect(back, isNotNull);
      expect(back!.vipExp, before.vipExp);
      expect(back.vipCoins, before.vipCoins);
      expect(back.vipTitleChoice, before.vipTitleChoice);
      expect(back.dealClaimedDay, before.dealClaimedDay);
      expect(back.guildVipBonusPct, before.guildVipBonusPct);
      expect(back.firstBuyClaimed, before.firstBuyClaimed);
      expect(back.topupClaimed, before.topupClaimed);
      expect(back.ownedLimited, before.ownedLimited);
      expect(back.referralRedeemed, before.referralRedeemed);
      expect(back.referralStageSent, before.referralStageSent);
    });
  }

  test('save toàn trường mới ở giá trị cực đoan: tải/lưu lại không crash và giữ nguyên', () {
    final g = GameState.newGame(nowMillis: 0)
      ..vipExp = 1 << 40
      ..vipCoins = 1 << 40
      ..vipExpFromGems = 1 << 40
      ..vipTitleChoice = 999
      ..dealClaimedDay = 1 << 30
      ..guildVipBonusPct = 9999
      ..firstBuyClaimed.addAll(['a', 'b'])
      ..topupClaimed.addAll([0, 1, 2]);
    final back = GameState.fromJson(g.toJson());
    expect(back.vipExp, g.vipExp);
    expect(back.vipCoins, g.vipCoins);
    expect(back.vipTitleChoice, 999); // lưu nguyên; setVipTitle/giao diện mới là chỗ kẹp
    expect(back.guildVipBonusPct, 9999);
    expect(back.firstBuyClaimed, ['a', 'b']);
  });

  test('save hỏng ở từng trường VIP/Hội mới (sai kiểu): tải không ném lỗi, game vẫn mở được',
      () async {
    final bad = <String, Object?>{
      'vipExp': 'x',
      'vipCoins': null,
      'vipTitleChoice': 'a',
      'topupClaimed': 'khong-phai-list',
      'firstBuyClaimed': 5,
      'guildVipBonusPct': 'abc',
      'dealClaimedDay': {},
      'ownedLimited': 'cung-sai',
      'referralRedeemed': 'yes',
    };
    for (final e in bad.entries) {
      final json = GameState.newGame(nowMillis: 0).toJson()..[e.key] = e.value;
      SharedPreferences.setMockInitialValues({
        GameStorage.saveKey: jsonEncode({'state': json}),
      });
      final prefs = await SharedPreferences.getInstance();
      // GameStorage.load nuốt lỗi → null (ván mới); quan trọng là KHÔNG ném.
      expect(() => GameStorage(prefs).load(), returnsNormally, reason: e.key);
      // Controller khởi động được trên save hỏng và có trạng thái dùng được.
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 5000),
      ]);
      final s = c.read(gameControllerProvider);
      expect(s.gems.isFinite, isTrue, reason: e.key);
      expect(s.vipCoins, greaterThanOrEqualTo(0), reason: e.key);
      c.dispose();
    }
  });
}
