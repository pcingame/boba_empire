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
import 'package:flutter/foundation.dart' show debugDefaultTargetPlatformOverride;
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

/// Món do bản app MỚI HƠN tạo ra — bản cũ không có trong danh mục.
List<MarketListing> _extraListings = const [];
int _wallet = 42;

class _FakeMarketController extends AccessoryMarketController {
  int buyCalls = 0;
  int cancelCalls = 0;

  @override
  AccessoryMarketViewState build() => AccessoryMarketLoaded(
    listings: [_myListing, _otherListing, ..._extraListings],
    myListings: [_myListing],
    walletBalance: _wallet,
    myUserId: 'me',
    recentSales: const [
      RecentSale(accessoryId: 'dragon', price: 777),
      RecentSale(accessoryId: 'item_from_future', price: 5),
    ],
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

  int listCalls = 0;

  @override
  Future<String?> listItem(String accessoryId, int price) async {
    listCalls++;
    return null;
  }
}

Future<(ProviderContainer, _FakeMarketController)> _pump(
    WidgetTester tester,
    {List<String> extraOwned = const [],
    bool starter = false,
    bool introSeen = true,
    int clockMs = 0}) async {
  SharedPreferences.setMockInitialValues({'market_intro_seen': introSeen});
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)
    ..ownedAccessories.addAll(['mint_leaf', ...extraOwned]); // món có thể đăng bán
  if (starter) {
    seed.stage = 3;
    seed.dailyQuestEverClaimed = true;
  }
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final fake = _FakeMarketController();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => clockMs),
    accessoryMarketControllerProvider.overrideWith(() => fake),
    priceStatsProvider.overrideWith((ref, id) async => id == 'dragon'
        ? const PriceStats(lastPrice: 700, lowestActive: 650, avg7d: 720)
        : const PriceStats()),
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
  testWidgets(
      'Android: cuộn hết cỡ không bóp danh sách (không có hiệu ứng kéo giãn) ở cả 2 tab',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final (container, _) = await _pump(tester);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    // Phải trả về null NGAY trong thân test (addTearDown chạy sau khi flutter_test
    // đã kiểm biến debug của foundation).
    debugDefaultTargetPlatformOverride = null;
    container.dispose();
  });

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
    _wallet = 5000; // đủ Xu Chợ cho món 999
    addTearDown(() => _wallet = 42);
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

  testWidgets('id phụ kiện lạ (từ bản app mới hơn) KHÔNG làm sập Chợ',
      (tester) async {
    _extraListings = [
      MarketListing(
        id: 'listing-future',
        sellerId: 'someone-else',
        accessoryId: 'item_from_future',
        price: 1,
        createdAt: DateTime.utc(2026, 10, 1),
      ),
    ];
    addTearDown(() => _extraListings = const []);
    final (container, _) = await _pump(tester, extraOwned: ['owned_from_future']);

    expect(tester.takeException(), isNull);
    expect(find.text('Rồng nhỏ'), findsOneWidget); // món biết vẫn hiện
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets('thiếu Xu Chợ: hộp mua báo thiếu bao nhiêu, nút thành Đổi, không mua',
      (tester) async {
    final (container, fake) = await _pump(tester); // ví 42, món 999

    await tester.tap(find.text('Mua'));
    await tester.pumpAndSettle();
    expect(find.text('Thiếu 957 Xu Chợ'), findsOneWidget);
    expect(find.text('Đổi'), findsOneWidget); // thay cho nút Mua xác nhận

    await tester.tap(find.text('Đổi'));
    await tester.pumpAndSettle();
    expect(fake.buyCalls, 0);
    expect(find.text('Mua với giá 999 Xu Chợ?'), findsNothing); // đã đóng
    container.dispose();
  });

  testWidgets('nhãn MỚI chỉ hiện với món chưa có; có rồi thì ẩn', (tester) async {
    var (container, _) = await _pump(tester);
    expect(find.text('MỚI'), findsOneWidget); // chưa có dragon
    container.dispose();
    await tester.pumpWidget(const SizedBox());

    (container, _) = await _pump(tester, extraOwned: ['dragon']);
    expect(find.text('MỚI'), findsNothing);
    container.dispose();
  });

  testWidgets('bộ lọc: độ hiếm không khớp -> thông báo rỗng; Tất cả -> hiện lại',
      (tester) async {
    final (container, _) = await _pump(tester);
    await tester.tap(find.text('Thường')); // listing duy nhất là huyền thoại
    await tester.pumpAndSettle();
    expect(find.text('Không có món nào khớp bộ lọc.'), findsOneWidget);
    expect(find.text('Rồng nhỏ'), findsNothing);

    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Rồng nhỏ'), findsOneWidget);
    container.dispose();
  });

  testWidgets('màn hẹp 360px + chữ 1.3x: thanh lọc, nhãn MỚI, tab số -> không tràn',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final (container, _) = await _pump(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.textContaining('Của tôi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    container.dispose();
  });

  testWidgets('thẻ Gói Khởi Nghiệp chỉ hiện khi đủ điều kiện', (tester) async {
    var (container, _) = await _pump(tester);
    expect(find.byKey(const Key('starter-pack-card')), findsNothing);
    container.dispose();
    await tester.pumpWidget(const SizedBox());

    (container, _) = await _pump(tester, starter: true);
    expect(find.byKey(const Key('starter-pack-card')), findsOneWidget);
    expect(find.text('Nhận quà'), findsOneWidget);
    container.dispose();
  });

  testWidgets('lần đầu vào Chợ hiện hướng dẫn 3 bước, đóng rồi không hiện lại',
      (tester) async {
    var (container, _) = await _pump(tester, introSeen: false);
    expect(find.byKey(const Key('market-intro')), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('market-intro')), findsNothing);
    container.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đã xem hướng dẫn thì không hiện', (tester) async {
    final (container, _) = await _pump(tester);
    expect(find.byKey(const Key('market-intro')), findsNothing);
    container.dispose();
  });

  testWidgets('hộp mua hiện giá tham khảo (bán gần nhất / rẻ nhất / TB 7 ngày)',
      (tester) async {
    final (container, _) = await _pump(tester);
    await tester.tap(find.text('Mua'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('price-reference')), findsOneWidget);
    expect(find.textContaining('Bán gần nhất: 700'), findsOneWidget);
    expect(find.textContaining('Rẻ nhất đang bán: 650'), findsOneWidget);
    expect(find.textContaining('TB 7 ngày: 720'), findsOneWidget);
    container.dispose();
  });

  testWidgets('hộp đăng bán: món chưa có dữ liệu giá thì không hiện khối tham khảo',
      (tester) async {
    final (container, _) = await _pump(tester);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng bán'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('price-reference')), findsNothing);
    container.dispose();
  });

  testWidgets('ngôi sao: thêm/bỏ món vào danh sách muốn có', (tester) async {
    final (container, _) = await _pump(tester);
    List<String> wl() => container.read(gameControllerProvider).wishlist;
    expect(wl(), isEmpty);
    await tester.tap(find.byKey(const Key('wish-dragon')));
    await tester.pump();
    expect(wl(), ['dragon']);
    await tester.tap(find.byKey(const Key('wish-dragon')));
    await tester.pump();
    expect(wl(), isEmpty);
    container.dispose();
    await tester.pumpAndSettle();
  });

  test('wishlist: JSON bỏ phần tử sai kiểu', () {
    final s = GameState.newGame(nowMillis: 0)..wishlist.addAll(['a', 'b']);
    final r = GameState.fromJson({...s.toJson(), 'wishlist': ['a', 3, null, 'b']});
    expect(r.wishlist, ['a', 'b']);
  });

  final saturday = DateTime.utc(2026, 10, 3, 12).millisecondsSinceEpoch;

  testWidgets('cuối tuần: có banner phí 0% và hộp đăng bán báo nhận đủ',
      (tester) async {
    final (container, _) = await _pump(tester, clockMs: saturday);
    expect(find.byKey(const Key('weekend-banner')), findsOneWidget);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng bán'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    expect(find.textContaining('Cuối tuần miễn phí'), findsOneWidget);
    expect(find.textContaining('phí 1%'), findsNothing);
    container.dispose();
  });

  testWidgets('ngày thường: không banner, hộp đăng bán báo phí 1%',
      (tester) async {
    final (container, _) = await _pump(tester); // clock 0 = thứ 5 (1/1/1970)
    expect(find.byKey(const Key('weekend-banner')), findsNothing);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng bán'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    expect(find.textContaining('1%'), findsOneWidget);
    container.dispose();
  });

  // Crash thật trên Crashlytics: ConsumerStatefulElement._assertNotDisposed ← _SellableTile.build
  // (ref.read sau await). Trong lúc hộp thoại giá mở, danh sách "có thể bán" đổi và gỡ ô đó.
  testWidgets('đăng bán: ô bị gỡ khỏi danh sách GIỮA lúc hộp giá mở -> xác nhận vẫn không crash',
      (tester) async {
    final (container, fake) = await _pump(tester);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng bán'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();

    // Trong lúc hộp thoại đang mở: món bị gỡ (vd đối chiếu/làm mới) -> _SellableTile dispose.
    container
        .read(gameControllerProvider.notifier)
        .removeOwnedAccessoryLocally('mint_leaf');
    await tester.pumpAndSettle();
    expect(find.text('Lá bạc hà'), findsNothing); // ô đã biến mất khỏi danh sách

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng bán')); // xác nhận trong hộp thoại
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(fake.listCalls, 1);
    container.dispose();
  });
}
