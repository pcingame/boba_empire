// Pha theo đơn khi BẬT animation (mặc định test tắt): đậy nắp + lắc ly rồi mới chấm, không cho sửa giữa chừng,
// tắt hiệu ứng thì chấm ngay. Khung dựng như recipe_motion_test.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/recipe_order_page.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/order_visuals.dart';
import 'package:boba_empire/ui/widgets/one_shot_lottie.dart' show debugResetLiveEffects;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

RecipeCatalog _catalog() => RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

final _live = <ProviderContainer>[];
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Future<void> _for(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _pump(WidgetTester tester, {EffectsPref quality = EffectsPref.high, int seed = 1}) async {
  tester.view.physicalSize = const Size(400 * 2, 900 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  EffectsController.instance.init(prefs, platformStart: EffectsQuality.high, listenFrames: false);
  await EffectsController.instance.setPref(quality);
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..tutorialSeen = true, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 100 * _day),
    recipeCatalogProvider.overrideWith((ref) async => _catalog()),
    recipeRandomProvider.overrideWithValue(Random(seed)),
  ]);
  _live.add(c);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const ui.Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RecipeOrderPage(),
    ),
  ));
  await _for(tester, 600);
}

Future<void> _pourAll(WidgetTester tester, Recipe r) async {
  for (final i in r.ingredients) {
    await tester.ensureVisible(find.byKey(Key('order-tray-${i.name}')));
    await _for(tester, 100);
    await tester.tap(find.byKey(Key('order-tray-${i.name}')));
    await _for(tester, 400);
    final r = tester.getRect(find.byKey(const Key('order-slider')));
    final steps = amountSteps(i.unit);
    await tester.tapAt(Offset(r.left + 24 + (r.width - 48) * nearestStep(i.unit, i.qty) / (steps.length - 1), r.center.dy));
    await _for(tester, 100);
    await tester.tap(find.byKey(const Key('order-pour')));
    await _for(tester, 500);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;

  setUp(() {
    mascot.debugDisableMascotAnimation = false;
    debugResetLiveEffects();
  });
  tearDown(() {
    debugResetLiveEffects();
    fx.debugReset();
    mascot.debugDisableMascotAnimation = true;
  });

  testWidgets('bật hiệu ứng: bấm Phục vụ → đậy nắp + lắc ~1s, CHƯA chấm; xong mới hiện phản hồi', (tester) async {
    await _pump(tester);
    final recipe = buildOrders(_catalog(), {}, 100, Random(1), pool: unlockedRecipes(_catalog(), (id) => 0)).first.recipe;
    await _pourAll(tester, recipe);
    await tester.tap(find.byKey(const Key('order-serve')));
    await _for(tester, 300);
    expect(find.byKey(const Key('order-feedback')), findsNothing);
    // Đang đậy nắp: nút phục vụ khoá, không sửa được nguyên liệu.
    expect(tester.widget<FilledButton>(find.byKey(const Key('order-serve'))).onPressed, isNull);
    await tester.tap(find.byKey(Key('order-poured-${recipe.ingredients.first.name}')), warnIfMissed: false);
    await _for(tester, 200);
    expect(find.byKey(const Key('order-slider')), findsNothing);
    await _for(tester, 900);
    expect(find.byKey(const Key('order-feedback')), findsOneWidget);
    expect(find.text('😍'), findsOneWidget); // hoàn hảo ⇒ khách vui
    await _teardown(tester);
  });

  testWidgets('tắt hiệu ứng: chấm ngay, không chờ đậy nắp', (tester) async {
    await _pump(tester, quality: EffectsPref.off);
    final recipe = buildOrders(_catalog(), {}, 100, Random(1), pool: unlockedRecipes(_catalog(), (id) => 0)).first.recipe;
    await _pourAll(tester, recipe);
    await tester.tap(find.byKey(const Key('order-serve')));
    await _for(tester, 50);
    expect(find.byKey(const Key('order-feedback')), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('rời màn lúc đang đậy nắp: không ném lỗi (không chấm sau khi đã huỷ)', (tester) async {
    await _pump(tester);
    final recipe = buildOrders(_catalog(), {}, 100, Random(1), pool: unlockedRecipes(_catalog(), (id) => 0)).first.recipe;
    await _pourAll(tester, recipe);
    await tester.tap(find.byKey(const Key('order-serve')));
    await _for(tester, 200);
    await tester.pumpWidget(const SizedBox());
    await _for(tester, 1200);
    expect(tester.takeException(), isNull);
    for (final c in _live) {
      c.dispose();
    }
    _live.clear();
  });

  testWidgets('topping (trân châu…) thả vào ly thì RƠI từng viên rồi tắt; nguyên liệu lỏng thì không', (tester) async {
    // Tìm seed mà khay đơn đầu có cả topping lẫn nguyên liệu lỏng.
    final pool = unlockedRecipes(_catalog(), (id) => 0);
    var seed = 1;
    Order first() => buildOrders(_catalog(), {}, 100, Random(seed), pool: pool).first;
    while (!first().tray.any((t) => isTopping(t.name)) || !first().tray.any((t) => !isTopping(t.name))) {
      seed++;
    }
    final tray = first().tray;
    final topping = tray.firstWhere((t) => isTopping(t.name));
    final liquid = tray.firstWhere((t) => !isTopping(t.name));
    await _pump(tester, seed: seed);
    double dropNow() => (tester.widget<CustomPaint>(find.byKey(const Key('order-cup-paint'))).painter as dynamic).drop as double;

    Future<void> pour(TrayItem t) async {
      await tester.ensureVisible(find.byKey(Key('order-tray-${t.name}')));
      await _for(tester, 100);
      await tester.tap(find.byKey(Key('order-tray-${t.name}')));
      await _for(tester, 400);
      await tester.tap(find.byKey(const Key('order-hold')));
      await _for(tester, 100);
      await tester.tap(find.byKey(const Key('order-pour')));
    }

    await pour(liquid);
    await _for(tester, 250);
    expect(dropNow(), 0, reason: 'nguyên liệu lỏng không rơi viên');
    await pour(topping);
    await _for(tester, 350);
    expect(dropNow(), greaterThan(0), reason: 'topping phải đang rơi');
    await _for(tester, 900);
    expect(dropNow(), 0, reason: 'rơi xong thì tắt, không ép vẽ mãi');
    await _teardown(tester);
  });
}
