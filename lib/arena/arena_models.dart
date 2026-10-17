/// Model dữ liệu Đấu Trường — ánh xạ trực tiếp từ row Supabase (bảng
/// `arena_matches`/`arena_actions` trong `supabase/arena_schema.sql`).
library;

import 'arena_rules.dart';

enum ArenaMatchStatus { active, finished }

/// Dạng PK — khớp cột `mode` ở `arena_matches`/`arena_queue`.
enum ArenaMode {
  tap('tap'),
  match3('match3'),
  recipe('recipe');

  const ArenaMode(this.wire);
  final String wire;

  static ArenaMode fromWire(String? v) =>
      switch (v) {
        'match3' => ArenaMode.match3,
        'recipe' => ArenaMode.recipe,
        _ => ArenaMode.tap,
      };
}

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
    this.mode = ArenaMode.tap,
    this.seq = const [],
    this.ghost = false,
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
        mode: ArenaMode.fromWire(row['mode'] as String?),
        ghost: row['ghost'] == true,
        seq: [
          for (final v in (row['seq'] as List<dynamic>? ?? const [])) (v as num).toInt(),
        ],
      );

  final String id;
  final String playerA;
  final String playerB;
  final ArenaMatchStatus status;
  final DateTime endsAt;
  final double scoreA;
  final double scoreB;
  final String? winner;
  final ArenaMode mode;

  /// Trận "bóng ma": đối thủ là bản ghi của một trận cũ (xem arena_join_queue).
  final bool ghost;

  /// Chuỗi ngẫu nhiên chung của trận: dạng match3 = loại ô; dạng recipe = id 5 món của 5 đơn.
  final List<int> seq;
}

/// Kết quả 1 trận đã kết thúc, nhìn từ góc của người chơi hiện tại.
class ArenaResult {
  const ArenaResult({required this.myScore, required this.opponentScore, required this.won, this.ghost = false});

  final double myScore;
  final double opponentScore;
  final bool won;

  /// Đối thủ là bóng ma (thưởng giảm, không vào bảng xếp hạng).
  final bool ghost;

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
        cell: (row['cell'] as num?)?.toInt(),
        dir: (row['dir'] as num?)?.toInt(),
        orderIndex: row['kind'] == 'serve' ? (row['cell'] as num?)?.toInt() : null,
        score: (row['score'] as num?)?.toInt(),
      ),
    );

/// Log hiển thị cho phía MÌNH: với trận bóng ma, hành động của đối thủ đã được server chép sẵn với mốc
/// thời gian tương lai nên chỉ hiện những hành động đã "xảy ra" ([at] <= [now]) — nếu không, điểm bóng ma
/// nhảy vọt đủ ngay từ giây đầu.
List<ArenaLogEntry> arenaVisibleLog(List<ArenaLogEntry> log, {required String me, required bool ghost, required DateTime now}) =>
    ghost ? [for (final e in log) if (e.playerId == me || !e.action.at.isAfter(now)) e] : log;
