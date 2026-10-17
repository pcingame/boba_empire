// Thưởng top BXH tuần: hằng số khớp SQL, đọc JSON, nhận thưởng (server xác nhận rồi mới cộng 💎),
// chống bấm đúp, giới hạn tần suất tải, lỗi được nuốt, chưa liên kết thì không gọi server.
import 'dart:io';

import 'package:boba_empire/core/lb_rewards.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/data/linked_session.dart';
import 'package:boba_empire/leaderboard/lb_rewards.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRepo implements LbRewardRepository {
  List<LbReward> rewards = [];
  Object? statusError;
  Object? claimError;
  int statusCalls = 0;
  final claimed = <String>[];
  int claimDelayMs = 0;

  @override
  Future<List<LbReward>> status() async {
    statusCalls++;
    if (statusError != null) throw statusError!;
    return [
      for (final r in rewards)
        LbReward(week: r.week, board: r.board, rank: r.rank, gems: r.gems, claimed: r.claimed || claimed.contains(r.id)),
    ];
  }

  @override
  Future<int> claim(LbReward r) async {
    if (claimDelayMs > 0) await Future<void>.delayed(Duration(milliseconds: claimDelayMs));
    if (claimError != null) throw claimError!;
    claimed.add(r.id);
    return r.gems;
  }
}

LbReward _r(LbBoard b, int rank, {String week = '2026-10-12', bool claimed = false}) =>
    LbReward(week: week, board: b, rank: rank, gems: lbRewardGemsFor(rank), claimed: claimed);

Future<(ProviderContainer, _FakeRepo, void Function(int))> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  final repo = _FakeRepo();
  var now = 1000;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
    lbRewardRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return (c, repo, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hằng số khớp SQL', () {
    final sql = File('supabase/leaderboard_rewards_schema.sql').readAsStringSync();
    test('💎 theo hạng 300/200/100', () {
      expect(lbRewardGemsByRank, [300, 200, 100]);
      expect(sql, contains('when 1 then 300 when 2 then 200 when 3 then 100 else 0'));
      expect(lbRewardGemsFor(0), 0);
      expect(lbRewardGemsFor(4), 0);
    });
    test('Thử thách ngày: top 10, hạng 4-10 nhận 50💎 — Dart khớp SQL', () {
      final m = RegExp(r"when p_board = 'daily' and p_rank between 4 and (\d+) then (\d+)").firstMatch(sql)!;
      expect(int.parse(m.group(1)!), lbRewardDailyMaxRank);
      expect(int.parse(m.group(2)!), lbRewardGemsDailyRest);
      expect(sql, contains('check (rank between 1 and $lbRewardDailyMaxRank)'));
      expect([for (var r = 1; r <= 11; r++) lbRewardGemsForBoard(LbBoard.daily, r)], [300, 200, 100, ...List.filled(7, 50), 0]);
      expect([for (var r = 1; r <= 11; r++) lbRewardGemsForBoard(LbBoard.arena, r)], [300, 200, 100, ...List.filled(7, 50), 0]);
      expect(sql, contains("p_board = 'arena' and p_rank between 4 and $lbRewardDailyMaxRank then $lbRewardGemsDailyRest"));
      // Bảng khác vẫn chỉ top 3.
      expect([for (var r = 1; r <= 5; r++) lbRewardGemsForBoard(LbBoard.income, r)], [300, 200, 100, 0, 0]);
    });
    test('số tuần còn nhận được', () {
      expect(sql, contains('select $lbRewardValidWeeks \$\$'));
    });
    test('mã bảng khớp CHECK của bảng chụp + 4 bảng', () {
      final check = RegExp(r"board in \(([^)]*)\)").firstMatch(sql)!.group(1)!;
      final boards = RegExp(r"'(\w+)'").allMatches(check).map((m) => m.group(1)).toSet();
      expect(boards, {for (final b in LbBoard.values) b.name});
    });
    test('RPC được cấp quyền authenticated và khoá anon; hàm chụp khoá hẳn', () {
      expect(sql, contains('grant execute on function lb_reward_status() to authenticated'));
      expect(sql, contains('grant execute on function lb_reward_claim(date, text) to authenticated'));
      expect(sql, contains('revoke all on function lb_reward_snapshot() from public, anon, authenticated'));
    });
  });

  group('đọc JSON', () {
    test('bỏ dòng hỏng/bảng lạ, giữ dòng đúng', () {
      final out = parseLbRewards([
        {'week': '2026-10-12', 'board': 'income', 'rank': 1, 'gems': 300, 'claimed': false},
        {'week': '2026-10-12', 'board': 'bang_moi', 'rank': 1, 'gems': 300, 'claimed': false},
        {'week': 5, 'board': 'vip', 'rank': 1, 'gems': 300},
        {'week': '2026-10-12', 'board': 'pearls', 'rank': 'x', 'gems': 100},
        'rac',
        {'week': '2026-10-05', 'board': 'collection', 'rank': 3, 'gems': 100, 'claimed': true},
      ]);
      expect(out.map((r) => r.id), ['2026-10-12/income', '2026-10-05/collection']);
      expect(out[1].claimed, isTrue);
    });
    test('không phải danh sách → rỗng', () {
      expect(parseLbRewards(null), isEmpty);
      expect(parseLbRewards({'a': 1}), isEmpty);
    });
    test('thông điệp lỗi server được dịch', () {
      expect(lbRewardFailureFromMessage('already claimed'), LbRewardFailure.alreadyClaimed);
      expect(lbRewardFailureFromMessage('not found'), LbRewardFailure.notFound);
      expect(lbRewardFailureFromMessage('timeout'), LbRewardFailure.network);
    });
  });

  group('repository', () {
    test('chưa liên kết → không gọi server', () async {
      var called = 0;
      final repo = LbRewardRepository((fn, p) async {
        called++;
        return [];
      }, () => null);
      await expectLater(repo.status(), throwsA(isA<NotLinkedException>()));
      await expectLater(repo.claim(_r(LbBoard.income, 1)),
          throwsA(isA<LbRewardException>().having((e) => e.failure, 'failure', LbRewardFailure.notLinked)));
      expect(called, 0);
    });
  });

  group('controller', () {
    test('refresh nạp thưởng; claimable chỉ đếm cái chưa nhận; chấm đỏ theo đó', () async {
      final (c, repo, _) = await _setup();
      repo.rewards = [_r(LbBoard.income, 1), _r(LbBoard.vip, 2, claimed: true)];
      expect(c.read(lbRewardAlertProvider), isFalse);
      await c.read(lbRewardsControllerProvider.notifier).refresh();
      expect(c.read(lbRewardsControllerProvider).loaded, isTrue);
      expect(c.read(lbRewardsControllerProvider).claimable.length, 1);
      expect(c.read(lbRewardAlertProvider), isTrue);
    });

    test('tải thường bị giới hạn 10 phút; force thì bỏ qua', () async {
      final (c, repo, setNow) = await _setup();
      final ctrl = c.read(lbRewardsControllerProvider.notifier);
      await ctrl.refresh();
      await ctrl.refresh();
      expect(repo.statusCalls, 1);
      setNow(1000 + 9 * 60 * 1000);
      await ctrl.refresh();
      expect(repo.statusCalls, 1);
      setNow(1000 + 10 * 60 * 1000 + 1);
      await ctrl.refresh();
      expect(repo.statusCalls, 2);
      await ctrl.refresh(force: true);
      expect(repo.statusCalls, 3);
    });

    test('lỗi mạng/server chưa có SQL bị nuốt, trạng thái cũ giữ nguyên', () async {
      final (c, repo, _) = await _setup();
      repo.rewards = [_r(LbBoard.income, 1)];
      await c.read(lbRewardsControllerProvider.notifier).refresh(force: true);
      repo.statusError = PostgrestException(message: 'function does not exist');
      await c.read(lbRewardsControllerProvider.notifier).refresh(force: true);
      expect(c.read(lbRewardsControllerProvider).rewards.length, 1);
    });

    test('chưa liên kết → trạng thái rỗng đã tải, không văng', () async {
      final (c, repo, _) = await _setup();
      repo.statusError = const NotLinkedException();
      await c.read(lbRewardsControllerProvider.notifier).refresh(force: true);
      expect(c.read(lbRewardsControllerProvider).loaded, isTrue);
      expect(c.read(lbRewardsControllerProvider).rewards, isEmpty);
    });

    test('nhận thưởng: server xác nhận RỒI mới cộng 💎; chấm đỏ tắt', () async {
      final (c, repo, _) = await _setup();
      repo.rewards = [_r(LbBoard.income, 1)];
      final ctrl = c.read(lbRewardsControllerProvider.notifier);
      await ctrl.refresh(force: true);
      final g0 = c.read(gameControllerProvider).gems;
      final got = await ctrl.claim(c.read(lbRewardsControllerProvider).rewards.single);
      expect(got, 300);
      expect(c.read(gameControllerProvider).gems, g0 + 300);
      expect(c.read(lbRewardAlertProvider), isFalse);
    });

    test('server từ chối → KHÔNG cộng 💎, lỗi được ném', () async {
      final (c, repo, _) = await _setup();
      repo.rewards = [_r(LbBoard.income, 1)];
      repo.claimError = const LbRewardException(LbRewardFailure.alreadyClaimed);
      final ctrl = c.read(lbRewardsControllerProvider.notifier);
      await ctrl.refresh(force: true);
      final g0 = c.read(gameControllerProvider).gems;
      await expectLater(ctrl.claim(c.read(lbRewardsControllerProvider).rewards.single), throwsA(isA<LbRewardException>()));
      expect(c.read(gameControllerProvider).gems, g0);
    });

    test('bấm đúp: chỉ một lần nhận, 💎 không cộng hai lần', () async {
      final (c, repo, _) = await _setup();
      repo.rewards = [_r(LbBoard.income, 1)];
      repo.claimDelayMs = 30;
      final ctrl = c.read(lbRewardsControllerProvider.notifier);
      await ctrl.refresh(force: true);
      final reward = c.read(lbRewardsControllerProvider).rewards.single;
      final g0 = c.read(gameControllerProvider).gems;
      final results = await Future.wait([ctrl.claim(reward), ctrl.claim(reward)]);
      expect(results..sort(), [0, 300]);
      expect(c.read(gameControllerProvider).gems, g0 + 300);
      expect(repo.claimed.length, 1);
    });
  });
}
