// Trang trí quán: mua + đặt qua UI, gỡ, và không tràn ở 320px / chữ 1.5× / 7 ngôn ngữ.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/decor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _open(WidgetTester tester,
    {String lang = 'vi', double scale = 1, Size size = const Size(400, 800), double gems = 5000}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..tutorialSeen = true
        ..gems = gems
        ..money = 1e12
        ..levels[Balance.generators.first.id] = 20,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 3600 * 1000),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) =>
          MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => showDecor(ctx), child: const Text('go')))),
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
  testWidgets('chạm ô → mua món hiếm bằng 💎 → tự đặt; thưởng hiện; gỡ được', (tester) async {
    final c = await _open(tester);
    expect(find.byKey(const Key('decor-bonus')), findsOneWidget);
    final gems0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('decor-slot-sign#0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('decor-buy-zen_sign')));
    await tester.pumpAndSettle();
    final g = c.read(gameControllerProvider);
    expect(g.decorPlaced, {'sign#0': 'zen_sign'});
    expect(g.gems, gems0 - 120);
    expect(find.textContaining('+0.5%'), findsOneWidget);
    // Mở lại: món đã có → nút Đặt chỉ khi ở ô khác; gỡ bằng nút Gỡ.
    await tester.tap(find.byKey(const Key('decor-slot-sign#0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('decor-buy-zen_sign')), findsNothing);
    await tester.tap(find.byKey(const Key('decor-remove')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).decorPlaced, isEmpty);
    expect(c.read(gameControllerProvider).decorOwned, ['zen_sign']);
    await _close(tester, c);
  });

  testWidgets('thiếu 💎: nút mua bị vô hiệu', (tester) async {
    final c = await _open(tester, gems: 10);
    await tester.tap(find.byKey(const Key('decor-slot-wall#0')));
    await tester.pumpAndSettle();
    final btn = tester.widget<FilledButton>(find.byKey(const Key('decor-buy-zen_wall')));
    expect(btn.onPressed, isNull);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5×: cảnh + bảng chọn ($lang)', (tester) async {
      final c = await _open(tester, lang: lang, scale: 1.5, size: const Size(320, 640));
      for (final k in ['sign#0', 'floor#2']) {
        await tester.ensureVisible(find.byKey(Key('decor-slot-$k')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('decor-slot-$k')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(5, 5)); // đóng bảng
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
