// BXH Thẻ Mùa: nộp XP khi có biệt danh, hỏi tên khi chưa có, danh sách + trạng thái rỗng; hằng số khớp SQL.
import 'dart:io';

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/season.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/season_leaderboard.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/season_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements SeasonLbRepository {
  List<SeasonLbEntry> rows = [];
  final submits = <(String, int, int)>[];
  @override
  Future<void> submit(String n, int s, int xp) async => submits.add((n, s, xp));
  @override
  Future<List<SeasonLbEntry>> top() async => rows;
  @override
  String? get myUserId => 'me';
  @override
  Future<List<SeasonEndReward>> rewardStatus() async => const [];
  @override
  Future<int> claimReward(int season) async => 0;
}

const _day = 86400000;

Future<(ProviderContainer, _Repo, SharedPreferences)> _open(WidgetTester tester,
    {String nickname = '', int xp = 0, List<SeasonLbEntry> rows = const []}) async {
  SharedPreferences.setMockInitialValues({if (nickname.isNotEmpty) 'leaderboard_nickname': nickname});
  final prefs = await SharedPreferences.getInstance();
  final now = 56 * _day;
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..seasonId = seasonIdFor(now)
        ..seasonXp = xp,
      nowMillis: now);
  final repo = _Repo()..rows = rows;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now + 1000),
    seasonLbRepositoryProvider.overrideWithValue(repo),
  ]);
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SeasonLeaderboardPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo, prefs);
}

void main() {
  test('trần XP và công thức id mùa khớp SQL', () {
    final sql = File('supabase/season_leaderboard_schema.sql').readAsStringSync();
    expect(sql, contains('xp between 0 and ${seasonLengthDays * seasonXpDailyCap}'));
    expect(sql, contains('/ 86400)::integer) / $seasonLengthDays'));
  });

  testWidgets('có biệt danh + XP: nộp lên server rồi hiện danh sách', (tester) async {
    final (c, repo, _) = await _open(tester,
        nickname: 'Tôi', xp: 500, rows: const [SeasonLbEntry('u1', 'Bạn A', 900, 1), SeasonLbEntry('me', 'Tôi', 500, 2)]);
    expect(repo.submits.single.$1, 'Tôi');
    expect(repo.submits.single.$3, 500);
    expect(repo.submits.single.$2, seasonIdFor(56 * _day));
    expect(find.byKey(const Key('season-lb-row-u1')), findsOneWidget);
    expect(find.text('900 XP'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chưa có biệt danh mà có XP: hiện form tên, nhập xong thì nộp', (tester) async {
    final (c, repo, prefs) = await _open(tester, xp: 300);
    expect(find.byKey(const Key('season-lb-name')), findsOneWidget);
    repo.rows = const [SeasonLbEntry('me', 'Tôi', 300, 1)];
    await tester.enterText(find.byKey(const Key('season-lb-name')), 'Tôi');
    await tester.tap(find.byKey(const Key('season-lb-submit')));
    await tester.pumpAndSettle();
    expect(prefs.getString('leaderboard_nickname'), 'Tôi');
    expect(repo.submits.single.$3, 300);
    expect(find.byKey(const Key('season-lb-row-me')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chưa có XP: không nộp, không đòi tên', (tester) async {
    final (c, repo, _) = await _open(tester);
    expect(repo.submits, isEmpty);
    expect(find.byKey(const Key('season-lb-name')), findsNothing);
    expect(find.byKey(const Key('season-lb-empty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
