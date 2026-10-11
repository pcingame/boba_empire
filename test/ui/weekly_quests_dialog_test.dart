import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/daily_quests_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayMs = 24 * 60 * 60 * 1000;

/// Thứ Tư của một tuần có đủ [weeks] kiểu bộ nhiệm vụ để test nhiều tổ hợp.
int _nowOfWeek(int w) => ((w * 7 - 3) + 2) * _dayMs + 1000;

Future<ProviderContainer> _open(
  WidgetTester tester, {
  required int week,
  bool allDone = false,
  String locale = 'en',
  Size size = const Size(400, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final now = _nowOfWeek(week);
  final seed = GameState.newGame(nowMillis: now)
    ..tutorialSeen = true
    ..weeklyQuestWeek = week
    ..gems = 0;
  if (allDone) {
    for (final q in weeklyQuestsFor(week)) {
      seed.weeklyProgress[q.kind.name] = q.target.toDouble();
    }
  }
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: now);
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: ui.Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showDailyQuests(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('weekly-quests-open')));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _done(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets(
    'hiện đúng 3 nhiệm vụ của tuần, tiến độ 0, nút nhận mờ, có đếm ngược',
    (tester) async {
      const week = 2950;
      final c = await _open(tester, week: week);
      expect(find.text('Weekly quests'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        final q = weeklyQuestsFor(week)[i];
        expect(find.text('0 / ${q.target}'), findsWidgets);
        expect(
          tester
              .widget<FilledButton>(find.byKey(Key('weekly-quest-claim-$i')))
              .onPressed,
          isNull,
        );
      }
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('weekly-chest')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('weekly-resets-in')), findsOneWidget);
      await _done(tester, c);
    },
  );

  testWidgets(
    'xong cả 3: nhận từng cái (+50💎) rồi mở rương (+150💎 và phụ kiện)',
    (tester) async {
      final c = await _open(tester, week: 2951, allDone: true);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('weekly-quest-claim-$i')));
        await tester.pumpAndSettle();
      }
      expect(
        c.read(gameControllerProvider).gems,
        3 * weeklyQuestRewardGems.toDouble(),
      );
      await tester.tap(find.byKey(const Key('weekly-chest')));
      await tester.pumpAndSettle();
      expect(
        c.read(gameControllerProvider).gems,
        greaterThanOrEqualTo(
          (3 * weeklyQuestRewardGems + weeklyChestGems).toDouble(),
        ),
      );
      expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('weekly-chest')))
            .onPressed,
        isNull,
      );
      await _done(tester, c);
    },
  );

  testWidgets('nút Nhận mờ lại sau khi nhận (không nhận đôi)', (tester) async {
    final c = await _open(tester, week: 2952, allDone: true);
    await tester.tap(find.byKey(const Key('weekly-quest-claim-0')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('weekly-quest-claim-0')))
          .onPressed,
      isNull,
    );
    expect(
      c.read(gameControllerProvider).gems,
      weeklyQuestRewardGems.toDouble(),
    );
    await _done(tester, c);
  });

  // Mọi loại nhiệm vụ đều có chuỗi ở 7 ngôn ngữ, không tràn ở 320px, không còn "{n}".
  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('320px, mọi loại nhiệm vụ, không tràn ($lang)', (tester) async {
      // Tìm các tuần phủ hết 6 loại nhiệm vụ.
      final weeks = <int>[];
      final covered = <WeeklyQuestKind>{};
      for (var w = 2900; covered.length < WeeklyQuestKind.values.length; w++) {
        final kinds = weeklyQuestsFor(w).map((q) => q.kind).toSet();
        if (!covered.containsAll(kinds)) {
          weeks.add(w);
          covered.addAll(kinds);
        }
      }
      for (final w in weeks) {
        final c = await _open(
          tester,
          week: w,
          allDone: true,
          locale: lang,
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull, reason: '$lang tuần $w');
        expect(
          find.textContaining(RegExp(r'\{[a-z]+\}')),
          findsNothing,
          reason: '$lang tuần $w',
        );
        await _done(tester, c);
      }
    });
  }
}
