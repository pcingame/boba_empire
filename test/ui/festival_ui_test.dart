import 'dart:ui' as ui;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/accessory_pack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Widget home,
    {required int now, double gems = 500, String locale = 'vi',
    List<String> limited = const []}) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..gems = gems
        ..ownedLimited.addAll(limited),
      nowMillis: now);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ],
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Widget _opener() => Builder(
    builder: (c) => TextButton(
        onPressed: () => showAccessoryPacks(c), child: const Text('open')));

void main() {
  final inWindow = festivals.first.start.millisecondsSinceEpoch + 1000;
  final outside = festivals.first.end.millisecondsSinceEpoch + 1000;

  testWidgets('trong dịp: dialog có Gói Lễ Hội, mua → hiện món + ô đã mở',
      (tester) async {
    final c = await _pump(tester, _opener(), now: inWindow);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('festival-pack')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('festival-pack-buy')));
    await tester.tap(find.byKey(const Key('festival-pack-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
    expect(c.read(gameControllerProvider).ownedLimited.length, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ngoài dịp: không có Gói Lễ Hội', (tester) async {
    await _pump(tester, _opener(), now: outside);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('festival-pack')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Kho: ô lễ hội khoá "???" khi chưa có, chạm để trưng bày khi đã có',
      (tester) async {
    final id = festivals.first.items.first.id;
    final c = await _pump(tester, const AccessoryInventoryPage(),
        now: outside, limited: [id]);
    await tester.scrollUntilVisible(
        find.byKey(Key('accessory-cell-$id')), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(Key('accessory-cell-$id')));
    await tester.pump();
    expect(c.read(gameControllerProvider).equippedAccessories, [id]);
    // món lễ hội chưa sở hữu: chạm không làm gì
    final other = festivals.last.items.first.id;
    await tester.scrollUntilVisible(
        find.byKey(Key('accessory-cell-$other')), 400,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(Key('accessory-cell-$other')));
    await tester.pump();
    expect(c.read(gameControllerProvider).equippedAccessories, [id]);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in ['vi', 'en', 'es', 'id', 'pt', 'th']) {
    testWidgets('[$locale] 320dp: Gói Lễ Hội + Kho (mục lễ hội) không tràn',
        (tester) async {
      await _pump(tester, _opener(), now: inWindow, locale: locale);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('festival-pack')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _pump(tester, const AccessoryInventoryPage(),
          now: inWindow, locale: locale);
      await tester.scrollUntilVisible(
          find.byKey(Key('accessory-cell-${festivals.last.items.last.id}')), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
