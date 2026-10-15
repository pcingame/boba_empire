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

  testWidgets('bật hiệu ứng: bảng phản hồi hiện dần (mờ → rõ), tắt thì rõ ngay', (tester) async {
    await _pump(tester);
    final recipe = buildOrders(_catalog(), {}, 100, Random(1), pool: unlockedRecipes(_catalog(), (id) => 0)).first.recipe;
    await _pourAll(tester, recipe);
    await tester.tap(find.byKey(const Key('order-serve')));
    final fb = find.byKey(const Key('order-feedback'));
    for (var i = 0; i < 200 && fb.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(fb, findsOneWidget);
    double minOpacity() => tester
        .widgetList<Opacity>(find.ancestor(of: fb, matching: find.byType(Opacity)))
        .map((o) => o.opacity)
        .fold(1.0, min);
    await tester.pump(const Duration(milliseconds: 60));
    expect(minOpacity(), lessThan(1.0), reason: 'đang hiện dần');
    await _for(tester, 600);
    expect(minOpacity(), 1.0);
    await _teardown(tester);
  });

  List<Order> sessionOrders() =>
      buildOrders(_catalog(), {}, 100, Random(1), pool: unlockedRecipes(_catalog(), (id) => 0));

  Future<void> serveAndFinish(WidgetTester tester, Recipe r) async {
    await _pourAll(tester, r);
    await tester.tap(find.byKey(const Key('order-serve')));
    await _for(tester, 1300);
  }

  double maxScaleAbove(WidgetTester tester, Finder f) => tester
      .widgetList<ScaleTransition>(find.ancestor(of: f, matching: find.byType(ScaleTransition)))
      .map((t) => t.scale.value)
      .fold(1.0, max);

  testWidgets('ly nhấp nhẹ khi phục vụ hoàn hảo rồi về 1.0; đơn sai thì không nhấp', (tester) async {
    await _pump(tester);
    final os = sessionOrders();
    await _pourAll(tester, os[0].recipe);
    expect(maxScaleAbove(tester, find.byKey(const Key('order-cup'))), 1.0, reason: 'chưa phục vụ');
    await tester.tap(find.byKey(const Key('order-serve')));
    final fb = find.byKey(const Key('order-feedback'));
    for (var i = 0; i < 200 && fb.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 80));
    expect(maxScaleAbove(tester, find.byKey(const Key('order-cup'))), greaterThan(1.0));
    await _for(tester, 500);
    expect(maxScaleAbove(tester, find.byKey(const Key('order-cup'))), 1.0);
    await tester.tap(find.byKey(const Key('order-next')));
    await _for(tester, 500);
    // Đơn 2: chỉ cho nguyên liệu đầu (món ≥ 2 nguyên liệu) → sai → ly không nhấp.
    final r2 = os[1].recipe;
    final i0 = r2.ingredients.first;
    await tester.ensureVisible(find.byKey(Key('order-tray-${i0.name}')));
    await _for(tester, 100);
    await tester.tap(find.byKey(Key('order-tray-${i0.name}')));
    await _for(tester, 400);
    await tester.tap(find.byKey(const Key('order-pour')));
    await _for(tester, 500);
    await tester.tap(find.byKey(const Key('order-serve')));
    for (var i = 0; i < 200 && fb.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Chưa đúng món'), findsOneWidget);
    expect(maxScaleAbove(tester, find.byKey(const Key('order-cup'))), 1.0);
    await _teardown(tester);
  });

  testWidgets('tổng kết: ba sao nảy ra lần lượt (sao sau còn nhỏ khi sao đầu đã lớn), cuối cùng đủ cỡ', (tester) async {
    await _pump(tester);
    final os = sessionOrders();
    for (final o in os) {
      await serveAndFinish(tester, o.recipe);
      await tester.tap(find.byKey(const Key('order-next')));
      if (o != os.last) await _for(tester, 500);
    }
    await tester.pump(); // màn tổng kết vừa dựng: các sao bắt đầu nảy từ đây
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    final stars = find.byIcon(Icons.star_rounded);
    expect(stars, findsNWidgets(3));
    double scaleOf(int i) {
      final t = tester.widget<Transform>(find.ancestor(of: stars.at(i), matching: find.byType(Transform)).first);
      return t.transform.storage[0]; // hệ số phóng theo trục x
    }
    await tester.pump(const Duration(milliseconds: 120));
    expect(scaleOf(0), greaterThan(scaleOf(2)), reason: 'sao đầu nảy trước sao cuối');
    expect(scaleOf(2), lessThan(0.5));
    await _for(tester, 1600);
    for (var i = 0; i < 3; i++) {
      expect(scaleOf(i), closeTo(1.0, 1e-6));
    }
    await _teardown(tester);
  });

  testWidgets('Giờ cao điểm: thanh kiên nhẫn trôi mượt giữa hai nhịp đồng hồ (không giật từng 200ms)', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('order-rush-toggle')));
    await tester.pump();
    double v() => tester.widget<LinearProgressIndicator>(find.byKey(const Key('order-patience'))).value!;
    expect(v(), 1.0);
    await tester.pump(const Duration(milliseconds: 200)); // nhịp đầu: đích mới < 1
    await tester.pump(const Duration(milliseconds: 100)); // giữa chừng
    final patience = orderPatienceSeconds(sessionOrders().first.recipe.ingredients.length) * 1000;
    final target = (patience - 200) / patience;
    expect(v(), lessThan(1.0));
    expect(v(), greaterThan(target), reason: 'chưa tới đích của nhịp — đang chạy mượt');
    await _for(tester, 400);
    expect(v(), lessThan(target + 1e-9));
    await _teardown(tester);
  });

  testWidgets('chip khay đổi màu mượt khi bật hiệu ứng (220ms); tắt hiệu ứng thì tức thì', (tester) async {
    await _pump(tester);
    final name = sessionOrders().first.recipe.ingredients.first.name;
    Duration dur() => tester.widget<Material>(find.descendant(of: find.byKey(Key('order-tray-$name')), matching: find.byType(Material)).first).animationDuration;
    expect(dur(), const Duration(milliseconds: 220));
    await _teardown(tester);
    await _pump(tester, quality: EffectsPref.off);
    expect(dur(), Duration.zero);
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
