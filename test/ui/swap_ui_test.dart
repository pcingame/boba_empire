// Trao đổi vật phẩm trên giao diện Chợ: tab "Trao đổi", nút Đổi chỉ bật khi có món họ cần, xác nhận, tạo đề
// nghị (chọn món + tìm kiếm), huỷ trong "Của tôi", thông báo lỗi, 7 ngôn ngữ ở 360px. Controller giả.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_market_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AccessorySwap _swap(String id, {String give = 'dragon', String want = 'cupcake', String seller = 'other'}) =>
    AccessorySwap(id: id, sellerId: seller, giveId: give, wantId: want, createdAt: DateTime.now());

class _Fake extends AccessoryMarketController {
  _Fake({this.swaps = const [], this.mySwaps = const []});
  final List<AccessorySwap> swaps;
  final List<AccessorySwap> mySwaps;
  final accepted = <String>[];
  final cancelled = <String>[];
  final created = <(String, String)>[];
  SwapError? acceptResult;
  SwapError? createResult;

  @override
  AccessoryMarketViewState build() => AccessoryMarketLoaded(
        listings: const [],
        myListings: const [],
        walletBalance: 0,
        myUserId: 'me',
        swaps: [...swaps, ...mySwaps],
        mySwaps: mySwaps,
      );

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  Future<SwapError?> acceptSwap(AccessorySwap swap) async {
    accepted.add(swap.id);
    return acceptResult;
  }

  @override
  Future<SwapError?> cancelSwap(AccessorySwap swap) async {
    cancelled.add(swap.id);
    return null;
  }

  @override
  Future<SwapError?> createSwap(String giveId, String wantId) async {
    created.add((giveId, wantId));
    return createResult;
  }
}

Future<(ProviderContainer, _Fake)> _open(
  WidgetTester tester,
  _Fake fake, {
  List<String> owned = const ['mint_leaf'],
  String locale = 'vi',
  Size size = const Size(400, 900),
}) async {
  SharedPreferences.setMockInitialValues({'market_intro_seen': true});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..ownedAccessories.addAll(owned), nowMillis: 0);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    accessoryMarketControllerProvider.overrideWith(() => fake),
    priceStatsProvider.overrideWith((ref, id) async => const PriceStats()),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccessoryMarketPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, fake);
}

Future<void> _swapTab(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('market-tab-swap')));
  await tester.pumpAndSettle();
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('tab Trao đổi có giải thích + nút tạo; chưa có đề nghị thì báo rỗng', (tester) async {
    final (c, _) = await _open(tester, _Fake());
    await _swapTab(tester);
    expect(find.byKey(const Key('swap-intro')), findsOneWidget);
    expect(find.byKey(const Key('swap-create')), findsOneWidget);
    expect(find.byKey(const Key('swap-empty')), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('đề nghị của người khác: Đổi chỉ bật khi mình có món họ cần; không thấy đề nghị của chính mình ở tab này',
      (tester) async {
    final fake = _Fake(swaps: [_swap('s1', want: 'cupcake'), _swap('s2', want: 'mint_leaf')], mySwaps: [_swap('m1', seller: 'me')]);
    final (c, _) = await _open(tester, fake, owned: ['mint_leaf']);
    await _swapTab(tester);
    expect(find.byKey(const Key('swap-s1')), findsOneWidget);
    expect(find.byKey(const Key('swap-m1')), findsNothing, reason: 'đề nghị của mình nằm ở tab Của tôi');
    expect(tester.widget<FilledButton>(find.byKey(const Key('swap-accept-s1'))).onPressed, isNull,
        reason: 'chưa có cupcake');
    expect(tester.widget<FilledButton>(find.byKey(const Key('swap-accept-s2'))).onPressed, isNotNull,
        reason: 'có mint_leaf');
    await _end(tester, c);
  });

  testWidgets('bấm Đổi → xác nhận → gọi acceptSwap đúng đề nghị và báo thành công', (tester) async {
    final fake = _Fake(swaps: [_swap('s2', want: 'mint_leaf')]);
    final (c, _) = await _open(tester, fake);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-accept-s2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap-confirm')), findsOneWidget);
    expect(fake.accepted, isEmpty, reason: 'chưa xác nhận thì chưa gọi');
    await tester.tap(find.byKey(const Key('swap-confirm-ok')));
    await tester.pumpAndSettle();
    expect(fake.accepted, ['s2']);
    expect(find.textContaining('Đã đổi xong'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('huỷ ở hộp xác nhận thì không gọi server', (tester) async {
    final fake = _Fake(swaps: [_swap('s2', want: 'mint_leaf')]);
    final (c, _) = await _open(tester, fake);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-accept-s2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ').last);
    await tester.pumpAndSettle();
    expect(fake.accepted, isEmpty);
    await _end(tester, c);
  });

  testWidgets('server từ chối (đề nghị vừa bị nhận): hiện thông báo đúng', (tester) async {
    final fake = _Fake(swaps: [_swap('s2', want: 'mint_leaf')])..acceptResult = SwapError.notOpen;
    final (c, _) = await _open(tester, fake);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-accept-s2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-confirm-ok')));
    await tester.pumpAndSettle();
    expect(find.textContaining('vừa được nhận hoặc đã huỷ'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('tạo đề nghị: chọn món đưa (chỉ món mình có) + món muốn (có ô tìm) → gọi createSwap', (tester) async {
    final fake = _Fake();
    final (c, _) = await _open(tester, fake, owned: ['mint_leaf', 'angel_wing']);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-create')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('swap-create-ok'))).onPressed, isNull);
    // Món đưa: chỉ liệt kê món đang có.
    await tester.tap(find.byKey(const Key('swap-pick-give')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap-item-mint_leaf')), findsOneWidget);
    expect(find.byKey(const Key('swap-item-dragon')), findsNothing, reason: 'không có dragon trong kho');
    await tester.tap(find.byKey(const Key('swap-item-mint_leaf')));
    await tester.pumpAndSettle();
    // Món muốn: cả danh mục, trừ món đang đưa; gõ tìm.
    await tester.tap(find.byKey(const Key('swap-pick-want')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap-item-mint_leaf')), findsNothing, reason: 'không muốn lại chính món đưa');
    await tester.enterText(find.byKey(const Key('swap-search')), 'zzzzzzzz');
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing, reason: 'tìm không ra gì');
    await tester.enterText(find.byKey(const Key('swap-search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-item-angel_wing')).evaluate().isNotEmpty
        ? find.byKey(const Key('swap-item-angel_wing'))
        : find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('swap-create-ok'))).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('swap-create-ok')));
    await tester.pumpAndSettle();
    expect(fake.created.length, 1);
    expect(fake.created.single.$1, 'mint_leaf');
    expect(fake.created.single.$2, isNot('mint_leaf'));
    expect(find.textContaining('Đã đăng đề nghị'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('kho trống: hộp tạo đề nghị báo không có món để đưa', (tester) async {
    final (c, _) = await _open(tester, _Fake(), owned: const []);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('swap-no-items')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('swap-create-ok'))).onPressed, isNull);
    await _end(tester, c);
  });

  testWidgets('quá giới hạn đề nghị: báo lỗi đúng', (tester) async {
    final fake = _Fake()..createResult = SwapError.tooMany;
    final (c, _) = await _open(tester, fake);
    await _swapTab(tester);
    await tester.tap(find.byKey(const Key('swap-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-pick-give')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-item-mint_leaf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-pick-want')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swap-create-ok')));
    await tester.pumpAndSettle();
    expect(find.textContaining('quá nhiều đề nghị'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('tab Của tôi: đề nghị của mình có còn hạn + nút Huỷ → gọi cancelSwap', (tester) async {
    final fake = _Fake(mySwaps: [_swap('m1', seller: 'me', give: 'mint_leaf', want: 'dragon')]);
    final (c, _) = await _open(tester, fake);
    await tester.tap(find.text('Của tôi'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('swap-mine-m1')));
    expect(find.byKey(const Key('swap-expiry-m1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap-cancel-m1')));
    await tester.pumpAndSettle();
    expect(fake.cancelled, ['m1']);
    expect(find.textContaining('Đã huỷ đề nghị'), findsOneWidget);
    await _end(tester, c);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] tab Trao đổi + Của tôi + hộp tạo 360px không tràn', (tester) async {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      final fake = _Fake(
        swaps: [_swap('s1', give: 'dragon', want: 'mint_leaf'), _swap('s2', give: 'angel_wing', want: 'cupcake')],
        mySwaps: [_swap('m1', seller: 'me', give: 'mint_leaf', want: 'dragon')],
      );
      final (c, _) = await _open(tester, fake, locale: l, size: const Size(360, 800));
      await _swapTab(tester);
      await tester.tap(find.byKey(const Key('swap-create')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-pick-give')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-item-mint_leaf')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swap-create-ok')).evaluate().isNotEmpty
          ? find.byKey(const Key('swap-pick-want'))
          : find.byKey(const Key('swap-pick-give')));
      await tester.pumpAndSettle();
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      await _end(tester, c);
    });
  }
}
