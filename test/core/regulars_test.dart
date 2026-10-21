import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/regulars.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('công thức: ghé xác định theo ngày, 3 lựa chọn luôn có món yêu thích, cấp theo điểm', () {
    for (var d = 100; d < 130; d++) {
      final v = regularsVisiting(d);
      expect(v.length, regularVisitsPerDay);
      expect(v.toSet().length, regularVisitsPerDay);
      expect(regularsVisiting(d), v);
      for (final i in v) {
        final o = regularOptions(i, d);
        expect(o.length, 3);
        expect(o.toSet().length, 3);
        expect(o, contains(regularFavorite(i)));
      }
    }
    expect([for (final p in [0, 2, 3, 8, 15, 25, 40, 999]) regularLevelOf(p)], [0, 0, 1, 2, 3, 4, 5, 5]);
    expect(regularPointsFor(0, regularFavorite(0)), 2);
    expect(regularPointsFor(0, (regularFavorite(0) + 1) % regularDrinks.length), 1);
    expect(regularServeCost(double.nan), 500);
    expect(regularIncomeMultiplier({'0': 40, '1': 8}), closeTo(1 + 7 * regularIncomePerLevel, 1e-9));
  });

  test('phục vụ: chỉ khách ghé hôm nay, một lần/ngày, trừ Xu, lên cấp thưởng 💎, tăng thu nhập, lưu/đọc', () async {
    var now = 10 * 24 * 3600 * 1000;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: now)
          ..tutorialSeen = true
          ..money = 1e9
          ..levels[Balance.generators.first.id] = 10,
        nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    final day = dayIndex(now);
    final visiting = regularsVisiting(day);
    final away = [for (var i = 0; i < regularCount; i++) if (!visiting.contains(i)) i].first;
    expect(ctl.serveRegular(away, 0), 0, reason: 'không ghé hôm nay');
    final i = visiting.first;
    final fav = regularFavorite(i);
    final inc0 = baseIncomePerSecond(ctl.debugGame, Balance.generators);
    final money0 = c.read(gameControllerProvider).money;
    expect(ctl.serveRegular(i, fav), 2);
    expect(c.read(gameControllerProvider).money, lessThan(money0));
    expect(ctl.serveRegular(i, fav), 0, reason: 'một lần/ngày');
    // Cùng khách, hai ngày sau: 2 điểm + 2 điểm = 4 ≥ 3 → cấp 1, +20 💎.
    now += 24 * 3600 * 1000;
    final next = regularsVisiting(dayIndex(now));
    if (next.contains(i)) {
      final gems0 = c.read(gameControllerProvider).gems;
      expect(ctl.serveRegular(i, fav), 2);
      expect(c.read(gameControllerProvider).gems, gems0 + regularLevelGems(1));
      expect(regularLevel(c.read(gameControllerProvider).regularPoints, i), 1);
      expect(effectiveIncomePerSecond(ctl.debugGame, Balance.generators, bonusPerStar: Balance.bonusPerStar),
          greaterThan(inc0));
    }
    final back = GameState.fromJson(ctl.debugGame.toJson()..['regularServed'] = [1, 99, -1]);
    expect(back.regularServed, [1]);
    expect(back.regularPoints['$i'], greaterThan(0));
    // Thiếu Xu thì không phục vụ.
    ctl.debugGame.money = 0;
    now += 24 * 3600 * 1000 * 7;
    final v2 = regularsVisiting(dayIndex(now)).first;
    expect(ctl.serveRegular(v2, 0), 0);
  });
}
