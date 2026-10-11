import 'dart:ui' as ui;

import 'package:boba_empire/core/daily_deal.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

int _dayWith(DealKind kind) {
  for (var d = 100; d < 107; d++) {
    if (dailyDealFor(d).kind == kind) return d;
  }
  throw StateError('$kind');
}

/// Mở cửa hàng 💎 ở ngày [day] (clock cố định giữa ngày) với [gems] 💎.
Future<ProviderContainer> _openShop(
  WidgetTester tester, {
  required int day,
  double gems = 1000,
  String locale = 'en',
  Size size = const Size(400, 800),
  int dealClaimedDay = 0,
  bool withIncome = false,
}) async {
  tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final now = day * _day + 12 * 3600 * 1000;
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..gems = gems
        ..dealClaimedDay = dealClaimedDay
        ..levels['tra_den'] = withIncome ? 10 : 0
        ..tutorialSeen = true,
      nowMillis: now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
    clockProvider.overrideWithValue(() => now),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: c, child: const BobaEmpireApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('gem-shop-button')));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('thẻ hiện món của ngày, giá gốc gạch ngang, % giảm, giá mới và giờ còn lại',
      (tester) async {
    final day = _dayWith(DealKind.packRare);
    final deal = dailyDealFor(day);
    final c = await _openShop(tester, day: day);
    expect(find.byKey(const Key('daily-deal')), findsOneWidget);
    expect(find.text("Today's deal"), findsOneWidget);
    expect(find.text('Rare Pack (Rare or better)'), findsOneWidget);
    expect(find.text('-${deal.discountPercent}%'), findsOneWidget);
    expect(find.text('${deal.baseGems} 💎'), findsOneWidget); // giá gốc
    expect(find.text('${deal.price} 💎'), findsOneWidget); // giá mới trên nút
    // Giữa ngày (12:00 UTC) còn đúng 12 giờ.
    expect(find.textContaining('00:00 UTC'), findsOneWidget);
    expect(find.textContaining('12h'), findsWidgets);
    await _close(tester, c);
  });

  testWidgets('đủ 💎: bấm mua → trừ 💎, đánh dấu đã mua, nút tắt, hiện "đã mua hôm nay"',
      (tester) async {
    final day = _dayWith(DealKind.packBasic);
    final deal = dailyDealFor(day);
    final c = await _openShop(tester, day: day, gems: 1000);
    await tester.tap(find.byKey(const Key('daily-deal-buy')));
    await tester.pumpAndSettle();
    final s = c.read(gameControllerProvider);
    expect(s.gems, closeTo(1000 - deal.price, 0.0001));
    expect(s.dealClaimedDay, day);
    expect(find.byKey(const Key('daily-deal-claimed')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('daily-deal-buy'))).onPressed,
        isNull);
    await _close(tester, c);
  });

  testWidgets('thiếu 💎: nút tắt, không mua được', (tester) async {
    final day = _dayWith(DealKind.packEpic);
    final deal = dailyDealFor(day);
    final c = await _openShop(tester, day: day, gems: deal.price - 1.0);
    expect(tester.widget<FilledButton>(find.byKey(const Key('daily-deal-buy'))).onPressed,
        isNull);
    await _close(tester, c);
  });

  testWidgets('đã mua hôm nay (từ save): hiện "đã mua", nút tắt', (tester) async {
    final day = _dayWith(DealKind.packRare);
    final c = await _openShop(tester, day: day, dealClaimedDay: day);
    expect(find.byKey(const Key('daily-deal-claimed')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('daily-deal-buy'))).onPressed,
        isNull);
    await _close(tester, c);
  });

  testWidgets('ngày hôm sau (đã mua hôm qua): thẻ hoạt động lại', (tester) async {
    final day = _dayWith(DealKind.packRare);
    final c = await _openShop(tester, day: day + 1, gems: 1000, dealClaimedDay: day);
    expect(find.byKey(const Key('daily-deal-claimed')), findsNothing);
    final next = dailyDealFor(day + 1);
    final enabled =
        tester.widget<FilledButton>(find.byKey(const Key('daily-deal-buy'))).onPressed != null;
    // Tua nhanh cần thu nhập nhưng nút vẫn bấm được (chỉ báo "chưa mua được" nếu thiếu thu nhập).
    expect(enabled, isTrue, reason: '${next.kind}');
    await _close(tester, c);
  });

  testWidgets('tua nhanh khi chưa có thu nhập: bấm → báo chưa mua được, không trừ 💎',
      (tester) async {
    final day = _dayWith(DealKind.timeSkip);
    final c = await _openShop(tester, day: day, gems: 500, withIncome: false);
    await tester.tap(find.byKey(const Key('daily-deal-buy')));
    await tester.pumpAndSettle();
    expect(find.text("This deal can't be bought right now."), findsOneWidget);
    expect(c.read(gameControllerProvider).gems, 500);
    expect(c.read(gameControllerProvider).dealClaimedDay, 0);
    await _close(tester, c);
  });

  for (final locale in ['vi', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('thẻ ưu đãi không tràn ở 320px ($locale), cả khi đã mua', (tester) async {
      final day = _dayWith(DealKind.packEpic);
      final c = await _openShop(
          tester, day: day, locale: locale, size: const Size(320, 700), dealClaimedDay: day);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('daily-deal')), findsOneWidget);
      await _close(tester, c);
    });
  }
}
