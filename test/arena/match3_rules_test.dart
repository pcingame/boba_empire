import 'dart:math';

import 'package:boba_empire/arena/arena_rules.dart';
import 'package:boba_empire/arena/match3_rules.dart';
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
