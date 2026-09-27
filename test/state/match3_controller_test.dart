// Lượt "xem quảng cáo thêm nước": đúng 1 lần mỗi lượt chơi. Không giới hạn thì
// xem đủ quảng cáo là qua được mọi màn.
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
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Match3Controller controller() =>
      container.read(match3ControllerProvider.notifier);
  Match3PlayState play() => container.read(match3ControllerProvider);

  test('bắt đầu màn: đủ số nước, chưa dùng lượt quảng cáo', () {
    controller().load(const Match3Level(1));
    expect(play().movesLeft, Balance.m3Moves);
    expect(play().adContinueUsed, isFalse);
    expect(play().finished, isFalse);
  });

  test('cộng nước một lần; lần thứ hai không có tác dụng', () {
    controller().load(const Match3Level(1));
    final before = play().movesLeft;

    controller().addMovesFromAd();
    expect(play().movesLeft, before + Balance.m3AdExtraMoves);
    expect(play().adContinueUsed, isTrue);

    controller().addMovesFromAd();
    expect(play().movesLeft, before + Balance.m3AdExtraMoves,
        reason: 'lượt thứ hai phải bị chặn');
  });

  test('cờ đã-dùng còn nguyên sau khi đi tiếp (không reset mỗi nước)', () {
    controller().load(const Match3Level(1));
    controller().addMovesFromAd();
    expect(_playOne(controller(), play()), isTrue);
    expect(play().adContinueUsed, isTrue);
    expect(_playOne(controller(), play()), isTrue);
    expect(play().adContinueUsed, isTrue);
  });

  test('chơi lại màn thì được mời xem quảng cáo lại từ đầu', () {
    controller().load(const Match3Level(1));
    controller().addMovesFromAd();
    controller().load(const Match3Level(1));
    expect(play().adContinueUsed, isFalse);
    expect(play().movesLeft, Balance.m3Moves);
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
