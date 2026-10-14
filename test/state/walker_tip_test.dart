// Boa của khách đi ngang: số tiền (giây sản xuất, có sàn), thời gian hồi, chỉ Xu (không 💎).
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(int) setNow)> _harness(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 0;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('boa = walkerTipSeconds giây sản xuất; chỉ cộng Xu, không đụng 💎', () async {
    // tra_den cấp 2 = 1 Xu/s → 8 giây = 8 Xu; sàn 5 lần chạm = 5 → lấy 8.
    final (c, _) = await _harness(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2);
    final ctrl = c.read(gameControllerProvider.notifier);
    final before = c.read(gameControllerProvider);
    final cash = ctrl.collectWalkerTip();
    expect(cash, closeTo(Balance.walkerTipSeconds * 1.0, 1e-9));
    final after = c.read(gameControllerProvider);
    expect(after.money - before.money, closeTo(cash!, 1e-9));
    expect(after.gems, before.gems);
  });

  test('chưa có thu nhập tự động: có sàn (walkerTipFloorTaps lần chạm), không bao giờ 0', () async {
    final (c, _) = await _harness(GameState.newGame(nowMillis: 0));
    final cash = c.read(gameControllerProvider.notifier).collectWalkerTip();
    expect(cash, closeTo(1.0 * Balance.walkerTipFloorTaps, 1e-9)); // tapValue 1
    expect(cash, greaterThan(0));
  });

  test('thời gian hồi: bấm lại ngay → null, không cộng thêm; hết hồi → nhận được', () async {
    final (c, setNow) = await _harness(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.walkerTipReady, isTrue);
    expect(ctrl.collectWalkerTip(), isNotNull);
    final money = c.read(gameControllerProvider).money;
    expect(ctrl.walkerTipReady, isFalse);

    setNow(Balance.walkerTipCooldownMs - 1);
    expect(ctrl.collectWalkerTip(), isNull);
    expect(c.read(gameControllerProvider).money, money);

    setNow(Balance.walkerTipCooldownMs);
    expect(ctrl.walkerTipReady, isTrue);
    expect(ctrl.collectWalkerTip(), isNotNull);
  });

  test('trần thu nhập thêm: tối đa ~walkerTipSeconds / cooldown (≤ 10%) so với thu nhập thường', () {
    expect(Balance.walkerTipSeconds * 1000 / Balance.walkerTipCooldownMs, lessThanOrEqualTo(0.10));
  });
}
