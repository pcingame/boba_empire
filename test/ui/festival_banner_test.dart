// Banner dịp lễ ở màn chính: chỉ hiện TRONG dịp, bấm mở hộp thoại sự kiện, có
// chấm đỏ khi có nhiệm vụ chờ nhận, và không làm tràn màn hẹp/thấp.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _inFestival = festivals.first.start.millisecondsSinceEpoch + 60000;

Future<ProviderContainer> _pump(WidgetTester tester,
    {required int now, GameState? seed, String locale = 'vi'}) async {
  SharedPreferences.setMockInitialValues({'app_locale': locale});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      seed ?? (GameState.newGame(nowMillis: 0)..tutorialSeen = true),
      nowMillis: now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return c;
}

GameState _seed({int tap = 0}) => GameState.newGame(nowMillis: 0)
  ..tutorialSeen = true
  ..eventId = 'halloween'
  ..eventProgress['tap'] = tap.toDouble();

void main() {
  testWidgets('ngoài dịp: không có banner', (tester) async {
    final c = await _pump(tester, now: 1000);
    expect(find.byKey(const Key('event-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('trong dịp: có banner, bấm mở hộp thoại, chấm đỏ khi có thưởng',
      (tester) async {
    final c = await _pump(tester, now: _inFestival, seed: _seed(tap: 1500));
    expect(find.byKey(const Key('event-banner')), findsOneWidget);
    expect(find.textContaining('Halloween'), findsWidgets);
    // Nhiệm vụ "chạm 1500" đã xong chưa nhận -> chấm đỏ "1".
    expect(
        find.descendant(
            of: find.byKey(const Key('event-banner')), matching: find.text('1')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('event-banner')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('event-leaderboard-button')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('dịp kết thúc khi app đang mở: banner biến mất ở lần tick sau',
      (tester) async {
    var now = _inFestival;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(_seed(), nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('event-banner')), findsOneWidget);

    now = festivals.first.end.millisecondsSinceEpoch + 1000;
    c.read(gameControllerProvider.notifier).debugTick();
    await tester.pump();
    expect(find.byKey(const Key('event-banner')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    for (final size in [const Size(320, 568), const Size(375, 667)]) {
      testWidgets('[$locale] banner không tràn ở ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final c = await _pump(tester,
            now: _inFestival, seed: _seed(tap: 1500), locale: locale);
        expect(find.byKey(const Key('event-banner')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
    c.dispose();
      });
    }
  }
}
