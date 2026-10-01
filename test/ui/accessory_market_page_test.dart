/// Chợ Phụ kiện: tab "Chợ" ẩn listing của chính mình, tab "Của tôi" hiện ví
/// + listing đang bán + món có thể đăng bán. Controller giả (không chạm
/// Supabase.instance) — cùng khuôn `story_speedrun_tabs_test.dart`.
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_market_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _myListing = MarketListing(
  id: 'listing-mine',
  sellerId: 'me',
  accessoryId: 'cupcake',
  price: 10,
  createdAt: DateTime.utc(2026, 10, 1),
);

final _otherListing = MarketListing(
  id: 'listing-other',
  sellerId: 'someone-else',
  accessoryId: 'dragon',
  price: 999,
  createdAt: DateTime.utc(2026, 10, 1),
);

class _FakeMarketController extends AccessoryMarketController {
  int buyCalls = 0;
  int cancelCalls = 0;

  @override
  AccessoryMarketViewState build() => AccessoryMarketLoaded(
    listings: [_myListing, _otherListing],
    myListings: [_myListing],
    walletBalance: 42,
    myUserId: 'me',
    recentSales: const [RecentSale(accessoryId: 'dragon', price: 777)],
  );

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  Future<String?> buyItem(MarketListing listing) async {
    buyCalls++;
    return null;
  }

  @override
  Future<String?> cancelItem(MarketListing listing) async {
    cancelCalls++;
    return null;
  }

  @override
  Future<String?> listItem(String accessoryId, int price) async => null;
}

Future<(ProviderContainer, _FakeMarketController)> _pump(
    WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)
    ..ownedAccessories.addAll(['mint_leaf']); // món có thể đăng bán
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final fake = _FakeMarketController();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    accessoryMarketControllerProvider.overrideWith(() => fake),
  ]);
  // KHÔNG addTearDown(container.dispose): tearDown chạy SAU khi flutter_test
  // đã kiểm "còn Timer treo không" (GameController có Timer tick định kỳ) —
  // phải tự dispose() ngay cuối mỗi test (xem cuối file) để kịp trước lúc đó.
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccessoryMarketPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, fake);
}

void main() {
  testWidgets('tab Chợ: ẩn listing của chính mình, chỉ hiện của người khác',
      (tester) async {
    final (container, _) = await _pump(tester);

    expect(find.text('Rồng nhỏ'), findsOneWidget); // listing của người khác
    expect(find.text('Bánh cupcake'), findsNothing); // listing của mình bị ẩn
    expect(find.textContaining('Vừa bán'), findsOneWidget);
    expect(find.textContaining('777'), findsOneWidget); // dải Vừa bán

    // GameController có Timer tick định kỳ — phải dispose() NGAY trong thân
    // test (addTearDown chạy sau khi flutter_test đã kiểm "còn Timer treo
    // không" nên quá trễ để kịp).
    container.dispose();
  });

  testWidgets(
      'tab Của tôi: hiện ví, listing đang bán (Huỷ đăng) + món có thể đăng bán',
      (tester) async {
    final (container, _) = await _pump(tester);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();

    expect(find.text('42 Xu Chợ'), findsOneWidget);
    expect(find.text('Bánh cupcake'), findsOneWidget); // listing của mình
    expect(find.text('Huỷ đăng'), findsOneWidget);
    expect(find.text('Lá bạc hà'), findsOneWidget); // món có thể đăng bán
    expect(find.text('Đăng bán'), findsOneWidget);

    container.dispose();
  });

  testWidgets('bấm Mua -> xác nhận -> gọi buyItem đúng 1 lần', (tester) async {
    final (container, fake) = await _pump(tester);

    await tester.tap(find.text('Mua'));
    await tester.pumpAndSettle();
    expect(find.text('Mua với giá 999 Xu Chợ?'), findsOneWidget);

    await tester.tap(find.text('Mua').last); // nút xác nhận trong dialog
    await tester.pumpAndSettle();

    expect(fake.buyCalls, 1);
    container.dispose();
  });

  testWidgets('tab Của tôi: bấm Huỷ đăng -> gọi cancelItem đúng 1 lần',
      (tester) async {
    final (container, fake) = await _pump(tester);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Huỷ đăng'));
    await tester.pumpAndSettle();

    expect(fake.cancelCalls, 1);
    container.dispose();
  });
}
