import 'package:boba_empire/arena/arena_rules.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _t(int s) => DateTime.fromMillisecondsSinceEpoch(s * 1000);

void main() {
  group('arenaComputeScore', () {
    test('log rỗng → 0', () {
      expect(arenaComputeScore(const []), 0);
    });

    test('mỗi tap cộng đúng tapValue hiện tại (mặc định 1)', () {
      final actions = List.generate(
        5,
        (i) => ArenaAction(kind: ArenaActionKind.tap, at: _t(i)),
      );
      expect(arenaComputeScore(actions), 5);
    });

    test('mua mốc 1 khi đủ tiền: trừ giá, nhân đôi tapValue cho các tap sau',
        () {
      final actions = [
        // 20 tap đầu (tapValue=1) → đủ 20 để mua mốc 1.
        ...List.generate(
            20, (i) => ArenaAction(kind: ArenaActionKind.tap, at: _t(i))),
        ArenaAction(kind: ArenaActionKind.buyTier1, at: _t(20)),
        // 3 tap sau, tapValue đã ×2 = 2 → +6.
        ...List.generate(3,
            (i) => ArenaAction(kind: ArenaActionKind.tap, at: _t(21 + i))),
      ];
      expect(arenaComputeScore(actions), 0 + 6); // 20 tiêu hết mua mốc, +6 sau
    });

    test('mua hụt (chưa đủ tiền tại thời điểm replay) → bỏ qua hành động đó',
        () {
      final actions = [
        ArenaAction(kind: ArenaActionKind.tap, at: _t(0)), // money=1
        ArenaAction(kind: ArenaActionKind.buyTier1, at: _t(1)), // cần 20, bỏ qua
        ArenaAction(kind: ArenaActionKind.tap, at: _t(2)), // vẫn tapValue=1
      ];
      expect(arenaComputeScore(actions), 2);
    });

    test('không mua trùng 2 lần mốc giống nhau vẫn tính đúng theo log thực tế '
        '(logic không tự chặn trùng — đó là việc của submit_action ở server)',
        () {
      final actions = [
        ...List.generate(
            20, (i) => ArenaAction(kind: ArenaActionKind.tap, at: _t(i))),
        ArenaAction(kind: ArenaActionKind.buyTier1, at: _t(20)), // money=0, ×2
        ...List.generate(10,
            (i) => ArenaAction(kind: ArenaActionKind.tap, at: _t(21 + i))),
        // money = 20 sau 10 tap ở tapValue=2 → đủ mua mốc 1 "lần nữa" nếu log
        // cho phép (server thực tế chặn trùng mốc, đây chỉ test hàm thuần).
        ArenaAction(kind: ArenaActionKind.buyTier1, at: _t(31)),
      ];
      expect(arenaComputeScore(actions), 0);
    });

    test('thứ tự log không quan trọng — hàm tự sắp theo `at`', () {
      final inOrder = [
        ArenaAction(kind: ArenaActionKind.tap, at: _t(0)),
        ArenaAction(kind: ArenaActionKind.tap, at: _t(1)),
      ];
      final reversed = inOrder.reversed.toList();
      expect(arenaComputeScore(reversed), arenaComputeScore(inOrder));
    });

    test('cùng `at` (đụng mili-giây) → phá thế bằng bằng id tăng dần', () {
      final sameTime = _t(0);
      final actions = [
        ArenaAction(kind: ArenaActionKind.buyTier1, at: sameTime, id: 21),
        // Nếu xử lý sai thứ tự (mua trước 20 tap), mốc này bị bỏ qua vì
        // thiếu tiền tại thời điểm replay.
        ...List.generate(20,
            (i) => ArenaAction(kind: ArenaActionKind.tap, at: sameTime, id: i)),
      ];
      expect(arenaComputeScore(actions), 0); // 20 tap rồi mới mua mốc, hết tiền
    });
  });

  group('ArenaActionKind <-> wire', () {
    test('round-trip đúng chiều', () {
      for (final kind in ArenaActionKind.values) {
        expect(ArenaActionKindJson.fromWire(kind.wireValue), kind);
      }
    });

    test('giá trị lạ ném lỗi thay vì âm thầm coi là tap', () {
      expect(() => ArenaActionKindJson.fromWire('nope'), throwsArgumentError);
    });

    test('tierIndex đúng cho hành động mua, null cho tap', () {
      expect(ArenaActionKind.tap.tierIndex, isNull);
      expect(ArenaActionKind.buyTier1.tierIndex, 0);
      expect(ArenaActionKind.buyTier2.tierIndex, 1);
      expect(ArenaActionKind.buyTier3.tierIndex, 2);
    });
  });
}
