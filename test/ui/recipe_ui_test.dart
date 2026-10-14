// Trò luyện công thức (giao diện): vào từ hộp "Kiếm thêm", luyện hết buổi, bậc/thưởng/lưu, tổng kết,
// và mọi ngôn ngữ ở 320px không tràn.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/recipe_quiz.dart';
import 'package:boba_empire/core/recipes.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/main.dart';
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

/// Buổi luyện sẽ hiện ra trong lần mở đầu tiên: cùng Random(seed) ⇒ cùng câu hỏi (kiểm xác định).
List<QuizQuestion> _expected(int seed, {Map<int, RecipeProgress> progress = const {}, int day = 100}) =>
    buildSession(_catalog(), progress, day, Random(seed));

Future<void> _answer(WidgetTester tester, QuizQuestion q, {required bool correct}) async {
  final pick = correct ? q.answer : (q.answer + 1) % 4;
  // Câu dài (công thức đầy đủ) có thể cao hơn màn nhỏ: cuộn tới lựa chọn trước khi chạm.
  await tester.ensureVisible(find.byKey(Key('recipe-quiz-option-$pick')));
  await tester.tap(find.byKey(Key('recipe-quiz-option-$pick')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('màn công thức: 20 món, tiến độ 0/20, nút luyện tập; mở thẻ công thức', (tester) async {
    await _pump(tester);
    expect(find.text('Thạo 0/20 món'), findsOneWidget);
    expect(find.text('20 món cần ôn hôm nay'), findsOneWidget);
    expect(find.byKey(const Key('recipe-practice')), findsOneWidget);
    expect(find.text('Hồng trà sữa'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipe-tile-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe-card')), findsOneWidget);
    expect(find.text('Hồng trà khô'), findsOneWidget);
    expect(find.text('10 g'), findsOneWidget);
    expect(find.text('Ôn lại: hôm nay'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('luyện đủ 8 câu đúng: lên bậc, có thưởng, lưu vào game; tiến độ hiện ở màn công thức', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.byKey(const Key('recipe-practice')));
    await tester.pumpAndSettle();
    final qs = _expected(1);
    for (var i = 0; i < 8; i++) {
      expect(find.text('${i + 1}/8'), findsOneWidget);
      expect(find.textContaining(qs[i].recipe.name), findsWidgets); // đúng câu hỏi dự kiến
      await _answer(tester, qs[i], correct: true);
      expect(find.text('Chính xác!'), findsOneWidget);
      expect(find.textContaining('lên bậc'), findsOneWidget);
      await tester.tap(find.byKey(const Key('recipe-quiz-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('recipe-result')), findsOneWidget);
    expect(find.text('8/8 câu đúng'), findsOneWidget);
    expect(find.text('8 món lên bậc'), findsOneWidget);
    expect(find.byKey(const Key('recipe-reward')), findsOneWidget);
    final snap = c.read(gameControllerProvider);
    expect(snap.recipeProgress.length, 8);
    expect(snap.recipeProgress.values.every((p) => p.box == 1), isTrue);
    expect(snap.money, closeTo(8 * recipeRewardFloorTaps[1], 1e-9));
    // Về màn công thức: 12 món còn cần ôn (8 món vừa trả lời hẹn ngày mai).
    await tester.tap(find.byKey(const Key('recipe-done')));
    await tester.pumpAndSettle();
    expect(find.text('12 món cần ôn hôm nay'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('trả lời sai: không lên bậc, hiện đáp án đúng, không thưởng; luyện tiếp bù 4 món đến hạn + 4 món chỉ luyện', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.byKey(const Key('recipe-practice')));
    await tester.pumpAndSettle();
    final qs = _expected(1);
    await _answer(tester, qs[0], correct: false);
    expect(find.textContaining('Chưa đúng'), findsOneWidget);
    expect(find.textContaining('lên bậc'), findsNothing);
    expect(find.byKey(const Key('recipe-quiz-next')), findsOneWidget);
    final box0 = c.read(gameControllerProvider).recipeProgress.values.single;
    expect(box0.box, 0);
    expect(c.read(gameControllerProvider).money, 0);
    await tester.tap(find.byKey(const Key('recipe-quiz-next')));
    await tester.pumpAndSettle();
    for (var i = 1; i < 8; i++) {
      await _answer(tester, qs[i], correct: true);
      await tester.tap(find.byKey(const Key('recipe-quiz-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('7/8 câu đúng'), findsOneWidget);
    // Buổi 2 (luyện tiếp, cùng ngày): 12 món chưa đụng + 1 món sai (vẫn đến hạn) = 13 đến hạn → đủ 8, không bù.
    await tester.tap(find.byKey(const Key('recipe-again')));
    await tester.pumpAndSettle();
    expect(find.text('1/8'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('món chưa tới hạn chỉ để luyện: báo rõ và không đổi bậc', (tester) async {
    // 20 món đều đã Quen và hẹn ngày mai → cả buổi chỉ là luyện.
    final progress = {for (final r in _catalog().playable) '${r.id}': [1, 101, 1]};
    final c = await _pump(tester, progress: progress);
    expect(find.text('Hôm nay bạn đã ôn xong! Vẫn có thể luyện thêm (không tính bậc).'), findsOneWidget);
    await tester.tap(find.byKey(const Key('recipe-practice')));
    await tester.pumpAndSettle();
    final qs = _expected(1, progress: {for (final e in progress.entries) int.parse(e.key): RecipeProgress.fromList(e.value)});
    await _answer(tester, qs[0], correct: true);
    expect(find.textContaining('chỉ để luyện'), findsOneWidget);
    expect(find.textContaining('lên bậc'), findsNothing);
    expect(c.read(gameControllerProvider).money, 0);
    expect(c.read(gameControllerProvider).recipeProgress.values.every((p) => p.box == 1), isTrue);
    await _teardown(tester);
  });

  testWidgets('thoát giữa buổi: kết quả đã trả lời được giữ', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.byKey(const Key('recipe-practice')));
    await tester.pumpAndSettle();
    await _answer(tester, _expected(1)[0], correct: true);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).recipeProgress.length, 1);
    expect(find.text('19 món cần ôn hôm nay'), findsOneWidget);
    await _teardown(tester);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ to 1.5×: màn công thức + thẻ + buổi luyện + tổng kết ($lang)', (tester) async {
      await _pump(tester, locale: lang, textScale: 1.5, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(
          find.byKey(const Key('recipe-tile-1')), find.byType(ListView), const Offset(0, -120));
      await tester.ensureVisible(find.byKey(const Key('recipe-tile-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recipe-tile-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe-card')), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.state<NavigatorState>(find.byType(Navigator).last).pop(); // đóng thẻ
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
          find.byKey(const Key('recipe-practice')), find.byType(ListView), const Offset(0, 200));
      await tester.ensureVisible(find.byKey(const Key('recipe-practice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recipe-practice')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 8; i++) {
        // Chữ to: lựa chọn nằm dưới mép — ListView dựng lười nên phải cuộn tới.
        await tester.ensureVisible(find.byKey(const Key('recipe-quiz-option-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recipe-quiz-option-0')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'câu ${i + 1}');
        await tester.ensureVisible(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('recipe-result')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  }

  testWidgets('tab Trò chơi ở màn chính: hộp có Trân Châu Rơi + Công thức; vào được công thức; hiện số món cần ôn', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..tutorialSeen = true, nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * _day),
      recipeCatalogProvider.overrideWith((ref) async => _catalog()),
    ]);
    _live.add(c);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('match3-button')));
    await tester.pumpAndSettle();
    expect(find.text('Trò chơi'), findsWidgets);
    expect(find.byKey(const Key('games-match3')), findsOneWidget);
    expect(find.text('Trân Châu Rơi'), findsOneWidget);
    expect(find.text('20 món cần ôn hôm nay'), findsOneWidget);
    await tester.tap(find.byKey(const Key('games-recipes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recipe-practice')), findsOneWidget);
    expect(find.text('Công thức pha chế'), findsWidgets);
    await _teardown(tester);
  });

  testWidgets('hộp Trò chơi: bấm Trân Châu Rơi mở màn hành trình; hết món cần ôn thì không hiện dòng phụ', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final g = GameState.newGame(nowMillis: 0)..tutorialSeen = true;
    for (final r in _catalog().playable) {
      g.recipeProgress['${r.id}'] = [1, 101, 1]; // đã ôn xong hôm nay
    }
    await GameStorage(prefs).save(g, nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * _day),
      recipeCatalogProvider.overrideWith((ref) async => _catalog()),
    ]);
    _live.add(c);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('match3-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('games-recipes-due')), findsNothing);
    await tester.tap(find.byKey(const Key('games-match3')));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget); // lưới màn của hành trình Trân Châu Rơi
    await _teardown(tester);
  });

  Future<void> openPractice(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recipe-practice')));
    await tester.pumpAndSettle();
  }

  int visibleOptions(WidgetTester tester) =>
      [for (var i = 0; i < 4; i++) find.byKey(Key('recipe-quiz-option-$i')).evaluate().isNotEmpty].where((x) => x).length;

  group('quảng cáo: gợi ý 50:50 + nhân đôi thưởng', () {
    testWidgets('gợi ý: xem xong thì bỏ 2 đáp án sai (đáp án đúng còn), nút gợi ý mất; câu này KHÔNG tính bậc',
        (tester) async {
      final ads = _Ads();
      final c = await _pump(tester, ads: ads);
      await openPractice(tester);
      final q = _expected(1)[0];
      expect(visibleOptions(tester), 4);
      await tester.ensureVisible(find.byKey(const Key('recipe-hint')));
      await tester.tap(find.byKey(const Key('recipe-hint')));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(visibleOptions(tester), 2);
      expect(find.byKey(Key('recipe-quiz-option-${q.answer}')), findsOneWidget);
      expect(find.byKey(const Key('recipe-hint')), findsNothing);
      await _answer(tester, q, correct: true);
      expect(find.text('Chính xác!'), findsOneWidget);
      expect(find.text('Đã dùng gợi ý nên câu này không tính bậc.'), findsOneWidget);
      expect(find.textContaining('lên bậc'), findsNothing);
      expect(c.read(gameControllerProvider).recipeProgress, isEmpty);
      expect(c.read(gameControllerProvider).money, 0);
      // Câu kế: gợi ý lại có sẵn (mỗi câu một lần).
      await tester.tap(find.byKey(const Key('recipe-quiz-next')));
      await tester.pumpAndSettle();
      expect(visibleOptions(tester), 4);
      expect(find.byKey(const Key('recipe-hint')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('quảng cáo không xem xong: không bỏ đáp án nào, báo "chưa có quảng cáo", vẫn bấm gợi ý lại được',
        (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      await _pump(tester, ads: ads);
      await openPractice(tester);
      await tester.ensureVisible(find.byKey(const Key('recipe-hint')));
      await tester.tap(find.byKey(const Key('recipe-hint')));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(visibleOptions(tester), 4);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const Key('recipe-hint')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('buổi toàn câu dùng gợi ý: KHÔNG tính nhiệm vụ ngày/tuần; buổi có câu được tính thì tính',
        (tester) async {
      final ads = _Ads();
      final c = await _pump(tester, ads: ads);
      await openPractice(tester);
      final qs = _expected(1);
      for (var i = 0; i < 8; i++) {
        await tester.ensureVisible(find.byKey(const Key('recipe-hint')));
        await tester.tap(find.byKey(const Key('recipe-hint')));
        await tester.pumpAndSettle();
        await _answer(tester, qs[i], correct: true);
        await tester.tap(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('recipe-result')), findsOneWidget);
      final g = c.read(gameControllerProvider.notifier).debugGame;
      expect(g.dailyProgress[DailyQuestKind.recipe.name], isNull);
      expect(g.weeklyProgress[WeeklyQuestKind.recipeSessions.name], isNull);
      expect(find.byKey(const Key('recipe-double')), findsNothing); // không có thưởng để nhân đôi

      // Luyện tiếp: lần này trả lời bình thường 8 câu đều được tính (món chưa đụng) ⇒ buổi được tính.
      await tester.tap(find.byKey(const Key('recipe-again')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        // Buổi 2 dùng Random đã tiêu hao nên câu khác buổi 1: đọc đáp án từ màn hình bằng cách thử lần lượt
        // lựa chọn 0 (đúng hay sai đều được "tính" miễn món đến hạn).
        await tester.tap(find.byKey(const Key('recipe-quiz-option-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
      }
      final g2 = c.read(gameControllerProvider.notifier).debugGame;
      expect(g2.dailyProgress[DailyQuestKind.recipe.name], 1.0);
      expect(g2.weeklyProgress[WeeklyQuestKind.recipeSessions.name], 1.0);
      await _teardown(tester);
    });

    testWidgets('nhân đôi thưởng: xem xong thì +đúng số Xu một lần, nút biến thành thông báo; không xem xong thì không đổi',
        (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      final c = await _pump(tester, ads: ads);
      await openPractice(tester);
      final qs = _expected(1);
      for (var i = 0; i < 8; i++) {
        await _answer(tester, qs[i], correct: true);
        await tester.tap(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
      }
      final reward = 8 * recipeRewardFloorTaps[1] * 1.0;
      expect(c.read(gameControllerProvider).money, closeTo(reward, 1e-9));
      expect(find.byKey(const Key('recipe-double')), findsOneWidget);
      await tester.tap(find.byKey(const Key('recipe-double'))); // quảng cáo không xem xong
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).money, closeTo(reward, 1e-9));
      expect(find.byKey(const Key('recipe-double')), findsOneWidget);

      ads.outcome = RewardOutcome.earned;
      await tester.tap(find.byKey(const Key('recipe-double')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).money, closeTo(reward * 2, 1e-9));
      expect(find.byKey(const Key('recipe-doubled')), findsOneWidget);
      expect(find.byKey(const Key('recipe-double')), findsNothing); // chỉ nhân đôi một lần
      expect(ads.shown, 2);
      await _teardown(tester);
    });
  });

  testWidgets('món Thạo thứ 5: màn luyện báo nhận phụ kiện (một lần), lưu cờ mốc', (tester) async {
    final ids = _catalog().playable.map((r) => r.id).toList();
    // 4 món đã Thạo (hẹn xa); 1 món bậc Thuộc đến hạn → đúng một câu đến hạn, lên Thạo = món thứ 5.
    final progress = <String, List<int>>{
      for (final id in ids) '$id': [3, 9999, 3],
      '${ids[4]}': [2, 0, 2],
    };
    for (final id in ids.skip(5)) {
      progress['$id'] = [1, 9999, 1]; // chưa tới hạn
    }
    final c = await _pump(tester, progress: progress);
    await openPractice(tester);
    final qs = _expected(1, progress: {for (final e in progress.entries) int.parse(e.key): RecipeProgress.fromList(e.value)});
    expect(qs.first.recipe.id, ids[4]);
    await _answer(tester, qs.first, correct: true);
    expect(find.textContaining('lên bậc'), findsOneWidget);
    expect(find.text('Thạo 5 món — bạn nhận được một phụ kiện!'), findsOneWidget);
    expect(c.read(gameControllerProvider.notifier).debugGame.recipeMilestonesClaimed, [5]);
    await _teardown(tester);
  });

  group('chuỗi ngày ôn + cứu chuỗi', () {
    void streak(GameState g, int days, int lastDay, {double gems = 0}) {
      g
        ..recipeStreak = days
        ..recipeStreakBest = days
        ..recipeStreakLastDay = lastDay
        ..gems = gems;
    }

    testWidgets('chuỗi đang sống: hiện số ngày + trạng thái hôm nay; đã đứt thì ẩn; chưa có thì ẩn', (tester) async {
      await _pump(tester, setup: (g) => streak(g, 4, 100)); // ôn hôm nay
      expect(find.text('🔥 Chuỗi ôn: 4 ngày'), findsOneWidget);
      expect(find.text('Hôm nay đã ôn ✓'), findsOneWidget);
      expect(find.byKey(const Key('recipe-rescue')), findsNothing);
      await _teardown(tester);

      await _pump(tester, setup: (g) => streak(g, 4, 99)); // ôn hôm qua, hôm nay chưa
      expect(find.text('🔥 Chuỗi ôn: 4 ngày'), findsOneWidget);
      expect(find.textContaining('chưa ôn'), findsOneWidget);
      await _teardown(tester);

      await _pump(tester, setup: (g) => streak(g, 4, 90)); // đứt từ lâu
      expect(find.byKey(const Key('recipe-streak')), findsNothing);
      expect(find.byKey(const Key('recipe-rescue')), findsNothing);
      await _teardown(tester);

      await _pump(tester); // chưa từng
      expect(find.byKey(const Key('recipe-streak')), findsNothing);
      await _teardown(tester);
    });

    testWidgets('lỡ đúng một ngày: hiện thẻ cứu chuỗi (không hiện hàng chuỗi thường)', (tester) async {
      await _pump(tester, setup: (g) => streak(g, 6, 98, gems: 100));
      expect(find.byKey(const Key('recipe-rescue')), findsOneWidget);
      expect(find.text('Bạn lỡ một ngày — chuỗi 6 ngày sắp mất!'), findsOneWidget);
      expect(find.text('Cứu bằng 30 💎'), findsOneWidget);
      expect(find.byKey(const Key('recipe-streak')), findsNothing);
      await _teardown(tester);
    });

    testWidgets('cứu bằng 💎: trừ đúng, chuỗi +1, thẻ biến mất; thiếu 💎 thì báo và giữ thẻ', (tester) async {
      final c = await _pump(tester, setup: (g) => streak(g, 6, 98, gems: 100));
      await tester.tap(find.byKey(const Key('recipe-rescue-gems')));
      await tester.pumpAndSettle();
      expect(find.text('Đã cứu chuỗi!'), findsOneWidget);
      expect(c.read(gameControllerProvider).gems, 70);
      expect(find.byKey(const Key('recipe-rescue')), findsNothing);
      expect(find.text('🔥 Chuỗi ôn: 7 ngày'), findsOneWidget);
      await _teardown(tester);

      final c2 = await _pump(tester, setup: (g) => streak(g, 6, 98, gems: 10));
      await tester.tap(find.byKey(const Key('recipe-rescue-gems')));
      await tester.pumpAndSettle();
      expect(find.text('Không đủ 💎 để cứu chuỗi.'), findsOneWidget);
      expect(c2.read(gameControllerProvider).gems, 10);
      expect(find.byKey(const Key('recipe-rescue')), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('cứu bằng quảng cáo: xem xong thì cứu miễn phí; không xem xong thì giữ thẻ', (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      final c = await _pump(tester, ads: ads, setup: (g) => streak(g, 6, 98, gems: 0));
      await tester.tap(find.byKey(const Key('recipe-rescue-ad')));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(find.byKey(const Key('recipe-rescue')), findsOneWidget);
      expect(c.read(gameControllerProvider).recipeStreak.days, 6);
      ads.outcome = RewardOutcome.earned;
      await tester.tap(find.byKey(const Key('recipe-rescue-ad')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recipe-rescue')), findsNothing);
      expect(c.read(gameControllerProvider).recipeStreak.days, 7);
      expect(c.read(gameControllerProvider).gems, 0);
      await _teardown(tester);
    });

    testWidgets('buổi luyện: câu đầu tiên trong ngày báo chuỗi; tới mốc 3 ngày báo +10 💎', (tester) async {
      final c = await _pump(tester, setup: (g) => streak(g, 2, 99)); // hôm qua ôn: hôm nay thành 3
      await openPractice(tester);
      final qs = _expected(1);
      await _answer(tester, qs[0], correct: true);
      expect(find.text('🔥 Chuỗi 3 ngày! +10 💎'), findsOneWidget);
      expect(c.read(gameControllerProvider).recipeStreak.days, 3);
      await tester.tap(find.byKey(const Key('recipe-quiz-next')));
      await tester.pumpAndSettle();
      await _answer(tester, qs[1], correct: true); // câu thứ hai cùng ngày: không báo chuỗi nữa
      expect(find.textContaining('Chuỗi'), findsNothing);
      await _teardown(tester);

      final c2 = await _pump(tester); // chưa có chuỗi
      await openPractice(tester);
      await _answer(tester, _expected(1)[0], correct: true);
      expect(find.text('🔥 Chuỗi ôn: 1 ngày'), findsOneWidget);
      expect(c2.read(gameControllerProvider).recipeStreak.days, 1);
      await _teardown(tester);
    });

    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      testWidgets('thẻ cứu chuỗi + hàng chuỗi không tràn ở 320px, chữ 1.5× ($lang)', (tester) async {
        await _pump(tester, locale: lang, textScale: 1.5, size: const Size(320, 640), setup: (g) => streak(g, 12, 98, gems: 100));
        expect(find.byKey(const Key('recipe-rescue')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _teardown(tester);
        await _pump(tester, locale: lang, textScale: 1.5, size: const Size(320, 640), setup: (g) => streak(g, 12, 99));
        expect(find.byKey(const Key('recipe-streak')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _teardown(tester);
      });
    }
  });

  // (Chỉ tiếng Việt: ở 400dp + chữ 1.5× các ngôn ngữ dài hơn có đáp án đa dòng cao hơn cả vùng cuộn nên không có cách nào vừa.
  // Kích thước 400 được chọn để bài kiểm CÓ KHẢ NĂNG PHÁT HIỆN lỗi: bỏ lệnh cuộn tới đáp án thì bài này đỏ.)
  for (final lang in ['vi']) {
    testWidgets('trả lời xong: đáp án đúng luôn nằm trong tầm nhìn (cuộn tới) dù màn thấp + chữ to ($lang)', (tester) async {
      await _pump(tester, locale: lang, textScale: 1.5, size: const Size(320, 400));
      await tester.ensureVisible(find.byKey(const Key('recipe-practice'))); // màn thấp + chữ to: thẻ tóm tắt cao hơn màn
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recipe-practice')));
      await tester.pumpAndSettle();
      final qs = _expected(1);
      for (var i = 0; i < 8; i++) {
        // Chọn lựa chọn SAI xa đáp án đúng nhất để nó phải cuộn mới thấy.
        final wrong = qs[i].answer <= 1 ? 3 : 0;
        await tester.ensureVisible(find.byKey(Key('recipe-quiz-option-$wrong')));
        await tester.tap(find.byKey(Key('recipe-quiz-option-$wrong')));
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byKey(Key('recipe-quiz-option-${qs[i].answer}')));
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        // Bảng phản hồi + nút "Câu tiếp" chiếm đáy; đáp án đúng phải nằm trên nó (không bị che / ngoài màn).
        final next = tester.getRect(find.byKey(const Key('recipe-quiz-next')));
        expect(box.top, greaterThanOrEqualTo(0), reason: 'câu $i: đáp án đúng trôi lên khỏi màn');
        expect(box.bottom, lessThanOrEqualTo(next.top + 1), reason: 'câu $i: đáp án đúng bị bảng phản hồi che');
        expect(box.bottom, lessThanOrEqualTo(screen.height));
        await tester.tap(find.byKey(const Key('recipe-quiz-next')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await _teardown(tester);
    });
  }

  group('giao diện (bố cục)', () {
    testWidgets('màn công thức: 3 hòm quà mốc 5/10/20 mờ-sáng theo số món đã Thạo; chip bậc sát mép phải của thẻ',
        (tester) async {
      // 6 món đã Thạo → mốc 5 sáng, 10 và 20 mờ.
      final c = await _pump(tester, progress: {for (var i = 1; i <= 6; i++) '$i': [3, 9999, 3]});
      double opacityOf(String m) {
        final o = find.ancestor(of: find.text(m), matching: find.byType(Opacity));
        return tester.widget<Opacity>(o.first).opacity;
      }

      expect(find.text('🎁'), findsNWidgets(3));
      expect((opacityOf('5'), opacityOf('10'), opacityOf('20')), (1.0, 0.4, 0.4));
      // Chip "Thạo" nằm sát mép phải thẻ món (không lưng chừng như khi chia đôi chỗ trống với tên).
      final tile = tester.getRect(find.byKey(const Key('recipe-tile-1')));
      final chip = tester.getRect(find.descendant(of: find.byKey(const Key('recipe-tile-1')), matching: find.text('Thạo')));
      expect(tile.right - chip.right, lessThan(40), reason: 'chip phải sát mép phải của thẻ');
      expect(c.read(gameControllerProvider).recipeProgress.length, 6);
      await _teardown(tester);
    });

    testWidgets('lựa chọn có huy hiệu A–D; sau khi trả lời huy hiệu đáp án đúng thành ✓, lựa chọn sai thành ✗', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(const Key('recipe-practice')));
      await tester.pumpAndSettle();
      final q = _expected(1)[0];
      for (final letter in ['A', 'B', 'C', 'D']) {
        expect(find.text(letter), findsOneWidget);
      }
      await _answer(tester, q, correct: false);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await _teardown(tester);
    });

    testWidgets('tổng kết: 🏆 + 3 sao khi đúng hết; 🎉 + 2 sao khi đúng ≥ 60%; 💪 + 1 sao khi dưới', (tester) async {
      final qs = _expected(1);
      for (final (wrongCount, emoji, stars) in [(0, '🏆', 3), (1, '🎉', 2), (6, '💪', 1)]) {
        await _pump(tester);
        await tester.tap(find.byKey(const Key('recipe-practice')));
        await tester.pumpAndSettle();
        for (var i = 0; i < 8; i++) {
          await _answer(tester, qs[i], correct: i >= wrongCount);
          await tester.tap(find.byKey(const Key('recipe-quiz-next')));
          await tester.pumpAndSettle();
        }
        expect(find.text(emoji), findsOneWidget, reason: '$wrongCount câu sai');
        expect(find.byIcon(Icons.star_rounded), findsNWidgets(stars), reason: '$wrongCount câu sai');
        expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(3 - stars));
        await _teardown(tester);
      }
    });
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('hòm quà mốc: nhãn số không bị cắt ở đáy với chữ $scale× (lỗi thật: height cố định 36)', (tester) async {
      await _pump(tester, textScale: scale, size: const Size(360, 800));
      final holder = tester.getRect(find.byKey(const Key('recipe-milestones')));
      for (final m in ['5', '10', '20']) {
        final label = tester.getRect(find.text(m));
        expect(label.bottom, lessThanOrEqualTo(holder.bottom + 0.5), reason: 'nhãn $m bị cắt (chữ $scale×)');
        expect(label.left, greaterThanOrEqualTo(holder.left - 0.5));
        expect(label.right, lessThanOrEqualTo(holder.right + 0.5));
      }
      await _teardown(tester);
    });
  }
}
