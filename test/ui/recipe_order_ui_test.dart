// Pha theo đơn (giao diện): vào từ màn công thức, kéo/chạm nguyên liệu, đặt lượng, phục vụ, ghi bậc, tổng kết.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/accessories.dart' show accessories;
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_names.dart';
import 'package:boba_empire/core/recipe_orders.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/collection_share_dialog.dart' show shareImageProvider;
import 'package:boba_empire/ui/recipe_order_page.dart';
import 'package:boba_empire/ui/widgets/order_visuals.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;
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
  bool daily = false,
  Future<void> Function(Uint8List, String, Rect?)? share,
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
    if (share != null) shareImageProvider.overrideWithValue(share),
  ]);
  _live.add(c);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecipeOrderPage(daily: daily),
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
  await tester.pumpAndSettle(); // trò mở thẳng: đã ở màn Pha theo đơn
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

  testWidgets('cúp BXH trên màn đơn hàng: chưa liên kết email thì bị cổng chặn', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    await tester.tap(find.byKey(const Key('order-leaderboard')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('giữ để rót: chạm nhẹ = một mức, giữ lâu tăng dần, thả ra thì dừng; "Rót lại" về 0; xác nhận vào ly', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    final o = _expected(1).first;
    final ing = o.recipe.ingredients.first;
    final steps = amountSteps(ing.unit);
    String amt(int i) => '${steps[i] == steps[i].roundToDouble() ? steps[i].round() : steps[i]} ${ing.unit}';
    await _open(tester);
    await tester.tap(find.byKey(Key('order-tray-${ing.name}')));
    await tester.pumpAndSettle();
    expect(find.text(amt(0)), findsOneWidget); // rót từ ly rỗng
    await tester.tap(find.byKey(const Key('order-hold')));
    await tester.pump();
    expect(find.text(amt(1)), findsOneWidget); // chạm nhẹ = đúng một mức
    await tester.pump(const Duration(milliseconds: 400)); // chạm nhẹ đã thả ⇒ không rót thêm
    expect(find.text(amt(1)), findsOneWidget);

    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('order-hold'))));
    await tester.pump(const Duration(milliseconds: 1000));
    await g.up();
    await tester.pump();
    final text = tester.widget<Text>(find.byKey(const Key('order-amount'))).data!;
    final idx = [for (var i = 0; i < steps.length; i++) if (amt(i) == text) i].single;
    expect(idx, greaterThanOrEqualTo(5), reason: 'giữ ~1s phải rót được vài mức');
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.widget<Text>(find.byKey(const Key('order-amount'))).data, text, reason: 'thả tay là dừng');

    await tester.tap(find.byKey(const Key('order-reset')));
    await tester.pump();
    expect(find.text(amt(0)), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-pour')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('order-poured-${ing.name}')), findsOneWidget);
    expect(find.descendant(of: find.byKey(Key('order-poured-${ing.name}')), matching: find.text(amt(0))), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('khách đứng quầy: nét mặt đổi theo kết quả (🙂 chờ → 😍 hoàn hảo / 😕 sai)', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    final os = _expected(1);
    await _open(tester);
    Finder face(String f) => find.descendant(of: find.byKey(const Key('order-customer-face')), matching: find.text(f));
    expect(find.text('🙂'), findsOneWidget);
    await _serveExact(tester, os[0]);
    expect(find.text('😍'), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-next')));
    await tester.pumpAndSettle();
    expect(find.text('🙂'), findsOneWidget); // khách mới
    final first = os[1].recipe.ingredients.first;
    await _pour(tester, first.name, first.unit, first.qty);
    await tester.tap(find.byKey(const Key('order-serve'))); // thiếu nguyên liệu (nếu món ≥ 2 nguyên liệu)
    await tester.pumpAndSettle();
    expect(find.text(os[1].recipe.ingredients.length == 1 ? '😍' : '😕'), findsOneWidget);
    expect(face('🙂'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('vạch gợi ý theo bậc: Mới có thước + vạch mốc đúng, Quen chỉ thước, Thuộc/Thạo ẩn hết', (tester) async {
    for (final (box, ticks, target) in [(0, true, true), (1, true, false), (2, false, false), (3, false, false)]) {
      final prog = {for (final r in _catalog().recipes) '${r.id}': [box, 0, box]};
      await _pump(tester, size: const Size(400, 900), progress: prog);
      final o = _expected(1, progress: {for (final e in prog.entries) int.parse(e.key): RecipeProgress.fromList(e.value)}).first;
      await _open(tester);
      final ing = o.recipe.ingredients.first;
      await tester.ensureVisible(find.byKey(Key('order-tray-${ing.name}')));
      await tester.tap(find.byKey(Key('order-tray-${ing.name}')));
      await tester.pumpAndSettle();
      final cup = tester.widget<OrderCup>(find.descendant(of: find.byType(BottomSheet), matching: find.byType(OrderCup)));
      expect(cup.marks.isNotEmpty, ticks, reason: 'bậc $box: vạch chia');
      expect(cup.target != null, target, reason: 'bậc $box: vạch mốc');
      if (target) {
        // Vạch mốc đúng ở đúng vị trí của lượng công thức.
        final steps = amountSteps(ing.unit);
        expect(cup.target, closeTo(nearestStep(ing.unit, ing.qty) / (steps.length - 1) * 0.9, 1e-9));
      }
      await _teardown(tester);
    }
  });

  testWidgets('nguyên liệu gây nhiễu (không có trong công thức) không có vạch mốc dù bậc Mới', (tester) async {
    await _pump(tester, size: const Size(400, 900));
    final o = _expected(1).first;
    final extra = o.tray.firstWhere((t) => !o.recipe.ingredients.any((i) => i.name == t.name));
    await _open(tester);
    await tester.ensureVisible(find.byKey(Key('order-tray-${extra.name}')));
    await tester.tap(find.byKey(Key('order-tray-${extra.name}')));
    await tester.pumpAndSettle();
    final cup = tester.widget<OrderCup>(find.descendant(of: find.byType(BottomSheet), matching: find.byType(OrderCup)));
    expect(cup.target, isNull);
    await _teardown(tester);
  });

  testWidgets('combo: hoàn hảo liên tiếp → từ đơn 2 có tip Xu; sai thì đứt combo; đơn không tính bậc có combo nhưng không tip', (tester) async {
    final ads = _Ads();
    final c = await _pump(tester, size: const Size(400, 1000), ads: ads);
    final os = _expected(1);
    await _open(tester);
    double money() => c.read(gameControllerProvider).money;
    expect(find.byKey(const Key('order-combo')), findsNothing);
    await _serveExact(tester, os[0]);
    expect(find.textContaining('tip +'), findsNothing, reason: 'đơn 1: chưa có combo');
    await tester.tap(find.byKey(const Key('order-next')));
    await tester.pumpAndSettle();
    var before = money();
    await _serveExact(tester, os[1]);
    expect(find.textContaining('Combo ×2: tip +'), findsOneWidget);
    expect(money() - before, greaterThan(os.length * 0)); // có cộng Xu (gồm cả thưởng bậc + tip)
    await tester.tap(find.byKey(const Key('order-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-combo')), findsOneWidget); // chip combo hiện khi đang ≥ 2
    // Đơn 3: sai (chỉ cho 1 nguyên liệu, món ≥ 2 nguyên liệu) → đứt combo.
    final bad = os[2].recipe;
    if (bad.ingredients.length >= 2) {
      await _pour(tester, bad.ingredients.first.name, bad.ingredients.first.unit, bad.ingredients.first.qty);
      await tester.tap(find.byKey(const Key('order-serve')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Combo'), findsNothing);
      await tester.tap(find.byKey(const Key('order-next')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-combo')), findsNothing);
      before = money();
      await _serveExact(tester, os[3]);
      expect(find.textContaining('tip +'), findsNothing, reason: 'combo bắt đầu lại từ 1');
    }
    await _teardown(tester);
  });

  testWidgets('combo không tip khi món chưa tới hạn ôn (chống cày): vẫn hiện "Combo ×n" nhưng Xu không đổi', (tester) async {
    // Mọi món Quen, hạn ôn ở tương lai ⇒ đơn chỉ để luyện (outcome.counted = false).
    final prog = {for (final r in _catalog().recipes) '${r.id}': [1, 9999, 1]};
    final c = await _pump(tester, size: const Size(400, 1000), progress: prog);
    final typed = {for (final e in prog.entries) int.parse(e.key): RecipeProgress.fromList(e.value)};
    final os = _expected(1, progress: typed);
    await _open(tester);
    final m0 = c.read(gameControllerProvider).money;
    await _serveExact(tester, os[0]);
    await tester.tap(find.byKey(const Key('order-next')));
    await tester.pumpAndSettle();
    await _serveExact(tester, os[1]);
    expect(find.text('🔥 Combo ×2'), findsWidgets);
    expect(find.textContaining('tip +'), findsNothing);
    expect(c.read(gameControllerProvider).money, m0);
    await _teardown(tester);
  });

  testWidgets('dùng gợi ý QC làm đứt combo', (tester) async {
    final ads = _Ads();
    await _pump(tester, size: const Size(400, 1000), progress: {for (final r in _catalog().recipes) '${r.id}': [3, 0, 3]}, ads: ads);
    final typed = {for (final r in _catalog().recipes) r.id: const RecipeProgress(box: 3, dueDay: 0, best: 3)};
    final os = _expected(1, progress: typed);
    await _open(tester);
    await _serveExact(tester, os[0]);
    await tester.tap(find.byKey(const Key('order-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-hint')));
    await tester.pumpAndSettle();
    await _serveExact(tester, os[1]);
    expect(find.textContaining('Combo'), findsNothing, reason: 'đơn có gợi ý không nối combo');
    await _teardown(tester);
  });

  group('Giờ cao điểm (đồng hồ kiên nhẫn)', () {
    Future<void> rushOn(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('order-rush-toggle')));
      await tester.pump();
    }

    testWidgets('mặc định tắt (không có thanh); bật ở đơn đầu thì hiện thanh; rót rồi thì công tắc ẩn', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      expect(find.byKey(const Key('order-patience')), findsNothing);
      expect(find.byKey(const Key('order-rush-toggle')), findsOneWidget);
      await rushOn(tester);
      expect(find.byKey(const Key('order-patience')), findsOneWidget);
      final o = _expected(1).first;
      final i = o.recipe.ingredients.first;
      await _pour(tester, i.name, i.unit, i.qty);
      expect(find.byKey(const Key('order-rush-toggle')), findsNothing);
      expect(find.byKey(const Key('order-patience')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('thử thách ngày không có Giờ cao điểm', (tester) async {
      await _pump(tester, size: const Size(400, 1000), daily: true);
      expect(find.byKey(const Key('order-rush-toggle')), findsNothing);
      await _teardown(tester);
    });

    testWidgets('đơn hoàn hảo kịp giờ (món đến hạn) → tip "Giao kịp giờ" ngay từ đơn đầu, kể cả chưa có combo', (tester) async {
      final c = await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final m0 = c.read(gameControllerProvider).money;
      await _serveExact(tester, _expected(1).first);
      expect(find.textContaining('Giao kịp giờ! Tip +'), findsOneWidget);
      expect(c.read(gameControllerProvider).money, greaterThan(m0));
      await _teardown(tester);
    });

    testWidgets('món chưa tới hạn ôn → không tip Giờ cao điểm (chống cày)', (tester) async {
      final prog = {for (final r in _catalog().recipes) '${r.id}': [1, 9999, 1]};
      final c = await _pump(tester, size: const Size(400, 1000), progress: prog);
      final typed = {for (final e in prog.entries) int.parse(e.key): RecipeProgress.fromList(e.value)};
      await rushOn(tester);
      final m0 = c.read(gameControllerProvider).money;
      await _serveExact(tester, _expected(1, progress: typed).first);
      expect(find.textContaining('Tip +'), findsNothing);
      expect(c.read(gameControllerProvider).money, m0);
      await _teardown(tester);
    });

    testWidgets('không bật Giờ cao điểm → đơn đầu hoàn hảo không có tip', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      await _serveExact(tester, _expected(1).first);
      expect(find.textContaining('Tip +'), findsNothing);
      await _teardown(tester);
    });

    testWidgets('hết giờ: ly dở bị chấm luôn, báo "Hết giờ", không tip, đứt combo, phục vụ tiếp được', (tester) async {
      final c = await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final o = _expected(1).first;
      final i = o.recipe.ingredients.first;
      await _pour(tester, i.name, i.unit, i.qty);
      await tester.pump(Duration(seconds: orderPatienceSeconds(o.recipe.ingredients.length) + 1));
      expect(find.textContaining('Hết giờ'), findsOneWidget);
      expect(find.byKey(const Key('order-next')), findsOneWidget);
      expect(find.byKey(const Key('order-serve')), findsNothing);
      expect(find.textContaining('Tip +'), findsNothing);
      expect(c.read(gameControllerProvider).recipeProgress[o.recipe.id]?.box ?? 0, 0);
      await _teardown(tester);
    });

    testWidgets('hết giờ khi ly còn trống → vẫn chấm (sai), không treo', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final o = _expected(1).first;
      await tester.pump(Duration(seconds: orderPatienceSeconds(o.recipe.ingredients.length) + 1));
      expect(find.textContaining('Hết giờ'), findsOneWidget);
      expect(find.text('Chưa đúng món'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('đồng hồ tạm dừng khi bảng đặt lượng đang mở', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final o = _expected(1).first;
      await tester.ensureVisible(find.byKey(Key('order-tray-${o.recipe.ingredients.first.name}')));
      await tester.tap(find.byKey(Key('order-tray-${o.recipe.ingredients.first.name}')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 300));
      expect(find.byKey(const Key('order-amount')), findsOneWidget);
      await tester.tap(find.byKey(const Key('order-pour')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Hết giờ'), findsNothing);
      expect(find.byKey(const Key('order-serve')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('popup che màn (VD cutscene Hồi 4 mở khoá giữa đơn) ⇒ đồng hồ đứng; đóng popup thì chạy tiếp', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final o = _expected(1).first;
      final total = orderPatienceSeconds(o.recipe.ingredients.length);
      double v() => tester.widget<LinearProgressIndicator>(find.byKey(const Key('order-patience'))).value!;
      showDialog<void>(context: tester.element(find.byType(RecipeOrderPage)), builder: (_) => const AlertDialog(content: Text('popup')));
      await tester.pumpAndSettle();
      await tester.pump(Duration(seconds: total * 3)); // lâu gấp 3 lần kiên nhẫn
      expect(find.byKey(const Key('order-feedback')), findsNothing);
      expect(v(), 1.0, reason: 'không trôi một giây nào lúc có popup');
      Navigator.of(tester.element(find.text('popup'))).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(v(), lessThan(1.0));
      expect(find.byKey(const Key('order-feedback')), findsNothing);
      await tester.pump(Duration(seconds: total));
      expect(find.byKey(const Key('order-feedback')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('đơn sau có đồng hồ mới đầy lại', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      await rushOn(tester);
      final os = _expected(1);
      await _serveExact(tester, os[0]);
      await tester.tap(find.byKey(const Key('order-next')));
      await tester.pump();
      final bar = tester.widget<LinearProgressIndicator>(find.byKey(const Key('order-patience')));
      expect(bar.value, 1.0);
      await _teardown(tester);
    });
  });

  group('đơn lễ hội', () {
    final halloween = DateTime.utc(2026, 10, 25).millisecondsSinceEpoch ~/ _day;

    /// Đúng cách trang dựng buổi: 5 đơn thường rồi đơn lễ hội, cùng một Random.
    List<Order> sessionAt(int day, {Map<int, RecipeProgress> progress = const {}}) {
      final r = Random(1);
      final pool = unlockedRecipes(_catalog(), (id) => progress[id]?.best ?? 0);
      final os = buildOrders(_catalog(), progress, day, r, pool: pool);
      final f = buildFestivalOrder('halloween', _catalog(), progress, day, r,
          pool: pool, exclude: {for (final o in os) o.recipe.id});
      return [...os, ?f];
    }

    Future<void> toLast(WidgetTester tester, List<Order> os) async {
      for (final o in os.take(os.length - 1)) {
        await _serveExact(tester, o);
        await tester.tap(find.byKey(const Key('order-next')));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('trong dịp lễ: đơn cuối là đơn lễ hội (chip + khách emoji lễ hội); ngoài dịp không có', (tester) async {
      await _pump(tester, size: const Size(400, 1000), day: halloween);
      final os = sessionAt(halloween);
      expect(os.length, 6);
      expect(os.last.festival, 'halloween');
      expect(find.byKey(const Key('order-festival')), findsNothing, reason: 'đơn đầu là đơn thường');
      await toLast(tester, os);
      expect(find.byKey(const Key('order-festival')), findsOneWidget);
      expect(find.textContaining('Đơn lễ hội'), findsOneWidget);
      expect(find.text('🦇'), findsWidgets);
      await _teardown(tester);

      await _pump(tester, size: const Size(400, 1000), day: 100);
      expect(find.text('1/5'), findsOneWidget, reason: 'ngoài dịp lễ chỉ có 5 đơn');
      await _teardown(tester);
    });

    testWidgets('đơn lễ hội hoàn hảo (tính bậc) → tip riêng, cộng Xu', (tester) async {
      final c = await _pump(tester, size: const Size(400, 1000), day: halloween);
      final os = sessionAt(halloween);
      await toLast(tester, os);
      final m0 = c.read(gameControllerProvider).money;
      await _serveExact(tester, os.last);
      expect(find.textContaining('Đơn lễ hội hoàn hảo! Tip +'), findsOneWidget);
      expect(c.read(gameControllerProvider).money, greaterThan(m0));
      await _teardown(tester);
    });

    testWidgets('đơn lễ hội làm sai → không tip', (tester) async {
      await _pump(tester, size: const Size(400, 1000), day: halloween);
      final os = sessionAt(halloween);
      await toLast(tester, os);
      final i = os.last.recipe.ingredients.first;
      await _pour(tester, i.name, i.unit, i.qty);
      await tester.tap(find.byKey(const Key('order-serve')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tip +'), findsNothing);
      await _teardown(tester);
    });

    testWidgets('món lễ hội chưa tới hạn ôn → không tip (chống cày)', (tester) async {
      final prog = {for (final r in _catalog().recipes) '${r.id}': [1, 999999, 1]};
      final typed = {for (final e in prog.entries) int.parse(e.key): RecipeProgress.fromList(e.value)};
      final c = await _pump(tester, size: const Size(400, 1000), day: halloween, progress: prog);
      final os = sessionAt(halloween, progress: typed);
      await toLast(tester, os);
      final m0 = c.read(gameControllerProvider).money;
      await _serveExact(tester, os.last);
      expect(find.textContaining('Tip +'), findsNothing);
      expect(c.read(gameControllerProvider).money, m0);
      await _teardown(tester);
    });

    for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      testWidgets('320px, chữ 1.5×, $loc: đơn lễ hội không tràn', (tester) async {
        await _pump(tester, locale: loc, textScale: 1.5, day: halloween);
        final os = sessionAt(halloween);
        await toLast(tester, os);
        expect(find.byKey(const Key('order-festival')), findsOneWidget);
        await _serveExact(tester, os.last);
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      });
    }
  });

  group('rung phản hồi (haptics)', () {
    final calls = <String>[];
    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        if (c.method == 'HapticFeedback.vibrate') calls.add(c.arguments as String);
        return null;
      });
    });
    tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    testWidgets('rót xong: nhẹ; phục vụ hoàn hảo: vừa; phục vụ sai: mạnh', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      final os = _expected(1);
      await _serveExact(tester, os[0]);
      expect(calls.where((x) => x.contains('lightImpact')).length, os[0].recipe.ingredients.length);
      expect(calls.where((x) => x.contains('mediumImpact')).length, 1);
      expect(calls.where((x) => x.contains('heavyImpact')), isEmpty);
      await tester.tap(find.byKey(const Key('order-next')));
      await tester.pumpAndSettle();
      calls.clear();
      final i = os[1].recipe.ingredients.first;
      await _pour(tester, i.name, i.unit, i.qty);
      await tester.tap(find.byKey(const Key('order-serve')));
      await tester.pumpAndSettle();
      expect(calls.where((x) => x.contains('heavyImpact')).length, 1);
      expect(calls.where((x) => x.contains('mediumImpact')), isEmpty);
      await _teardown(tester);
    });

    testWidgets('thử thách ngày cũng rung khi chấm', (tester) async {
      await _pump(tester, size: const Size(400, 1000), daily: true);
      final o = buildDailyOrders(_catalog(), 100).first;
      await _serveExact(tester, o);
      expect(calls.where((x) => x.contains('mediumImpact')).length, 1);
      await _teardown(tester);
    });
  });

  group('khay: chip đã rót hiện ✓ + lượng', () {
    testWidgets('rót xong chip hiện "✓ lượng"; bỏ ra thì mất', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      final i = _expected(1).first.recipe.ingredients.first;
      expect(find.byKey(Key('order-tray-amount-${i.name}')), findsNothing);
      await _pour(tester, i.name, i.unit, i.qty);
      final t = tester.widget<Text>(find.byKey(Key('order-tray-amount-${i.name}')));
      expect(t.data, startsWith('✓ '));
      expect(t.data, contains(i.unit));
      await tester.tap(find.byKey(Key('order-poured-${i.name}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('order-remove')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('order-tray-amount-${i.name}')), findsNothing);
      await _teardown(tester);
    });
  });

  group('kệ trưng bày + khoe ly', () {
    testWidgets('không có phụ kiện → không có kệ', (tester) async {
      await _pump(tester, size: const Size(400, 1000));
      expect(find.byKey(const Key('order-shelf')), findsNothing);
      await _teardown(tester);
    });

    testWidgets('kệ hiện phụ kiện đang trưng bày; chưa đủ món Thạo thì có dòng nhắc mốc đầu', (tester) async {
      final a = accessories.first;
      await _pump(tester, size: const Size(400, 1000), setup: (g) {
        g.ownedAccessories.add(a.id);
        g.equippedAccessories.add(a.id);
      });
      expect(find.byKey(const Key('order-shelf')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('order-shelf')), matching: find.text(a.emoji)), findsOneWidget);
      expect(find.text('Thạo 10 món để mở thêm 1 chỗ trưng bày'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('đủ 10 món Thạo → mở 1 chỗ phụ cho món hiếm nhất trong kho; dòng nhắc chuyển sang mốc 30', (tester) async {
      final top = ([...accessories]..sort((a, b) {
          final r = b.rarity.index.compareTo(a.rarity.index);
          return r != 0 ? r : a.id.compareTo(b.id);
        }))
          .first;
      final eq = accessories.firstWhere((a) => a.rarity != top.rarity);
      await _pump(tester, size: const Size(400, 1000), setup: (g) {
        g.ownedAccessories.addAll([top.id, eq.id]);
        g.equippedAccessories.add(eq.id);
        for (final r in _catalog().recipes.take(10)) {
          g.recipeProgress['${r.id}'] = [3, 9999999, 3];
        }
      });
      final shelf = find.byKey(const Key('order-shelf'));
      expect(find.descendant(of: shelf, matching: find.text(top.emoji)), findsOneWidget);
      expect(find.text('Thạo 30 món để mở thêm 1 chỗ trưng bày'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('chỉ đơn hoàn hảo mới có nút Khoe ly; bấm → thẻ có tên món; chia sẻ ra PNG kèm lời', (tester) async {
      Uint8List? png;
      String? caption;
      await _pump(tester, size: const Size(400, 1000), share: (b, t, o) async {
        png = b;
        caption = t;
      });
      final o = _expected(1).first;
      expect(find.byKey(const Key('order-share')), findsNothing);
      await _serveExact(tester, o);
      await tester.tap(find.byKey(const Key('order-share')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cup-card-name')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('cup-card-name'))).data, o.recipe.name);
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.ios_share).last);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(caption, contains(o.recipe.name));
      expect(caption, contains('bobaempiregame.com'));
      await _teardown(tester);
    });

    testWidgets('đơn sai → không có nút Khoe ly; chia sẻ lỗi → báo lỗi, không crash', (tester) async {
      await _pump(tester, size: const Size(400, 1000), share: (_, _, _) async => throw 'boom');
      final o = _expected(1).first;
      final i = o.recipe.ingredients.first;
      await _pour(tester, i.name, i.unit, i.qty);
      await tester.tap(find.byKey(const Key('order-serve')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-share')), findsNothing);
      await _teardown(tester);

      await _pump(tester, size: const Size(400, 1000), share: (_, _, _) async => throw 'boom');
      await _serveExact(tester, o);
      await tester.tap(find.byKey(const Key('order-share')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.ios_share).last);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      expect(find.textContaining('Không chia sẻ được'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });

    for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      testWidgets('320px, chữ 1.5×, $loc: kệ + nút khoe ly + thẻ không tràn', (tester) async {
        final a = accessories.first;
        await _pump(tester, locale: loc, textScale: 1.5, setup: (g) {
          g.ownedAccessories.add(a.id);
          g.equippedAccessories.add(a.id);
        });
        await _serveExact(tester, _expected(1).first);
        await tester.tap(find.byKey(const Key('order-share')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('cup-card-name')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      });
    }
  });

  group('thử thách hằng ngày', () {
    testWidgets('đủ 3 đơn đúng → 300/300; thưởng 💎 + Xu một lần; KHÔNG đụng bậc / BXH Pha theo đơn / combo', (tester) async {
      final c = await _pump(tester, size: const Size(400, 1000), daily: true);
      final orders = buildDailyOrders(_catalog(), 100);
      final g0 = c.read(gameControllerProvider).gems;
      final m0 = c.read(gameControllerProvider).money;
      expect(find.byKey(const Key('daily-intro')), findsOneWidget);
      expect(find.byKey(const Key('order-hint')), findsNothing, reason: 'thử thách không có gợi ý QC');
      for (var i = 0; i < orders.length; i++) {
        await _serveExact(tester, orders[i]);
        expect(find.text('Điểm đơn này: 100/100'), findsOneWidget);
        expect(find.textContaining('Combo'), findsNothing);
        await tester.tap(find.byKey(const Key('order-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('300/300 điểm'), findsOneWidget);
      expect(find.byKey(const Key('daily-reward')), findsOneWidget);
      final v = c.read(gameControllerProvider);
      expect((v.recipeDailyDay, v.recipeDailyScore), (100, 300));
      expect(v.gems, g0 + dailyChallengeGems);
      expect(v.money, greaterThan(m0));
      expect(v.recipeProgress, isEmpty, reason: 'không ghi bậc thuộc');
      expect(v.recipeOrderPerfect, isEmpty);
      await _teardown(tester);
    });

    testWidgets('đơn thiếu nguyên liệu: điểm từng đơn đúng scoreOrder, tổng = tổng ba đơn', (tester) async {
      await _pump(tester, size: const Size(400, 1000), daily: true);
      final orders = buildDailyOrders(_catalog(), 100);
      var total = 0;
      for (var i = 0; i < orders.length; i++) {
        final o = orders[i];
        final partial = o.recipe.ingredients.take(1).toList();
        for (final ing in partial) {
          await _pour(tester, ing.name, ing.unit, ing.qty);
        }
        await tester.tap(find.byKey(const Key('order-serve')));
        await tester.pumpAndSettle();
        final expected = scoreOrder(o, gradeOrder(o, [for (final ing in partial) Poured(TrayItem(ing.name, ing.unit), ing.qty)]));
        total += expected;
        expect(find.text('Điểm đơn này: $expected/100'), findsOneWidget);
        await tester.tap(find.byKey(const Key('order-next')));
        await tester.pumpAndSettle();
      }
      expect(find.text('$total/300 điểm'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('đề cố định cho mọi người: seed ngẫu nhiên của người chơi khác nhau vẫn ra cùng đơn đầu', (tester) async {
      final texts = <String>[];
      for (final seed in [1, 2, 3]) {
        await _pump(tester, size: const Size(400, 1000), daily: true, seed: seed);
        texts.add(tester.widget<Text>(find.byKey(const Key('order-prompt'))).data!);
        await _teardown(tester);
      }
      expect(texts.toSet().length, 1);
    });

    testWidgets('đã làm hôm nay: chỉ xem lại điểm, không chơi lại; hôm qua thì chơi được', (tester) async {
      final c = await _pump(tester, size: const Size(400, 1000), daily: true, setup: (g) {
        g.recipeDailyDay = 100;
        g.recipeDailyScore = 180;
      });
      expect(find.byKey(const Key('daily-already')), findsOneWidget);
      expect(find.text('Hôm nay bạn được 180/300 điểm'), findsOneWidget);
      expect(find.byKey(const Key('order-prompt')), findsNothing);
      expect(c.read(gameControllerProvider).recipeDailyScore, 180);
      await _teardown(tester);

      await _pump(tester, size: const Size(400, 1000), daily: true, setup: (g) {
        g.recipeDailyDay = 99;
        g.recipeDailyScore = 300;
      });
      expect(find.byKey(const Key('daily-already')), findsNothing);
      expect(find.byKey(const Key('order-prompt')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('nút bảng xếp hạng: chưa liên kết email thì bị cổng chặn', (tester) async {
      await _pump(tester, size: const Size(400, 1000), daily: true, setup: (g) {
        g.recipeDailyDay = 100;
        g.recipeDailyScore = 50;
      });
      await tester.tap(find.byKey(const Key('daily-board')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget);
      await _teardown(tester);
    });

    for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      testWidgets('320px, chữ 1.5×, $loc: thử thách (đang chơi, kết quả, đã làm) không tràn', (tester) async {
        await _pump(tester, locale: loc, textScale: 1.5, daily: true);
        final orders = buildDailyOrders(_catalog(), 100);
        expect(tester.takeException(), isNull);
        for (final o in orders) {
          final first = o.recipe.ingredients.first;
          await _pour(tester, first.name, first.unit, first.qty);
          await tester.tap(find.byKey(const Key('order-serve')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$loc feedback');
          await tester.tap(find.byKey(const Key('order-next')));
          await tester.pumpAndSettle();
        }
        expect(find.byKey(const Key('daily-result')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$loc kết quả');
        await _teardown(tester);
        await _pump(tester, locale: loc, textScale: 1.5, daily: true, setup: (g) {
          g.recipeDailyDay = 100;
          g.recipeDailyScore = 123;
        });
        expect(find.byKey(const Key('daily-already')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$loc đã làm');
        await _teardown(tester);
      });
    }
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

    testWidgets('320px, chữ 1.5×, $loc: Giờ cao điểm (công tắc, thanh, hết giờ) không tràn', (tester) async {
      await _pump(tester, locale: loc, textScale: 1.5);
      await tester.tap(find.byKey(const Key('order-rush-toggle')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final o = _expected(1).first;
      await tester.pump(Duration(seconds: orderPatienceSeconds(o.recipe.ingredients.length) + 1));
      expect(find.byKey(const Key('order-feedback')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  }
}
