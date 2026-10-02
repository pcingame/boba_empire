import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pump(WidgetTester tester, MarketListing? listing,
      {int clock = 0}) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(
      prefs,
    ).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => clock),
          marketHighlightProvider.overrideWith((ref) async => listing),
        ],
        child: const BobaEmpireApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('có listing mới -> hiện banner Chợ', (tester) async {
    await pump(
      tester,
      MarketListing(
        id: 'l1',
        sellerId: 'other',
        accessoryId: 'galaxy',
        price: 500,
        createdAt: DateTime(2026, 10, 1),
      ),
    );
    expect(find.byKey(const Key('market-banner')), findsOneWidget);
    expect(find.textContaining('500'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('không có gì mới -> không banner', (tester) async {
    await pump(tester, null);
    expect(find.byKey(const Key('market-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  MarketListing listing() => MarketListing(
        id: 'l1',
        sellerId: 'other',
        accessoryId: 'galaxy',
        price: 500,
        createdAt: DateTime(2026, 10, 1),
      );

  testWidgets('nút ✕ ẩn banner Chợ', (tester) async {
    await pump(tester, listing());
    expect(find.byKey(const Key('market-banner')), findsOneWidget);

    await tester.tap(find.byKey(const Key('market-banner-dismiss')));
    await tester.pump();
    expect(find.byKey(const Key('market-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sự kiện đang chạy: chỉ hiện banner sự kiện, banner Chợ nhường chỗ',
      (tester) async {
    final orig = (Balance.eventIncomeMult, Balance.eventStartMillis, Balance.eventEndMillis);
    addTearDown(() {
      Balance.eventIncomeMult = orig.$1;
      Balance.eventStartMillis = orig.$2;
      Balance.eventEndMillis = orig.$3;
    });
    Balance.eventIncomeMult = 2.0;
    Balance.eventStartMillis = 0;
    Balance.eventEndMillis = 3665000;

    await pump(tester, listing(), clock: 1000);
    expect(find.byKey(const Key('event-banner-text')), findsOneWidget);
    expect(find.byKey(const Key('market-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
