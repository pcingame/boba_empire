/// Ô "Chợ" trong hộp Thi đấu: vào Chợ chỉ 2 chạm; chấm đỏ khi có listing mới.
library;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/ui/compete_hub_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, MarketListing? highlight) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      marketHighlightProvider.overrideWith((ref) async => highlight),
    ],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => showCompeteHub(c),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('có ô Chợ riêng, không chấm đỏ khi không có gì mới', (t) async {
    await _open(t, null);
    expect(find.byKey(const Key('compete-market-tile')), findsOneWidget);
    expect(find.byKey(const Key('compete-market-dot')), findsNothing);
  });

  testWidgets('listing mới -> ô Chợ có chấm đỏ', (t) async {
    await _open(
      t,
      MarketListing(
        id: 'x',
        sellerId: 'other',
        accessoryId: 'dragon',
        price: 5,
        createdAt: DateTime.utc(2026, 10, 3),
      ),
    );
    expect(find.byKey(const Key('compete-market-dot')), findsOneWidget);
  });
}
