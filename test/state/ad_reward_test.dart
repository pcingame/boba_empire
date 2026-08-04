import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('StubAdService luôn earned', () async {
    expect(await const StubAdService().showRewardedAd(), RewardOutcome.earned);
  });

  test('claimDoubleOffline cộng thêm đúng số tiền offline rồi về 0', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // tra_den cấp 2 = 1 Xu/s; save t=0, mở t=60s → offline 60.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 60000),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider).money, closeTo(60, 1e-9));

    final bonus = ctrl.claimDoubleOffline();
    expect(bonus, closeTo(60, 1e-9));
    expect(container.read(gameControllerProvider).money, closeTo(120, 1e-9));

    // Gọi lần nữa không cộng thêm (đã tiêu).
    expect(ctrl.claimDoubleOffline(), 0);
    expect(container.read(gameControllerProvider).money, closeTo(120, 1e-9));
  });

  test('claimInstantCash: 0 khi chưa có thu nhập', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(gameControllerProvider.notifier).claimInstantCash(), 0);
  });

  test('claimInstantCash: thưởng 15 phút sản xuất', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // tra_den cấp 2 = 1 Xu/s → 900s * 1 = 900 Xu.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
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
    expect(ctrl.claimInstantCash(), closeTo(900, 1e-9));
    expect(container.read(gameControllerProvider).money, closeTo(900, 1e-9));
  });
}
