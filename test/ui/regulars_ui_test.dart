import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/regulars.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/regulars_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _now = 10 * 24 * 3600 * 1000;

Future<ProviderContainer> _open(WidgetTester tester, {String lang = 'vi', double scale = 1, Size size = const Size(400, 800), double money = 1e9}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..tutorialSeen = true
        ..money = money
        ..levels[Balance.generators.first.id] = 10
        ..regularPoints.addAll({'0': 9, '1': 3}),
      nowMillis: _now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => showRegulars(ctx), child: const Text('go')))),
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
  testWidgets('khách ghé hôm nay có nhãn; chọn đồ uống → điểm tăng, nhãn chuyển sang "đã phục vụ"', (tester) async {
    final c = await _open(tester);
    final visiting = regularsVisiting(dayIndex(_now));
    expect(find.textContaining('Ghé hôm nay'), findsNWidgets(visiting.length));
    final i = visiting.first;
    await tester.tap(find.byKey(Key('regular-$i')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('regular-drink-${regularFavorite(i)}')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).regularServed, [i]);
    expect(find.byKey(Key('regular-served-$i')), findsOneWidget);
    // Đã phục vụ thì bấm lại không mở hộp chọn.
    await tester.tap(find.byKey(Key('regular-$i')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('regular-drink-${regularFavorite(i)}')), findsNothing);
    await _close(tester, c);
  });

  testWidgets('thiếu Xu: báo, không trừ điểm', (tester) async {
    final c = await _open(tester, money: 0);
    final i = regularsVisiting(dayIndex(_now)).first;
    final before = c.read(gameControllerProvider).regularPoints['$i'];
    await tester.tap(find.byKey(Key('regular-$i')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('regular-drink-${regularFavorite(i)}')));
    await tester.pumpAndSettle();
    expect(find.text('Không đủ Xu'), findsOneWidget);
    expect(c.read(gameControllerProvider).regularPoints['$i'], before);
    expect(c.read(gameControllerProvider).regularServed, isEmpty);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5× ($lang)', (tester) async {
      final c = await _open(tester, lang: lang, scale: 1.5, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final i = regularsVisiting(dayIndex(_now)).first;
      await tester.scrollUntilVisible(find.byKey(Key('regular-$i')), 80, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(Key('regular-$i')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
