// Thưởng cuối mùa BXH Thẻ Mùa: thẻ trên trang Thẻ Mùa, nhận (server trước, 💎 sau), lỗi, top 3 → Quán quân; hằng số khớp SQL.
import 'dart:io';

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/season.dart';
import 'package:boba_empire/core/titles.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/season_leaderboard.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/season_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements SeasonLbRepository {
  _Repo(this.rewards);
  List<SeasonEndReward> rewards;
  Object? claimError;
  final claimed = <int>[];
  @override
  Future<List<SeasonEndReward>> rewardStatus() async => [
        for (final r in rewards) SeasonEndReward(r.season, r.rank, r.gems, r.claimed || claimed.contains(r.season))
      ];
  @override
  Future<int> claimReward(int season) async {
    if (claimError != null) throw claimError!;
    claimed.add(season);
    return rewards.firstWhere((r) => r.season == season).gems;
  }

  @override
  Future<void> submit(String n, int s, int xp) async {}
  @override
  Future<List<SeasonLbEntry>> top() async => const [];
  @override
  String? get myUserId => null;
}

const _day = 86400000;

Future<(ProviderContainer, _Repo, SharedPreferences)> _open(WidgetTester tester, List<SeasonEndReward> rewards) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final now = 56 * _day;
  await GameStorage(prefs).save(GameState.newGame(nowMillis: now)..seasonId = seasonIdFor(now), nowMillis: now);
  final repo = _Repo(rewards);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now + 1000),
    seasonLbRepositoryProvider.overrideWithValue(repo),
  ]);
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SeasonPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo, prefs);
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  test('💎 theo hạng khớp SQL', () {
    final sql = File('supabase/season_leaderboard_schema.sql').readAsStringSync();
    final body = RegExp(r'season_reward_gems\(p_rank integer\).*?\$\$;', dotAll: true).firstMatch(sql)!.group(0)!;
    final pairs = RegExp(r'when (\d+) then (\d+)').allMatches(body).map((m) => (int.parse(m.group(1)!), int.parse(m.group(2)!)));
    expect(pairs.toList(), [for (var r = 1; r <= 10; r++) (r, seasonRewardGemsFor(r))]);
    expect(seasonRewardGemsFor(0), 0);
    expect(seasonRewardGemsFor(11), 0);
  });

  test('danh hiệu Quán quân chỉ mở khi từng nhận thưởng top 3', () {
    const base = TitleStats(stage: 1, ascension: 0, prestigeStars: 0, vipLevel: 0, owned: 0);
    const champ = TitleStats(stage: 1, ascension: 0, prestigeStars: 0, vipLevel: 0, owned: 0, champion: true);
    final t = playerTitleById('champion')!;
    expect(t.unlocked(base), isFalse);
    expect(t.unlocked(champ), isTrue);
  });

  testWidgets('không có thưởng: không hiện thẻ', (tester) async {
    final (c, _, _) = await _open(tester, const []);
    expect(find.byKey(const Key('season-reward-claim')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('hạng 1: nhận 1000💎 (server trước), cộng 💎, nhớ Quán quân, nút thành "đã nhận"', (tester) async {
    final (c, repo, prefs) = await _open(tester, const [SeasonEndReward(1, 1, 1000, false)]);
    final g0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('season-reward-claim')));
    await tester.pumpAndSettle();
    expect(repo.claimed, [1]);
    expect(c.read(gameControllerProvider).gems, g0 + 1000);
    expect(prefs.getBool(seasonChampionPrefsKey), isTrue);
    expect(tester.widget<FilledButton>(find.byKey(const Key('season-reward-claim'))).onPressed, isNull);
    await _end(tester, c);
  });

  testWidgets('hạng 7: nhận 200💎 nhưng KHÔNG mở Quán quân', (tester) async {
    final (c, _, prefs) = await _open(tester, const [SeasonEndReward(1, 7, 200, false)]);
    await tester.tap(find.byKey(const Key('season-reward-claim')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(seasonChampionPrefsKey), isNull);
    await _end(tester, c);
  });

  testWidgets('lỗi server: báo lỗi, không cộng 💎, không nhớ Quán quân', (tester) async {
    final (c, repo, prefs) = await _open(tester, const [SeasonEndReward(1, 1, 1000, false)]);
    repo.claimError = Exception('network');
    final g0 = c.read(gameControllerProvider).gems;
    await tester.tap(find.byKey(const Key('season-reward-claim')));
    await tester.pumpAndSettle();
    expect(find.text('Không nhận được thưởng. Thử lại sau nhé.'), findsOneWidget);
    expect(c.read(gameControllerProvider).gems, g0);
    expect(prefs.getBool(seasonChampionPrefsKey), isNull);
    await _end(tester, c);
  });

  testWidgets('đã nhận từ trước: nút tắt', (tester) async {
    final (c, _, _) = await _open(tester, const [SeasonEndReward(1, 2, 600, true)]);
    expect(tester.widget<FilledButton>(find.byKey(const Key('season-reward-claim'))).onPressed, isNull);
    await _end(tester, c);
  });
}
