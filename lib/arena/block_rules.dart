/// Luật dạng "Xếp khối" của Đấu Trường — HÀM THUẦN, phải khớp bit-for-bit với
/// `arena_compute_score_blocks` trong `supabase/arena_schema.sql`. Đổi bảng khối,
/// kích thước bảng hay bảng điểm thì đổi CẢ HAI nơi (và vector vàng trong
/// `test/arena/block_rules_test.dart`).
///
/// Không có trọng lực theo thời gian: mỗi lượt chọn (hướng xoay, cột) rồi thả —
/// khối rơi thẳng xuống điểm thấp nhất. Replay chỉ cần (rot, col) cho mỗi lần thả.
library;

import 'arena_rules.dart';

const int blockCols = 10;
const int blockRows = 20;
const int blockFullRow = (1 << blockCols) - 1;

/// Điểm theo số hàng xoá cùng lúc (0..4).
const List<int> blockLineScores = [0, 1, 3, 5, 8];

/// Số khối trong chuỗi chung của 1 trận (khớp `arena_join_queue`).
const int blockSeqLength = 300;

/// I, O, T, S, Z, J, L — ô (x, y), y hướng xuống, ở hướng xoay 0.
const List<List<(int, int)>> _baseShapes = [
  [(0, 0), (1, 0), (2, 0), (3, 0)],
  [(0, 0), (1, 0), (0, 1), (1, 1)],
  [(1, 0), (0, 1), (1, 1), (2, 1)],
  [(1, 0), (2, 0), (0, 1), (1, 1)],
  [(0, 0), (1, 0), (1, 1), (2, 1)],
  [(0, 0), (0, 1), (1, 1), (2, 1)],
  [(2, 0), (0, 1), (1, 1), (2, 1)],
];

/// Mỗi hướng xoay = danh sách mặt nạ bit theo từng hàng (bit x = cột x), từ
/// trên xuống. Xoay 90° theo chiều kim đồng hồ: (x, y) -> (-y, x), rồi dời về
/// góc (0, 0).
final List<List<List<int>>> blockOrientations = [
  for (final base in _baseShapes) _rotations(base),
];

List<List<int>> _rotations(List<(int, int)> base) {
  final out = <List<int>>[];
  var cells = base;
  for (var r = 0; r < 4; r++) {
    final minX = cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    final minY = cells.map((c) => c.$2).reduce((a, b) => a < b ? a : b);
    final maxY = cells.map((c) => c.$2).reduce((a, b) => a > b ? a : b);
    final rows = List<int>.filled(maxY - minY + 1, 0);
    for (final (x, y) in cells) {
      rows[y - minY] |= 1 << (x - minX);
    }
    out.add(rows);
    cells = [for (final (x, y) in cells) (-y, x)];
  }
  return out;
}

/// Bề ngang (số cột) của mặt nạ hàng.
int blockWidth(List<int> rows) {
  var mask = 0;
  for (final r in rows) {
    mask |= r;
  }
  return mask.bitLength;
}

class BlockDropResult {
  const BlockDropResult({required this.lines, required this.overflow});

  /// Số hàng xoá được (0..4).
  final int lines;

  /// Khối không đặt được vì chạm đỉnh — bảng coi như đã tràn.
  final bool overflow;

  int get score => blockLineScores[lines];
}

class BlockBoard {
  BlockBoard() : rows = List<int>.generate(blockRows, (_) => 0);

  /// Mặt nạ bit theo hàng, hàng 0 ở trên cùng.
  final List<int> rows;

  bool overflowed = false;

  bool _fits(List<int> shape, int col, int top) {
    if (top + shape.length > blockRows) return false;
    for (var i = 0; i < shape.length; i++) {
      if (rows[top + i] & (shape[i] << col) != 0) return false;
    }
    return true;
  }

  /// Cột hợp lệ cho hướng [rot] của khối [piece]: 0..blockCols - bề ngang.
  static int maxCol(int piece, int rot) =>
      blockCols - blockWidth(blockOrientations[piece][rot]);

  /// Hàng trên cùng mà khối sẽ nằm khi thả ở [col], hoặc null nếu không đặt
  /// được (cột ngoài biên hoặc chạm đỉnh). Không đổi bảng.
  int? dropTop(int piece, int rot, int col) {
    final shape = blockOrientations[piece][rot];
    if (col < 0 || col > maxCol(piece, rot)) return null;
    if (!_fits(shape, col, 0)) return null;
    var top = 0;
    while (_fits(shape, col, top + 1)) {
      top++;
    }
    return top;
  }

  /// Thả khối và xoá hàng đầy. Cột sai bị bỏ qua (lines 0, không tràn); chạm
  /// đỉnh thì đánh dấu [overflowed] và không đổi bảng.
  BlockDropResult drop(int piece, int rot, int col) {
    if (piece < 0 || piece >= blockOrientations.length) {
      return const BlockDropResult(lines: 0, overflow: false);
    }
    if (rot < 0 || rot > 3) return const BlockDropResult(lines: 0, overflow: false);
    final shape = blockOrientations[piece][rot];
    if (col < 0 || col > maxCol(piece, rot)) {
      return const BlockDropResult(lines: 0, overflow: false);
    }
    final top = dropTop(piece, rot, col);
    if (top == null) {
      overflowed = true;
      return const BlockDropResult(lines: 0, overflow: true);
    }
    for (var i = 0; i < shape.length; i++) {
      rows[top + i] |= shape[i] << col;
    }
    var cleared = 0;
    for (var r = blockRows - 1; r >= 0;) {
      if (rows[r] == blockFullRow) {
        rows.removeAt(r);
        rows.insert(0, 0);
        cleared++;
      } else {
        r--;
      }
    }
    return BlockDropResult(lines: cleared, overflow: false);
  }
}

/// Điểm của MỘT người chơi sau khi replay các lần thả (thứ tự `at`, rồi `id`).
/// Lần thả thứ n dùng khối `seq[n]`. Sau khi tràn hoặc hết chuỗi, các lần thả
/// còn lại bị bỏ qua. Log rỗng / hành động không phải `drop` không gây lỗi.
int blockComputeScore(List<int> seq, List<ArenaAction> actions) {
  final drops = actions.where((a) => a.kind == ArenaActionKind.drop).toList()
    ..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  final board = BlockBoard();
  var score = 0;
  for (var n = 0; n < drops.length && n < seq.length; n++) {
    if (board.overflowed) break;
    final d = drops[n];
    score += board.drop(seq[n], d.rot ?? -1, d.col ?? -1).score;
  }
  return score;
}
