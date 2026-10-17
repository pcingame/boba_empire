/// Thẻ Mùa + thẻ Món của ngày: hiển thị, nhận/mua, không tràn ở 320px × chữ 1.5 × 7 ngôn ngữ.
library;

import 'package:boba_empire/core/daily_item.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/season.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/daily_item_card.dart';
import 'package:boba_empire/ui/season_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;
const _today = 56;

Future<ProviderContainer> _pump(WidgetTester tester, GameState seed, Widget home, {String locale = 'vi', double scale = 1.5}) async {
  await tester.binding.setSurfaceSize(const Size(320, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: _today * _day);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _today * _day + 1000),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MediaQuery(
      data: MediaQueryData(size: const Size(320, 2400), textScaler: TextScaler.linear(scale)),
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home is SeasonPage ? home : Scaffold(body: SingleChildScrollView(child: home)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

GameState _seed({int xp = 0, bool premium = false, double gems = 0}) => GameState.newGame(nowMillis: 0)
  ..seasonId = seasonIdFor(_today * _day)
  ..seasonXp = xp
  ..seasonPremium = premium
  ..gems = gems;

void main() {
  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('Thẻ Mùa ($loc) 320px × chữ 1.5: trang + lối vào + Món của ngày không tràn', (tester) async {
      final c = await _pump(tester, _seed(xp: 450, gems: 5000), const SeasonPage(), locale: loc);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('season-tier')), findsOneWidget);
      expect(find.byKey(const Key('season-buy-premium')), findsOneWidget);
      await _end(tester, c);

      final c2 = await _pump(tester, _seed(xp: 450, gems: 5000),
          const Column(children: [SeasonEntryCard(), DailyItemCard()]), locale: loc);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('season-open-dot')), findsOneWidget, reason: 'có bậc chưa nhận');
      expect(find.byKey(const Key('daily-item')), findsOneWidget);
      await _end(tester, c2);
    });
  }

  testWidgets('trang Thẻ Mùa: bậc đủ XP bấm nhận → ✓ + cộng 💎; bậc chưa đủ không bấm được', (tester) async {
    final c = await _pump(tester, _seed(xp: 120, gems: 0), const SeasonPage(), scale: 1.0);
    final cell = find.byKey(const Key('season-free-1'));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pump();
    expect(c.read(gameControllerProvider).seasonFreeClaimed, [1]);
    expect(c.read(gameControllerProvider).gems, 5);
    expect(find.descendant(of: find.byKey(const Key('season-free-1')), matching: find.text('✓')), findsOneWidget);
    await tester.tap(find.byKey(const Key('season-free-3'))); // chưa đủ bậc
    await tester.pump();
    expect(c.read(gameControllerProvider).seasonFreeClaimed, [1]);
    await _end(tester, c);
  });

  testWidgets('mua Cao cấp: thiếu 💎 → nút tắt; đủ → bấm → hiện "đã mở" và mở khoá ô Cao cấp', (tester) async {
    final poor = await _pump(tester, _seed(xp: 300, gems: 10), const SeasonPage(), scale: 1.0);
    expect(tester.widget<FilledButton>(find.byKey(const Key('season-buy-premium'))).onPressed, isNull);
    await _end(tester, poor);

    final c = await _pump(tester, _seed(xp: 300, gems: seasonPremiumGems + 1.0), const SeasonPage(), scale: 1.0);
    await tester.tap(find.byKey(const Key('season-buy-premium')));
    await tester.pump();
    expect(find.byKey(const Key('season-premium-owned')), findsOneWidget);
    expect(c.read(gameControllerProvider).seasonPremium, isTrue);
    await tester.ensureVisible(find.byKey(const Key('season-premium-2')));
    await tester.tap(find.byKey(const Key('season-premium-2')));
    await tester.pump();
    expect(c.read(gameControllerProvider).seasonPremiumClaimed, [2]);
    await _end(tester, c);
  });

  testWidgets('Món của ngày: tên + nút mua; mua xong ghi "đã nhận" và nút tắt', (tester) async {
    final item = dailyItemFor(_today, {});
    final c = await _pump(tester, _seed(gems: dailyItemPrice(item.rarity) + 1.0), const DailyItemCard(), scale: 1.0);
    expect(find.text('${dailyItemPrice(item.rarity)} 💎'), findsOneWidget);
    await tester.tap(find.byKey(const Key('daily-item-buy')));
    await tester.pump();
    expect(c.read(gameControllerProvider).ownedAccessories, contains(item.id));
    expect(tester.widget<FilledButton>(find.byKey(const Key('daily-item-buy'))).onPressed, isNull);
    await _end(tester, c);
  });
}
