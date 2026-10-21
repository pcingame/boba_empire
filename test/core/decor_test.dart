import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/decor.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _c({double gems = 1000, double money = 1e9}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..tutorialSeen = true
        ..gems = gems
        ..money = money
        ..levels[Balance.generators.first.id] = 5,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('danh mục: 20 món, 4 chủ đề × 5, mỗi chủ đề đủ ô; id duy nhất', () {
    expect(decorItems.length, 20);
    expect({for (final d in decorItems) d.id}.length, 20);
    for (var t = 0; t < decorThemeCount; t++) {
      expect(decorItems.where((d) => d.theme == t).length, decorThemeSize);
    }
    expect(decorSlotKeys.length, 8);
  });

  test('thưởng: +0.5%/món, bộ 3 +2%, đủ 5 +6%', () {
    expect(decorIncomeMultiplier({}), 1);
    expect(decorIncomeMultiplier({'sign#0': 'zen_sign'}), closeTo(1.005, 1e-12));
    final three = {'sign#0': 'zen_sign', 'wall#0': 'zen_wall', 'counter#0': 'zen_counter'};
    expect(decorIncomeMultiplier(three), closeTo(1 + 3 * 0.005 + 0.02, 1e-12));
    final five = {...three, 'floor#0': 'zen_floor1', 'floor#1': 'zen_floor2'};
    expect(decorIncomeMultiplier(five), closeTo(1 + 5 * 0.005 + 0.06, 1e-12));
    expect(decorCompleteThemes(five), {1});
    expect(decorIncomeMultiplier({'sign#0': 'khong_co'}), 1);
  });

  test('sanitize: bỏ ô lạ, sai loại, chưa sở hữu, trùng', () {
    final out = decorSanitizePlaced({
      'sign#0': 'zen_sign',
      'sign#9': 'zen_sign',
      'wall#0': 'zen_counter', // sai loại
      'wall#1': 'retro_wall', // chưa sở hữu
      'floor#0': 'zen_floor1',
      'floor#1': 'zen_floor1', // trùng
      'counter#0': 5,
    }, {'zen_sign', 'zen_counter', 'zen_floor1'});
    expect(out, {'sign#0': 'zen_sign', 'floor#0': 'zen_floor1'});
    expect(decorSanitizePlaced('rác', {}), isEmpty);
    expect(decorSanitizePlaced(null, {}), isEmpty);
  });

  test('save rác không làm hỏng: decorOwned/decorPlaced sai kiểu', () {
    final g = GameState.fromJson({
      ...GameState.newGame(nowMillis: 0).toJson(),
      'decorOwned': ['zen_sign', 'zen_sign', 'lạ', 3],
      'decorPlaced': {'sign#0': 'zen_sign', 'wall#0': 'retro_wall'},
    });
    expect(g.decorOwned, ['zen_sign']);
    expect(g.decorPlaced, {'sign#0': 'zen_sign'});
    final g2 = GameState.fromJson({...GameState.newGame(nowMillis: 0).toJson(), 'decorOwned': 'x', 'decorPlaced': [1]});
    expect(g2.decorOwned, isEmpty);
  });

  test('mua: 💎 cho món hiếm, Xu cho món thường; không mua hai lần; thiếu tiền thì từ chối', () async {
    final c = await _c();
    final ctl = c.read(gameControllerProvider.notifier);
    final g0 = c.read(gameControllerProvider).gems;
    expect(ctl.buyDecor('zen_sign'), isTrue);
    expect(c.read(gameControllerProvider).gems, g0 - 120);
    expect(ctl.buyDecor('zen_sign'), isFalse);
    final m0 = c.read(gameControllerProvider).money;
    expect(ctl.buyDecor('zen_counter'), isTrue);
    expect(c.read(gameControllerProvider).money, lessThan(m0));
    expect(ctl.buyDecor('không_có'), isFalse);
    final poor = await _c(gems: 10, money: 0);
    final p = poor.read(gameControllerProvider.notifier);
    expect(p.buyDecor('zen_sign'), isFalse);
    expect(p.buyDecor('zen_counter'), isFalse);
    expect(poor.read(gameControllerProvider).decorOwned, isEmpty);
  });

  test('đặt: đúng loại, phải sở hữu, dời món sang ô khác, gỡ; tăng thu nhập; lưu/đọc', () async {
    final c = await _c();
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.placeDecor('wall#0', 'zen_wall'), isFalse, reason: 'chưa mua');
    ctl.buyDecor('zen_wall');
    expect(ctl.placeDecor('sign#0', 'zen_wall'), isFalse, reason: 'sai loại');
    expect(ctl.placeDecor('wall#9', 'zen_wall'), isFalse);
    final before = ctl.debugGame.decorPlaced.length;
    expect(ctl.placeDecor('wall#0', 'zen_wall'), isTrue);
    expect(ctl.placeDecor('wall#1', 'zen_wall'), isTrue);
    expect(c.read(gameControllerProvider).decorPlaced, {'wall#1': 'zen_wall'}, reason: 'dời, không nhân đôi');
    expect(before, 0);
    final back = GameState.fromJson(ctl.debugGame.toJson());
    expect(back.decorPlaced, {'wall#1': 'zen_wall'});
    expect(back.decorOwned, ['zen_wall']);
    expect(ctl.clearDecor('wall#1'), isTrue);
    expect(ctl.clearDecor('wall#1'), isFalse);
    expect(c.read(gameControllerProvider).decorOwned, ['zen_wall'], reason: 'gỡ vẫn giữ món');
  });
}
