import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(GameState seed) async {
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

  test('chưa đủ điều kiện -> doAscend() = 0, không đổi gì', () async {
    final c = await _container(GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = 1e12
      ..prestigeStars = 5);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(c.read(gameControllerProvider).ascensionPointsAvailable, 0);
    expect(ctrl.doAscend(), 0);
    expect(c.read(gameControllerProvider).prestigeStars, 5);
    expect(c.read(gameControllerProvider).ascensionCount, 0);
  });

  test('đủ điều kiện -> nhận điểm, reset Sao, snapshot đổi, lưu ngay', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = Balance.ascensionMinLifetime * 100
      ..prestigeStars = 1000
      ..stage = 18;
    final c = await _container(seed);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(c.read(gameControllerProvider).ascensionPointsAvailable, 10);

    expect(ctrl.doAscend(), 10);
    final snap = c.read(gameControllerProvider);
    expect(snap.ascensionCount, 1);
    expect(snap.ascensionPointsSpendable, 10);
    expect(snap.prestigeStars, 0);
    expect(snap.stage, 1);
    expect(snap.ascensionPointsAvailable, 0);

    // Đã lưu ngay: container mới đọc lại cùng storage phải thấy trạng thái mới.
    final prefs = await SharedPreferences.getInstance();
    final reloaded = GameStorage(prefs).load()!;
    expect(reloaded.ascensionCount, 1);
    expect(reloaded.prestigeStars, 0);
  });

  test('mua perk trừ điểm và tăng cấp; thiếu điểm thì false', () async {
    final c = await _container(GameState.newGame(nowMillis: 0)
      ..ascensionPointsEarned = 1);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.buyAscensionIncomeUpgrade(), isTrue); // giá 1
    expect(c.read(gameControllerProvider).ascensionIncomeLevel, 1);
    expect(c.read(gameControllerProvider).ascensionPointsSpendable, 0);
    expect(ctrl.buyAscensionIncomeUpgrade(), isFalse);
  });

  test('thu nhập trong snapshot tăng theo perk Nguồn năng lượng', () async {
    final c = await _container(GameState.newGame(nowMillis: 0)
      ..levels['tra_den'] = 10
      ..ascensionPointsEarned = 1);
    final before = c.read(gameControllerProvider).incomePerSecond;
    c.read(gameControllerProvider.notifier).buyAscensionIncomeUpgrade();
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(before * 1.5, 1e-9));
  });

  test('tiến độ thang log: 0 ở đầu game, 1 khi đủ ngưỡng', () async {
    final c0 = await _container(GameState.newGame(nowMillis: 0));
    expect(c0.read(gameControllerProvider).ascensionProgress, 0);
    final c1 = await _container(GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = Balance.ascensionMinLifetime);
    expect(c1.read(gameControllerProvider).ascensionProgress, 1);
    final mid = await _container(GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = 1e18);
    expect(mid.read(gameControllerProvider).ascensionProgress,
        inExclusiveRange(0.4, 0.6));
  });
}
