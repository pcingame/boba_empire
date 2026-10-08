// Hộp thoại sự kiện + BXH sự kiện: không tràn ở mọi ngôn ngữ trên màn hẹp,
// nút nhận/đổi hoạt động, và BXH xử lý tên dài/rỗng/chưa có điểm.
import 'dart:ui' as ui;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/event_leaderboard_controller.dart';
import 'package:boba_empire/leaderboard/event_leaderboard_repository.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/event_dialog.dart';
import 'package:boba_empire/ui/event_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = festivals.first.start.millisecondsSinceEpoch + 60000;

class _FakeLb extends EventLeaderboardController {
  _FakeLb(this.view);
  final EventLeaderboardViewState view;
  @override
  EventLeaderboardViewState build() => view;
  @override
  Future<void> refresh({bool silent = false}) async {}
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

Widget _app(String locale, SharedPreferences prefs, Widget home,
        {List<Override> extra = const []}) =>
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
        flairCacheProvider.overrideWith(_Flair.new),
        ...extra,
      ],
      child: MaterialApp(
        locale: ui.Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

Future<SharedPreferences> _prefs(GameState g) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(g, nowMillis: _now);
  return prefs;
}

void main() {
  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] hộp thoại sự kiện không tràn trên 320px; nhận + đổi được',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await _prefs(GameState.newGame(nowMillis: _now)
        ..eventId = 'halloween'
        ..eventPoints = 30
        ..eventProgress['tap'] = 1500);
      await tester.pumpWidget(_app(
          locale,
          prefs,
          Builder(
              builder: (c) => TextButton(
                  onPressed: () => showEventDialog(c),
                  child: const Text('open')))));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Món epic (25) đổi được với 30 điểm; legendary (50) thì không.
      final ghost = find.byKey(const Key('event-redeem-ghost'));
      final witch = find.byKey(const Key('event-redeem-witch'));
      expect(tester.widget<FilledButton>(ghost).onPressed, isNotNull);
      expect(tester.widget<FilledButton>(witch).onPressed, isNull);
      await tester.ensureVisible(ghost);
      await tester.tap(ghost);
      await tester.pumpAndSettle();
      expect(find.text('✓'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('event-leaderboard-button')), findsOneWidget);
    });
  }

  testWidgets('tiến độ hiện số nguyên đúng với tiêu đề (1500, không phải "2K")',
      (tester) async {
    final prefs = await _prefs(GameState.newGame(nowMillis: _now)
      ..eventId = 'halloween'
      ..eventProgress['tap'] = 1234);
    await tester.pumpWidget(_app(
        'en',
        prefs,
        Builder(
            builder: (c) => TextButton(
                onPressed: () => showEventDialog(c),
                child: const Text('open')))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('1234 / 1500'), findsOneWidget);
  });

  group('BXH sự kiện', () {
    Future<void> show(WidgetTester tester, EventLeaderboardViewState v,
        {String locale = 'vi'}) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = await _prefs(GameState.newGame(nowMillis: _now));
      await tester.pumpWidget(_app(locale, prefs, const EventLeaderboardPage(),
          extra: [
            eventLeaderboardControllerProvider
                .overrideWith(() => _FakeLb(v)),
          ]));
      await tester.pumpAndSettle();
    }

    testWidgets('tên rất dài + điểm lớn không gây tràn', (tester) async {
      await show(
          tester,
          const EventLeaderboardLoaded(
            entries: [
              EventLeaderboardEntry(
                  userId: 'u1',
                  nickname: 'MộtCáiTênRấtRấtDàiNhưngVẫnPhảiVừa',
                  score: 999999999,
                  rank: 1),
              EventLeaderboardEntry(
                  userId: 'me', nickname: 'Tôi', score: 12, rank: 2),
            ],
            myUserId: 'me',
            myScore: 12,
          ));
      expect(tester.takeException(), isNull);
      expect(find.text('Tôi'), findsOneWidget);
    });

    testWidgets('bảng rỗng hiện lời mời; chưa có điểm thì nhắc cách lên bảng',
        (tester) async {
      await show(tester,
          const EventLeaderboardLoaded(entries: [], myUserId: null, myScore: 0));
      expect(find.textContaining('Chưa có ai lên bảng'), findsOneWidget);
    });

    testWidgets('có người nhưng mình 0 điểm -> nhắc làm gì để lên bảng',
        (tester) async {
      await show(
          tester,
          const EventLeaderboardLoaded(
            entries: [
              EventLeaderboardEntry(
                  userId: 'u1', nickname: 'A', score: 5, rank: 1)
            ],
            myUserId: 'me',
            myScore: 0,
          ));
      expect(find.textContaining('chưa có điểm'), findsOneWidget);
    });

    testWidgets('cần đặt tên / lỗi mạng: hiện form / nút thử lại', (tester) async {
      await show(tester, const EventLeaderboardNeedsNickname());
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('lỗi: có nút thử lại', (tester) async {
      await show(tester, const EventLeaderboardError());
      expect(find.byType(FilledButton), findsOneWidget);
    });

    for (final locale in ['en', 'pt', 'es', 'id', 'th', 'ko']) {
      testWidgets('[$locale] bảng đầy không tràn', (tester) async {
        await show(
            tester,
            const EventLeaderboardLoaded(
              entries: [
                EventLeaderboardEntry(
                    userId: 'u1', nickname: 'Player', score: 123456, rank: 1)
              ],
              myUserId: 'u1',
              myScore: 123456,
            ),
            locale: locale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
