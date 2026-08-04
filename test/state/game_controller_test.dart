import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('không có save -> ván mới, tiền 0', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final snap = container.read(gameControllerProvider);
    expect(snap.money, 0);
    expect(snap.incomePerSecond, 0);
  });

  test('tapCup cộng tapValue vào snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    container.read(gameControllerProvider.notifier).tapCup();
    expect(container.read(gameControllerProvider).money, 1);
  });

  test('buy trừ tiền và tăng cấp; thiếu tiền thì thất bại', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..money = 20,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    expect(ctrl.buy('tra_den'), isTrue); // baseCost 15
    var snap = container.read(gameControllerProvider);
    expect(snap.money, closeTo(5, 1e-9));
    expect(snap.levelOf('tra_den'), 1);
    expect(snap.incomePerSecond, closeTo(0.5, 1e-9));

    expect(ctrl.buy('tra_den'), isFalse); // cấp 2 giá 17.25 > 5
    snap = container.read(gameControllerProvider);
    expect(snap.levelOf('tra_den'), 1);
  });

  test('build tính tiền offline theo đồng hồ', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // tra_den cấp 2 = 1.0 Xu/s. Save lúc t=0.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 60000), // mở lại sau 60s
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(gameControllerProvider).money, closeTo(60, 1e-9));
  });

  test('saveNow persist để container sau load lại được', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.tapCup();
    ctrl.tapCup();
    ctrl.tapCup(); // money = 3
    await ctrl.saveNow();

    final reloaded = GameStorage(prefs).load();
    expect(reloaded, isNotNull);
    expect(reloaded!.money, 3);
  });

  test('resetGame xóa save và đưa tiền về 0', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..money = 500,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider).money, 500);
    await ctrl.resetGame();
    expect(container.read(gameControllerProvider).money, 0);
    expect(GameStorage(prefs).load(), isNull);
  });
}
