/// Thẻ Mùa + Món của ngày qua GameController: XP từ hoạt động có trần, mua Cao cấp, nhận bậc, mua món.
library;

import 'package:boba_empire/core/daily_item.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/season.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

Future<(ProviderContainer, GameController, List<int>)> _setup(GameState seed, {int day = 56}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: day * _day);
  final clock = [day * _day + 1000];
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => clock[0]),
  ]);
  addTearDown(c.dispose);
  return (c, c.read(gameControllerProvider.notifier), clock);
}

void main() {
  test('hoạt động cộng XP; trần ngày; thẻ cũ tự reset khi sang mùa mới', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..seasonId = 1
      ..seasonXp = 500
      ..seasonPremium = true;
    final (c, ctrl, clock) = await _setup(seed); // ngày 56 = mùa 2
    expect(c.read(gameControllerProvider).seasonXp, 0, reason: 'mùa 1 → mùa 2: reset');
    expect(c.read(gameControllerProvider).seasonPremium, isFalse);
    ctrl.grantArenaReward(1);
    expect(c.read(gameControllerProvider).seasonXp, SeasonSource.arena.xp);
    for (var i = 0; i < 30; i++) {
      ctrl.completeRecipeSession(anyCounted: true);
    }
    expect(c.read(gameControllerProvider).seasonXp, seasonXpDailyCap, reason: 'trần/ngày');
    ctrl.completeRecipeSession(anyCounted: false);
    expect(c.read(gameControllerProvider).seasonXp, seasonXpDailyCap);
    clock[0] += _day;
    ctrl.grantArenaReward(1);
    expect(c.read(gameControllerProvider).seasonXp, seasonXpDailyCap + SeasonSource.arena.xp, reason: 'ngày mới: trần reset');
  });

  test('mua Cao cấp: thiếu 💎 → false; đủ → trừ 💎, mua lại bị chặn', () async {
    final seed = GameState.newGame(nowMillis: 0)..gems = seasonPremiumGems - 1.0;
    final (c, ctrl, _) = await _setup(seed);
    expect(ctrl.buySeasonPremium(), isFalse);
    expect(c.read(gameControllerProvider).seasonPremium, isFalse);
    ctrl.debugGame.gems = seasonPremiumGems + 10.0;
    expect(ctrl.buySeasonPremium(), isTrue);
    expect(c.read(gameControllerProvider).gems, 10);
    expect(c.read(gameControllerProvider).seasonPremium, isTrue);
    expect(ctrl.buySeasonPremium(), isFalse);
    expect(c.read(gameControllerProvider).gems, 10, reason: 'không trừ lần hai');
  });

  test('nhận bậc: miễn phí → 💎; Cao cấp cần mua; rơi phụ kiện đúng độ hiếm; không nhận hai lần', () async {
    final (c, ctrl, _) = await _setup(GameState.newGame(nowMillis: 0));
    ctrl.debugGame.seasonXp = 3000; // đủ 30 bậc (seasonSync giữ vì cùng mùa sau lần đồng bộ đầu)
    ctrl.debugGame.seasonId = seasonIdFor(56 * _day);
    expect(ctrl.claimSeasonTier(1, premium: true), isNull, reason: 'chưa mua Cao cấp');
    final g0 = c.read(gameControllerProvider).gems;
    final r1 = ctrl.claimSeasonTier(1, premium: false)!;
    expect(r1.gems, 5);
    expect(r1.drop, isNull);
    expect(c.read(gameControllerProvider).gems, g0 + 5);
    expect(ctrl.claimSeasonTier(1, premium: false), isNull, reason: 'đã nhận');
    final r5 = ctrl.claimSeasonTier(5, premium: false)!;
    expect(r5.drop, isNotNull);
    ctrl.debugGame.seasonPremium = true;
    final e0 = c.read(gameControllerProvider).essence;
    final r3 = ctrl.claimSeasonTier(3, premium: true)!;
    expect(r3.gems, 8);
    expect(r3.essence, 20);
    expect(c.read(gameControllerProvider).essence, e0 + 20);
    final r30 = ctrl.claimSeasonTier(30, premium: true)!;
    final items = seasonItemsFor(ctrl.debugGame.seasonId);
    expect(r30.drop!.accessory.id, items.premium.id);
    expect(ctrl.debugGame.ownedLimited, contains(items.premium.id));
    expect(ctrl.claimSeasonTier(20, premium: false)!.drop!.accessory.id, items.free.id);
    expect(r30.gems, 48);
    expect(c.read(gameControllerProvider).seasonPremiumClaimed, containsAll([3, 30]));
  });

  test('Món của ngày: trừ đúng giá, cấp món, một lần/ngày, thiếu 💎 thì không đổi gì', () async {
    const day = 57;
    final item = dailyItemFor(day, {});
    final price = dailyItemPrice(item.rarity);
    final seed = GameState.newGame(nowMillis: 0)..gems = price - 1.0;
    final (c, ctrl, clock) = await _setup(seed, day: day);
    expect(ctrl.buyDailyItem(), isNull);
    expect(c.read(gameControllerProvider).ownedAccessories, isEmpty);
    ctrl.debugGame.gems = price + 5.0;
    final drop = ctrl.buyDailyItem()!;
    expect(drop.accessory.id, item.id);
    expect(drop.isNew, isTrue);
    expect(c.read(gameControllerProvider).gems, 5);
    expect(c.read(gameControllerProvider).ownedAccessories, contains(item.id));
    ctrl.debugGame.gems = 9999;
    expect(ctrl.buyDailyItem(), isNull, reason: 'một lần/ngày');
    clock[0] += _day;
    expect(ctrl.buyDailyItem(), isNotNull, reason: 'ngày mới');
  });
}
