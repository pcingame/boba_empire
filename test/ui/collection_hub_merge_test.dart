/// Chợ + Kho gộp vào nút Sưu tập ✨: hộp Thi đấu không còn 2 mục đó; chấm đỏ
/// "listing mới" chuyển sang nút ✨ (màn chính) và icon cửa hàng (trong Kho).
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/compete_hub_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _fresh = MarketListing(
  id: 'x',
  sellerId: 'other',
  accessoryId: 'dragon',
  price: 5,
  createdAt: DateTime.utc(2026, 10, 3),
);

Future<ProviderContainer> _container(MarketListing? highlight) async {
  SharedPreferences.setMockInitialValues({'market_intro_seen': true});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    marketHighlightProvider.overrideWith((ref) async => highlight),
  ]);
}

Widget _localized(ProviderContainer c, Widget home) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('hộp Thi đấu không còn mục Sưu tập / Chợ', (tester) async {
    final c = await _container(null);
    await tester.pumpWidget(_localized(
      c,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showCompeteHub(ctx),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile),
        findsNWidgets(5)); // Đấu trường, Hội, BXH, Speedrun, PK
    expect(find.byKey(const Key('compete-guild')), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
    expect(find.byIcon(Icons.storefront), findsNothing);
    c.dispose();
  });

  testWidgets('listing mới: chấm đỏ ở nút ✨ màn chính, KHÔNG ở tab Thi đấu',
      (tester) async {
    final c = await _container(_fresh);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    // Banner Chợ có chữ chạy (animation vô hạn) → pumpAndSettle không bao giờ xong.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final chip = find.byKey(const Key('collection-chip'));
    expect(find.descendant(of: chip, matching: find.text('1')), findsOneWidget);
    final compete = find.byKey(const Key('compete-button'));
    expect(find.descendant(of: compete, matching: find.text('1')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('không có gì mới: ✨ không chấm đỏ', (tester) async {
    final c = await _container(null);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    final chip = find.byKey(const Key('collection-chip'));
    expect(find.descendant(of: chip, matching: find.text('1')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('trong Kho: icon cửa hàng có chấm khi Chợ có listing mới',
      (tester) async {
    final c = await _container(_fresh);
    await tester.pumpWidget(_localized(c, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    final dot = tester.widget<Badge>(find.byKey(const Key('collection-market-dot')));
    expect(dot.isLabelVisible, isTrue);
    c.dispose();
    await tester.pumpWidget(const SizedBox());

    final c2 = await _container(null);
    await tester.pumpWidget(_localized(c2, const AccessoryInventoryPage()));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Badge>(find.byKey(const Key('collection-market-dot')))
            .isLabelVisible,
        isFalse);
    c2.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
