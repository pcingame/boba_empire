import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/core/vip_shop.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/topup_dialog.dart';
import 'package:boba_empire/ui/vip_shop_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

/// Mở màn VIP (qua nút) hoặc thẳng cửa hàng VIP.
Future<ProviderContainer> _open(
  WidgetTester tester, {
  int vipExp = 0,
  int coins = 0,
  String locale = 'en',
  Size size = const Size(400, 900),
  bool shopDirect = true,
  List<String> owned = const [],
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..vipExp = vipExp
        ..vipCoins = coins
        ..ownedLimited.addAll(owned),
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 100 * _day),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => shopDirect ? showVipShop(ctx) : showTopupDialog(ctx),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

FilledButton _buy(WidgetTester tester, String id) =>
    tester.widget<FilledButton>(find.byKey(Key('vip-shop-buy-$id')));

void main() {
  testWidgets('hiện số dư Xu VIP và đủ 8 món; món vượt cấp bị khoá kèm cấp yêu cầu', (tester) async {
    final c = await _open(tester, vipExp: topupTiers[1].exp, coins: 1000); // VIP 2
    expect(find.text('VIP Coins: ${formatNumber(1000)}'), findsOneWidget);
    for (final i in vipShopItems) {
      await tester.ensureVisible(find.byKey(Key('vip-shop-item-${i.id}')));
      expect(find.byKey(Key('vip-shop-item-${i.id}')), findsOneWidget, reason: i.id);
    }
    // VIP 2: món cấp ≤ 2 mua được, từ cấp 3 trở lên khoá.
    expect(_buy(tester, 'vip_watch').onPressed, isNotNull);
    expect(_buy(tester, 'vip_luggage').onPressed, isNotNull);
    expect(_buy(tester, 'vip_briefcase').onPressed, isNull);
    expect(find.text('Needs VIP 8'), findsOneWidget); // vip_jet
    await _close(tester, c);
  });

  testWidgets('đủ cấp nhưng thiếu Xu: nút tắt; đủ Xu: mua → trừ Xu, món vào kho, hiện "Owned"',
      (tester) async {
    final item = vipShopItems[0];
    final poor = await _open(tester, vipExp: topupTiers[0].exp, coins: item.price - 1);
    expect(_buy(tester, item.id).onPressed, isNull);
    await _close(tester, poor);

    final c = await _open(tester, vipExp: topupTiers[0].exp, coins: item.price + 20);
    await tester.tap(find.byKey(Key('vip-shop-buy-${item.id}')));
    await tester.pumpAndSettle();
    final s = c.read(gameControllerProvider);
    expect(s.vipCoins, 20);
    expect(s.ownedLimited, contains(item.id));
    expect(find.text('Got Luxury Watch!'), findsOneWidget);
    expect(find.text('Owned'), findsOneWidget);
    expect(find.byKey(Key('vip-shop-buy-${item.id}')), findsNothing); // thay bằng dấu tick
    await _close(tester, c);
  });

  testWidgets('đã có món từ save: hiện "Owned", không có nút mua', (tester) async {
    final c = await _open(tester,
        vipExp: topupTiers[7].exp, coins: 9999, owned: ['vip_jet']);
    await tester.ensureVisible(find.byKey(const Key('vip-shop-item-vip_jet')));
    expect(find.byKey(const Key('vip-shop-buy-vip_jet')), findsNothing);
    expect(find.text('Owned'), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('màn VIP: nút Cửa hàng VIP hiện số Xu; nhận quà kỳ báo kèm Xu VIP và cộng Xu',
      (tester) async {
    final c = await _open(tester,
        vipExp: topupTiers[2].exp, shopDirect: false); // VIP 3
    expect(find.textContaining('VIP shop'), findsOneWidget);
    // Quà ngày VIP 3 = 30 💎 + 15 Xu VIP.
    await tester.ensureVisible(find.byKey(const Key('vip-claim-daily')));
    await tester.pumpAndSettle();
    expect(find.textContaining('+15 🛍️'), findsOneWidget);
    await tester.tap(find.byKey(const Key('vip-claim-daily')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).vipCoins, 15);
    expect(find.text('Claimed +30 💎 +15 VIP Coins'), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('mở cửa hàng VIP từ màn VIP rồi đóng được', (tester) async {
    final c = await _open(tester, vipExp: topupTiers[0].exp, shopDirect: false);
    await tester.ensureVisible(find.byKey(const Key('vip-shop-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vip-shop-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vip-shop-coins')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Close').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vip-shop-coins')), findsNothing);
    expect(find.byKey(const Key('vip-shop-open')), findsOneWidget); // màn VIP còn mở
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('cửa hàng VIP không tràn ở 320px ($lang) với số Xu rất lớn', (tester) async {
      final c = await _open(tester,
          vipExp: topupTiers.last.exp,
          coins: 999999999,
          locale: lang,
          size: const Size(320, 640),
          owned: ['vip_jet']);
      for (final i in vipShopItems) {
        await tester.ensureVisible(find.byKey(Key('vip-shop-item-${i.id}')));
      }
      expect(tester.takeException(), isNull, reason: lang);
      await _close(tester, c);
    });
  }
}
