import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(int) setNow)> _harness(
  GameState seed,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 0;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  return (container, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('collectVip không làm gì khi chưa có VIP', () async {
    final (container, _) = await _harness(GameState.newGame(nowMillis: 0));
    addTearDown(container.dispose);

    final reward = container.read(gameControllerProvider.notifier).collectVip();
    expect(reward.cash, 0);
    expect(reward.gems, 0);
    expect(container.read(gameControllerProvider).gems, 0);
  });

  test('chạm VIP → +Kim Cương (1..3) và +tiền, VIP biến mất', () async {
    // tra_den cấp 2 = 1 Xu/s → vipCashSeconds=60 → 60 Xu (sàn tapValue*10=10).
    final (container, _) = await _harness(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
    );
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnVip();
    expect(container.read(gameControllerProvider).vipVisible, isTrue);

    final reward = ctrl.collectVip();
    expect(reward.cash, closeTo(60, 1e-9));
    expect(reward.gems, inInclusiveRange(Balance.vipGemsMin, Balance.vipGemsMax));

    final snap = container.read(gameControllerProvider);
    expect(snap.vipVisible, isFalse);
    expect(snap.gems, reward.gems);
    expect(snap.money, closeTo(60, 1e-9));
  });

  test('sàn tiền = tapValue*10 khi chưa có thu nhập tự động', () async {
    final (container, _) = await _harness(GameState.newGame(nowMillis: 0));
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnVip();
    final reward = ctrl.collectVip();
    expect(reward.cash, closeTo(10, 1e-9)); // tapValue 1 * 10
  });

  test('VIP tự rời đi sau vipLinger nếu không phục vụ', () async {
    final (container, setNow) = await _harness(GameState.newGame(nowMillis: 0));
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnVip();
    setNow(Balance.vipLingerMs + 1000);
    ctrl.debugTick();
    expect(container.read(gameControllerProvider).vipVisible, isFalse);
  });
}
