// Animation của trò công thức: lắc/nảy/đếm/thanh mượt/chuyển câu, hiệu ứng Lottie theo mức chất lượng,
// và KHÔNG ép vẽ khung khi đứng yên. Các test này BẬT animation (mặc định test tắt — xem flutter_test_config).
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_quiz.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/recipe_providers.dart';
import 'package:boba_empire/ui/recipe_hub_page.dart';
import 'package:boba_empire/ui/widgets/ambient_ticker.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/idle_mascot.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/one_shot_lottie.dart' show debugResetLiveEffects;
import 'package:boba_empire/ui/widgets/recipe_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

RecipeCatalog _catalog() => RecipeCatalog.fromJson(
    jsonDecode(File('assets/recipes/recipes.json').readAsStringSync()) as Map<String, dynamic>);

List<QuizQuestion> _expected(int seed, {Map<int, RecipeProgress> progress = const {}}) =>
    buildSession(_catalog(), progress, 100, Random(seed),
        pool: unlockedRecipes(_catalog(), (id) => progress[id]?.best ?? 0));

final _live = <ProviderContainer>[];
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

/// Bơm [ms] mili giây theo bước 16ms (KHÔNG dùng pumpAndSettle: mascot hơi nước ở màn công thức chạy mãi).
Future<void> _for(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Chờ hiệu ứng Lottie nạp xong (đọc file bất đồng bộ) rồi chạy hết.
Future<void> _drain(WidgetTester tester, {int ms = 4000}) async {
  for (var t = 0; t < ms; t += 200) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  EffectsPref quality = EffectsPref.high,
  Map<String, List<int>>? progress,
  void Function(GameState)? setup,
  int seed = 1,
}) async {
  tester.view.physicalSize = const Size(320 * 2, 700 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  EffectsController.instance.init(prefs, platformStart: EffectsQuality.high, listenFrames: false);
  await EffectsController.instance.setPref(quality);
  final g = GameState.newGame(nowMillis: 0)..tutorialSeen = true;
  if (progress != null) g.recipeProgress.addAll(progress);
  setup?.call(g);
  await GameStorage(prefs).save(g, nowMillis: 0);
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
      home: const RecipeHubPage(),
    ),
  ));
  await _for(tester, 600);
  return c;
}

Future<void> _openPractice(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('recipe-practice')));
  await _for(tester, 600);
}

Future<void> _answer(WidgetTester tester, QuizQuestion q, {required bool correct}) async {
  final pick = correct ? q.answer : (q.answer + 1) % 4;
  // Câu dài (công thức đầy đủ) có thể cao hơn màn nhỏ: cuộn tới lựa chọn trước khi chạm.
  await tester.ensureVisible(find.byKey(Key('recipe-quiz-option-$pick')));
  await tester.tap(find.byKey(Key('recipe-quiz-option-$pick')));
}

/// Dịch chuyển ngang hiện tại của lớp "lắc" bọc quanh lựa chọn [i].
double _shakeDx(WidgetTester tester, int i) {
  final t = find.ancestor(of: find.byKey(Key('recipe-quiz-option-$i')), matching: find.byKey(const Key('shake-transform')));
  return tester.widget<Transform>(t.first).transform.getTranslation().x;
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

  group('widget chuyển động', () {
    Widget host(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

    testWidgets('ShakeOnTrigger: chỉ lắc khi trigger TĂNG; biên độ ≤ distance và tắt dần về 0', (tester) async {
      Widget build(int trigger) => host(ShakeOnTrigger(trigger: trigger, distance: 10, child: const SizedBox(width: 50, height: 20)));
      double dx() => tester.widget<Transform>(find.byKey(const Key('shake-transform'))).transform.getTranslation().x;
      await tester.pumpWidget(build(0));
      expect(dx(), 0);
      await tester.pumpWidget(build(0));
      await _for(tester, 100);
      expect(dx(), 0); // không đổi → không lắc
      await tester.pumpWidget(build(1));
      final seen = <double>[];
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        seen.add(dx());
      }
      expect(seen.any((x) => x.abs() > 1), isTrue, reason: 'phải có chuyển động');
      expect(seen.every((x) => x.abs() <= 10), isTrue);
      await _for(tester, 500);
      expect(dx().abs(), lessThan(0.01)); // đã dừng, về chỗ cũ
      await tester.pumpWidget(build(0)); // giảm: không lắc
      await _for(tester, 100);
      expect(dx().abs(), lessThan(0.01));
    });

    testWidgets('ShakeOnTrigger: tắt animation (reduceMotion) thì không lắc', (tester) async {
      mascot.debugDisableMascotAnimation = true;
      Widget build(int trigger) => host(ShakeOnTrigger(trigger: trigger, child: const SizedBox(width: 50, height: 20)));
      await tester.pumpWidget(build(0));
      await tester.pumpWidget(build(1));
      await _for(tester, 120);
      expect(tester.widget<Transform>(find.byKey(const Key('shake-transform'))).transform.getTranslation().x, 0);
    });

    testWidgets('CountUp: chạy từ 0 lên giá trị rồi dừng; tắt animation thì hiện luôn', (tester) async {
      await tester.pumpWidget(host(CountUp(value: 8, builder: (_, n) => Text('n=$n'))));
      expect(find.text('n=0'), findsOneWidget);
      await _for(tester, 250);
      final mid = int.parse((tester.widget<Text>(find.byType(Text)).data!).substring(2));
      expect(mid, inInclusiveRange(1, 7), reason: 'đang đếm dở');
      await _for(tester, 900);
      expect(find.text('n=8'), findsOneWidget);

      mascot.debugDisableMascotAnimation = true;
      await tester.pumpWidget(host(CountUp(key: UniqueKey(), value: 5, builder: (_, n) => Text('m=$n'))));
      expect(find.text('m=5'), findsOneWidget);
    });

    testWidgets('SmoothBar: lần đầu hiện ngay; đổi giá trị thì chạy mượt qua giá trị trung gian', (tester) async {
      double v() => tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value!;
      await tester.pumpWidget(host(const SizedBox(width: 200, child: SmoothBar(value: 0.25))));
      expect(v(), 0.25);
      await tester.pumpWidget(host(const SizedBox(width: 200, child: SmoothBar(value: 0.75))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(v(), inExclusiveRange(0.3, 0.74), reason: 'đang chạy giữa 0.25 và 0.75');
      await _for(tester, 600);
      expect(v(), closeTo(0.75, 1e-6));

      mascot.debugDisableMascotAnimation = true;
      await tester.pumpWidget(host(const SizedBox(width: 200, child: SmoothBar(value: 0.1))));
      await tester.pump();
      expect(v(), closeTo(0.1, 1e-6)); // tắt animation: nhảy thẳng
    });
  });

  group('buổi luyện có animation', () {
    testWidgets('trả lời SAI: lựa chọn đã chọn lắc, đáp án đúng nảy; các lựa chọn khác đứng yên; sau đó dừng',
        (tester) async {
      await _pump(tester);
      await _openPractice(tester);
      final q = _expected(1)[0];
      final wrong = (q.answer + 1) % 4;
      final other = [for (var i = 0; i < 4; i++) if (i != q.answer && i != wrong) i].first;
      await _answer(tester, q, correct: false);
      final shakes = <double>[];
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        shakes.add(_shakeDx(tester, wrong));
        expect(_shakeDx(tester, other), 0, reason: 'lựa chọn không liên quan không được lắc');
        expect(_shakeDx(tester, q.answer), 0, reason: 'đáp án đúng nảy chứ không lắc');
      }
      expect(shakes.any((x) => x.abs() > 1), isTrue);
      await _for(tester, 600);
      expect(_shakeDx(tester, wrong).abs(), lessThan(0.01));
      await _teardown(tester);
    });

    testWidgets('trả lời ĐÚNG: không lắc; đáp án đúng nảy to hơn 1 rồi về 1', (tester) async {
      await _pump(tester);
      await _openPractice(tester);
      final q = _expected(1)[0];
      await _answer(tester, q, correct: true);
      double scale() {
        final st = find.ancestor(of: find.byKey(Key('recipe-quiz-option-${q.answer}')), matching: find.byType(ScaleTransition));
        return tester.widget<ScaleTransition>(st.first).scale.value;
      }

      var peak = 1.0;
      for (var i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = max(peak, scale());
        expect(_shakeDx(tester, q.answer), 0);
      }
      expect(peak, greaterThan(1.02));
      await _for(tester, 500);
      expect(scale(), closeTo(1.0, 1e-6));
      await _teardown(tester);
    });

    testWidgets('chuyển câu: có khoảnh khắc cả hai câu cùng hiện (trượt + mờ), rồi chỉ còn câu mới', (tester) async {
      await _pump(tester);
      await _openPractice(tester);
      await _answer(tester, _expected(1)[0], correct: true);
      await _for(tester, 400);
      await tester.tap(find.byKey(const Key('recipe-quiz-next')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('recipe-quiz-prompt')), findsNWidgets(2));
      await _for(tester, 500);
      expect(find.byKey(const Key('recipe-quiz-prompt')), findsOneWidget);
      expect(find.text('2/8'), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('thanh tiến độ trên cùng chạy mượt sau mỗi câu', (tester) async {
      await _pump(tester);
      await _openPractice(tester);
      double bar() => tester.widget<LinearProgressIndicator>(
          find.descendant(of: find.byKey(const Key('recipe-quiz-progress')), matching: find.byType(LinearProgressIndicator))).value!;
      expect(bar(), 0);
      await _answer(tester, _expected(1)[0], correct: true);
      await tester.pump(); // khung đầu: animation bắt đầu tính giờ
      await tester.pump(const Duration(milliseconds: 150));
      expect(bar(), inExclusiveRange(0.0, 0.125), reason: 'đang chạy tới 1/8');
      await _for(tester, 600);
      expect(bar(), closeTo(1 / 8, 1e-6));
      await _teardown(tester);
    });

    testWidgets('tổng kết: điểm đếm lên; đúng hết thì có pháo giấy, sai một câu thì không', (tester) async {
      final qs = _expected(1);
      for (final perfect in [true, false]) {
        await _pump(tester);
        await _openPractice(tester);
        for (var i = 0; i < 8; i++) {
          await _answer(tester, qs[i], correct: perfect || i != 3);
          await _for(tester, 400);
          await tester.tap(find.byKey(const Key('recipe-quiz-next')));
          await _for(tester, 400);
        }
        expect(find.byKey(const Key('recipe-result')), findsOneWidget);
        final correct = perfect ? 8 : 7;
        // Điểm đang đếm dở rồi đạt đúng giá trị.
        await _for(tester, 900);
        expect(find.text('$correct/8 câu đúng'), findsOneWidget);
        await _teardown(tester);
      }
    });
  });

  group('hiệu ứng Lottie theo mức chất lượng', () {
    /// Số Lottie đang có trên cây (kể cả mascot hơi nước ở màn dưới) — so sánh trước/sau một thao tác.
    int lotties(WidgetTester tester) => find.byType(Lottie).evaluate().length;

    Future<int> effectsAfterAnswer(WidgetTester tester, EffectsPref quality,
        {bool correct = true, Map<String, List<int>>? progress}) async {
      await _pump(tester, quality: quality, progress: progress);
      await _openPractice(tester);
      final q = _expected(1, progress: {
        for (final e in (progress ?? {}).entries) int.parse(e.key): RecipeProgress.fromList(e.value),
      })[0];
      final before = lotties(tester);
      await _answer(tester, q, correct: correct);
      // Lottie nạp bất đồng bộ: bơm vừa đủ để thấy chúng đang chạy, chưa chờ chạy hết.
      var peak = 0;
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 60));
        peak = max(peak, lotties(tester) - before);
      }
      await _drain(tester);
      await _teardown(tester);
      return peak;
    }

    testWidgets('mức Cao: đúng câu món mới → tia sáng + hiệu ứng lên bậc (2 hiệu ứng); sai → không có', (tester) async {
      expect(await effectsAfterAnswer(tester, EffectsPref.high), 2);
      expect(await effectsAfterAnswer(tester, EffectsPref.high, correct: false), 0);
    });

    testWidgets('mức Thấp: chỉ còn tia sáng nhỏ (bỏ hiệu ứng lên bậc nặng); mức Tắt: không có gì', (tester) async {
      expect(await effectsAfterAnswer(tester, EffectsPref.low), 1);
      expect(await effectsAfterAnswer(tester, EffectsPref.off), 0);
    });

    testWidgets('đứng yên ở màn luyện: KHÔNG ép vẽ khung (không animation vô hạn)', (tester) async {
      await _pump(tester);
      await _openPractice(tester);
      await _answer(tester, _expected(1)[0], correct: true);
      await _drain(tester); // chạy hết mọi hiệu ứng
      var scheduled = 0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (tester.binding.hasScheduledFrame) scheduled++;
      }
      expect(scheduled, 0, reason: 'trang đứng yên không được xin khung mới');
      await _teardown(tester);
    });
  });

  group('màn công thức', () {
    testWidgets('cốc hơi nước chạy bằng nhịp chung khi bật; Tắt hiệu ứng thì mascot đứng yên, không nhịp nào', (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('recipe-steam')), findsOneWidget);
      expect(tester.widget<IdleMascot>(find.byKey(const Key('recipe-steam'))).animate, isTrue);
      expect(AmbientTicker.instance.running, isTrue);
      await _teardown(tester);

      await _pump(tester, quality: EffectsPref.off);
      expect(tester.widget<IdleMascot>(find.byKey(const Key('recipe-steam'))).animate, isFalse);
      expect(AmbientTicker.instance.running, isFalse);
      var scheduled = 0;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (tester.binding.hasScheduledFrame) scheduled++;
      }
      expect(scheduled, 0, reason: 'mức Tắt: màn công thức hoàn toàn yên');
      await _teardown(tester);
    });

    testWidgets('thanh Thạo chạy mượt khi tiến độ đổi (không nhảy thẳng); thẻ cứu chuỗi có mặt', (tester) async {
      final c = await _pump(
        tester,
        progress: {'1': [2, 0, 2]}, // món 1 bậc Thuộc, đến hạn: trả lời đúng sẽ lên Thạo
        setup: (g) => g
          ..recipeStreak = 5
          ..recipeStreakBest = 5
          ..recipeStreakLastDay = 98
          ..gems = 100,
      );
      expect(find.byKey(const Key('recipe-rescue')), findsOneWidget);
      double bar() => tester.widget<LinearProgressIndicator>(
          find.descendant(of: find.byKey(const Key('recipe-mastered-bar')), matching: find.byType(LinearProgressIndicator))).value!;
      expect(bar(), 0);
      c.read(gameControllerProvider.notifier).answerRecipe(1, true); // → Thạo: 1/20 = 0.05
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(bar(), inExclusiveRange(0.0, 0.05), reason: 'đang chạy từ 0 tới 0.05');
      await _for(tester, 600);
      expect(bar(), closeTo(0.05, 1e-6));
      await _teardown(tester);
    });
  });
}
