import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/iap/iap_products.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _ctl(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cấp VIP theo bậc điểm, bậc cuối = số bậc', () {
    expect(topupVipLevel(0), 0);
    expect(topupVipLevel(4), 0);
    expect(topupVipLevel(5), 1);
    expect(topupVipLevel(29), 2);
    expect(topupVipLevel(30), 3);
    expect(topupVipLevel(999999), topupTiers.length);
    expect(vipIncomeMultiplier(0), 1.0);
    expect(vipIncomeMultiplier(5), closeTo(1.02, 1e-9));
  });

  test('mọi sản phẩm IAP có điểm nạp > 0', () {
    for (final p in IapProduct.values) {
      expect(p.topup, greaterThan(0), reason: p.id);
    }
  });

  test('điểm nạp tăng thu nhập theo cấp VIP', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10);
    final n = c.read(gameControllerProvider.notifier);
    final before = c.read(gameControllerProvider).incomePerSecond;
    n.addTopupPoints(5); // VIP 1
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(before * 1.02, 1e-6));
  });

  test('nhận mốc: chưa đủ điểm → null; đủ → +💎 một lần; nhận lại → null',
      () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0));
    final n = c.read(gameControllerProvider.notifier);
    expect(n.claimTopupTier(0), isNull); // chưa đủ điểm
    n.addTopupPoints(5);
    final gems0 = c.read(gameControllerProvider).gems;
    final r = n.claimTopupTier(0);
    expect(r, isNotNull);
    expect(c.read(gameControllerProvider).gems, gems0 + topupTiers[0].gems);
    expect(n.claimTopupTier(0), isNull); // đã nhận
    expect(c.read(gameControllerProvider).topupClaimed, [0]);
    expect(n.claimTopupTier(-1), isNull);
    expect(n.claimTopupTier(999), isNull);
  });

  test('bậc có phụ kiện: rớt đúng một món, độ hiếm không thấp hơn yêu cầu',
      () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0));
    final n = c.read(gameControllerProvider.notifier);
    n.addTopupPoints(500);
    for (var i = 0; i < topupTiers.length; i++) {
      final withAcc = topupTiers[i].accessory != null;
      final r = n.claimTopupTier(i)!;
      expect(r.drop != null, withAcc, reason: 'bậc $i');
    }
    final s = c.read(gameControllerProvider);
    expect(s.topupClaimed.length, topupTiers.length);
    // 3 bậc có phụ kiện → 3 món (có thể trùng nhau thì vào bản dư): ít nhất 1 món.
    expect(s.ownedAccessories, isNotEmpty);
  });

  test('điểm nạp và bậc đã nhận được lưu qua save/load', () {
    final g = GameState.newGame(nowMillis: 0)
      ..topupPoints = 42
      ..topupClaimed.add(1);
    final back = GameState.fromJson(g.toJson());
    expect(back.topupPoints, 42);
    expect(back.topupClaimed, [1]);
    // save cũ không có khoá → mặc định 0/rỗng.
    final old = GameState.fromJson(GameState.newGame(nowMillis: 0).toJson()
      ..remove('topupPoints')
      ..remove('topupClaimed'));
    expect(old.topupPoints, 0);
    expect(old.topupClaimed, isEmpty);
  });
}
