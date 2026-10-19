// Sự kiện chi nhánh (ô 3h, nhận 1 lần), chuyên ngành cấp 10, skin bản đồ: công thức, controller, save.
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
  test('sự kiện: null khi chưa mở nơi nào; luôn rơi vào chi nhánh đã mở; xác định theo ô', () {
    expect(branchEventFor({}, 5), isNull);
    final lv = {'saigon': 2, 'tokyo': 1};
    for (var slot = 0; slot < 200; slot++) {
      final e = branchEventFor(lv, slot)!;
      expect(lv.containsKey(e.cityId), isTrue);
      expect(e.type, inInclusiveRange(0, 2));
      expect(branchEventFor(lv, slot)!.cityId, e.cityId);
    }
    expect({for (var s = 0; s < 200; s++) branchEventFor(lv, s)!.cityId}.length, 2);
  });

  test('nhận sự kiện: 1 lần/ô, ô mới nhận lại được', () async {
    var now = _t0;
    final c = await _c(_rich()..branchLevels['saigon'] = 3, () => now);
    final ctl = c.read(gameControllerProvider.notifier);
    final m0 = c.read(gameControllerProvider).money;
    final xu = ctl.claimBranchEvent();
    expect(xu, isNotNull);
    expect(c.read(gameControllerProvider).money, greaterThan(m0));
    expect(ctl.claimBranchEvent(), isNull);
    now += branchEventSlotSeconds * 1000;
    expect(ctl.claimBranchEvent(), isNotNull);
  });

  test('chuyên ngành: cần cấp tối đa; lần đầu miễn phí; đổi tốn 💎; không đủ thì giữ nguyên', () async {
    final c = await _c(_rich()..branchLevels['saigon'] = 9..branchLevels['tokyo'] = 10, () => _t0);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.setBranchSpec('saigon', 1), isFalse);
    final g0 = c.read(gameControllerProvider).gems;
    expect(ctl.setBranchSpec('tokyo', 1), isTrue);
    expect(c.read(gameControllerProvider).gems, g0);
    expect(ctl.setBranchSpec('tokyo', 1), isFalse);
    expect(ctl.setBranchSpec('tokyo', 2), isTrue);
    expect(c.read(gameControllerProvider).gems, g0 - branchSpecRespecGems);
    expect(c.read(gameControllerProvider).branchSpecs['tokyo'], 2);
  });

  test('xuất khẩu tăng Xu thu về; skin chỉ nhận 0..3; save loại giá trị lạ', () async {
    var now = _t0;
    GameState seed(int? spec) => _rich()
      ..branchLevels['tokyo'] = 10
      ..branchSince['tokyo'] = _t0
      ..branchSpecs.addAll({'tokyo': ?spec});
    final a = await _c(seed(null), () => now);
    final b = await _c(seed(1), () => now);
    now += 3600 * 1000;
    final income = b.read(gameControllerProvider.notifier).branchIncome;
    final base = branchPendingIncomeSeconds({'tokyo': 10}, {'tokyo': _t0}, branchCityById('tokyo')!, now) * income;
    final perk = 1 + branchPerkValue(branchCityById('tokyo')!, 10) * (branchCityById('tokyo')!.perk == BranchPerk.collect ? 1 : 0);
    final xb = b.read(gameControllerProvider.notifier).collectBranches().xu;
    final want = base * (perk + branchSpecCollectBonus);
    // cao điểm ×3 là ngẫu nhiên → chấp nhận cả hai.
    expect(xb, anyOf(closeTo(want, want * 1e-9), closeTo(want * branchRushMult, want * 1e-9)));
    final ctl = a.read(gameControllerProvider.notifier);
    ctl.setBranchMapSkin(9);
    expect(a.read(gameControllerProvider).branchMapSkin, 0);
    ctl.setBranchMapSkin(2);
    expect(a.read(gameControllerProvider).branchMapSkin, 2);
    final back = GameState.fromJson({
      ...seed(1).toJson(),
      'branchSpecs': {'tokyo': 1, 'x': 7},
      'branchMapSkin': 99,
    });
    expect(back.branchSpecs, {'tokyo': 1});
    expect(back.branchMapSkin, 3);
  });
}
