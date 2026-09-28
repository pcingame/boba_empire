import 'dart:math';

import 'package:boba_empire/arena/arena_rules.dart';
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 1, 1);

/// Chuỗi giả ngẫu nhiên xác định (LCG) — cùng công thức dùng cho vector vàng
/// chép sang `supabase/arena_schema.sql`.
List<int> _lcg(int n, int seed) {
  var x = seed;
  return [
    for (var i = 0; i < n; i++)
      () {
        x = (x * 1103515245 + 12345) & 0x7fffffff;
        return (x >> 16) % 5;
      }(),
  ];
}

List<ArenaAction> _swaps(List<int> cells, List<int> dirs) => [
      for (var i = 0; i < cells.length; i++)
        ArenaAction(
          kind: ArenaActionKind.swap,
          at: _t0.add(Duration(milliseconds: i * 300)),
          id: i,
          cell: cells[i],
          dir: dirs[i],
        ),
    ];

bool _hasRun(List<int> c) {
  for (var r = 0; r < m3Size; r++) {
    for (var col = 0; col < m3Size; col++) {
      final v = c[r * m3Size + col];
      if (col + 2 < m3Size && c[r * m3Size + col + 1] == v && c[r * m3Size + col + 2] == v) return true;
      if (r + 2 < m3Size && c[(r + 1) * m3Size + col] == v && c[(r + 2) * m3Size + col] == v) return true;
    }
  }
  return false;
}

/// Bảng 8x8 không có dãy 3 nào: loại ô = (2r + 3c) mod 5 (mọi ô kề nhau khác loại).
Match3Board _flatBoard(List<int> seq) {
  final b = Match3Board.initial(seq);
  for (var i = 0; i < m3Cells; i++) {
    b.cells[i] = (2 * (i ~/ m3Size) + 3 * (i % m3Size)) % m3Types;
  }
  return b;
}

void main() {
  _reshuffleTests();
  _clearedTests();
  _specialTests();
  _shuffleGoldenTest();
  group('bảng đầu', () {
    test('không có match sẵn, đủ 64 ô loại 0..4, cố định theo seq', () {
      for (var seed = 1; seed <= 50; seed++) {
        final seq = _lcg(m3SeqLength, seed);
        final a = Match3Board.initial(seq);
        expect(a.cells.length, m3Cells);
        expect(a.cells.every((v) => v >= 0 && v < m3Types), isTrue);
        expect(_hasRun(a.cells), isFalse, reason: 'seed $seed');
        expect(Match3Board.initial(seq).cells, a.cells);
      }
    });

    test('seq toàn một loại vẫn ra bảng hợp lệ (tăng loại để tránh bộ 3)', () {
      final b = Match3Board.initial(List.filled(m3SeqLength, 2));
      expect(_hasRun(b.cells), isFalse);
    });
  });

  group('trySwap', () {
    test('nước sai không đổi bảng: ngoài biên, hướng lạ, hai ô cùng loại, không tạo match', () {
      final b = _flatBoard(_lcg(m3SeqLength, 7));
      final before = [...b.cells];
      expect(b.trySwap(-1, 0).valid, isFalse);
      expect(b.trySwap(64, 0).valid, isFalse);
      expect(b.trySwap(0, 2).valid, isFalse);
      expect(b.trySwap(7, 0).valid, isFalse); // cột cuối, không có ô phải
      expect(b.trySwap(56, 1).valid, isFalse); // hàng cuối, không có ô dưới
      expect(b.trySwap(20, 0).valid, isFalse); // không tạo match trên bảng phẳng
      expect(b.cells, before);
    });

    test('nước tạo match: hợp lệ, điểm là bội của 10, bảng cuối không còn match và không có ô trống', () {
      final b = _flatBoard(_lcg(m3SeqLength, 7));
      // Ô (0,0)=A, (0,1)=A, (0,2)=B; ô (1,2)=A -> đổi (0,2) xuống dưới tạo A A A ở hàng 0.
      b.cells[0] = 0;
      b.cells[1] = 0;
      b.cells[2] = 1;
      b.cells[10] = 0;
      final m = b.trySwap(2, 1);
      expect(m.valid, isTrue);
      expect(m.score, greaterThanOrEqualTo(3 * m3TilePoints));
      expect(m.score % m3TilePoints, 0);
      expect(b.cells.contains(-1), isFalse);
      expect(_hasRun(b.cells), isFalse);
      // frames: sau đổi, rồi (xoá, rơi+bù) cho từng bước; bảng cuối = kết quả.
      expect(m.frames.length, 1 + 2 * ((m.frames.length - 1) ~/ 2));
      expect(m.frames.last, b.cells);
      expect(m.frames[1].contains(-1), isTrue);
    });

    test('luồng bù ô xác định: cùng bảng + cùng nước = cùng kết quả', () {
      final seq = _lcg(m3SeqLength, 99);
      final a = Match3Board.initial(seq), b = Match3Board.initial(seq);
      for (var n = 0; n < 30; n++) {
        Match3Move? first;
        for (var cell = 0; cell < m3Cells && first == null; cell++) {
          for (var dir = 0; dir < 2 && first == null; dir++) {
            final m = a.copy().trySwap(cell, dir);
            if (m.valid) {
              first = m;
              expect(a.trySwap(cell, dir).score, b.trySwap(cell, dir).score);
            }
          }
        }
      }
      expect(a.cells, b.cells);
    });

    test('seq ngắn (chỉ vừa bảng đầu + vài ô) quay vòng thay vì lỗi', () {
      final seq = _lcg(70, 3);
      final b = Match3Board.initial(seq);
      var played = 0;
      for (var n = 0; n < 20; n++) {
        for (var cell = 0; cell < m3Cells; cell++) {
          if (b.trySwap(cell, 0).valid || b.trySwap(cell, 1).valid) {
            played++;
            break;
          }
        }
      }
      expect(played, greaterThan(0));
      expect(b.cells.contains(-1), isFalse);
    });

    test('bất biến qua 200 nước ngẫu nhiên: không ô trống, không match khi nghỉ, điểm >= 0', () {
      final rnd = Random(5);
      final b = Match3Board.initial(_lcg(m3SeqLength, 5));
      var moves = 0;
      for (var n = 0; n < 2000 && moves < 200; n++) {
        final m = b.trySwap(rnd.nextInt(m3Cells), rnd.nextInt(2));
        if (!m.valid) continue;
        moves++;
        expect(m.score, greaterThan(0));
        expect(b.cells.contains(-1), isFalse);
        expect(_hasRun(b.cells), isFalse);
      }
      expect(moves, greaterThan(50));
    });
  });

  group('dò nước hợp lệ', () {
    test('isValidMove khớp trySwap(...).valid trên mọi nước của nhiều bảng', () {
      for (var seed = 1; seed <= 20; seed++) {
        final b = Match3Board.initial(_lcg(m3SeqLength, seed));
        for (var cell = 0; cell < m3Cells; cell++) {
          for (var dir = -1; dir <= 2; dir++) {
            expect(b.isValidMove(cell, dir), b.copy().trySwap(cell, dir).valid,
                reason: 'seed $seed cell $cell dir $dir');
          }
        }
      }
    });

    test('isValidMove không đổi bảng', () {
      final b = Match3Board.initial(_lcg(m3SeqLength, 4));
      final before = [...b.cells];
      for (var cell = 0; cell < m3Cells; cell++) {
        b.isValidMove(cell, 0);
        b.isValidMove(cell, 1);
      }
      expect(b.cells, before);
    });

    test('HỒI QUY: fromCells + findMove kết thúc ngay (từng lặp vô hạn vì bù giả toàn 0)', () {
      final cells = Match3Board.initial(_lcg(m3SeqLength, 2026)).cells;
      final b = Match3Board.fromCells(cells);
      final move = b.findMove();
      expect(move, isNotNull);
      expect(b.trySwap(move!.$1, move.$2).valid, isFalse); // không có luồng bù thì không chơi được
      expect(b.cells, cells);
    });
  });

  group('hết nước đi', () {
    test('bảng phẳng tuần hoàn không có nước nào -> hasAnyMove false', () {
      expect(_flatBoard(_lcg(m3SeqLength, 1)).hasAnyMove(), isFalse);
    });

    test('bảng đầu ngẫu nhiên thường còn nước đi', () {
      expect(Match3Board.initial(_lcg(m3SeqLength, 12345)).hasAnyMove(), isTrue);
    });
  });

  group('match3ComputeScore', () {
    test('log rỗng / seq rỗng / hành động tap = 0', () {
      final seq = _lcg(m3SeqLength, 1);
      expect(match3ComputeScore(seq, const []), 0);
      expect(match3ComputeScore(const [], _swaps([2], [0])), 0);
      expect(
        match3ComputeScore(seq, [ArenaAction(kind: ArenaActionKind.tap, at: _t0)]),
        0,
      );
    });

    test('thứ tự theo at rồi id, không theo thứ tự trong danh sách', () {
      const cells = [2, 2, 9, 1, 2, 2, 13, 17];
      const dirs = [0, 1, 1, 0, 0, 1, 0, 1];
      final seq = _lcg(m3SeqLength, 12345);
      final ordered = _swaps(cells, dirs);
      expect(match3ComputeScore(seq, [...ordered.reversed]), match3ComputeScore(seq, ordered));
    });

    test('nước thiếu cell/dir hoặc vô hiệu bị bỏ qua', () {
      final seq = _lcg(m3SeqLength, 12345);
      final actions = [
        ArenaAction(kind: ArenaActionKind.swap, at: _t0, id: 0),
        ArenaAction(kind: ArenaActionKind.swap, at: _t0.add(const Duration(seconds: 1)), id: 1, cell: 99, dir: 0),
      ];
      expect(match3ComputeScore(seq, actions), 0);
    });

    test('chỉ tính tối đa m3MaxMoves nước đầu', () {
      final seq = _lcg(m3SeqLength, 12345);
      final b = Match3Board.initial(seq);
      final cells = <int>[], dirs = <int>[];
      for (var n = 0; n < m3MaxMoves + 30; n++) {
        var found = false;
        for (var cell = 0; cell < m3Cells && !found; cell++) {
          for (var dir = 0; dir < 2 && !found; dir++) {
            if (b.copy().trySwap(cell, dir).valid) {
              b.trySwap(cell, dir);
              cells.add(cell);
              dirs.add(dir);
              found = true;
            }
          }
        }
        if (!found) break;
      }
      final capped = match3ComputeScore(seq, _swaps(cells.take(m3MaxMoves).toList(), dirs.take(m3MaxMoves).toList()));
      expect(match3ComputeScore(seq, _swaps(cells, dirs)), capped);
    });

    // VECTOR VÀNG — chép nguyên sang khối comment cuối `supabase/arena_schema.sql`;
    // hàm `arena_m3_replay` phải cho đúng 1260 với cùng đầu vào.
    test('vector vàng Dart<->SQL: seq LCG(12345), 25 nước -> 1260', () {
      final seq = _lcg(m3SeqLength, 12345);
      const cells = [2, 2, 9, 1, 2, 2, 13, 17, 3, 0, 11, 8, 0, 2, 10, 4, 1, 11, 1, 2, 10, 9, 2, 0, 11];
      const dirs = [0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0];
      expect(match3ComputeScore(seq, _swaps(cells, dirs)), 1260);
    });
  });

  test('save/wire: swap <-> chuỗi "swap"', () {
    expect(ArenaActionKind.swap.wireValue, 'swap');
    expect(ArenaActionKindJson.fromWire('swap'), ArenaActionKind.swap);
    expect(ArenaActionKind.swap.tierIndex, isNull);
  });
}

// --- Xáo bàn khi hết nước (CHỈ chơi đơn dùng, xem ghi chú trong reshuffle) ---
void _reshuffleTests() {
  List<int> seqFrom(int seed) {
    var x = seed;
    return [
      for (var i = 0; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
    ];
  }

  test('bàn bí nước → xáo xong luôn có nước đi', () {
    // Lát gạch 2x2 [[0,1],[2,3]]: không có dãy 3 sẵn, và mọi nước đổi (ngang
    // hay dọc) đều chỉ tạo được cặp đôi, không bao giờ đủ 3.
    final stuck = [
      for (var i = 0; i < m3Cells; i++)
        ((i ~/ m3Size) % 2) * 2 + ((i % m3Size) % 2),
    ];
    final board = Match3Board.initial(seqFrom(7));
    board.cells.setAll(0, stuck);
    expect(board.hasAnyMove(), isFalse, reason: 'bàn dựng ra phải đang bí');

    board.reshuffle();
    expect(board.hasAnyMove(), isTrue);
    expect(board.cells.every((v) => v >= 0 && v < m3Types), isTrue);
  });

  test('xáo không để lại dãy 3 sẵn (không tự ăn điểm chùa)', () {
    final board = Match3Board.initial(seqFrom(99));
    board.reshuffle();
    // Không có 3 ô liên tiếp cùng loại theo hàng hoặc cột.
    for (var r = 0; r < m3Size; r++) {
      for (var c = 0; c < m3Size; c++) {
        final i = r * m3Size + c;
        if (c >= 2) {
          expect(
            board.cells[i] == board.cells[i - 1] && board.cells[i] == board.cells[i - 2],
            isFalse,
            reason: 'dãy ngang ở ô $i',
          );
        }
        if (r >= 2) {
          expect(
            board.cells[i] == board.cells[i - m3Size] &&
                board.cells[i] == board.cells[i - 2 * m3Size],
            isFalse,
            reason: 'dãy dọc ở ô $i',
          );
        }
      }
    }
  });

  test('bàn không có luồng bù (fromCells) thì xáo là no-op, không ném', () {
    final board = Match3Board.fromCells(List<int>.filled(m3Cells, 1));
    board.reshuffle();
    expect(board.cells.every((v) => v == 1), isTrue);
  });
}

// --- Đếm ô đã xoá theo loại (mục tiêu "thu thập" của chơi đơn) ---
void _clearedTests() {
  test('cleared đếm đúng loại và đúng số ô của nước đi', () {
    final seq = [
      for (var i = 0, x = 4242; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
    ];
    final board = Match3Board.initial(seq);
    final move = board.findMove()!;
    final result = board.trySwap(move.$1, move.$2);

    expect(result.valid, isTrue);
    expect(result.cleared.length, m3Types);
    // Tổng ô xoá phải khớp với điểm: điểm = sum(ô xoá ở bước n) * 10 * n, nên
    // tổng ô xoá <= điểm/10 và >= 3 (ít nhất một dãy 3).
    final total = result.cleared.reduce((a, b) => a + b);
    expect(total, greaterThanOrEqualTo(3));
    expect(total * m3TilePoints, lessThanOrEqualTo(result.score));
    expect(result.cleared.every((c) => c >= 0), isTrue);
  });

  test('nước vô hiệu không đếm gì', () {
    final board = Match3Board.initial(const [1, 2, 3]);
    // Ô ngoài bảng -> vô hiệu.
    expect(board.trySwap(-1, 0).cleared, isEmpty);
  });
}

// --- Kẹo đặc biệt (CHỈ chơi đơn; Đấu Trường phải không đổi gì) ---
void _specialTests() {
  /// Bàn dựng tay: [rows] là 8 chuỗi 8 chữ số loại ô.
  Match3Board boardOf(List<String> rows, {bool specials = true}) {
    // Chuỗi bù ô phải ĐA DẠNG: seq toàn một loại thì ô bù luôn khớp nhau và
    // dây chuyền không bao giờ dừng (đã đụng lúc viết test này).
    final seq = [
      for (var i = 0, x = 20260928; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
    ];
    final b = Match3Board.initial(seq, specials: specials);
    final cells = [
      for (final row in rows)
        for (final ch in row.split('')) int.parse(ch),
    ];
    b.cells.setAll(0, cells);
    return b;
  }

  test('ghép 4 sinh bom chéo tại ô người chơi vừa đổi tới', () {
    // Hàng 0: 1 0 0 0 ... đổi ô (0,0) với (1,0)=0 -> hàng 0 thành 0 0 0 0.
    final b = boardOf([
      '10001234',
      '01234123',
      '12341234',
      '23412341',
      '34123412',
      '41234123',
      '12341234',
      '23412341',
    ]);
    final move = b.trySwap(0, 1); // đổi xuống
    expect(move.valid, isTrue);
    final specials = b.cells.where(m3IsSpecial).toList();
    expect(specials.length, 1, reason: 'đúng một kẹo được sinh');
    expect(specials.first, greaterThanOrEqualTo(m3CrossBase));
    expect(specials.first, lessThan(m3ColorBase), reason: 'ghép 4 = bom chéo');
  });

  test('ghép 5 sinh bom màu', () {
    final b = boardOf([
      '10000234',
      '01234123',
      '12341234',
      '23412341',
      '34123412',
      '41234123',
      '12341234',
      '23412341',
    ]);
    final move = b.trySwap(0, 1);
    expect(move.valid, isTrue);
    final specials = b.cells.where(m3IsSpecial).toList();
    expect(specials.length, 1);
    expect(specials.first, greaterThanOrEqualTo(m3ColorBase),
        reason: 'ghép 5 = bom màu');
  });

  test('TẮT kẹo (mặc định, như Đấu Trường) thì ghép 4 xoá sạch', () {
    final b = boardOf([
      '10001234',
      '01234123',
      '12341234',
      '23412341',
      '34123412',
      '41234123',
      '12341234',
      '23412341',
    ], specials: false);
    expect(b.trySwap(0, 1).valid, isTrue);
    expect(b.cells.any(m3IsSpecial), isFalse);
  });

  test('bom chéo nổ khi bị xoá: quét cả hàng và cột', () {
    final b = boardOf([
      '01234123',
      '12341234',
      '23412341',
      '34123412',
      '41234123',
      '12341234',
      '23412341',
      '34123412',
    ]);
    // Đặt tay một bom chéo loại 0 và ba ô loại 0 quanh nó để ghép được.
    b.cells[27] = m3CrossBase + 0; // (3,3)
    b.cells[28] = 0;
    b.cells[29] = 0;
    b.cells[26] = 1;
    b.cells[25] = 0; // đổi (3,1)<->(3,2) để có 0 0 0 từ cột 2
    final before = b.cells.where((v) => v != -1).length;
    final move = b.trySwap(25, 0);
    expect(move.valid, isTrue);
    // Bom nổ quét hàng 3 + cột 3 nên số ô bị xoá phải lớn hơn hẳn một dãy 3.
    expect(move.cleared.reduce((a, b) => a + b), greaterThan(3));
    expect(before, m3Cells);
  });

  test('bàn màn chơi THẬT có sinh kẹo trong lúc chơi bình thường', () {
    // Không chỉ bàn dựng tay: chạy bàn của màn 1 và đánh 60 nước máy móc.
    // Đo được ~3 kẹo/60 nước (người chơi nhắm ghép 4 sẽ nhiều hơn) — nếu con
    // số này về 0 nghĩa là luật sinh kẹo đã chết ở đường đi thật.
    final b = Match3Board.initial(const Match3Level(1).seq(), specials: true);
    var created = 0;
    for (var i = 0; i < 60; i++) {
      final m = b.findMove();
      if (m == null) break;
      final before = b.cells.where(m3IsSpecial).length;
      b.trySwap(m.$1, m.$2);
      final after = b.cells.where(m3IsSpecial).length;
      if (after > before) created += after - before;
    }
    expect(created, greaterThan(0));
  });

  test('m3BaseType/m3IsSpecial ánh xạ đúng', () {
    expect(m3BaseType(3), 3);
    expect(m3BaseType(m3CrossBase + 2), 2);
    expect(m3BaseType(m3ColorBase + 4), 4);
    expect(m3IsSpecial(4), isFalse);
    expect(m3IsSpecial(m3CrossBase), isTrue);
    expect(m3IsSpecial(m3ColorBase + 1), isTrue);
  });
}

// --- Vector vàng cho reshuffle: Dart <-> SQL phải ra CÙNG một bàn ---
void _shuffleGoldenTest() {
  test('reshuffle vector vàng Dart<->SQL: bàn bí + LCG(12345), refill 64', () {
    final seq = [
      for (var i = 0, x = 12345; i < m3SeqLength; i++)
        (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
    ];
    // Lát gạch 2x2 [[0,1],[2,3]]: không dãy 3 sẵn, không nước đi nào.
    final stuck = [
      for (var i = 0; i < m3Cells; i++)
        ((i ~/ m3Size) % 2) * 2 + ((i % m3Size) % 2),
    ];
    final board = Match3Board.initial(seq);
    board.cells.setAll(0, stuck);
    expect(board.hasAnyMove(), isFalse, reason: 'bàn đầu vào phải đang bí');

    board.reshuffle();

    // Con số này cũng nằm trong khối comment cuối supabase/arena_schema.sql.
    // Đổi luật xáo mà quên đổi SQL (hoặc ngược lại) là test này đỏ.
    expect(board.cells, [
      0, 0, 3, 4, 2, 3, 1, 4, 3, 0, 0, 2, 1, 1, 4, 1, //
      2, 2, 0, 3, 4, 1, 0, 3, 0, 3, 2, 4, 1, 2, 4, 4, //
      0, 1, 4, 4, 3, 1, 2, 1, 1, 2, 4, 0, 2, 4, 4, 0, //
      4, 4, 1, 1, 3, 2, 2, 3, 2, 3, 3, 1, 4, 3, 4, 1, //
    ]);
    expect(board.hasAnyMove(), isTrue);
  });

  test('sau MỌI nước đi bàn luôn còn nước — bất biến người chơi thấy', () {
    // ĐO ĐƯỢC (2026-09-28): quét 4000 hạt giống x 150 nước (~600k nước) KHÔNG
    // có lần nào bàn bí sau một nước; ép bằng chuỗi bù chỉ 2-3 loại cũng không
    // bí. Nghĩa là nhánh xáo trong `trySwap` gần như không bao giờ chạy — nó là
    // lưới an toàn, không phải đường đi thường. Test này vì vậy KHÔNG phủ được
    // nhánh đó (thuật toán xáo do vector vàng ở trên khoá); nó khoá bất biến mà
    // người chơi thực sự cảm nhận: đánh xong vẫn luôn còn nước để đi.
    var moves = 0;
    for (var seed = 1; seed <= 40; seed++) {
      final seq = [
        for (var i = 0, x = seed; i < m3SeqLength; i++)
          (x = (x * 1103515245 + 12345) & 0x7fffffff, (x >> 16) % m3Types).$2,
      ];
      final board = Match3Board.initial(seq);
      for (var n = 0; n < 40; n++) {
        final move = board.findMove();
        if (move == null) break;
        expect(board.trySwap(move.$1, move.$2).valid, isTrue);
        moves++;
        expect(board.hasAnyMove(), isTrue,
            reason: 'hạt giống $seed, sau nước $n bàn bí');
      }
    }
    expect(moves, greaterThan(1000));
  });
}
