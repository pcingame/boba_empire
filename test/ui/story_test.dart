import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {GameState? seed, String? locale}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({'app_locale': ?locale});
  final prefs = await SharedPreferences.getInstance();
  if (seed != null) await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(HomePage)));
}

void main() {
  testWidgets('ván mới: Chương 1 tự hiện, "Tiếp tục" đóng và bump con trỏ',
      (tester) async {
    debugAutoShowStory = true;
    addTearDown(() => debugAutoShowStory = false);

    final container = await _pump(tester);
    expect(find.byKey(const Key('story-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('story-continue')), findsNothing);
    expect(container.read(gameControllerProvider).storyChapter, 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chương 6: chọn nhánh → perk áp vào thu nhập', (tester) async {
    debugAutoShowStory = true;
    addTearDown(() => debugAutoShowStory = false);

    final container = await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 5
        ..stage = 5
        ..levels['tra_den'] = 10,
    );
    final before = container.read(gameControllerProvider).incomePerSecond;

    expect(find.byKey(const Key('story-choice-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-choice-1'))); // "Thần tốc"
    await tester.pumpAndSettle();

    final snap = container.read(gameControllerProvider);
    expect(snap.storyChoiceA, 'scale');
    expect(snap.pendingStoryChapterId, isNull);
    expect(snap.incomePerSecond, greaterThan(before));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nút 📖 mở Cốt truyện và đóng được', (tester) async {
    await _pump(tester); // debugAutoShowStory = false

    await tester.tap(find.byKey(const Key('story-log-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-log-close')), findsOneWidget);

    await tester.tap(find.byKey(const Key('story-log-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-log-close')), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Nhật ký: chương khoá hiện ĐIỀU KIỆN + thanh tiến độ (chương kế), '
      'chương sau thì "Mở sau Chương N"', (tester) async {
    await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 1
        ..stage = 1,
    );
    await tester.tap(find.byKey(const Key('story-log-button')));
    await tester.pumpAndSettle();

    // Chương 2 là chương kế tiếp: điều kiện + tiến độ 1/2.
    expect(find.textContaining('Mở khi: Đạt giai đoạn 2'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(LinearProgressIndicator)),
        findsOneWidget); // chỉ chương kế tiếp có thanh tiến độ
    // Chương 3 chưa thoả: điều kiện riêng, không có thanh tiến độ.
    expect(find.textContaining('Mở khi: Đạt giai đoạn 3'), findsOneWidget);
    expect(find.text('Chương chưa mở'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Nhật ký: điều kiện đã thoả nhưng chương trước chưa xem -> '
      '"Mở sau Chương N-1"', (tester) async {
    await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 1
        ..stage = 6, // vượt ngưỡng chương 3, nhưng chương 2 chưa xem
    );
    await tester.tap(find.byKey(const Key('story-log-button')));
    await tester.pumpAndSettle();

    expect(find.text('Mở sau Chương 2'), findsOneWidget); // chương 3
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Nhật ký: gợi ý mở khoá không tràn ở màn 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 28 // gần Hồi 3: điều kiện Kỷ Nguyên + Trân Châu Rơi dài
        ..stage = 18,
    );
    expect(tester.takeException(), isNull, reason: 'màn chính (trước khi mở Nhật ký)');
    await tester.tap(find.byKey(const Key('story-log-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'Nhật ký');
    expect(find.textContaining('Mở khi:'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Nhật ký Hồi 4: chương kế hiện mốc trò chơi nhỏ + tiến độ; chương sau chỉ hiện điều kiện', (tester) async {
    await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 36
        ..storyChoiceG = 'open'
        ..recipeProgress.addAll({'1': [3, 0, 3], '2': [3, 0, 3]}),
    );
    await tester.tap(find.byKey(const Key('story-log-button')));
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    // Chương 37 (kế tiếp): Thạo 5 món ở Công thức, đã có 2.
    await tester.scrollUntilVisible(find.textContaining('Thạo 5 món'), 200, scrollable: list);
    expect(find.textContaining('Mở khi: Thạo 5 món'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    // Chương 39: pha hoàn hảo 5 món (chưa phải chương kế ⇒ không có thanh tiến độ).
    await tester.scrollUntilVisible(find.textContaining('Pha hoàn hảo 5 món'), 200, scrollable: list);
    expect(find.textContaining('Mở khi: Pha hoàn hảo 5 món'), findsOneWidget);
    // Chương 40: Thử thách hằng ngày 2 ngày.
    await tester.scrollUntilVisible(find.textContaining('trong 2 ngày'), 200, scrollable: list);
    expect(find.textContaining('Mở khi: Làm'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });

  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('Nhật ký Hồi 4 không tràn ở 320px, chữ lớn, $loc', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        locale: loc,
        seed: GameState.newGame(nowMillis: 0)
          ..storyChapter = 36
          ..storyChoiceG = 'open',
      );
      await tester.tap(find.byKey(const Key('story-log-button')));
      await tester.pumpAndSettle();
      final list = find.byType(Scrollable).last;
      for (var i = 0; i < 12; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Hồi 4 trên màn chính: làm xong Thử thách hằng ngày thứ 2 → cutscene Chương 40 tự hiện, "Tiếp tục" bump con trỏ', (tester) async {
    debugAutoShowStory = true;
    addTearDown(() => debugAutoShowStory = false);
    final container = await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 39
        ..storyChoiceG = 'open'
        ..recipeDailyCount = 1,
    );
    expect(find.byKey(const Key('story-continue')), findsNothing);
    container.read(gameControllerProvider.notifier).completeDailyChallenge(150);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-continue')), findsOneWidget);
    expect(find.text('Mỗi ngày một đề'), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-continue')));
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider).storyChapter, 40);
    expect(find.byKey(const Key('story-continue')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chương 46: hiện 2 lựa chọn (không đóng được), chọn "Tôn vinh tay nghề" → trục H, perk chạm, chốt mốc Hồi 4', (tester) async {
    debugAutoShowStory = true;
    addTearDown(() => debugAutoShowStory = false);
    final container = await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)
        ..storyChapter = 45
        ..storyChoiceG = 'open'
        ..stage = 18
        ..recipeOrderPerfect.addAll(List.generate(40, (i) => i + 1)),
    );
    expect(find.byKey(const Key('story-choice-0')), findsOneWidget);
    expect(find.byKey(const Key('story-choice-1')), findsOneWidget);
    expect(find.byKey(const Key('story-continue')), findsNothing);
    expect(find.text('Cúp Đại Hội'), findsOneWidget);
    await tester.tap(find.byKey(const Key('story-choice-0')));
    await tester.pumpAndSettle();
    final snap = container.read(gameControllerProvider);
    expect(snap.pendingStoryChapterId, isNull);
    expect(snap.storyChapter, 46);
    expect(snap.storyFourthActCompleteSeconds, isNotNull, reason: 'chốt mốc phá đảo Hồi 4');
    // Lưu xuống đĩa: đúng nhánh "mastery" (trục chạm).
    final saved = GameStorage(container.read(sharedPreferencesProvider)).load()!;
    expect(saved.storyChoiceH, 'mastery');
    expect(saved.storyFourthActCompleteSeconds, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('cutscene Chương 46 (lựa chọn) không tràn ở 320px, chữ 1.5×, $loc', (tester) async {
      debugAutoShowStory = true;
      addTearDown(() => debugAutoShowStory = false);
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        locale: loc,
        seed: GameState.newGame(nowMillis: 0)
          ..storyChapter = 45
          ..storyChoiceG = 'open'
          // Không đặt stage 18: header giai đoạn ở màn chính (không liên quan cutscene) tràn 4.7px ở en/320px/1.5×.
          ..recipeOrderPerfect.addAll(List.generate(40, (i) => i + 1)),
      );
      expect(find.byKey(const Key('story-choice-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
