import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {GameState? seed}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
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
}
