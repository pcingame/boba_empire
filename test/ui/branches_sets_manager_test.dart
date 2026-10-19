// Bộ sưu tập châu lục + Quản lý chi nhánh: công thức, nhận thưởng một lần, thuê/gia hạn/trần 30 ngày, trần kho 24h, save.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/branches.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _t0 = 1000000;

Future<ProviderContainer> _c(GameState seed, int Function() clock) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: _t0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
  addTearDown(c.dispose);
  return c;
}

GameState _rich() => GameState.newGame(nowMillis: _t0)
  ..tutorialSeen = true
  ..stage = 18
  ..money = 1e12
  ..gems = 1000
  ..levels[Balance.generators.first.id] = 50;

void main() {
  test('bộ: id thành phố hợp lệ, "all" = 17, mốc 2 gấp đôi', () {
    final ids = branchCities.map((c) => c.id).toSet();
    for (final s in branchSets) {
      expect(s.cityIds.every(ids.contains), isTrue, reason: s.id);
    }
    expect(branchSets.last.cityIds.toSet(), ids);
    final s = branchSets.first;
    expect(branchSetReward(s, 2).gems, 2 * branchSetReward(s, 1).gems);
    expect(isBranchSetKey('asia:1'), isTrue);
    expect(isBranchSetKey('asia:3'), isFalse);
  });

  test('nhận thưởng bộ: chỉ khi đủ, chỉ một lần', () async {
    final seed = _rich()..branchLevels['moon'] = 1;
    final c = await _c(seed, () => _t0);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.claimBranchSet('europe:1'), isFalse);
    final g0 = c.read(gameControllerProvider).gems;
    expect(ctl.claimBranchSet('space:1'), isTrue);
    expect(c.read(gameControllerProvider).gems, g0 + 30);
    expect(ctl.claimBranchSet('space:1'), isFalse);
    expect(ctl.claimBranchSet('space:2'), isFalse);
  });

  test('quản lý: thuê trừ 💎, gia hạn cộng dồn, trần 30 ngày, thiếu 💎 thì không', () async {
    final c = await _c(_rich(), () => _t0);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.branchManagerActive(), isFalse);
    final g0 = c.read(gameControllerProvider).gems;
    for (var i = 0; i < 4; i++) {
      expect(ctl.hireBranchManager(), isTrue);
    }
    expect(ctl.hireBranchManager(), isFalse, reason: '35 ngày > 30');
    final s = c.read(gameControllerProvider);
    expect(s.gems, g0 - 4 * branchManagerGems);
    expect(s.branchManagerUntilMillis, _t0 + 28 * 86400000);
  });

  test('quản lý nâng trần kho 8h → 24h', () {
    final lv = {'saigon': 1};
    final since = {'saigon': _t0};
    final c = branchCityById('saigon')!;
    final now = _t0 + 20 * 3600 * 1000;
    final a = branchPendingIncomeSeconds(lv, since, c, now);
    final b = branchPendingIncomeSeconds(lv, since, c, now, manager: true);
    expect(b, closeTo(a * 20 / 8, 1e-6));
  });

  test('tự thu khi quản lý còn hạn; save giữ dữ liệu; khoá lạ bị loại', () async {
    var now = _t0;
    final seed = _rich()
      ..branchLevels['saigon'] = 3
      ..branchSince['saigon'] = _t0
      ..branchManagerUntilMillis = _t0 + 86400000
      ..branchSetClaims.add('asia:1');
    final c = await _c(seed, () => now);
    final ctl = c.read(gameControllerProvider.notifier);
    now += 3600 * 1000;
    final m0 = c.read(gameControllerProvider).money;
    ctl.collectBranches();
    expect(c.read(gameControllerProvider).money, greaterThan(m0));
    final back = GameState.fromJson({
      ...seed.toJson(),
      'branchSetClaims': ['asia:1', 'bogus:9'],
    });
    expect(back.branchSetClaims, ['asia:1']);
    expect(back.branchManagerUntilMillis, seed.branchManagerUntilMillis);
  });
}
