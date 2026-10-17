/// Màn Bí quyết: 18 dòng, mua bậc bằng Tinh chất, không tràn ở 320px × chữ 1.5 × 7 ngôn ngữ.
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/mastery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  int essence = 0,
  Map<int, int> tiers = const {},
  Locale locale = const Locale('vi'),
  Size size = const Size(400, 12800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)..essence = essence;
  seed.masteryTiers.addAll(tiers);
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000000),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MasteryPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('đủ tiền thì nút bật, bấm → trừ Tinh chất và hiện thêm chấm', (tester) async {
    final c = await _pump(tester, essence: 12);
    expect(find.byKey(const Key('mastery-row-18')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('mastery-buy-1'))).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('mastery-buy-1')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).essence, 2);
    expect(find.text('●○○○○'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('mastery-buy-1'))).onPressed, isNull,
        reason: 'bậc 2 giá 20');
    c.dispose();
  });

  testWidgets('bậc đầy hiện "Tối đa" thay nút', (tester) async {
    final c = await _pump(tester, tiers: {3: 5});
    expect(find.byKey(const Key('mastery-max-3')), findsOneWidget);
    expect(find.byKey(const Key('mastery-buy-3')), findsNothing);
    c.dispose();
  });

  for (final loc in AppLocalizations.supportedLocales) {
    testWidgets('không tràn ở 320px × chữ 1.5 (${loc.languageCode})', (tester) async {
      final c = await _pump(tester,
          essence: 123456,
          tiers: {1: 5, 2: 4, 3: 3, 18: 1},
          locale: loc,
          size: const Size(320, 12800),
          textScale: 1.5);
      expect(tester.takeException(), isNull);
      c.dispose();
    });
  }
}
