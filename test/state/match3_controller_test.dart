// "Xem quảng cáo thêm nước": hết nước xem tiếp được, không giới hạn số lần.
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/state/match3_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đi một nước hợp lệ bất kỳ trên bàn hiện tại.
bool _playOne(Match3Controller c, Match3PlayState s) {
  final move = Match3Board.fromCells(s.cells).findMove();
  if (move == null) return false;
  return c.swap(move.$1, move.$2);
}

void main() {
  _collectTests();
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Match3Controller controller() =>
      container.read(match3ControllerProvider.notifier);
  Match3PlayState play() => container.read(match3ControllerProvider);

  test('bắt đầu màn: đủ số nước', () {
    controller().load(const Match3Level(1));
    expect(play().movesLeft, Balance.m3Moves);
    expect(play().finished, isFalse);
  });

  test('ván dang dở: canResume sau khi đi nước, không phải trước đó', () {
    controller().load(const Match3Level(1));
    expect(controller().canResume(const Match3Level(1)), isFalse);
    expect(_playOne(controller(), play()), isTrue);
    expect(controller().canResume(const Match3Level(1)), isTrue);
    expect(controller().canResume(const Match3Level(2)), isFalse);
  });

  test('cộng nước KHÔNG giới hạn số lần: mỗi lần +5, giữ điểm và bàn', () {
    controller().load(const Match3Level(1));
    expect(_playOne(controller(), play()), isTrue);
    final start = play();
    for (var i = 1; i <= 4; i++) {
      controller().addMovesFromAd();
      expect(play().movesLeft, start.movesLeft + i * Balance.m3AdExtraMoves,
          reason: 'lần $i');
    }
    expect(play().score, start.score);
    expect(play().cells, start.cells);
    expect(play().moveId, start.moveId);
  });

  test('chơi lại màn thì số nước về lại ban đầu (nước QC không dồn sang)', () {
    controller().load(const Match3Level(1));
    controller().addMovesFromAd();
    controller().load(const Match3Level(1));
    expect(play().movesLeft, Balance.m3Moves);
  });

  test('đi tiếp sau khi cộng nước: số nước vẫn trừ đúng 1 mỗi nước', () {
    controller().load(const Match3Level(1));
    controller().addMovesFromAd();
    final before = play().movesLeft;
    expect(_playOne(controller(), play()), isTrue);
    expect(play().movesLeft, before - 1);
  });

  test('hết nước thì khoá bàn, cộng nước xong chơi tiếp được', () {
    controller().load(const Match3Level(1));
    var guard = 0;
    while (!play().finished && guard++ < 200) {
      if (!_playOne(controller(), play())) break;
    }
    expect(play().finished, isTrue);
    expect(controller().swap(0, 0), isFalse, reason: 'hết nước là khoá bàn');

    controller().addMovesFromAd();
    expect(play().finished, isFalse);
    expect(_playOne(controller(), play()), isTrue);
  });
}

// --- Màn thu thập: chỉ đếm ô ĐÚNG LOẠI, tiến độ tính theo ô chứ không theo điểm ---
void _collectTests() {
  late ProviderContainer container;
  late int savedEvery;
  setUp(() {
    container = ProviderContainer();
    savedEvery = Balance.m3CollectEvery;
    Balance.m3CollectEvery = 3;
  });
  tearDown(() {
    Balance.m3CollectEvery = savedEvery;
    container.dispose();
  });

  Match3Controller controller() =>
      container.read(match3ControllerProvider.notifier);
  Match3PlayState play() => container.read(match3ControllerProvider);

  test('màn thu thập: đếm ĐÚNG số ô đúng loại, không phải điểm', () {
    // Màn 6 chứ không phải màn 3: màn 3 có collectType = 0 nên test không phân
    // biệt được "đếm đúng loại" với "luôn đếm loại 0".
    controller().load(const Match3Level(6));
    expect(play().level.collectType, isNot(0));
    expect(play().level.goal, Match3GoalKind.collect);
    expect(play().progress, 0);

    final type = play().level.collectType;
    // Bàn "gương": cùng seq, nhận cùng nước đi nên luôn khớp bàn của controller
    // → tự tính được số ô đúng loại mà mỗi nước xoá.
    final mirror =
        Match3Board.initial(play().level.seq(), specials: true);
    var expected = 0;
    for (var i = 0; i < 5; i++) {
      final move = mirror.findMove();
      if (move == null) break;
      expected += mirror.trySwap(move.$1, move.$2).cleared[type];
      expect(controller().swap(move.$1, move.$2), isTrue);
      expect(play().cells, mirror.cells, reason: 'hai bàn phải khớp');
      expect(play().collected, expected, reason: 'nước ${i + 1}');
      expect(play().progress, expected, reason: 'tiến độ = số ô thu được');
    }
    expect(expected, greaterThan(0), reason: 'phải thu được ít nhất vài ô');
  });

  test('màn tính điểm: không đếm thu thập', () {
    controller().load(const Match3Level(1));
    expect(play().level.goal, Match3GoalKind.score);
    final move = Match3Board.fromCells(play().cells).findMove()!;
    controller().swap(move.$1, move.$2);
    expect(play().collected, 0);
    expect(play().progress, play().score);
  });

  test('cộng nước bằng quảng cáo giữ nguyên tiến độ thu thập', () {
    controller().load(const Match3Level(3));
    final move = Match3Board.fromCells(play().cells).findMove()!;
    controller().swap(move.$1, move.$2);
    final collected = play().collected;
    controller().addMovesFromAd();
    expect(play().collected, collected);
  });
}
