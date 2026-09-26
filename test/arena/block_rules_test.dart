import 'package:boba_empire/arena/arena_rules.dart';
import 'package:boba_empire/arena/block_rules.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 1, 1);

List<ArenaAction> _drops(List<(int rot, int col)> moves) => [
      for (var i = 0; i < moves.length; i++)
        ArenaAction(
          kind: ArenaActionKind.drop,
          at: _t0.add(Duration(milliseconds: i * 200)),
          id: i,
          rot: moves[i].$1,
          col: moves[i].$2,
        ),
    ];

void main() {
  group('bảng khối', () {
    test('28 hướng, mỗi hướng đúng 4 ô và nằm trong 4x4', () {
      expect(blockOrientations.length, 7);
      for (final piece in blockOrientations) {
        expect(piece.length, 4);
        for (final rows in piece) {
          final cells = rows.fold<int>(0, (n, r) => n + r.toRadixString(2).replaceAll('0', '').length);
          expect(cells, 4);
          expect(rows.length, lessThanOrEqualTo(4));
          expect(blockWidth(rows), lessThanOrEqualTo(4));
        }
      }
    });

    test('xoay 4 lần trở về hình cũ; I/O đối xứng đúng', () {
      expect(blockOrientations[0][0], [15]); // I ngang
      expect(blockOrientations[0][1], [1, 1, 1, 1]); // I dọc
      expect(blockOrientations[1][0], [3, 3]); // O
      expect(blockOrientations[2][0], [2, 7]); // T chỉ lên
    });
  });

  group('BlockBoard', () {
    test('rơi chạm đáy; cột ngoài biên bị bỏ qua', () {
      final b = BlockBoard();
      expect(b.dropTop(1, 0, 0), blockRows - 2);
      expect(b.dropTop(1, 0, 9), isNull); // O rộng 2, cột 9 tràn ngang
      final r = b.drop(1, 0, 9);
      expect(r.lines, 0);
      expect(b.rows.every((x) => x == 0), isTrue);
      expect(b.overflowed, isFalse);
    });

    test('vector vàng: I,I,O lấp đầy đáy -> 1 hàng = 1 điểm', () {
      final b = BlockBoard();
      final score = blockComputeScore(
        [0, 0, 1],
        _drops([(0, 0), (0, 4), (0, 8)]),
      );
      expect(score, 1);
      b.drop(0, 0, 0);
      b.drop(0, 0, 4);
      expect(b.drop(1, 0, 8).lines, 1);
    });

    test('vector vàng: 10 khối I dọc cột 0..9 xoá 4 hàng cùng lúc = 8 điểm', () {
      final score = blockComputeScore(
        List.filled(blockSeqLength, 0),
        _drops([for (var c = 0; c < 10; c++) (1, c)]),
      );
      expect(score, 8);
    });

    test('vector vàng: chồng I dọc một cột -> tràn ở lần thứ 6, ngừng tính', () {
      final b = BlockBoard();
      for (var i = 0; i < 5; i++) {
        expect(b.drop(0, 1, 0).overflow, isFalse);
      }
      expect(b.drop(0, 1, 0).overflow, isTrue);
      expect(b.overflowed, isTrue);
      // Sau khi tràn, các lần thả sau không cộng điểm dù có thể xoá hàng.
      final moves = <(int, int)>[
        for (var i = 0; i < 6; i++) (1, 0),
        for (var c = 1; c < 10; c++) (1, c),
      ];
      expect(blockComputeScore(List.filled(blockSeqLength, 0), _drops(moves)), 0);
    });

    test('xoá 2 và 3 hàng đúng bảng điểm', () {
      expect(blockLineScores, [0, 1, 3, 5, 8]);
    });
  });

  group('blockComputeScore', () {
    test('log rỗng = 0; hành động tap bị bỏ qua', () {
      expect(blockComputeScore([0, 1], const []), 0);
      expect(
        blockComputeScore([0], [ArenaAction(kind: ArenaActionKind.tap, at: _t0)]),
        0,
      );
    });

    test('thứ tự theo at rồi id, không theo thứ tự trong danh sách', () {
      final ordered = _drops([for (var c = 0; c < 10; c++) (1, c)]);
      final shuffled = [...ordered.reversed];
      final seq = List.filled(blockSeqLength, 0);
      expect(blockComputeScore(seq, shuffled), blockComputeScore(seq, ordered));
    });

    test('hết chuỗi khối thì bỏ qua các lần thả thừa', () {
      final moves = [for (var c = 0; c < 10; c++) (1, c)];
      expect(blockComputeScore([0, 0, 0], _drops(moves)), 0);
    });
  });

  test('save/wire: drop <-> chuỗi "drop"', () {
    expect(ArenaActionKind.drop.wireValue, 'drop');
    expect(ArenaActionKindJson.fromWire('drop'), ArenaActionKind.drop);
    expect(ArenaActionKind.drop.tierIndex, isNull);
  });
}
