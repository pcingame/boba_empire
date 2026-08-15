import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
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

  test('IAP x2 vĩnh viễn: gấp đôi income + cờ owned', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10);
    final before = c.read(gameControllerProvider).incomePerSecond;
    c.read(gameControllerProvider.notifier).applyDoubleIncome();
    final snap = c.read(gameControllerProvider);
    expect(snap.doubleIncomeOwned, isTrue);
    expect(snap.incomePerSecond, closeTo(before * 2, 1e-6));
  });

  test('rewarded: nhận Kim Cương miễn phí đúng số', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0));
    final before = c.read(gameControllerProvider).gems;
    c.read(gameControllerProvider.notifier).grantFreeGems();
    expect(c.read(gameControllerProvider).gems,
        before + Balance.rewardedFreeGems);
  });

  test('rewarded: tua nhanh thưởng = income × thời lượng', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10);
    final income = c.read(gameControllerProvider).incomePerSecond;
    final before = c.read(gameControllerProvider).money;
    final reward = c.read(gameControllerProvider.notifier).claimTimeSkip();
    expect(reward,
        closeTo(income * Balance.rewardedTimeSkipSeconds, 1e-3));
    expect(c.read(gameControllerProvider).money, closeTo(before + reward, 1e-3));
  });

  test('rewarded: x2 income 24h bật boost → income x2 + còn thời gian', () async {
    final c = await _ctl(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 10);
    final before = c.read(gameControllerProvider).incomePerSecond;
    c.read(gameControllerProvider.notifier).activateX2Income();
    final snap = c.read(gameControllerProvider);
    expect(snap.x2IncomeRemainingSeconds, greaterThan(0));
    expect(snap.incomePerSecond, closeTo(before * 2, 1e-6));
  });
}
