import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weather_delivery.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/delivery_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _t0 = 1000 * 3600 * 1000;

Future<ProviderContainer> _open(WidgetTester tester, int Function() clock,
    {String lang = 'vi', double scale = 1, Size size = const Size(400, 800), void Function(GameState)? setup}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final g = GameState.newGame(nowMillis: _t0)
    ..tutorialSeen = true
    ..money = 1e12
    ..levels[Balance.generators.first.id] = 10;
  setup?.call(g);
  await GameStorage(prefs).save(g, nowMillis: _t0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => showDelivery(ctx), child: const Text('go')))),
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
  testWidgets('chọn menu: nhận thưởng rồi khoá các nút trong khung giờ này', (tester) async {
    final c = await _open(tester, () => _t0);
    final best = weatherBestMenu(weatherOf(weatherSlot(_t0)));
    await tester.tap(find.byKey(Key('weather-menu-$best')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).weatherSlotPicked, weatherSlot(_t0));
    final btn = tester.widget<OutlinedButton>(find.byKey(const Key('weather-menu-0')));
    expect(btn.onPressed, isNull);
    await _close(tester, c);
  });

  testWidgets('giao hàng: nhận đơn → đang giao → tới hạn bấm nhận kết quả', (tester) async {
    var now = _t0;
    final c = await _open(tester, () => now);
    await tester.ensureVisible(find.byKey(const Key('delivery-tier-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delivery-tier-0')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).contractTier, 0);
    expect(find.byKey(const Key('delivery-running')), findsOneWidget);
    now += deliveryDurationMillis(0);
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const Key('delivery-finish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delivery-finish')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).contractTier, -1);
    expect(find.byKey(const Key('delivery-tier-0')), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('thiếu Xu: các nút nhận đơn bị khoá', (tester) async {
    final c = await _open(tester, () => _t0, setup: (g) => g.money = 0);
    final btn = tester.widget<FilledButton>(find.byKey(const Key('delivery-tier-0')));
    expect(btn.onPressed, isNull);
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5× ($lang): rảnh và đang giao', (tester) async {
      var c = await _open(tester, () => _t0, lang: lang, scale: 1.5, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
      c = await _open(tester, () => _t0, lang: lang, scale: 1.5, size: const Size(320, 640), setup: (g) {
        g.contractTier = 2;
        g.contractEnd = _t0 + 5000 * 1000;
        g.contractStake = 1e6;
        g.weatherSlotPicked = weatherSlot(_t0);
      });
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
