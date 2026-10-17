/// Nguồn Tinh chất qua controller: bậc Công thức, đơn 3★ (trần ngày), thử thách ngày, nhân đôi QC, sao Ghép 3, mua Bí quyết.
library;

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

Future<(ProviderContainer, void Function(int))> _harness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  var now = 100 * _day;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int d) => now = d * _day);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bậc Công thức mới: thưởng = số bậc, chỉ một lần; trả lời lại không thưởng', () async {
    final (c, _) = await _harness();
    final ctrl = c.read(gameControllerProvider.notifier);
    final r = ctrl.answerRecipe(1, true);
    expect(r.essence, 1);
    expect(c.read(gameControllerProvider).essence, 1);
    expect(ctrl.answerRecipe(1, true).essence, 0, reason: 'chưa tới hạn: không đổi bậc');
    expect(c.read(gameControllerProvider).essence, 1);
  });

  test('đơn 3★: tối đa 10/ngày, sang ngày làm tiếp', () async {
    final (c, setDay) = await _harness();
    final ctrl = c.read(gameControllerProvider.notifier);
    var got = 0;
    for (var i = 0; i < 14; i++) {
      got += ctrl.grantOrderEssence();
    }
    expect(got, Balance.essenceOrdersDailyCap);
    setDay(101);
    expect(ctrl.grantOrderEssence(), 1);
  });

  test('thử thách ngày +5; nhân đôi QC bị trần chung 20 chặn', () async {
    final (c, _) = await _harness();
    final ctrl = c.read(gameControllerProvider.notifier);
    for (var i = 0; i < 10; i++) {
      ctrl.grantOrderEssence();
    }
    final r = ctrl.completeDailyChallenge(100);
    expect(r.essence, 5);
    expect(ctrl.doubleRecipeReward(10, essence: 50), 5, reason: '10 + 5 + 5 = 20');
    expect(c.read(gameControllerProvider).essence, 20);
    expect(ctrl.doubleRecipeReward(10, essence: 3), 0);
    expect(ctrl.completeDailyChallenge(100).essence, 0, reason: 'đã làm hôm nay');
  });

  test('Ghép 3: thưởng theo số sao TĂNG THÊM; chơi lại không tăng thì 0', () async {
    final (c, _) = await _harness();
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.grantMatch3Result(1, 2);
    expect((ctrl.lastMatch3Essence, c.read(gameControllerProvider).essence), (2, 2));
    ctrl.grantMatch3Result(1, 2);
    expect(ctrl.lastMatch3Essence, 0);
    ctrl.grantMatch3Result(1, 3);
    expect((ctrl.lastMatch3Essence, c.read(gameControllerProvider).essence), (1, 3));
  });

  test('buyMasteryTier: trừ Tinh chất, tăng bậc, snapshot cập nhật; thiếu thì false', () async {
    final (c, _) = await _harness();
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.buyMasteryTier(1), isFalse);
    ctrl.debugGame.essence = 30;
    expect(ctrl.buyMasteryTier(2), isTrue);
    final s = c.read(gameControllerProvider);
    expect((s.essence, s.masteryTiers[2]), (20, 1));
    expect(ctrl.buyMasteryTier(2), isTrue);
    expect(c.read(gameControllerProvider).masteryTiers[2], 2);
    expect(c.read(gameControllerProvider).essence, 0);
  });
}
