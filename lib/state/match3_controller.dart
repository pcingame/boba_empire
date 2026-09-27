/// Trạng thái một lượt chơi màn Ghép 3. Thuần cục bộ — KHÔNG gọi mạng, khác
/// hẳn `ArenaController` (PvP có server chấm điểm).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../arena/match3_rules.dart';
import '../core/balance.dart';
import '../core/match3_levels.dart';

class Match3PlayState {
  const Match3PlayState({
    required this.level,
    required this.cells,
    required this.movesLeft,
    required this.score,
    this.collected = 0,
    this.frames = const [],
    this.moveId = 0,
    this.adContinueUsed = false,
  });

  final Match3Level level;
  final List<int> cells;
  final int movesLeft;
  final int score;

  /// Số ô loại cần thu thập đã xoá được (chỉ dùng ở màn [Match3GoalKind.collect]).
  final int collected;

  /// Tiến độ tính theo mục tiêu của màn — điểm, hoặc số ô đã thu thập.
  int get progress =>
      level.goal == Match3GoalKind.collect ? collected : score;
  final List<List<int>> frames;
  final int moveId;

  /// Đã dùng lượt "xem QC thêm nước" của lượt chơi này chưa (1 lần/lượt).
  final bool adContinueUsed;

  int get stars => match3Stars(progress, level.target);

  /// Đã đạt mục tiêu (1 sao) — màn coi như qua, kể cả khi còn nước.
  bool get goalReached => progress >= level.target;

  /// Hết nước → khoá bàn. KHÔNG khoá khi vừa đạt mục tiêu: người chơi có thể
  /// chọn "Chơi nốt" để dùng nốt số nước còn lại săn 2-3 sao.
  bool get finished => movesLeft <= 0;
}

class Match3Controller extends Notifier<Match3PlayState> {
  Match3Board? _board;

  @override
  Match3PlayState build() => _start(const Match3Level(1));

  /// Bắt đầu (hoặc chơi lại) một màn.
  void load(Match3Level level) => state = _start(level);

  /// Cộng nước sau khi xem quảng cáo thưởng. Chỉ có tác dụng một lần mỗi lượt
  /// chơi (xem [Balance.m3AdExtraMoves]).
  void addMovesFromAd() {
    if (state.adContinueUsed) return;
    state = Match3PlayState(
      level: state.level,
      cells: state.cells,
      movesLeft: state.movesLeft + Balance.m3AdExtraMoves,
      score: state.score,
      collected: state.collected,
      moveId: state.moveId,
      adContinueUsed: true,
    );
  }

  Match3PlayState _start(Match3Level level) {
    final board = Match3Board.initial(level.seq());
    // Bàn đầu có thể bí ngay (hiếm) — xáo cho tới khi đi được.
    if (!board.hasAnyMove()) board.reshuffle();
    _board = board;
    return Match3PlayState(
      level: level,
      cells: [...board.cells],
      movesLeft: level.moves,
      score: 0,
    );
  }

  /// Số ô thuộc loại cần thu thập mà nước này xoá được (0 ở màn tính điểm).
  int _collectedBy(Match3Move move) {
    if (state.level.goal != Match3GoalKind.collect) return 0;
    final type = state.level.collectType;
    return type < move.cleared.length ? move.cleared[type] : 0;
  }

  /// Trả true nếu nước hợp lệ (bàn cờ chỉ phát hoạt ảnh khi true).
  bool swap(int cell, int dir) {
    final board = _board;
    if (board == null || state.finished) return false;
    final move = board.trySwap(cell, dir);
    if (!move.valid) return false;
    // Hết nước đi hợp lệ thì xáo lại — chơi đơn không có server nên xáo thoải
    // mái (xem ghi chú trong Match3Board.reshuffle).
    if (!board.hasAnyMove()) board.reshuffle();
    state = Match3PlayState(
      level: state.level,
      cells: [...board.cells],
      movesLeft: state.movesLeft - 1,
      score: state.score + move.score,
      collected: state.collected + _collectedBy(move),
      frames: move.frames,
      moveId: state.moveId + 1,
      // PHẢI mang theo: quên là cờ reset sau mỗi nước đi -> xem quảng cáo
      // thêm nước được vô hạn.
      adContinueUsed: state.adContinueUsed,
    );
    return true;
  }
}

final match3ControllerProvider =
    NotifierProvider.autoDispose<Match3Controller, Match3PlayState>(
  Match3Controller.new,
);
