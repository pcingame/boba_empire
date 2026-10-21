import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/staff.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dải giai đoạn → nhân viên, hệ số, lưu/đọc kẹp cấp', () {
    expect([for (final s in [1, 3, 4, 18]) staffOfStage(s)], [0, 0, 1, 5]);
    expect(staffMultiplier({'0': 4}, 2), closeTo(1 + 4 * staffPerLevel, 1e-9));
    expect(staffMultiplier({'0': 4}, 4), 1);
    final g = GameState.newGame(nowMillis: 0)..staff['1'] = 3;
    final back = GameState.fromJson(g.toJson()..['staff'] = {'1': 3, '2': 999, 'x': 1});
    expect(back.staff, {'1': 3, '2': staffMaxLevel});
  });

  test('thuê bằng 💎, nâng bằng Xu, tăng thu nhập, thiếu tiền thì không đổi gì', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = GameState.newGame(nowMillis: 0)
      ..tutorialSeen = true
      ..gems = 60
      ..money = 0
      ..levels[Balance.generators.first.id] = 10;
    await GameStorage(prefs).save(seed, nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    double inc() => baseIncomePerSecond(c.read(gameControllerProvider.notifier).debugGame, Balance.generators);
    final before = inc();
    expect(ctl.upgradeStaff(1), isFalse, reason: '100 💎 > 60');
    expect(ctl.upgradeStaff(0), isTrue);
    expect(c.read(gameControllerProvider).gems, 10);
    expect(c.read(gameControllerProvider).staff, {'0': 1});
    expect(inc(), closeTo(before * (1 + staffPerLevel), before * 1e-9));
    expect(ctl.upgradeStaff(0), isFalse, reason: 'hết Xu');
  });
}
