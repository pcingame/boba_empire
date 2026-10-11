import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily_deal.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

/// Ngày [n] kể từ epoch có ưu đãi là [kind]: tìm ngày đầu tiên ≥ 100 khớp loại.
int _dayWith(DealKind kind) {
  for (var d = 100; d < 107; d++) {
    if (dailyDealFor(d).kind == kind) return d;
  }
  throw StateError('không có ngày nào cho $kind');
}

Future<ProviderContainer> _ctl(GameState seed, int Function() clock) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gói phụ kiện: thiếu 💎 → null, không đổi gì; đủ → trừ đúng giá đã giảm + rớt ≥ độ hiếm',
      () async {
    final day = _dayWith(DealKind.packRare);
    final deal = dailyDealFor(day);
    final poor = await _ctl(GameState.newGame(nowMillis: 0)..gems = deal.price - 1.0, () => day * _day);
    expect(poor.read(gameControllerProvider.notifier).buyDailyDeal(), isNull);
    expect(poor.read(gameControllerProvider).gems, deal.price - 1.0);
    expect(poor.read(gameControllerProvider).dealClaimedDay, 0);

    final c = await _ctl(GameState.newGame(nowMillis: 0)..gems = 1000, () => day * _day);
    final r = c.read(gameControllerProvider.notifier).buyDailyDeal();
    expect(r, isNotNull);
    expect(r!.drop, isNotNull);
    expect(r.cash, 0);
    expect(c.read(gameControllerProvider).gems, 1000 - deal.price);
    expect(c.read(gameControllerProvider).dealClaimedDay, day);
    // Gói Hiếm: độ hiếm ≥ Hiếm.
    expect(r.drop!.accessory.rarity.index, greaterThanOrEqualTo(AccessoryRarity.rare.index));
  });

  test('mỗi ngày một lần: mua lần 2 cùng ngày → null và không trừ 💎', () async {
    final day = _dayWith(DealKind.packBasic);
    final c = await _ctl(GameState.newGame(nowMillis: 0)..gems = 1000, () => day * _day);
    final n = c.read(gameControllerProvider.notifier);
    expect(n.buyDailyDeal(), isNotNull);
    final after = c.read(gameControllerProvider).gems;
    expect(n.buyDailyDeal(), isNull);
    expect(c.read(gameControllerProvider).gems, after);
  });

  test('sang ngày mới: mua lại được, món mới theo vòng xoay', () async {
    var now = _dayWith(DealKind.packBasic) * _day;
    final c = await _ctl(GameState.newGame(nowMillis: 0)..gems = 5000, () => now);
    final n = c.read(gameControllerProvider.notifier);
    expect(n.buyDailyDeal(), isNotNull);
    expect(n.buyDailyDeal(), isNull);
    now += _day; // ngày kế
    final before = c.read(gameControllerProvider).gems;
    final r = n.buyDailyDeal();
    final next = dailyDealFor(now ~/ _day);
    // Ngày kế có thể là tua nhanh (cần thu nhập) hoặc gói; tay trắng + 5000💎 chỉ mua được gói.
    if (next.kind == DealKind.timeSkip) {
      expect(r, isNull); // chưa có thu nhập → không mua, không mất 💎
      expect(c.read(gameControllerProvider).gems, before);
    } else {
      expect(r, isNotNull);
      // Rớt trùng món đã có (ngẫu nhiên) được đổi thành 💎: tính vào kỳ vọng, khỏi chập chờn.
      final dup = r!.drop != null && !r.drop!.isNew ? Balance.duplicateAccessoryGems : 0;
      expect(c.read(gameControllerProvider).gems, before - next.price + dup);
    }
  });

  test('tua nhanh: cộng ~4 giờ thu nhập với giá giảm, KHÔNG tính vào hạn mức tua nhanh ngày',
      () async {
    final day = _dayWith(DealKind.timeSkip);
    final deal = dailyDealFor(day);
    final seed = GameState.newGame(nowMillis: 0)
      ..gems = 500
      ..levels['tra_den'] = 10;
    final c = await _ctl(seed, () => day * _day);
    final income = c.read(gameControllerProvider).incomePerSecond;
    final moneyBefore = c.read(gameControllerProvider).money;
    // Tính theo 💎 ngay trước khi mua (nhiệm vụ mở màn có thể đã tự cộng vài 💎 lúc nạp save).
    final gemsBefore = c.read(gameControllerProvider).gems;
    final r = c.read(gameControllerProvider.notifier).buyDailyDeal();
    expect(r, isNotNull);
    expect(r!.drop, isNull);
    expect(r.cash, closeTo(income * Balance.gemTimeSkipSeconds, 1e-6));
    final s = c.read(gameControllerProvider);
    expect(s.money, closeTo(moneyBefore + r.cash, 1e-6));
    expect(s.gems, gemsBefore - deal.price);
    expect(s.gemTimeSkipRemainingToday, Balance.maxGemTimeSkipPerDay);
  });

  test('tua nhanh khi chưa có thu nhập: null, không trừ 💎, không đánh dấu đã mua', () async {
    final day = _dayWith(DealKind.timeSkip);
    final c = await _ctl(GameState.newGame(nowMillis: 0)..gems = 500, () => day * _day);
    expect(c.read(gameControllerProvider.notifier).buyDailyDeal(), isNull);
    expect(c.read(gameControllerProvider).gems, 500);
    expect(c.read(gameControllerProvider).dealClaimedDay, 0);
  });

  test('ngày đã mua được lưu qua save/load; save cũ không có khoá → 0', () {
    final g = GameState.newGame(nowMillis: 0)..dealClaimedDay = 123;
    expect(GameState.fromJson(g.toJson()).dealClaimedDay, 123);
    final old = GameState.fromJson(
        GameState.newGame(nowMillis: 0).toJson()..remove('dealClaimedDay'));
    expect(old.dealClaimedDay, 0);
  });
}
