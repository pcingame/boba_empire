import 'dart:ui' as ui;

import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
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

Future<ProviderContainer> _openShop(
  WidgetTester tester, {
  int vipExp = 0,
  String locale = 'en',
  Size size = const Size(400, 900),
  bool claimedAll = false,
}) async {
  tester.platformDispatcher.localesTestValue = [ui.Locale(locale)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  const day = 100;
  final now = day * _day + 12 * 3600 * 1000;
  final save = GameState.newGame(nowMillis: now)
    ..vipExp = vipExp
    ..tutorialSeen = true;
  if (claimedAll) {
    save
      ..vipClaimDay = vipPeriodIndex(VipPeriod.daily, now)
      ..vipClaimWeek = vipPeriodIndex(VipPeriod.weekly, now)
      ..vipClaimMonth = vipPeriodIndex(VipPeriod.monthly, now);
  }
  await GameStorage(prefs).save(save, nowMillis: now);
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
  testWidgets('chưa có VIP: thẻ ở ĐẦU cửa hàng, rộng hết hàng, có lời mời nạp, không chấm đỏ',
      (tester) async {
    final c = await _openShop(tester);
    expect(find.byKey(const Key('topup-open')), findsOneWidget);
    expect(find.text('Top-up rewards & VIP'), findsOneWidget);
    expect(find.text('Top up to unlock daily, weekly and monthly VIP gifts'), findsOneWidget);
    expect(find.byKey(const Key('topup-open-dot')), findsNothing);
    // Thẻ nằm trên thẻ Ưu đãi hôm nay (đầu danh sách) và chiếm toàn bộ chiều rộng nội dung.
    final card = tester.getRect(find.byKey(const Key('topup-open')));
    final deal = tester.getRect(find.byKey(const Key('daily-deal')));
    expect(card.top, lessThan(deal.top));
    expect(card.width, closeTo(deal.width, 1));
    await _close(tester, c);
  });

  testWidgets('có VIP và còn quà chưa nhận: hiện biệt danh + EXP và chấm đỏ', (tester) async {
    final c = await _openShop(tester, vipExp: topupTiers[4].exp); // VIP 5
    expect(find.text('Shop Owner · ${formatNumber(topupTiers[4].exp.toDouble())} VIP EXP'),
        findsOneWidget);
    expect(find.byKey(const Key('topup-open-dot')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('đã nhận hết quà kỳ: không còn chấm đỏ', (tester) async {
    final c = await _openShop(tester, vipExp: topupTiers[2].exp, claimedAll: true);
    expect(find.byKey(const Key('topup-open-dot')), findsNothing);
    expect(find.byKey(const Key('topup-open-title')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('bấm thẻ mở màn VIP; nhận quà xong quay lại thì chấm đỏ biến mất', (tester) async {
    final c = await _openShop(tester, vipExp: topupTiers[0].exp); // VIP 1
    expect(find.byKey(const Key('topup-open-dot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('topup-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vip-how-to-button')), findsOneWidget); // màn VIP đã mở
    for (final p in ['daily', 'weekly', 'monthly']) {
      await tester.ensureVisible(find.byKey(Key('vip-claim-$p')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('vip-claim-$p')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(TextButton, 'Close').last); // đóng màn VIP
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('topup-open-dot')), findsNothing);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('thẻ VIP không tràn ở 320px ($lang): chưa có VIP và VIP 10', (tester) async {
      var c = await _openShop(tester, locale: lang, size: const Size(320, 700));
      expect(tester.takeException(), isNull, reason: '$lang chưa VIP');
      await _close(tester, c);
      c = await _openShop(tester,
          vipExp: topupTiers.last.exp, locale: lang, size: const Size(320, 700));
      expect(tester.takeException(), isNull, reason: '$lang VIP 10');
      await _close(tester, c);
    });
  }
}
