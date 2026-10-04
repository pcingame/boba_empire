import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _open() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..stage = 3
        ..lifetimeEarnings = 1e12
        ..levels.addAll({'tra_den': 50}),
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('xem QC: Sao y hệt, Xu khởi đầu thêm ~600s thu nhập (hữu hạn)', () async {
    final a = await _open();
    final b = await _open();
    final income = b.read(gameControllerProvider).incomePerSecond;
    expect(income, greaterThan(0));
    final starsA = (a.read(gameControllerProvider.notifier) as dynamic).doPrestige();
    final starsB =
        (b.read(gameControllerProvider.notifier) as dynamic).doPrestige(adBonus: true);
    expect(starsB, starsA); // không thưởng Sao
    final moneyA = a.read(gameControllerProvider).money;
    final moneyB = b.read(gameControllerProvider).money;
    expect(moneyB.isFinite, isTrue);
    expect(moneyB - moneyA,
        closeTo(income * Balance.prestigeAdBonusSeconds, income));
  });
}
