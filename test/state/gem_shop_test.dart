import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(GameState seed, int nowMillis) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => nowMillis),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mua Tăng thu nhập: trừ gems, lên cấp, thu nhập tăng', () async {
    final container = await _container(
      GameState.newGame(nowMillis: 0)
        ..gems = 5
        ..levels['tra_den'] = 2, // 1 Xu/s base
      0,
    );
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    expect(container.read(gameControllerProvider).incomePerSecond, closeTo(1, 1e-9));
    expect(ctrl.buyGemBoostUpgrade(), isTrue);

    final snap = container.read(gameControllerProvider);
    expect(snap.gems, 0);
    expect(snap.gemBoostLevel, 1);
    expect(snap.incomePerSecond, closeTo(1.1, 1e-9)); // +10%
  });

  test('Kho lạnh offline nâng trần tiền offline', () async {
    // 30000s vắng mặt: > trần gốc 8h (28800s) nhưng < 8h + 2h khi có cấp 1.
    final gapSeconds = 30000;
    final container = await _container(
      GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 2 // 1 Xu/s
        ..offlineCapLevel = 1, // +2h trần
      gapSeconds * 1000,
    );
    addTearDown(container.dispose);

    // Với trần mở rộng, nhận đủ 30000 Xu (không bị cắt ở 28800).
    expect(
      container.read(gameControllerProvider).money,
      closeTo(gapSeconds.toDouble(), 1e-6),
    );
    expect(gapSeconds, greaterThan(Balance.maxOfflineSeconds));
  });
}
