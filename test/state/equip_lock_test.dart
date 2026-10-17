/// Khoá đổi trang bị phụ kiện: lấp ô trống luôn được; tháo/thay chỉ khi hết khoá rồi khoá tiếp
/// (Balance.equipSwapLockMinutes); mở khoá bằng unlockEquipSwap; lưu/đọc và kẹp giá trị hỏng.
library;

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lockMs = 30 * 60000;
final _owned = ['mint_leaf', 'cupcake', 'cookie', 'dragon'];

Future<(ProviderContainer, GameController, int Function())> _setup(
    {GameState? seed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final s = seed ?? (GameState.newGame(nowMillis: 0)..ownedAccessories.addAll(_owned));
  await GameStorage(prefs).save(s, nowMillis: 0);
  var now = 1000000;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, c.read(gameControllerProvider.notifier), () => now);
}

void main() {
  test('lấp ô trống: luôn được, không bao giờ khoá', () async {
    final (c, ctrl, _) = await _setup();
    expect(ctrl.tryToggleEquippedAccessory('mint_leaf'), EquipResult.equipped);
    expect(ctrl.tryToggleEquippedAccessory('cupcake'), EquipResult.equipped);
    expect(ctrl.tryToggleEquippedAccessory('cookie'), EquipResult.equipped);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
  });

  test('chưa có món / hết ô: báo đúng lý do, không đổi gì', () async {
    final (c, ctrl, _) = await _setup();
    expect(ctrl.tryToggleEquippedAccessory('galaxy'), EquipResult.notOwned);
    for (final id in ['mint_leaf', 'cupcake', 'cookie']) {
      ctrl.tryToggleEquippedAccessory(id);
    }
    expect(ctrl.tryToggleEquippedAccessory('dragon'), EquipResult.full);
    expect(c.read(gameControllerProvider).equippedAccessories, ['mint_leaf', 'cupcake', 'cookie']);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0, reason: 'bị từ chối không được khoá');
  });

  test('tháo một món: khoá đúng 30 phút; tháo món thứ hai trong lúc khoá bị từ chối', () async {
    final (c, ctrl, now) = await _setup();
    for (final id in ['mint_leaf', 'cupcake', 'cookie']) {
      ctrl.tryToggleEquippedAccessory(id);
    }
    expect(ctrl.tryToggleEquippedAccessory('cupcake'), EquipResult.removed);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, now() + _lockMs);
    expect(Balance.equipSwapLockMinutes * 60000, _lockMs);

    expect(ctrl.tryToggleEquippedAccessory('cookie'), EquipResult.locked);
    expect(c.read(gameControllerProvider).equippedAccessories, ['mint_leaf', 'cookie'],
        reason: 'bị khoá thì món vẫn ở nguyên chỗ');
  });

  test('đang khoá vẫn lấp được ô trống (đây là nửa sau của một lần thay)', () async {
    final (c, ctrl, _) = await _setup();
    for (final id in ['mint_leaf', 'cupcake', 'cookie']) {
      ctrl.tryToggleEquippedAccessory(id);
    }
    ctrl.tryToggleEquippedAccessory('cupcake'); // tháo → khoá
    expect(ctrl.tryToggleEquippedAccessory('dragon'), EquipResult.equipped);
    expect(c.read(gameControllerProvider).equippedAccessories, ['mint_leaf', 'cookie', 'dragon']);
    // và lần thay kế tiếp thì bị chặn:
    expect(ctrl.tryToggleEquippedAccessory('mint_leaf'), EquipResult.locked);
  });

  test('hết 30 phút thì tháo lại được', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(_owned)
      ..equippedAccessories.addAll(['mint_leaf', 'cupcake'])
      ..equipLockUntilMillis = 1000000 + 60000; // còn 1 phút so với đồng hồ test
    final (_, ctrl, _) = await _setup(seed: seed);
    expect(ctrl.tryToggleEquippedAccessory('cupcake'), EquipResult.locked);
  });

  test('qua mốc khoá thì được tháo (đồng hồ chạy tới)', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(_owned)
      ..equippedAccessories.addAll(['mint_leaf', 'cupcake'])
      ..equipLockUntilMillis = 1000000; // đúng bằng "bây giờ" → đã hết khoá
    final (_, ctrl, _) = await _setup(seed: seed);
    expect(ctrl.tryToggleEquippedAccessory('cupcake'), EquipResult.removed);
  });

  test('unlockEquipSwap: mở khoá ngay, tháo được liền', () async {
    final (c, ctrl, _) = await _setup();
    for (final id in ['mint_leaf', 'cupcake']) {
      ctrl.tryToggleEquippedAccessory(id);
    }
    ctrl.tryToggleEquippedAccessory('cupcake');
    expect(ctrl.tryToggleEquippedAccessory('mint_leaf'), EquipResult.locked);
    ctrl.unlockEquipSwap();
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
    expect(ctrl.tryToggleEquippedAccessory('mint_leaf'), EquipResult.removed);
  });

  test('toggleEquippedAccessory (API cũ): true khi đổi được, false khi bị khoá/hết ô/chưa có', () async {
    final (_, ctrl, _) = await _setup();
    expect(ctrl.toggleEquippedAccessory('mint_leaf'), isTrue);
    expect(ctrl.toggleEquippedAccessory('cupcake'), isTrue);
    expect(ctrl.toggleEquippedAccessory('mint_leaf'), isTrue); // tháo → khoá
    expect(ctrl.toggleEquippedAccessory('cupcake'), isFalse); // bị khoá
    expect(ctrl.toggleEquippedAccessory('galaxy'), isFalse); // chưa có
  });

  test('bán nốt bản cuối tự gỡ KHÔNG bị tính là tháo (không khoá)', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.add('dragon')
      ..equippedAccessories.add('dragon');
    final (c, ctrl, _) = await _setup(seed: seed);
    ctrl.removeOwnedAccessoryLocally('dragon');
    expect(c.read(gameControllerProvider).equippedAccessories, isEmpty);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
  });

  group('lưu / đọc', () {
    test('equipLockUntilMillis lưu và đọc lại; save cũ thiếu trường → 0', () {
      final s = GameState.newGame(nowMillis: 0)..equipLockUntilMillis = 12345;
      expect(GameState.fromJson(s.toJson()).equipLockUntilMillis, 12345);
      expect(GameState.fromJson(s.toJson()..remove('equipLockUntilMillis')).equipLockUntilMillis, 0);
    });

    test('nạp save có mốc khoá quá xa (lỗi/chỉnh đồng hồ) bị kẹp về tối đa 30 phút', () async {
      final seed = GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(_owned)
        ..equippedAccessories.add('dragon')
        ..equipLockUntilMillis = 999999999999;
      final (c, _, now) = await _setup(seed: seed);
      expect(c.read(gameControllerProvider).equipLockUntilMillis, lessThanOrEqualTo(now() + _lockMs));
    });

    test('mốc khoá âm bị kẹp về 0', () async {
      final seed = GameState.newGame(nowMillis: 0)
        ..ownedAccessories.addAll(_owned)
        ..equipLockUntilMillis = -5;
      final (c, _, _) = await _setup(seed: seed);
      expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
    });
  });
}
