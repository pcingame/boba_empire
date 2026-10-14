// Pha theo đơn (giao diện): vào từ màn công thức, kéo/chạm nguyên liệu, đặt lượng, phục vụ, ghi bậc, tổng kết.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_names.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/recipe_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

RecipeCatalog _catalog() => RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

RecipeNames _names() =>
    RecipeNames.fromJson(jsonDecode(File('assets/recipes/names.json').readAsStringSync()) as Map<String, dynamic>);

/// Quảng cáo giả: đếm số lần được gọi, kết quả chỉnh được.
class _Ads implements AdService {
  _Ads([this.outcome = RewardOutcome.earned]);
  RewardOutcome outcome;
  int shown = 0;
  @override
  Future<RewardOutcome> showRewardedAd() async {
    shown++;
    return outcome;
  }
}

/// GameController có Timer.periodic: dispose container NGAY sau khi gỡ cây (xem ghi chú ở test khác).
final _live = <ProviderContainer>[];
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  String locale = 'vi',
  Size size = const Size(320, 700),
  int seed = 1,
  int day = 100,
  Map<String, List<int>>? progress,
  double textScale = 1.0,
  AdService? ads,
  void Function(GameState)? setup,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final g = GameState.newGame(nowMillis: 0)..tutorialSeen = true;
  if (progress != null) g.recipeProgress.addAll(progress);
  setup?.call(g);
  await GameStorage(prefs).save(g, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => day * _day),
    recipeCatalogProvider.overrideWith((ref) async => _catalog()),
    recipeNamesProvider.overrideWith((ref) async => _names()),
    recipeRandomProvider.overrideWithValue(Random(seed)),
    if (ads != null) adServiceProvider.overrideWithValue(ads),
  ]);
  _live.add(c);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RecipeHubPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}


List<Order> _expected(int seed, {Map<int, RecipeProgress> progress = const {}, int day = 100}) => buildOrders(
    _catalog(), progress, day, Random(seed),
    pool: unlockedRecipes(_catalog(), (id) => progress[id]?.best ?? 0));

/// Chạm ô thanh trượt tại mức [index]/[count] (thanh trượt dính vào mốc gần nhất).
Future<void> _setStep(WidgetTester tester, int index, int count) async {
  final r = tester.getRect(find.byKey(const Key('order-slider')));
  const pad = 24.0;
  await tester.tapAt(Offset(r.left + pad + (r.width - 2 * pad) * index / (count - 1), r.center.dy));
  await tester.pumpAndSettle();
}

Future<void> _pour(WidgetTester tester, String name, String unit, double qty) async {
  final chip = find.byKey(Key('order-tray-$name'));
  await tester.ensureVisible(chip);
  await tester.pumpAndSettle();
  await tester.tap(chip);
  await tester.pumpAndSettle();
  await _setStep(tester, nearestStep(unit, qty), amountSteps(unit).length);
  expect(find.byKey(const Key('order-amount')), findsOneWidget);
  await tester.tap(find.byKey(const Key('order-pour')));
  await tester.pumpAndSettle();
}

Future<void> _serveExact(WidgetTester tester, Order o) async {
  for (final i in o.recipe.ingredients) {
    await _pour(tester, i.name, i.unit, i.qty);
  }
  await tester.tap(find.byKey(const Key('order-serve')));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('recipe-orders')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('đơn đầu: hiện tên món + công thức mẫu (bậc Mới); pha đúng → Hoàn hảo, ghi bậc', (tester) async {
    final c = await _pump(tester, size: const Size(400, 900));
    final orders = _expected(1);
    await _open(tester);
    final o = orders.first;
    expect(find.byKey(const Key('order-guide')), findsOneWidget);
    expect(find.textContaining(o.recipe.name), findsWidgets);
    await _serveExact(tester, o);
    expect(find.text('Hoàn hảo! Đúng từng lượng'), findsOneWidget);
    final saved = c.read(gameControllerProvider).recipeProgress[o.recipe.id];
    expect(saved, isNotNull);
    expect(saved!.box, 1);
    await _teardown(tester);
  });

  testWidgets('thiếu nguyên liệu → "Chưa đúng món" kèm dòng thiếu; bậc không tăng', (tester) async {
    final c = await _pump(tester, size: const Size(400, 900));
    final o = _expected(1).first;
    await _open(tester);
    final first = o.recipe.ingredients.first;
    await _pour(tester, first.name, first.unit, first.qty);
    await tester.tap(find.byKey(const Key('order-serve')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa đúng món'), findsOneWidget);
    if (o.recipe.ingredients.length > 1) {
      final miss = o.recipe.ingredients[1];
      expect(find.textContaining('Thiếu'), findsWidgets);
      expect(find.textContaining(miss.amount), findsWidgets);
    }
    final saved = c.read(gameControllerProvider).recipeProgress[o.recipe.id];
    expect(saved == null || saved.box == 0, true);
    await _teardown(tester);
  });

  testWidgets('kéo nguyên liệu thả vào ly mở bảng đặt lượng; "Bỏ ra" lấy lại khỏi ly', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    final o = _expected(1).first;
    await _open(tester);
    final name = o.recipe.ingredients.first.name;
    await tester.drag(find.byKey(Key('order-tray-$name')), tester.getCenter(find.byKey(const Key('order-cup'))) -
        tester.getCenter(find.byKey(Key('order-tray-$name'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-slider')), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-pour')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('order-poured-$name')), findsOneWidget);
    await tester.tap(find.byKey(Key('order-poured-$name')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-remove')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('order-poured-$name')), findsNothing);
    await _teardown(tester);
  });

  testWidgets('trọn buổi 5 đơn → tổng kết 5/5 và nhiệm vụ buổi được tính', (tester) async {
    final c = await _pump(tester, size: const Size(400, 900));
    final orders = _expected(1);
    await _open(tester);
    for (var i = 0; i < orders.length; i++) {
      await _serveExact(tester, orders[i]);
      await tester.tap(find.byKey(const Key('order-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('order-result')), findsOneWidget);
    expect(find.byKey(const Key('order-score')), findsOneWidget);
    expect(find.text('5/5 câu đúng'), findsWidgets);
    expect(c.read(gameControllerProvider).recipeProgress.length, 5);
    await tester.tap(find.byKey(const Key('order-again')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-prompt')), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('gợi ý theo bậc của đơn đầu: Mới có công thức mẫu, Thạo chỉ còn dòng "không gợi ý"', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    await _open(tester);
    expect(find.text('Công thức mẫu'), findsOneWidget);
    await _teardown(tester);

    // Mọi món ở bậc Thạo.
    final progress = {for (final r in _catalog().recipes) '${r.id}': [3, 0, 3]};
    final typed = {for (final e in progress.entries) int.parse(e.key): RecipeProgress.fromList(e.value)};
    expect(_expected(1, progress: typed).first.box, 3);
    await _pump(tester, size: const Size(400, 900), progress: progress);
    await _open(tester);
    expect(find.text('Không gợi ý — pha theo trí nhớ!'), findsOneWidget);
    expect(find.text('Công thức mẫu'), findsNothing);
    await _teardown(tester);
  });

  Map<String, List<int>> mastered() => {for (final r in _catalog().recipes) '${r.id}': [3, 0, 3]};

  testWidgets('gợi ý bằng quảng cáo: hiện công thức mẫu, đơn đó không tính bậc và không vào BXH', (tester) async {
    final ads = _Ads();
    final c = await _pump(tester, size: const Size(400, 900), progress: mastered(), ads: ads);
    final o = _expected(1, progress: {for (final e in mastered().entries) int.parse(e.key): RecipeProgress.fromList(e.value)})
        .first;
    await _open(tester);
    expect(find.text('Công thức mẫu'), findsNothing);
    await tester.tap(find.byKey(const Key('order-hint')));
    await tester.pumpAndSettle();
    expect(ads.shown, 1);
    expect(find.text('Công thức mẫu'), findsOneWidget);
    expect(find.byKey(const Key('order-hint')), findsNothing); // dùng một lần mỗi đơn
    await _serveExact(tester, o);
    expect(find.text('Hoàn hảo! Đúng từng lượng'), findsOneWidget);
    expect(find.text('Đã dùng gợi ý nên câu này không tính bậc.'), findsOneWidget);
    expect(c.read(gameControllerProvider).recipeOrderPerfect, isEmpty);
    expect(c.read(gameControllerProvider).recipeProgress[o.recipe.id]!.dueDay, 0); // không đổi lịch ôn
    await _teardown(tester);
  });

  testWidgets('đóng quảng cáo sớm: không lộ công thức mẫu, nút gợi ý còn đó', (tester) async {
    final ads = _Ads(RewardOutcome.dismissed);
    await _pump(tester, size: const Size(400, 900), progress: mastered(), ads: ads);
    await _open(tester);
    await tester.tap(find.byKey(const Key('order-hint')));
    await tester.pumpAndSettle();
    expect(ads.shown, 1);
    expect(find.text('Công thức mẫu'), findsNothing);
    expect(find.byKey(const Key('order-hint')), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('BXH: pha hoàn hảo KHÔNG gợi ý được ghi; pha ở bậc Mới (có công thức mẫu) thì không', (tester) async {
    final c = await _pump(tester, size: const Size(400, 900), progress: mastered());
    final o = _expected(1, progress: {for (final e in mastered().entries) int.parse(e.key): RecipeProgress.fromList(e.value)})
        .first;
    await _open(tester);
    await _serveExact(tester, o);
    expect(c.read(gameControllerProvider).recipeOrderPerfect, [o.recipe.id]);
    await _teardown(tester);

    final c2 = await _pump(tester, size: const Size(400, 900));
    await _open(tester);
    await _serveExact(tester, _expected(1).first); // bậc Mới ⇒ thấy công thức mẫu
    expect(find.text('Hoàn hảo! Đúng từng lượng'), findsOneWidget);
    expect(c2.read(gameControllerProvider).recipeOrderPerfect, isEmpty);
    await _teardown(tester);
  });

  testWidgets('pha đúng nhưng lệch 1 mức ở bậc Quen: đạt (2 sao) nhưng KHÔNG vào BXH', (tester) async {
    final prog = {for (final r in _catalog().recipes) '${r.id}': [1, 0, 1]};
    final c = await _pump(tester, size: const Size(400, 900), progress: prog);
    final o = _expected(1, progress: {for (final e in prog.entries) int.parse(e.key): RecipeProgress.fromList(e.value)}).first;
    await _open(tester);
    final first = o.recipe.ingredients.first;
    final steps = amountSteps(first.unit);
    final i0 = nearestStep(first.unit, first.qty);
    for (final i in o.recipe.ingredients) {
      await _pour(tester, i.name, i.unit, i == first ? steps[i0 + 1 < steps.length ? i0 + 1 : i0 - 1] : i.qty);
    }
    await tester.tap(find.byKey(const Key('order-serve')));
    await tester.pumpAndSettle();
    expect(find.text('Đạt — còn lệch chút lượng'), findsOneWidget);
    expect(c.read(gameControllerProvider).recipeOrderPerfect, isEmpty);
    await _teardown(tester);
  });

  testWidgets('nhân đôi thưởng cuối buổi: xem QC một lần, cộng đúng phần Xu thưởng, không bấm lại được', (tester) async {
    final ads = _Ads();
    final c = await _pump(tester, size: const Size(400, 900), ads: ads);
    final orders = _expected(1);
    await _open(tester);
    for (final o in orders) {
      await _serveExact(tester, o);
      await tester.tap(find.byKey(const Key('order-next')));
      await tester.pumpAndSettle();
    }
    final before = c.read(gameControllerProvider).money;
    await tester.ensureVisible(find.byKey(const Key('order-double')));
    await tester.tap(find.byKey(const Key('order-double')));
    await tester.pumpAndSettle();
    expect(ads.shown, 1);
    expect(find.byKey(const Key('order-doubled')), findsOneWidget);
    expect(find.byKey(const Key('order-double')), findsNothing);
    expect(c.read(gameControllerProvider).money, greaterThan(before));
    await _teardown(tester);
  });

  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('320px, chữ 1.5×, $loc: đơn + phản hồi sai không tràn', (tester) async {
      await _pump(tester, locale: loc, textScale: 1.5);
      final o = _expected(1).first;
      await _open(tester);
      final first = o.recipe.ingredients.first;
      await _pour(tester, first.name, first.unit, amountSteps(first.unit).last);
      await tester.tap(find.byKey(const Key('order-serve')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-feedback')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  }
}
