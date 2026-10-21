// Hộp "Quán của tôi" (Nhân viên + Linh vật) và "Sự kiện tuần" (Boss Thế Giới + Đấu giá): mở đúng mục, không tràn 320px.
import 'package:boba_empire/auction/auction.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/my_shop_hub_dialog.dart';
import 'package:boba_empire/ui/weekly_events_hub_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements AuctionRepository {
  @override
  Future<AuctionInfo> current() async => AuctionInfo(
      itemId: 'season_sakura', endsAt: DateTime.now().toUtc(), open: false, topBid: 0, bidCount: 0, topIsMe: false, topNick: null, nextMin: 100, maxBid: 20000);
  @override
  Future<void> bid(int gems) async {}
  @override
  Future<AuctionPickups> collect() async => const AuctionPickups();
  @override
  Future<void> ack(AuctionPickups p) async {}
}

Future<ProviderContainer> _open(WidgetTester tester, void Function(BuildContext) show, {String lang = 'vi', double scale = 1}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..tutorialSeen = true, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    auctionRepositoryProvider.overrideWithValue(_Repo()),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => show(ctx), child: const Text('go')))),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('Quán của tôi: mở Nhân viên và Linh vật', (tester) async {
    final c = await _open(tester, showMyShopHub);
    await tester.tap(find.byKey(const Key('shop-staff')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('staff-0')), findsOneWidget);
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    c.dispose();

    final c2 = await _open(tester, showMyShopHub);
    await tester.tap(find.byKey(const Key('shop-pet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pet-up')), findsOneWidget);
    await _close(tester, c2);
  });

  testWidgets('Sự kiện tuần: mở Đấu giá', (tester) async {
    final c = await _open(tester, showWeeklyEventsHub);
    expect(find.byKey(const Key('weekly-world-boss')), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly-auction')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auction-closed')), findsOneWidget);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('hai hộp không tràn ở 320px, chữ 1.5× ($lang)', (tester) async {
      var c = await _open(tester, showMyShopHub, lang: lang, scale: 1.5);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
      c = await _open(tester, showWeeklyEventsHub, lang: lang, scale: 1.5);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
