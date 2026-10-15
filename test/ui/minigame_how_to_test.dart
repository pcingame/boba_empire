// Hướng dẫn cách chơi các trò nhỏ (Công thức, Pha theo đơn, Thử thách ngày): nút ? mở được, nội dung đúng số liệu
// thật của game, tự hiện LẦN ĐẦU (mỗi trò một cờ riêng, không hiện lại), không tự hiện khi chỉ xem lại điểm thử
// thách, không tràn ở 7 ngôn ngữ.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_names.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/minigame_how_to_dialogs.dart';
import 'package:boba_empire/ui/recipe_hub_page.dart';
import 'package:boba_empire/ui/recipe_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

RecipeCatalog _catalog() => RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);
RecipeNames _names() =>
    RecipeNames.fromJson(jsonDecode(File('assets/recipes/names.json').readAsStringSync()) as Map<String, dynamic>);

final _live = <ProviderContainer>[];
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget home, {
  String locale = 'vi',
  Size size = const Size(400, 900),
  double scale = 1.0,
  void Function(GameState)? setup,
  SharedPreferences? reuse,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = reuse ?? await SharedPreferences.getInstance();
  if (reuse == null) {
    final g = GameState.newGame(nowMillis: 0)..tutorialSeen = true;
    setup?.call(g);
    await GameStorage(prefs).save(g, nowMillis: 0);
  }
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 100 * _day),
    recipeCatalogProvider.overrideWith((ref) async => _catalog()),
    recipeNamesProvider.overrideWith((ref) async => _names()),
    recipeRandomProvider.overrideWithValue(Random(1)),
  ]);
  _live.add(c);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('nội dung', () {
    for (final entry in {
      MiniGameGuide.recipes: (6, 'Cách chơi: Công thức pha chế'),
      MiniGameGuide.orders: (8, 'Cách chơi: Pha theo đơn'),
      MiniGameGuide.daily: (5, 'Cách chơi: Thử thách hằng ngày'),
    }.entries) {
      testWidgets('${entry.key.name}: nút ? mở bảng đúng tiêu đề, đủ ${entry.value.$1} bước đánh số, đóng được', (tester) async {
        await _pump(tester, Builder(builder: (c) => Scaffold(appBar: AppBar(actions: [HowToButton(entry.key)]))));
        expect(find.byKey(Key('howto-${entry.key.name}')), findsNothing);
        await tester.tap(find.byKey(Key('howto-button-${entry.key.name}')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('howto-${entry.key.name}')), findsOneWidget);
        expect(find.text(entry.value.$2), findsOneWidget);
        for (var i = 0; i < entry.value.$1; i++) {
          expect(find.byKey(Key('howto-line-$i')), findsOneWidget, reason: 'bước ${i + 1}');
          expect(tester.widget<Text>(find.byKey(Key('howto-line-$i'))).data, isNotEmpty);
        }
        expect(find.byKey(Key('howto-line-${entry.value.$1}')), findsNothing);
        await tester.tap(find.byKey(const Key('howto-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(Key('howto-${entry.key.name}')), findsNothing);
        await _teardown(tester);
      });
    }

    testWidgets('số liệu trong bài viết lấy từ hằng số thật của game (không gõ tay)', (tester) async {
      await _pump(tester, Builder(builder: (c) => Scaffold(appBar: AppBar(actions: const [HowToButton(MiniGameGuide.recipes)]))));
      await tester.tap(find.byKey(const Key('howto-button-recipes')));
      await tester.pumpAndSettle();
      String line(int i) => tester.widget<Text>(find.byKey(Key('howto-line-$i'))).data!;
      expect(line(1), contains('${recipeIntervalDays[1]} / ${recipeIntervalDays[2]} / ${recipeIntervalDays[3]} ngày'));
      expect(line(5), contains('$recipeGroupUnlockLearned món'));
      await _teardown(tester);
      await _pump(tester, Builder(builder: (c) => Scaffold(appBar: AppBar(actions: const [HowToButton(MiniGameGuide.daily)]))));
      await tester.tap(find.byKey(const Key('howto-button-daily')));
      await tester.pumpAndSettle();
      expect(line(2), contains('300 điểm'));
      expect(line(3), contains('5 💎'));
      await _teardown(tester);
    });
  });

  group('tự hiện lần đầu', () {
    setUp(() => debugAutoShowHowTo = true);
    tearDown(() => debugAutoShowHowTo = false);

    testWidgets('Công thức: vào hub lần đầu tự mở; lần sau không; cờ lưu vào save', (tester) async {
      final c = await _pump(tester, const RecipeHubPage());
      expect(find.byKey(const Key('howto-recipes')), findsOneWidget);
      expect(c.read(gameControllerProvider).howToSeen, 'recipes');
      await tester.tap(find.byKey(const Key('howto-close')));
      await tester.pumpAndSettle();
      final prefs = c.read(sharedPreferencesProvider);
      expect(GameStorage(prefs).load()!.howToSeen, ['recipes'], reason: 'đã lưu xuống đĩa');
      await _teardown(tester);
      await _pump(tester, const RecipeHubPage(), reuse: prefs);
      expect(find.byKey(const Key('howto-recipes')), findsNothing, reason: 'đã xem rồi');
      await tester.tap(find.byKey(const Key('howto-button-recipes')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('howto-recipes')), findsOneWidget, reason: 'nút ? vẫn mở lại được');
      await _teardown(tester);
    });

    testWidgets('Pha theo đơn và Thử thách ngày: mỗi trò một cờ riêng', (tester) async {
      var c = await _pump(tester, const RecipeOrderPage());
      expect(find.byKey(const Key('howto-orders')), findsOneWidget);
      expect(find.byKey(const Key('howto-daily')), findsNothing);
      expect(c.read(gameControllerProvider).howToSeen, 'orders');
      final prefs = c.read(sharedPreferencesProvider);
      await _teardown(tester);
      c = await _pump(tester, const RecipeOrderPage(daily: true), reuse: prefs);
      expect(find.byKey(const Key('howto-daily')), findsOneWidget, reason: 'xem hướng dẫn Pha theo đơn không làm mất hướng dẫn Thử thách ngày');
      expect(find.byKey(const Key('howto-orders')), findsNothing);
      expect(c.read(gameControllerProvider).howToSeen.split(',').toSet(), {'orders', 'daily'});
      await _teardown(tester);
    });

    testWidgets('chỉ xem lại điểm thử thách đã làm hôm nay: KHÔNG tự hiện hướng dẫn (và không đánh dấu đã xem)', (tester) async {
      final c = await _pump(tester, const RecipeOrderPage(daily: true), setup: (g) {
        g.recipeDailyDay = 100;
        g.recipeDailyScore = 200;
      });
      expect(find.byKey(const Key('daily-already')), findsOneWidget);
      expect(find.byKey(const Key('howto-daily')), findsNothing);
      expect(c.read(gameControllerProvider).howToSeen, isEmpty);
      await _teardown(tester);
    });

    testWidgets('đóng hướng dẫn rồi chơi bình thường: màn Pha theo đơn dùng được', (tester) async {
      await _pump(tester, const RecipeOrderPage());
      await tester.tap(find.byKey(const Key('howto-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-prompt')), findsOneWidget);
      expect(find.byKey(const Key('order-serve')), findsOneWidget);
      await _teardown(tester);
    });
  });

  test('autoshow tắt mặc định trong test (cấu hình chung) — không che thao tác ở các test khác', () {
    expect(debugAutoShowHowTo, isFalse);
  });

  group('không tràn', () {
    for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      for (final g in MiniGameGuide.values) {
        testWidgets('${g.name} · $loc · 320px, chữ 1.5×', (tester) async {
          await _pump(tester, Scaffold(appBar: AppBar(actions: [HowToButton(g)])),
              locale: loc, size: const Size(320, 640), scale: 1.5);
          await tester.tap(find.byKey(Key('howto-button-${g.name}')));
          await tester.pumpAndSettle();
          expect(find.byKey(Key('howto-${g.name}')), findsOneWidget);
          expect(tester.takeException(), isNull);
          // Cuộn hết nội dung: bước cuối phải tới được.
          final last = g == MiniGameGuide.orders ? 7 : (g == MiniGameGuide.recipes ? 5 : 4);
          await tester.scrollUntilVisible(find.byKey(Key('howto-line-$last')), 120, scrollable: find.byType(Scrollable).last);
          expect(tester.takeException(), isNull);
          await _teardown(tester);
        });
      }
    }
  });
}
