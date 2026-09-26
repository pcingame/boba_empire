/// Luật dạng "Ghép 3" của Đấu Trường — HÀM THUẦN, phải khớp bit-for-bit với
/// `arena_m3_replay` trong `supabase/arena_schema.sql`. Đổi kích thước bảng, số
/// loại, thứ tự rơi/bù hay bảng điểm thì đổi CẢ HAI nơi (và vector vàng trong
/// `test/arena/match3_rules_test.dart`).
///
/// Bảng 8x8, ô = `r * 8 + c` (hàng 0 ở trên). Hành động `swap(cell, dir)` đổi ô
/// với hàng xóm phải (dir 0) hoặc phía dưới (dir 1); chỉ có hiệu lực nếu tạo ra
/// dãy >= 3 cùng loại.
library;

import 'arena_rules.dart';

const int m3Size = 8;
const int m3Cells = m3Size * m3Size;
const int m3Types = 5;

/// Điểm mỗi ô xoá ở bước dây chuyền 1; bước n nhân n.
const int m3TilePoints = 10;

/// Trần số nước tính điểm cho mỗi người (khớp trần ở `arena_submit_action`).
const int m3MaxMoves = 150;

/// Độ dài chuỗi ngẫu nhiên chung của một trận (khớp `arena_join_queue`).
const int m3SeqLength = 2000;

const int _empty = -1;

class Match3Move {
  const Match3Move({required this.valid, required this.score, required this.frames});

  static const Match3Move invalid = Match3Move(valid: false, score: 0, frames: []);

  final bool valid;
  final int score;

  /// Các bảng trung gian để UI phát hoạt ảnh: sau khi đổi, rồi với mỗi bước dây
  /// chuyền — sau khi xoá (ô trống = -1) và sau khi rơi + bù. Bảng cuối = kết quả.
  final List<List<int>> frames;
}

class Match3Board {
  Match3Board._(this.cells, this._seq, this._refill);

  /// Bảng đầu từ chuỗi chung [seq]: 64 ô đầu theo thứ tự chỉ số; ô nào tạo bộ 3
  /// sẵn (2 ô trái hoặc 2 ô trên cùng loại) thì tăng loại +1 (mod 5) tới khi hết
  /// trùng. Luồng bù ô bắt đầu ở seq[64].
  factory Match3Board.initial(List<int> seq) {
    final cells = List<int>.filled(m3Cells, 0);
    if (seq.isNotEmpty) {
      for (var i = 0; i < m3Cells; i++) {
        final r = i ~/ m3Size, c = i % m3Size;
        var t = seq[i % seq.length] % m3Types;
        while ((c >= 2 && cells[i - 1] == t && cells[i - 2] == t) ||
            (r >= 2 && cells[i - m3Size] == t && cells[i - 2 * m3Size] == t)) {
          t = (t + 1) % m3Types;
        }
        cells[i] = t;
      }
    }
    return Match3Board._(cells, seq, m3Cells);
  }

  /// Bảng từ danh sách ô có sẵn — CHỈ để dò nước hợp lệ ([findMove]/[isValidMove]).
  /// Không có luồng bù nên [trySwap] luôn trả vô hiệu: bù bằng giá trị giả sẽ làm
  /// dây chuyền lặp vô hạn.
  factory Match3Board.fromCells(List<int> cells) =>
      Match3Board._([...cells], const [], m3Cells);

  final List<int> cells;
  final List<int> _seq;
  int _refill;

  Match3Board copy() => Match3Board._([...cells], _seq, _refill);

  int _next() {
    final v = _seq[_refill % _seq.length] % m3Types;
    _refill++;
    return v;
  }

  /// Ô liền kề theo [dir] hoặc null nếu ra ngoài bảng.
  static int? neighbor(int cell, int dir) {
    if (cell < 0 || cell >= m3Cells) return null;
    final r = cell ~/ m3Size, c = cell % m3Size;
    if (dir == 0) return c == m3Size - 1 ? null : cell + 1;
    if (dir == 1) return r == m3Size - 1 ? null : cell + m3Size;
    return null;
  }

  /// Ô nằm trong dãy ngang/dọc >= 3 cùng loại.
  List<bool> _findMatches() {
    final marked = List<bool>.filled(m3Cells, false);
    for (var r = 0; r < m3Size; r++) {
      var start = 0;
      for (var c = 1; c <= m3Size; c++) {
        final same = c < m3Size &&
            cells[r * m3Size + c] != _empty &&
            cells[r * m3Size + c] == cells[r * m3Size + start];
        if (same) continue;
        if (c - start >= 3 && cells[r * m3Size + start] != _empty) {
          for (var k = start; k < c; k++) {
            marked[r * m3Size + k] = true;
          }
        }
        start = c;
      }
    }
    for (var c = 0; c < m3Size; c++) {
      var start = 0;
      for (var r = 1; r <= m3Size; r++) {
        final same = r < m3Size &&
            cells[r * m3Size + c] != _empty &&
            cells[r * m3Size + c] == cells[start * m3Size + c];
        if (same) continue;
        if (r - start >= 3 && cells[start * m3Size + c] != _empty) {
          for (var k = start; k < r; k++) {
            marked[k * m3Size + c] = true;
          }
        }
        start = r;
      }
    }
    return marked;
  }

  /// Nước đổi [cell] theo [dir] có tạo dãy >= 3 không (không đổi bảng, không
  /// giải quyết dây chuyền) — tương đương `trySwap(...).valid` nhưng rẻ hơn.
  bool isValidMove(int cell, int dir) {
    final other = neighbor(cell, dir);
    if (other == null || cells[cell] == cells[other]) return false;
    final a = cells[cell], b = cells[other];
    cells[cell] = b;
    cells[other] = a;
    final ok = _findMatches().contains(true);
    cells[cell] = a;
    cells[other] = b;
    return ok;
  }

  /// Đổi rồi giải quyết dây chuyền. Nước sai (ngoài bảng, hai ô cùng loại, hoặc
  /// không tạo match) trả [Match3Move.invalid] và KHÔNG đổi bảng / luồng bù.
  Match3Move trySwap(int cell, int dir) {
    if (_seq.isEmpty) return Match3Move.invalid;
    final other = neighbor(cell, dir);
    if (other == null) return Match3Move.invalid;
    if (cells[cell] == cells[other]) return Match3Move.invalid;
    final saved = [...cells];
    cells[cell] = saved[other];
    cells[other] = saved[cell];
    if (!_findMatches().contains(true)) {
      cells.setAll(0, saved);
      return Match3Move.invalid;
    }
    final frames = <List<int>>[[...cells]];
    var score = 0;
    for (var step = 1;; step++) {
      final marked = _findMatches();
      final count = marked.where((m) => m).length;
      if (count == 0) break;
      score += count * m3TilePoints * step;
      for (var i = 0; i < m3Cells; i++) {
        if (marked[i]) cells[i] = _empty;
      }
      frames.add([...cells]);
      _gravityAndRefill();
      frames.add([...cells]);
    }
    return Match3Move(valid: true, score: score, frames: frames);
  }

  void _gravityAndRefill() {
    final emptyPerCol = List<int>.filled(m3Size, 0);
    for (var c = 0; c < m3Size; c++) {
      var write = m3Size - 1;
      for (var r = m3Size - 1; r >= 0; r--) {
        final v = cells[r * m3Size + c];
        if (v != _empty) {
          cells[write * m3Size + c] = v;
          write--;
        }
      }
      emptyPerCol[c] = write + 1;
      for (var r = 0; r <= write; r++) {
        cells[r * m3Size + c] = _empty;
      }
    }
    for (var c = 0; c < m3Size; c++) {
      for (var r = 0; r < emptyPerCol[c]; r++) {
        cells[r * m3Size + c] = _next();
      }
    }
  }

  /// Nước hợp lệ đầu tiên (theo thứ tự ô, rồi hướng) hoặc null nếu hết nước.
  (int cell, int dir)? findMove() {
    for (var cell = 0; cell < m3Cells; cell++) {
      for (var dir = 0; dir < 2; dir++) {
        if (isValidMove(cell, dir)) return (cell, dir);
      }
    }
    return null;
  }

  /// Còn nước đi hợp lệ nào không (để báo hết nước).
  bool hasAnyMove() => findMove() != null;
}

/// Điểm của MỘT người chơi sau khi replay các `swap` (thứ tự `at`, rồi `id`),
/// tối đa [m3MaxMoves] nước đầu. Nước vô hiệu bị bỏ qua. Log rỗng, hành động
/// khác `swap` hoặc chuỗi rỗng đều không gây lỗi.
int match3ComputeScore(List<int> seq, List<ArenaAction> actions) {
  if (seq.isEmpty) return 0;
  final swaps = actions.where((a) => a.kind == ArenaActionKind.swap).toList()
    ..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  final board = Match3Board.initial(seq);
  var score = 0;
  for (var n = 0; n < swaps.length && n < m3MaxMoves; n++) {
    score += board.trySwap(swaps[n].cell ?? -1, swaps[n].dir ?? -1).score;
  }
  return score;
}
