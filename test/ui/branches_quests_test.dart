// Nhiệm vụ chi nhánh: tiến độ từ hành động thật, làm mới theo ngày, nhận một lần, thưởng cả bộ, save.
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
  ..money = 1e15
  ..gems = 1000
  ..levels[Balance.generators.first.id] = 50;

void main() {
  _stallTests();
  test('claimable: nhiệm vụ xong + thưởng cả bộ chỉ khi đủ 4', () {
    expect(branchQuestClaimable([0, 0, 0, 0], 0), isEmpty);
    expect(branchQuestClaimable([3, 0, 0, 0], 0), [0]);
    expect(branchQuestClaimable([3, 0, 0, 0], 1), isEmpty);
    expect(branchQuestClaimable([3, 2, 2, 1], 0), [0, 1, 2, 3, 4]);
    expect(branchQuestClaimable([3, 2, 2, 1], 31), isEmpty);
  });

  test('hành động thật cộng tiến độ; nâng cấp + sự kiện; nhận 1 lần; sang ngày thì làm mới', () async {
    var now = _t0;
    final c = await _c(_rich()..branchLevels['saigon'] = 2..branchSince['saigon'] = _t0, () => now);
    final ctl = c.read(gameControllerProvider.notifier);
    ctl.upgradeBranch('saigon');
    ctl.upgradeBranch('saigon');
    ctl.claimBranchEvent();
    now += 3600 * 1000;
    ctl.collectBranches();
    var s = c.read(gameControllerProvider);
    expect(s.branchQuestProgress[0], 1);
    expect(s.branchQuestProgress[2], 2);
    expect(s.branchQuestProgress[3], 1);
    expect(ctl.claimBranchQuest(0), isFalse, reason: 'mới thu 1/3');
    expect(ctl.claimBranchQuest(2), isTrue);
    expect(ctl.claimBranchQuest(2), isFalse);
    final g = c.read(gameControllerProvider).gems;
    expect(ctl.claimBranchQuest(3), isTrue);
    expect(c.read(gameControllerProvider).gems, g + branchQuestGems);
    expect(ctl.claimBranchQuest(4), isFalse);
    now += 86400 * 1000;
    expect(ctl.claimBranchQuest(3), isFalse);
    ctl.collectBranches();
    s = c.read(gameControllerProvider);
    expect(s.branchQuestProgress, [1, 0, 0, 0]);
    expect(s.branchQuestClaimed, 0);
  });

  test('save loại giá trị lạ (tiến độ âm/sai kiểu, mặt nạ ngoài 5 bit)', () async {
    final back = GameState.fromJson({
      ..._rich().toJson(),
      'branchQuestProgress': [1, -5, 'x'],
      'branchQuestClaimed': 999,
    });
    expect(back.branchQuestProgress, [1, 0, 0, 0]);
    expect(back.branchQuestClaimed, 999 & 31);
  });
}

void _stallTests() {
  test('quầy: khoá theo cấp chi nhánh, trừ Xu, tối đa 5, tăng doanh thu thu về', () async {
    var now = _t0;
    final seed = _rich()
      ..branchLevels['tokyo'] = 4
      ..branchSince['tokyo'] = _t0;
    final c = await _c(seed, () => now);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.upgradeBranchStall('tokyo', 2), isFalse, reason: 'quầy 3 cần cấp 7');
    expect(ctl.upgradeBranchStall('xx', 0), isFalse);
    final m0 = c.read(gameControllerProvider).money;
    expect(ctl.upgradeBranchStall('tokyo', 1), isTrue);
    expect(c.read(gameControllerProvider).money, lessThan(m0));
    for (var k = 0; k < 4; k++) {
      expect(ctl.upgradeBranchStall('tokyo', 1), isTrue);
    }
    expect(ctl.upgradeBranchStall('tokyo', 1), isFalse, reason: 'tối đa');
    expect(branchStallMultiplier(c.read(gameControllerProvider).branchStalls, 'tokyo'), closeTo(1.3, 1e-12));
    // Tiến độ nhiệm vụ "nâng cấp" cũng tăng (5 lần nâng quầy).
    expect(c.read(gameControllerProvider).branchQuestProgress[2], 5);
  });

  test('save loại khoá quầy lạ và kẹp cấp', () {
    final back = GameState.fromJson({
      ..._rich().toJson(),
      'branchStalls': {'tokyo:0': 99, 'tokyo:7': 1, 'zzz:0': 1, 'tokyo:1': 2},
    });
    expect(back.branchStalls, {'tokyo:0': branchStallMaxLevel, 'tokyo:1': 2});
  });
}
