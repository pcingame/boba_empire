import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _closeKey = Key('how-to-play-close');

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
  testWidgets('nút ? mở bảng Cách chơi rồi đóng được', (tester) async {
    // debugAutoShowTutorial = false (mặc định trong flutter_test_config).
    await _pump(tester);
    expect(find.byKey(_closeKey), findsNothing); // chưa tự mở

    await tester.tap(find.byKey(const Key('how-to-play-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(_closeKey), findsOneWidget);

    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();
    expect(find.byKey(_closeKey), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('lần chơi đầu tự hiện hướng dẫn và đánh dấu đã xem',
      (tester) async {
    debugAutoShowTutorial = true;
    addTearDown(() => debugAutoShowTutorial = false);

    final container = await _pump(tester); // ván mới, tutorialSeen = false
    expect(find.byKey(_closeKey), findsOneWidget); // tự hiện
    expect(container.read(gameControllerProvider).tutorialSeen, true);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đã xem rồi thì không tự hiện lại', (tester) async {
    debugAutoShowTutorial = true;
    addTearDown(() => debugAutoShowTutorial = false);

    await _pump(
      tester,
      seed: GameState.newGame(nowMillis: 0)..tutorialSeen = true,
    );
    expect(find.byKey(_closeKey), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
