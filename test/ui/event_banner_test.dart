// Dải sự kiện giới hạn thời gian ở màn chính: ẩn khi không có sự kiện, hiện
// đúng chữ khi có, và KHÔNG làm tràn màn hẹp (400px + hệ số lẻ + đếm ngược
// dài — đúng lớp lỗi RenderFlex đã gặp nhiều lần trong file này).
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, {required int now}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs)
      .save(GameState.newGame(nowMillis: 0)..tutorialSeen = true, nowMillis: 0);
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

void main() {
  late double origMult, origStart, origEnd;
  setUp(() {
    origMult = Balance.eventIncomeMult;
    origStart = Balance.eventStartMillis;
    origEnd = Balance.eventEndMillis;
  });
  tearDown(() {
    Balance.eventIncomeMult = origMult;
    Balance.eventStartMillis = origStart;
    Balance.eventEndMillis = origEnd;
  });

  testWidgets('không có sự kiện -> không hiện dải', (tester) async {
    Balance.eventIncomeMult = 1.0;
    Balance.eventStartMillis = 0;
    Balance.eventEndMillis = 0;
    final c = await _pump(tester, now: 1000);
    expect(find.byKey(const Key('event-banner-text')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đang trong sự kiện -> hiện đúng hệ số và đếm ngược', (tester) async {
    Balance.eventIncomeMult = 2.0;
    Balance.eventStartMillis = 0;
    Balance.eventEndMillis = 3665000; // 1h 1m 5s sau mốc 0
    final c = await _pump(tester, now: 1000); // còn ~1h1m
    final text = tester.widget<Text>(find.byKey(const Key('event-banner-text'))).data!;
    expect(text, contains('×2'));
    expect(text, contains('1h'));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final width in [320, 375, 400]) {
    testWidgets('dải sự kiện không tràn ở màn ${width}px, hệ số lẻ',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width.toDouble(), 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Balance.eventIncomeMult = 1.5; // hệ số LẺ — nhánh format khác ×2
      Balance.eventStartMillis = 0;
      Balance.eventEndMillis = 999999000; // đếm ngược dài, nhiều chữ số
      final c = await _pump(tester, now: 1000);
      // pumpAndSettle không cần: FittedBox tự co, không ném RenderFlex nếu
      // đúng; build() ném lỗi thật nếu tràn — đủ để _pump ở trên không throw.
      final text = tester
          .widget<Text>(find.byKey(const Key('event-banner-text')))
          .data!;
      expect(text, contains('×1.5'));
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
