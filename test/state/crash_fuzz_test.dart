import 'dart:math';

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chuỗi hành động ngẫu nhiên (khỉ gõ phím) lên các hàm MỚI của controller, đồng
/// hồ nhảy tới/lui lung tung (qua ngày, qua dịp lễ, lùi giờ), rồi kiểm các bất biến.
/// Chỉ cần không ném lỗi + các bất biến sau giữ nguyên.
const _day = 24 * 60 * 60 * 1000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final seed in [1, 2, 3, 4, 5]) {
    test('khỉ gõ phím seed=$seed: không crash, bất biến giữ nguyên', () async {
      final rnd = Random(seed);
      var now = 100 * _day + 1000;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
          GameState.newGame(nowMillis: now)
            ..tutorialSeen = true
            ..stage = 3
            ..lifetimeEarnings = 1e12
            ..levels['tra_den'] = 50
            ..gems = 300
            ..dailyStreak = 4
            ..lastDailyDay = 98,
          nowMillis: now);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(c.dispose);
      final ctrl = c.read(gameControllerProvider.notifier) as dynamic;
      final festivalDays = [
        for (final f in festivals) f.start.millisecondsSinceEpoch ~/ _day
      ];

      for (var i = 0; i < 400; i++) {
        // nhảy đồng hồ: tiến vài giờ/ngày, nhảy vào đúng dịp lễ, hoặc LÙI giờ
        switch (rnd.nextInt(5)) {
          case 0:
            now += rnd.nextInt(3 * _day);
          case 1:
            now = (festivalDays[rnd.nextInt(festivalDays.length)] +
                    rnd.nextInt(8)) *
                    _day +
                rnd.nextInt(_day);
          case 2:
            now -= rnd.nextInt(2 * _day); // lùi giờ
          default:
            now += rnd.nextInt(60000);
        }
        if (now < 0) now = 1000;

        switch (rnd.nextInt(11)) {
          case 0:
            ctrl.claimDailyReward(
                restore: rnd.nextBool(), payGems: rnd.nextBool());
          case 1:
            ctrl.buyAccessoryPack(AccessoryPack.values[rnd.nextInt(3)]);
          case 2:
            ctrl.buyFestivalPack();
          case 3:
            ctrl.spinAccessoryWheel(withAd: rnd.nextBool());
          case 4:
            ctrl.claimAdAccessoryDrop();
          case 5:
            ctrl.claimDailyBonus();
          case 6:
            ctrl.doPrestige(adBonus: rnd.nextBool());
          case 7:
            final all = [...accessories, ...limitedAccessories];
            ctrl.toggleEquippedAccessory(all[rnd.nextInt(all.length)].id);
          case 8:
            ctrl.tapCup();
          case 9:
            ctrl.toggleEquippedAccessory('id_khong_ton_tai');
          default:
            ctrl.claimDoubleOffline();
        }

        final s = c.read(gameControllerProvider);
        expect(s.gems.isFinite && s.gems >= 0, isTrue, reason: 'gems=${s.gems} @$i');
        expect(s.money.isFinite && s.money >= 0, isTrue, reason: 'money=${s.money} @$i');
        expect(s.ownedLimited.toSet().length, s.ownedLimited.length); // không trùng
        expect(s.ownedAccessories.toSet().length, s.ownedAccessories.length);
        expect(s.accessoryAdSpinsLeft, inInclusiveRange(0, 10));
        expect(
            s.equippedAccessories.length,
            lessThanOrEqualTo(maxEquippedFor(vip: true)));
        // mọi id đang sở hữu tra được trong danh mục
        for (final id in [...s.ownedAccessories, ...s.ownedLimited]) {
          accessoryById(id);
        }
        for (final id in s.equippedAccessories) {
          expect(s.ownedAccessories.contains(id) || s.ownedLimited.contains(id),
              isTrue, reason: 'trưng bày món không sở hữu: $id');
        }
      }
      // lưu → tải lại giữ nguyên
      ctrl.saveNow();
    });
  }

  test('save tương lai: id lạ trong ownedLimited/equipped không làm crash', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 5000)
          ..ownedLimited.addAll(['santa', 'mon_cua_ban_tuong_lai'])
          ..equippedAccessories.addAll(['santa', 'mon_cua_ban_tuong_lai']),
        nowMillis: 5000);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 5000),
    ]);
    addTearDown(c.dispose);
    final s = c.read(gameControllerProvider);
    expect(s.ownedLimited, contains('santa'));
    // mua gói lễ hội ở bản hiện tại vẫn chạy bình thường
    (c.read(gameControllerProvider.notifier) as dynamic).buyFestivalPack();
  });

  test('save hỏng ở trường mới: rơi về ván mới thay vì ném lỗi', () async {
    SharedPreferences.setMockInitialValues({
      GameStorage.saveKey: '{"state":{"ownedLimited":"khong-phai-list"}}',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 5000),
    ]);
    addTearDown(c.dispose);
    expect(c.read(gameControllerProvider).ownedLimited, isEmpty);
  });
}
