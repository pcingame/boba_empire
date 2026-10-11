import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/core/vip_shop.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

Future<ProviderContainer> _ctl(GameState seed, {int Function()? clock}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock ?? () => 100 * _day),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nhận quà VIP theo kỳ cộng Xu VIP đúng theo cấp; nhận lại cùng kỳ không cộng thêm', () async {
    var now = 100 * _day;
    final c = await _ctl(GameState.newGame(nowMillis: 0)..vipExp = topupTiers[2].exp,
        clock: () => now); // VIP 3
    final n = c.read(gameControllerProvider.notifier);
    expect(c.read(gameControllerProvider).vipCoins, 0);
    expect(n.claimVipBenefit(VipPeriod.daily)!.coins, 15);
    expect(n.claimVipBenefit(VipPeriod.weekly)!.coins, 105);
    expect(n.claimVipBenefit(VipPeriod.monthly)!.coins, 450);
    expect(c.read(gameControllerProvider).vipCoins, 15 + 105 + 450);
    expect(n.claimVipBenefit(VipPeriod.daily), isNull); // cùng ngày
    expect(c.read(gameControllerProvider).vipCoins, 570);
    now += _day;
    expect(n.claimVipBenefit(VipPeriod.daily)!.coins, 15); // ngày mới
    expect(c.read(gameControllerProvider).vipCoins, 585);
  });

  test('mua: mã không tồn tại, bị khoá theo cấp, thiếu Xu, đã có — đều KHÔNG đổi gì', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)
      ..vipExp = topupTiers[1].exp // VIP 2
      ..vipCoins = 1000);
    final n = c.read(gameControllerProvider.notifier);
    expect(n.buyVipShopItem('khong_co'), VipShopResult.unknownItem);
    // vip_racecar đòi VIP 5.
    expect(n.buyVipShopItem('vip_racecar'), VipShopResult.locked);
    var s = c.read(gameControllerProvider);
    expect(s.vipCoins, 1000);
    expect(s.ownedLimited, isEmpty);

    // Đủ cấp nhưng thiếu Xu.
    final poor = await _ctl(GameState.newGame(nowMillis: 0)
      ..vipExp = topupTiers[1].exp
      ..vipCoins = vipShopItems[0].price - 1);
    expect(poor.read(gameControllerProvider.notifier).buyVipShopItem(vipShopItems[0].id),
        VipShopResult.notEnoughCoins);
    expect(poor.read(gameControllerProvider).vipCoins, vipShopItems[0].price - 1);
    expect(poor.read(gameControllerProvider).ownedLimited, isEmpty);

    // Mua được rồi mua lại → alreadyOwned và không trừ lần hai.
    expect(n.buyVipShopItem(vipShopItems[0].id), VipShopResult.ok);
    s = c.read(gameControllerProvider);
    expect(s.vipCoins, 1000 - vipShopItems[0].price);
    expect(s.ownedLimited, [vipShopItems[0].id]);
    expect(n.buyVipShopItem(vipShopItems[0].id), VipShopResult.alreadyOwned);
    expect(c.read(gameControllerProvider).vipCoins, 1000 - vipShopItems[0].price);
  });

  test('mở khoá theo cấp: nâng cấp VIP thì mua được món cấp cao hơn', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)
      ..vipExp = topupTiers[3].exp // VIP 4
      ..vipCoins = 5000);
    final n = c.read(gameControllerProvider.notifier);
    expect(n.buyVipShopItem('vip_racecar'), VipShopResult.locked); // cần VIP 5
    n.addVipExp(topupTiers[4].exp - topupTiers[3].exp); // lên VIP 5
    expect(n.buyVipShopItem('vip_racecar'), VipShopResult.ok);
    expect(n.buyVipShopItem('vip_heli'), VipShopResult.locked); // cần VIP 6
  });

  test('mua hết 8 món với đủ Xu và cấp 8: không món nào mua lỗi, tổng trừ đúng', () async {
    final total = vipShopItems.fold<int>(0, (a, i) => a + i.price);
    final c = await _ctl(GameState.newGame(nowMillis: 0)
      ..vipExp = topupTiers[7].exp
      ..vipCoins = total + 7);
    final n = c.read(gameControllerProvider.notifier);
    for (final i in vipShopItems) {
      expect(n.buyVipShopItem(i.id), VipShopResult.ok, reason: i.id);
    }
    final s = c.read(gameControllerProvider);
    expect(s.vipCoins, 7);
    expect(s.ownedLimited.toSet(), vipShopItems.map((i) => i.id).toSet());
  });

  test('Xu VIP và món đã đổi được lưu qua save/load; save cũ → 0', () {
    final g = GameState.newGame(nowMillis: 0)
      ..vipCoins = 321
      ..ownedLimited.add('vip_jet');
    final back = GameState.fromJson(g.toJson());
    expect(back.vipCoins, 321);
    expect(back.ownedLimited, contains('vip_jet'));
    final old = GameState.fromJson(
        GameState.newGame(nowMillis: 0).toJson()..remove('vipCoins'));
    expect(old.vipCoins, 0);
  });
}
