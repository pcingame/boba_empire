import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weather_delivery.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _t0 = 1000 * 3600 * 1000;

Future<ProviderContainer> _c(int Function() clock, {double money = 1e12}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _t0)
        ..tutorialSeen = true
        ..money = money
        ..levels[Balance.generators.first.id] = 10,
      nowMillis: _t0);
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
}

void main() {
  test('công thức: thời tiết xác định theo khung, đủ 4 loại, đếm ngược trong khung', () {
    expect({for (var s = 0; s < 200; s++) weatherOf(s)}, {0, 1, 2, 3});
    expect(weatherOf(77), weatherOf(77));
    expect(weatherSlot(0), 0);
    expect(weatherSlot(weatherSlotHours * 3600 * 1000), 1);
    expect(weatherSecondsLeft(0), weatherSlotHours * 3600);
    expect(weatherSecondsLeft(weatherSlotHours * 3600 * 1000 - 1000), 1);
    expect(weatherReward(true, double.nan), weatherFloor);
    expect(weatherReward(true, 1e6) > weatherReward(false, 1e6), isTrue);
    expect(deliveryStake(2, double.infinity), 1000);
    // Xác suất thắng thực tế gần danh nghĩa (hạt giống 0..9999).
    for (var t = 0; t < deliveryTiers.length; t++) {
      final wins = [for (var s = 0; s < 10000; s++) deliveryWins(t, s)].where((w) => w).length / 10000;
      expect(wins, closeTo(deliveryTiers[t].winChance, 0.02));
      expect(deliveryTiers[t].winChance * deliveryTiers[t].payout, greaterThan(1), reason: 'kỳ vọng dương');
    }
  });

  test('thời tiết: mỗi khung chọn một lần, đúng thưởng hơn sai, sang khung mới chọn lại, lưu/đọc', () async {
    var now = _t0;
    final c = await _c(() => now);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    final best = weatherBestMenu(weatherOf(weatherSlot(now)));
    final wrong = (best + 1) % weatherKinds;
    expect(ctl.pickWeatherMenu(-1), 0);
    expect(ctl.pickWeatherMenu(99), 0);
    final money0 = c.read(gameControllerProvider).money;
    final right = ctl.pickWeatherMenu(best);
    expect(right, greaterThan(0));
    expect(c.read(gameControllerProvider).money, closeTo(money0 + right, right * 1e-6 + 1));
    expect(ctl.pickWeatherMenu(wrong), 0, reason: 'đã chọn khung này');
    now += weatherSlotHours * 3600 * 1000;
    final b2 = weatherBestMenu(weatherOf(weatherSlot(now)));
    final w2 = ctl.pickWeatherMenu((b2 + 1) % weatherKinds);
    expect(w2, greaterThan(0));
    expect(w2, lessThan(right), reason: 'chọn sai thưởng ít hơn chọn đúng');
    expect(GameState.fromJson(ctl.debugGame.toJson()).weatherSlotPicked, weatherSlot(now));
  });

  test('giao hàng: cược trừ Xu, chưa tới hạn không chốt, chốt xác định (đóng mở app không đổi), một hợp đồng một lúc', () async {
    var now = _t0;
    final c = await _c(() => now);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.finishDelivery(), isNull, reason: 'không có hợp đồng');
    final money0 = c.read(gameControllerProvider).money;
    expect(ctl.startDelivery(1), isTrue);
    final stake = c.read(gameControllerProvider).contractStake;
    expect(c.read(gameControllerProvider).money, closeTo(money0 - stake, 1));
    expect(ctl.startDelivery(0), isFalse, reason: 'đang có hợp đồng');
    expect(ctl.finishDelivery(), isNull, reason: 'chưa tới hạn');
    // Lưu/đọc giữ hợp đồng; kết quả theo hạt giống nên giống nhau.
    final back = GameState.fromJson(ctl.debugGame.toJson());
    expect(back.contractTier, 1);
    expect(deliveryWins(back.contractTier, back.contractSeed), deliveryWins(1, ctl.debugGame.contractSeed));
    now += deliveryDurationMillis(1);
    final win = deliveryWins(1, ctl.debugGame.contractSeed);
    final gain = ctl.finishDelivery()!;
    expect(gain > 0, win);
    if (win) expect(gain, closeTo(stake * deliveryTiers[1].payout, 1));
    expect(c.read(gameControllerProvider).contractTier, -1);
    expect(ctl.finishDelivery(), isNull);
    // Thiếu Xu thì không nhận.
    ctl.debugGame.money = 0;
    expect(ctl.startDelivery(0), isFalse);
    expect(ctl.startDelivery(5), isFalse);
  });
}
