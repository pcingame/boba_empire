/// Nguồn rớt phụ kiện có bảo đảm độ hiếm: Kỷ Nguyên (Sử thi/Huyền thoại) và
/// mốc Trân Châu Rơi 10/30/60 (chỉ lần ĐẦU qua màn).
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(GameState seed) async {
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

  test('rollAccessoryOfRarity luôn đúng độ hiếm', () {
    for (final r in AccessoryRarity.values) {
      for (final roll in [0.0, 0.5, 0.999999]) {
        expect(rollAccessoryOfRarity(r, roll).rarity, r);
      }
    }
  });

  test('Kỷ Nguyên hoá rớt món Sử thi hoặc Huyền thoại', () async {
    final c = await _container(GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = Balance.ascensionMinLifetime * 100
      ..prestigeStars = 1000
      ..stage = 18);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.doAscend(), greaterThan(0));
    final drop = ctrl.lastAccessoryDrop!;
    expect(
      [AccessoryRarity.epic, AccessoryRarity.legendary],
      contains(drop.accessory.rarity),
    );
    expect(c.read(gameControllerProvider).equippedAccessories, isEmpty);
  });

  test('chưa đủ điều kiện Kỷ Nguyên thì không rớt', () async {
    final c = await _container(GameState.newGame(nowMillis: 0));
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.doAscend(), 0);
    expect(ctrl.lastAccessoryDrop, isNull);
  });

  test('mốc màn 10: lần đầu rớt món Hiếm, chơi lại thì không', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..m3Stars.addAll(List.filled(9, 3));
    final c = await _container(seed);
    final ctrl = c.read(gameControllerProvider.notifier);

    ctrl.grantMatch3Result(10, 1);
    expect(ctrl.lastAccessoryDrop!.accessory.rarity, AccessoryRarity.rare);

    ctrl.grantMatch3Result(10, 3); // phá kỷ lục sao nhưng KHÔNG phải lần đầu
    expect(ctrl.lastAccessoryDrop, isNull);
  });

  test('thua màn mốc (0 sao) hoặc màn thường: không rớt', () async {
    final c = await _container(GameState.newGame(nowMillis: 0)
      ..m3Stars.addAll(List.filled(9, 3)));
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.grantMatch3Result(10, 0);
    expect(ctrl.lastAccessoryDrop, isNull);
    ctrl.grantMatch3Result(9, 3);
    expect(ctrl.lastAccessoryDrop, isNull);
  });
}
