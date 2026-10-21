import 'package:boba_empire/core/legacy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/ascension_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _open(WidgetTester tester, {int ascensions = 4, String lang = 'vi', double scale = 1, Size size = const Size(400, 900)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..tutorialSeen = true
        ..ascensionCount = ascensions
        ..ascensionPointsEarned = 50,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => showAscensionDialog(ctx), child: const Text('go')))),
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
  testWidgets('chưa đủ 4 Kỷ Nguyên: hiện dòng khoá, không có perk Di sản', (tester) async {
    final c = await _open(tester, ascensions: 3);
    await tester.scrollUntilVisible(find.byKey(const Key('legacy-locked')), 100, scrollable: find.byType(Scrollable).last);
    expect(find.byKey(const Key('legacy-locked')), findsOneWidget);
    expect(find.byKey(const Key('legacy-income')), findsNothing);
    await _close(tester, c);
  });

  testWidgets('đủ 4 Kỷ Nguyên: mua perk Di sản trừ ⏳ và tăng cấp', (tester) async {
    final c = await _open(tester);
    await tester.scrollUntilVisible(find.byKey(const Key('legacy-income')), 100, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(const Key('ascension-perk-Di sản thu nhập')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).legacyIncomeLevel, 1);
    expect(c.read(gameControllerProvider).ascensionPointsSpendable, 50 - legacyCost(0));
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5× ($lang)', (tester) async {
      final c = await _open(tester, lang: lang, scale: 1.5, size: const Size(320, 640));
      await tester.scrollUntilVisible(find.byKey(const Key('legacy-tap')), 100, scrollable: find.byType(Scrollable).last);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
