// Thử thách trong hộp Nhiệm vụ ngày: hiện tiêu đề + 2 hàng + thưởng cả bộ; nhận thưởng cộng 💎; không tràn.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/challenges.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/daily_quests_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dayMs = 24 * 60 * 60 * 1000;

Future<ProviderContainer> _open(WidgetTester tester,
    {int day = 20000, String locale = 'vi', Size size = const Size(400, 1000)}) async {
  final now = day * _dayMs + 1000;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: now), nowMillis: now);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showDailyQuests(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

int _dayWith(ChallengeKind k) {
  for (var d = 20000;; d++) {
    if (challengesFor(d).any((c) => c.kind == k)) return d;
  }
}

void main() {
  testWidgets('hộp nhiệm vụ ngày có mục Thử thách với đủ số hàng + thưởng cả bộ', (tester) async {
    final c = await _open(tester);
    await tester.ensureVisible(find.byKey(const Key('challenge-header')));
    expect(find.byKey(const Key('challenge-header')), findsOneWidget);
    for (final ch in challengesFor(20000)) {
      expect(find.byKey(Key('challenge-claim-${ch.kind.name}')), findsOneWidget, reason: ch.kind.name);
    }
    expect(find.byKey(const Key('challenge-bonus')), findsOneWidget);
    // Nút khoá khi chưa đạt.
    for (final ch in challengesFor(20000)) {
      final b = tester.widget<FilledButton>(find.byKey(Key('challenge-claim-${ch.kind.name}')));
      expect(b.onPressed, isNull);
    }
    await _end(tester, c);
  });

  testWidgets('đủ tiến độ thì nút bật; bấm → cộng 💎 đúng và nút thành "Đã nhận"', (tester) async {
    final day = _dayWith(ChallengeKind.tap);
    final c = await _open(tester, day: day);
    final ctrl = c.read(gameControllerProvider.notifier);
    final snap = c.read(gameControllerProvider);
    final tapChallenge = snap.challenges.firstWhere((x) => x.kind == ChallengeKind.tap);
    for (var i = 0; i < tapChallenge.target; i++) {
      ctrl.tapCup();
    }
    await tester.pumpAndSettle();
    final key = find.byKey(const Key('challenge-claim-tap'));
    await tester.ensureVisible(key);
    expect(tester.widget<FilledButton>(key).onPressed, isNotNull);
    final g0 = c.read(gameControllerProvider).gems;
    await tester.tap(key);
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).gems, g0 + Balance.challengeRewardGems);
    expect(tester.widget<FilledButton>(key).onPressed, isNull);
    expect(find.text('Đã nhận'), findsWidgets);
    await _end(tester, c);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] mục Thử thách 360px không tràn', (tester) async {
      // Không được có lỗi layout nào trong cả hộp (kể cả hàng thưởng cả bộ mới thêm).
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      // Ngày có loại dài nhất (mèo/VIP/m3) để thử nhãn dài.
      final c = await _open(tester, day: _dayWith(ChallengeKind.m3Win), locale: l, size: const Size(360, 800));
      await tester.ensureVisible(find.byKey(const Key('challenge-bonus')));
      await tester.pumpAndSettle();
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      await _end(tester, c);
    });
  }
}
