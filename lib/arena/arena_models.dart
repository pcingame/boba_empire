/// Model dữ liệu Đấu Trường — ánh xạ trực tiếp từ row Supabase (bảng
/// `arena_matches`/`arena_actions` trong `supabase/arena_schema.sql`).
library;

import 'arena_rules.dart';

enum ArenaMatchStatus { active, finished }

class ArenaMatch {
  const ArenaMatch({
    required this.id,
    required this.playerA,
    required this.playerB,
    required this.status,
    required this.endsAt,
    required this.scoreA,
    required this.scoreB,
    this.winner,
  });

  factory ArenaMatch.fromRow(Map<String, dynamic> row) => ArenaMatch(
        id: row['id'] as String,
        playerA: row['player_a'] as String,
        playerB: row['player_b'] as String,
        status: (row['status'] as String) == 'finished'
            ? ArenaMatchStatus.finished
            : ArenaMatchStatus.active,
        endsAt: DateTime.parse(row['ends_at'] as String),
        scoreA: (row['score_a'] as num).toDouble(),
        scoreB: (row['score_b'] as num).toDouble(),
        winner: row['winner'] as String?,
      );

  final String id;
  final String playerA;
  final String playerB;
  final ArenaMatchStatus status;
  final DateTime endsAt;
  final double scoreA;
  final double scoreB;
  final String? winner;
}

/// Kết quả 1 trận đã kết thúc, nhìn từ góc của người chơi hiện tại.
class ArenaResult {
  const ArenaResult({required this.myScore, required this.opponentScore, required this.won});

  final double myScore;
  final double opponentScore;
  final bool won;

  bool get isDraw => myScore == opponentScore;
}

/// Một dòng log kèm chủ nhân — log của cả trận (2 người chơi) đọc về gộp
/// chung, cần `playerId` để tách trước khi đưa vào [arenaComputeScore] (hàm
/// đó chỉ nhận log của MỘT người).
class ArenaLogEntry {
  const ArenaLogEntry({required this.playerId, required this.action});

  final String playerId;
  final ArenaAction action;
}

ArenaLogEntry arenaLogEntryFromRow(Map<String, dynamic> row) => ArenaLogEntry(
      playerId: row['player_id'] as String,
      action: ArenaAction(
        kind: ArenaActionKindJson.fromWire(row['kind'] as String),
        at: DateTime.parse(row['at'] as String),
        id: row['id'] as int,
      ),
    );
