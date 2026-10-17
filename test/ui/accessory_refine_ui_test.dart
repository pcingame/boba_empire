// Tinh luyện trong Kho phụ kiện: nút ✦ mở hộp, giá hiện đúng, nâng cấp trừ bản dư + 🧪 và lưu, nút khoá khi thiếu,
// món độc quyền không có ✦, không tràn ở 320px × chữ 1.5 × 7 ngôn ngữ.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/accessory_refine.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String _id = accessories.first.id;

Future<(ProviderContainer, SharedPreferences)> _pump(
  WidgetTester tester, {
  int spares = 0,
  int essence = 0,
  int level = 0,
  List<String> limitedOwned = const [],
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
  final seed = GameState.newGame(nowMillis: 0)
    ..ownedAccessories.add(_id)
    ..accessorySpares[_id] = spares
    ..essence = essence
    ..ownedLimited.addAll(limitedOwned);
  if (level > 0) seed.refineLevels[_id] = level;
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000000),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccessoryInventoryPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, prefs);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('✦ mở hộp: hiện cấp 0, giá cấp 1; đủ thì nâng → trừ bản dư + 🧪, lưu', (tester) async {
    final (c, prefs) = await _pump(tester, spares: 2, essence: 20);
    await tester.tap(find.byKey(Key('refine-open-$_id')));
    await tester.pumpAndSettle();
    expect(find.text('Bản dư của món này: 2/1'), findsOneWidget);
    expect(find.text('🧪 Tinh chất: 20/15'), findsOneWidget);
    expect(find.text('Cấp 0/3'), findsNothing); // nhãn nằm cùng dòng với ✧✧✧
    expect(find.textContaining('Cấp 0/3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('refine-button')));
    await tester.pumpAndSettle();
    final s = c.read(gameControllerProvider);
    expect((s.refineLevels[_id], s.essence, s.accessorySpares[_id]), (1, 5, 1));
    expect(find.textContaining('Cấp 1/3'), findsOneWidget);
    expect(find.text('🧪 Tinh chất: 5/40'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('refine-button'))).onPressed, isNull,
        reason: 'cấp 2 cần 2 bản dư + 40 🧪');
    final saved = GameStorage(prefs).load()!;
    expect(saved.refineLevels[_id], 1);
    await _end(tester, c);
  });

  testWidgets('thiếu bản dư hoặc 🧪 → nút khoá; đã đầy cấp → "Đã đạt cấp tối đa"', (tester) async {
    final (c, _) = await _pump(tester, spares: 0, essence: 999);
    await tester.tap(find.byKey(Key('refine-open-$_id')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('refine-button'))).onPressed, isNull);
    await _end(tester, c);
    final (c2, _) = await _pump(tester, spares: 9, essence: 999, level: 3);
    await tester.tap(find.byKey(Key('refine-open-$_id')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('refine-maxed')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('refine-button'))).onPressed, isNull);
    await _end(tester, c2);
  });

  testWidgets('món độc quyền (kho riêng, không có bản dư) không có nút ✦', (tester) async {
    final lim = limitedAccessories.first.id;
    final (c, _) = await _pump(tester, limitedOwned: [lim]);
    expect(find.byKey(Key('accessory-cell-$lim')), findsOneWidget);
    expect(find.byKey(Key('refine-open-$lim')), findsNothing);
    expect(find.byKey(Key('refine-open-$_id')), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('controller: refineAccessory trả đúng kết quả', (tester) async {
    final (c, _) = await _pump(tester, spares: 1, essence: 15);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.refineAccessory('nope'), RefineResult.unknown);
    expect(ctrl.refineAccessory(_id), RefineResult.ok);
    expect(ctrl.refineAccessory(_id), RefineResult.notEnoughSpares);
    await _end(tester, c);
  });

  for (final loc in AppLocalizations.supportedLocales) {
    testWidgets('hộp Tinh luyện không tràn ở 320px × chữ 1.5 (${loc.languageCode})', (tester) async {
      final (c, _) = await _pump(tester,
          spares: 1, essence: 5, level: 1, locale: loc, size: const Size(320, 12800), textScale: 1.5);
      await tester.tap(find.byKey(Key('refine-open-$_id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('refine-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _end(tester, c);
    });
  }
}
