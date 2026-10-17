import 'package:boba_empire/arena/arena_controller.dart';
import 'package:boba_empire/arena/arena_models.dart';
import 'package:boba_empire/arena/arena_rules.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaLogEntry _e(String p, DateTime at, int id) =>
    ArenaLogEntry(playerId: p, action: ArenaAction(kind: ArenaActionKind.tap, at: at, id: id));

void main() {
  final now = DateTime.utc(2026, 10, 18, 12);
  final log = [
    _e('me', now.add(const Duration(seconds: 5)), 1), // của mình luôn hiện (kể cả lệch đồng hồ)
    _e('ghost', now.subtract(const Duration(seconds: 3)), 2),
    _e('ghost', now, 3), // đúng lúc này: đã xảy ra
    _e('ghost', now.add(const Duration(seconds: 1)), 4), // chưa xảy ra
  ];

  test('bóng ma: chỉ hiện hành động đối thủ đã xảy ra; trận thật: giữ nguyên', () {
    final ghost = arenaVisibleLog(log, me: 'me', ghost: true, now: now);
    expect(ghost.map((e) => e.action.id), [1, 2, 3]);
    expect(arenaVisibleLog(log, me: 'me', ghost: false, now: now).length, 4);
  });

  test('điểm bóng ma tăng dần theo thời gian, không nhảy vọt ngay giây đầu', () {
    double theirs(DateTime t) => arenaComputeScore([
          for (final e in arenaVisibleLog(log, me: 'me', ghost: true, now: t))
            if (e.playerId == 'ghost') e.action
        ]);
    expect(theirs(now.subtract(const Duration(seconds: 10))), 0);
    expect(theirs(now.subtract(const Duration(seconds: 2))), 1);
    expect(theirs(now.add(const Duration(seconds: 2))), 3);
  });

  test('thưởng: bóng ma thấp hơn trận thật, thua bóng ma = 0', () {
    ArenaResult r(bool won, bool ghost) => ArenaResult(myScore: 1, opponentScore: 0, won: won, ghost: ghost);
    expect(arenaRewardGems(r(true, false)), 3);
    expect(arenaRewardGems(r(false, false)), 1);
    expect(arenaRewardGems(r(true, true)), 1);
    expect(arenaRewardGems(r(false, true)), 0);
  });

  test('ArenaMatch.fromRow đọc cờ ghost (thiếu = false, server cũ vẫn chạy)', () {
    Map<String, dynamic> row([Object? ghost]) => {
          'id': 'm', 'player_a': 'a', 'player_b': 'b', 'status': 'active',
          'ends_at': '2026-10-18T12:01:00Z', 'score_a': 0, 'score_b': 0,
          'ghost': ?ghost,
        };
    expect(ArenaMatch.fromRow(row()).ghost, isFalse);
    expect(ArenaMatch.fromRow(row(true)).ghost, isTrue);
    expect(ArenaMatch.fromRow(row('x')).ghost, isFalse);
  });
}
