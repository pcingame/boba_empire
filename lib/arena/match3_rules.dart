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

/// Trần số bước dây chuyền của MỘT nước đi — lưới an toàn chống treo, xem ghi
/// chú trong [Match3Board.trySwap].
const int m3MaxCascadeSteps = 200;

const int _empty = -1;

/// Ô đặc biệt được mã hoá NGAY TRONG mảng ô (vẫn là `List<int>`) để hoạt ảnh,
/// frame và bàn cờ không phải đổi kiểu dữ liệu:
///   0..4                      ô thường
///   m3CrossBase + loại        bom chéo (ghép 4) — xoá cả hàng và cột
///   m3ColorBase + loại        bom màu (ghép `>=5`) — xoá mọi ô cùng loại
///
/// CHỈ chơi đơn sinh ra các giá trị này (xem cờ `specials` của
/// [Match3Board.initial]). Đấu Trường không bật nên bàn PvP luôn chỉ có 0..4,
/// đúng y như `arena_m3_replay` trong SQL.
const int m3CrossBase = 100;
const int m3ColorBase = 200;

/// Loại ô cơ bản (0..4) của một giá trị ô, kể cả ô đặc biệt.
int m3BaseType(int v) {
  if (v >= m3ColorBase) return v - m3ColorBase;
  if (v >= m3CrossBase) return v - m3CrossBase;
  return v;
}

bool m3IsSpecial(int v) => v >= m3CrossBase;

class Match3Move {
  const Match3Move({
    required this.valid,
    required this.score,
    required this.frames,
    this.cleared = const [],
  });

  static const Match3Move invalid =
      Match3Move(valid: false, score: 0, frames: []);

  final bool valid;
  final int score;

  /// Số ô đã xoá theo từng loại (dài [m3Types]) — dùng cho mục tiêu "thu thập N
  /// ô loại X" ở chơi đơn. THÊM thông tin thôi: không đụng điểm/rơi/bù nên
  /// `arena_m3_replay` (SQL) không phải đổi gì.
  final List<int> cleared;

  /// Các bảng trung gian để UI phát hoạt ảnh: sau khi đổi, rồi với mỗi bước dây
  /// chuyền — sau khi xoá (ô trống = -1) và sau khi rơi + bù. Bảng cuối = kết quả.
  final List<List<int>> frames;
}

class Match3Board {
  Match3Board._(this.cells, this._seq, this._refill, this.specials);

  /// Bảng đầu từ chuỗi chung [seq]: 64 ô đầu theo thứ tự chỉ số; ô nào tạo bộ 3
  /// sẵn (2 ô trái hoặc 2 ô trên cùng loại) thì tăng loại +1 (mod 5) tới khi hết
  /// trùng. Luồng bù ô bắt đầu ở seq[64].
  /// [specials] bật kẹo đặc biệt (ghép 4/5) — CHỈ dùng cho chơi đơn. Để mặc
  /// định false thì mọi đường đi giống hệt trước, nên Đấu Trường và
  /// `arena_m3_replay` (SQL) không đổi gì (vector vàng trong test khoá điều này).
  factory Match3Board.initial(List<int> seq, {bool specials = false}) {
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
    return Match3Board._(cells, seq, m3Cells, specials);
  }

  /// Bảng từ danh sách ô có sẵn — CHỈ để dò nước hợp lệ ([findMove]/[isValidMove]).
  /// Không có luồng bù nên [trySwap] luôn trả vô hiệu: bù bằng giá trị giả sẽ làm
  /// dây chuyền lặp vô hạn.
  factory Match3Board.fromCells(List<int> cells) =>
      Match3Board._([...cells], const [], m3Cells, false);

  final List<int> cells;
  final List<int> _seq;

  /// Có sinh kẹo đặc biệt khi ghép >= 4 ô không.
  final bool specials;
  int _refill;

  Match3Board copy() =>
      Match3Board._([...cells], _seq, _refill, specials);

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

  /// Các dãy >= 3 ô cùng loại: ngang trước rồi dọc, mỗi dãy là danh sách chỉ
  /// số ô. [_findMatches] dựng thẳng từ đây nên hai bên không thể lệch nhau.
  List<List<int>> _findRuns() {
    final runs = <List<int>>[];
    for (var r = 0; r < m3Size; r++) {
      var start = 0;
      for (var c = 1; c <= m3Size; c++) {
        final same = c < m3Size &&
            cells[r * m3Size + c] != _empty &&
            m3BaseType(cells[r * m3Size + c]) ==
                m3BaseType(cells[r * m3Size + start]);
        if (same) continue;
        if (c - start >= 3 && cells[r * m3Size + start] != _empty) {
          runs.add([for (var k = start; k < c; k++) r * m3Size + k]);
        }
        start = c;
      }
    }
    for (var c = 0; c < m3Size; c++) {
      var start = 0;
      for (var r = 1; r <= m3Size; r++) {
        final same = r < m3Size &&
            cells[r * m3Size + c] != _empty &&
            m3BaseType(cells[r * m3Size + c]) ==
                m3BaseType(cells[start * m3Size + c]);
        if (same) continue;
        if (r - start >= 3 && cells[start * m3Size + c] != _empty) {
          runs.add([for (var k = start; k < r; k++) k * m3Size + c]);
        }
        start = r;
      }
    }
    return runs;
  }

  /// Ô nằm trong dãy ngang/dọc >= 3 cùng loại.
  List<bool> _findMatches() {
    final marked = List<bool>.filled(m3Cells, false);
    for (final run in _findRuns()) {
      for (final i in run) {
        marked[i] = true;
      }
    }
    return marked;
  }

  /// Ô đặc biệt NẰM TRONG vùng bị xoá thì nổ, kéo theo ô khác (và ô đặc biệt
  /// khác) — lặp tới khi không lan thêm được nữa.
  void _activateSpecials(List<bool> marked) {
    final done = <int>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (var i = 0; i < m3Cells; i++) {
        if (!marked[i] || done.contains(i)) continue;
        final v = cells[i];
        if (!m3IsSpecial(v)) continue;
        done.add(i);
        changed = true;
        if (v >= m3ColorBase) {
          final t = v - m3ColorBase; // bom màu: mọi ô cùng loại
          for (var k = 0; k < m3Cells; k++) {
            if (cells[k] != _empty && m3BaseType(cells[k]) == t) {
              marked[k] = true;
            }
          }
        } else {
          final r = i ~/ m3Size, c = i % m3Size; // bom chéo: cả hàng và cột
          for (var k = 0; k < m3Size; k++) {
            if (cells[r * m3Size + k] != _empty) marked[r * m3Size + k] = true;
            if (cells[k * m3Size + c] != _empty) marked[k * m3Size + c] = true;
          }
        }
      }
    }
  }

  /// Nước đổi [cell] theo [dir] có tạo dãy >= 3 không (không đổi bảng, không
  /// giải quyết dây chuyền) — tương đương `trySwap(...).valid` nhưng rẻ hơn.
  bool isValidMove(int cell, int dir) {
    final other = neighbor(cell, dir);
    if (other == null ||
        m3BaseType(cells[cell]) == m3BaseType(cells[other])) {
      return false; // cùng loại gốc thì đổi chỗ không đổi được dãy nào
    }
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
    if (m3BaseType(cells[cell]) == m3BaseType(cells[other])) {
      return Match3Move.invalid;
    }
    final saved = [...cells];
    cells[cell] = saved[other];
    cells[other] = saved[cell];
    if (!_findMatches().contains(true)) {
      cells.setAll(0, saved);
      return Match3Move.invalid;
    }
    final frames = <List<int>>[[...cells]];
    final cleared = List<int>.filled(m3Types, 0);
    var score = 0;
    // Ô người chơi vừa đổi tới — kẹo đặc biệt sinh ra ngay tại đó cho "đã tay";
    // các bước dây chuyền sau không có ô nào là "của người chơi" nữa.
    var swapA = cell, swapB = other;
    // Trần số bước dây chuyền — LƯỚI AN TOÀN, không phải luật chơi. Một chuỗi
    // bù ô suy biến (mọi ô bù cùng một loại) sẽ tạo dây chuyền vô tận và treo
    // app. Chuỗi thật do server sinh ngẫu nhiên nên không bao giờ chạm trần
    // này; `arena_m3_replay` (SQL) không có trần, nhưng treo app còn tệ hơn
    // lệch điểm ở một ca không thể xảy ra.
    for (var step = 1; step <= m3MaxCascadeSteps; step++) {
      final runs = _findRuns();
      if (runs.isEmpty) break;
      final marked = List<bool>.filled(m3Cells, false);
      for (final run in runs) {
        for (final i in run) {
          marked[i] = true;
        }
      }

      // Kẹo đặc biệt: ghép 4 -> bom chéo, ghép >= 5 -> bom màu. Ô được chọn
      // KHÔNG bị xoá, nó biến thành kẹo.
      final creations = <int, int>{};
      if (specials) {
        for (final run in runs) {
          if (run.length < 4) continue;
          final at = run.contains(swapA)
              ? swapA
              : (run.contains(swapB) ? swapB : run[run.length ~/ 2]);
          if (creations.containsKey(at)) continue;
          creations[at] = (run.length >= 5 ? m3ColorBase : m3CrossBase) +
              m3BaseType(cells[at]);
        }
        _activateSpecials(marked);
        for (final at in creations.keys) {
          marked[at] = false; // kẹo vừa sinh thì ở lại bàn
        }
      }

      final count = marked.where((m) => m).length;
      if (count == 0 && creations.isEmpty) break;
      score += count * m3TilePoints * step;
      for (var i = 0; i < m3Cells; i++) {
        if (marked[i]) {
          final t = m3BaseType(cells[i]);
          if (t >= 0 && t < m3Types) cleared[t]++;
          cells[i] = _empty;
        }
      }
      creations.forEach((at, v) => cells[at] = v);
      swapA = swapB = -1;
      frames.add([...cells]);
      _gravityAndRefill();
      frames.add([...cells]);
    }
    return Match3Move(
      valid: true,
      score: score,
      frames: frames,
      cleared: cleared,
    );
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

  /// Xáo lại bàn khi hết nước đi: dựng bàn mới từ phần [_seq] CHƯA dùng, theo
  /// đúng luật bảng đầu của [Match3Board.initial] (không có dãy sẵn), lặp tới
  /// khi bàn có ít nhất một nước đi.
  ///
  /// CHỈ dùng cho chơi đơn. Đấu Trường KHÔNG được gọi: `arena_m3_replay`
  /// (supabase/arena_schema.sql) replay cả trận chỉ từ seq + log nước đi và
  /// không biết có xáo bàn — client tự xáo là bàn lệch server, mọi nước sau bị
  /// chấm sai. Muốn Đấu Trường xáo thì phải viết cùng logic ở cả SQL.
  ///
  /// ponytail: thử tối đa [tries] lần rồi thôi (bàn 8x8 5 loại gần như không
  /// bao giờ bí tới lần thứ hai); cần bảo đảm tuyệt đối thì phải dựng bàn có
  /// chủ đích thay vì bốc ngẫu nhiên.
  void reshuffle({int tries = 20}) {
    if (_seq.isEmpty) return;
    for (var t = 0; t < tries; t++) {
      for (var i = 0; i < m3Cells; i++) {
        final r = i ~/ m3Size, c = i % m3Size;
        var v = _next();
        while ((c >= 2 && cells[i - 1] == v && cells[i - 2] == v) ||
            (r >= 2 && cells[i - m3Size] == v && cells[i - 2 * m3Size] == v)) {
          v = (v + 1) % m3Types;
        }
        cells[i] = v;
      }
      if (hasAnyMove()) return;
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
