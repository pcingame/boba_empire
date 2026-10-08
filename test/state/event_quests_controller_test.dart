// Nhiệm vụ sự kiện qua controller thật: tiến độ được cộng từ chạm/mua, nhận
// thưởng, đổi món, reset khi hết dịp, và sống sót qua lưu/mở lại.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/event_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t = festivals.first.start.millisecondsSinceEpoch + 60000;

Future<(ProviderContainer, void Function(int), SharedPreferences)> _open(
    int at, {GameState? seed}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs)
      .save(seed ?? GameState.newGame(nowMillis: at), nowMillis: at);
  var now = at;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int t) => now = t, prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('chạm ly trong dịp cộng tiến độ sự kiện; ngoài dịp thì không', () async {
    final (out, _, _) = await _open(0);
    out.read(gameControllerProvider.notifier).tapCup();
    expect(out.read(gameControllerProvider).eventProgress, isEmpty);
    expect(out.read(gameControllerProvider).eventId, isEmpty);

    final (c, _, _) = await _open(_t);
    final ctrl = c.read(gameControllerProvider.notifier);
    for (var i = 0; i < 3; i++) {
      ctrl.tapCup();
    }
    final s = c.read(gameControllerProvider);
    expect(s.eventId, 'halloween');
    expect(s.eventProgress['tap'], 3);
  });

  test('app đang mở khi dịp bắt đầu: tick tự vào dịp rồi bắt đầu đếm', () async {
    final (c, setNow, _) = await _open(festivals.first.start.millisecondsSinceEpoch - 5000);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.tapCup();
    expect(c.read(gameControllerProvider).eventProgress, isEmpty);
    setNow(_t);
    ctrl.debugTick();
    ctrl.tapCup();
    expect(c.read(gameControllerProvider).eventProgress['tap'], 1);
  });

  test('nhận thưởng nhiệm vụ: +💎 +điểm, chỉ 1 lần, chưa xong thì không được',
      () async {
    final seed = GameState.newGame(nowMillis: _t)
      ..eventId = 'halloween'
      ..eventProgress['tap'] = 1500;
    final (c, _, _) = await _open(_t, seed: seed);
    final ctrl = c.read(gameControllerProvider.notifier);
    final gems0 = c.read(gameControllerProvider).gems;

    expect(ctrl.claimEventQuestReward(1), 0); // buy chưa xong
    expect(ctrl.claimEventQuestReward(0), Balance.eventQuestGems);
    expect(ctrl.claimEventQuestReward(0), 0);
    final s = c.read(gameControllerProvider);
    expect(s.gems, gems0 + Balance.eventQuestGems);
    expect(s.eventPoints, Balance.eventQuestPoints);
    expect(s.eventClaimableCount, 0);
  });

  test('chấm đỏ: đếm nhiệm vụ xong chưa nhận', () async {
    final seed = GameState.newGame(nowMillis: _t)
      ..eventId = 'halloween'
      ..eventProgress['tap'] = 1500
      ..eventProgress['cat'] = 6;
    final (c, _, _) = await _open(_t, seed: seed);
    expect(c.read(gameControllerProvider).eventClaimableCount, 2);
  });

  test('đổi điểm lấy món: trừ điểm, vào ownedLimited, không đổi 2 lần, '
      'thiếu điểm thì từ chối', () async {
    final seed = GameState.newGame(nowMillis: _t)
      ..eventId = 'halloween'
      ..eventPoints = 40;
    final (c, _, _) = await _open(_t, seed: seed);
    final ctrl = c.read(gameControllerProvider.notifier);

    expect(ctrl.redeemEventReward('witch'), isFalse); // legendary 50 > 40
    expect(ctrl.redeemEventReward('ghost'), isTrue); // epic 25
    expect(ctrl.redeemEventReward('ghost'), isFalse); // đã có
    expect(ctrl.redeemEventReward('santa'), isFalse); // món của dịp khác
    final s = c.read(gameControllerProvider);
    expect(s.eventPoints, 15);
    expect(s.ownedLimited, ['ghost']);
    expect(ctrl.redeemEventReward('bat'), isTrue); // rare 15, đủ đúng
    expect(c.read(gameControllerProvider).eventPoints, 0);
  });

  test('tổng điểm kiếm được < tổng giá cả bộ (người chơi phải chọn)', () {
    final total = festivals.first.items.fold<int>(0, (a, i) => a + eventItemCost(i));
    expect(eventQuests.length * Balance.eventQuestPoints, lessThan(total));
    // ...nhưng đủ đổi món huyền thoại nếu dồn hết cho nó.
    final legend = festivals.first.items
        .firstWhere((a) => a.rarity == AccessoryRarity.legendary);
    expect(eventQuests.length * Balance.eventQuestPoints,
        greaterThanOrEqualTo(eventItemCost(legend)));
  });

  test('mọi dịp: có đủ 4 món và giá hợp lệ', () {
    for (final f in festivals) {
      expect(f.items.length, 4, reason: f.id);
      for (final a in f.items) {
        expect(eventItemCost(a), greaterThan(0));
      }
    }
  });

  test('hết dịp (mở lại sau): tiến độ/điểm bị xoá, món đã đổi vẫn giữ', () async {
    final seed = GameState.newGame(nowMillis: _t)
      ..eventId = 'halloween'
      ..eventPoints = 30
      ..eventProgress['tap'] = 900
      ..ownedLimited.add('bat');
    final (c, _, _) =
        await _open(festivals.first.end.millisecondsSinceEpoch + 1000, seed: seed);
    final s = c.read(gameControllerProvider);
    expect(s.eventId, isEmpty);
    expect(s.eventPoints, 0);
    expect(s.eventProgress, isEmpty);
    expect(s.ownedLimited, ['bat']);
  });

  test('sống sót qua lưu rồi mở lại (cùng dịp)', () async {
    final (c, _, prefs) = await _open(_t);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.tapCup();
    await ctrl.saveNow();
    c.dispose();
    final c2 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => _t + 1000),
    ]);
    addTearDown(c2.dispose);
    final s = c2.read(gameControllerProvider);
    expect(s.eventId, 'halloween');
    expect(s.eventProgress['tap'], 1);
  });

  test('mua nhiều cấp một lần cộng đúng số lần vào tiến độ "buy"', () async {
    final seed = GameState.newGame(nowMillis: _t)..money = 1e9;
    final (c, _, _) = await _open(_t, seed: seed);
    final bought = c.read(gameControllerProvider.notifier).buyBulk('tra_den', 10);
    expect(bought, greaterThan(0));
    expect(c.read(gameControllerProvider).eventProgress['buy'], bought.toDouble());
  });
}
