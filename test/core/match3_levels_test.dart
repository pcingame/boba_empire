// Lõi Hành trình Ghép 3: mốc sao, mở khoá, bàn tất định, và — quan trọng nhất —
// thưởng KHÔNG lặp lại (bàn tất định nên chơi lại được đúng điểm cũ).
import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mốc sao: đúng bằng mục tiêu là 1 sao, 1.5x là 2, 2x là 3', () {
    expect(match3Stars(999, 1000), 0);
    expect(match3Stars(1000, 1000), 1); // biên dưới
    expect(match3Stars(1499, 1000), 1);
    expect(match3Stars(1500, 1000), 2);
    expect(match3Stars(1999, 1000), 2);
    expect(match3Stars(2000, 1000), 3);
    expect(match3Stars(100, 0), 0); // mục tiêu 0 không cho sao chùa
  });

  test('mở khoá tuần tự: phải có >= 1 sao ở màn trước', () {
    expect(levelUnlocked(const [], 1), isTrue);
    expect(levelUnlocked(const [], 2), isFalse);
    expect(levelUnlocked(const [0], 2), isFalse); // chơi nhưng chưa đạt sao
    expect(levelUnlocked(const [1], 2), isTrue);
    expect(levelUnlocked(const [3, 1], 3), isTrue);
    expect(levelUnlocked(const [3, 0], 3), isFalse);
  });

  test('bàn cờ tất định theo màn, và khác nhau giữa các màn', () {
    final a1 = Match3Board.initial(const Match3Level(5).seq()).cells;
    final a2 = Match3Board.initial(const Match3Level(5).seq()).cells;
    final b = Match3Board.initial(const Match3Level(6).seq()).cells;
    expect(a1, a2, reason: 'cùng màn phải ra cùng bàn');
    expect(a1, isNot(b));
    expect(a1.every((v) => v >= 0 && v < m3Types), isTrue);
  });

  test('mục tiêu tăng dần theo màn', () {
    expect(const Match3Level(2).target,
        greaterThan(const Match3Level(1).target));
    expect(const Match3Level(30).target,
        greaterThan(const Match3Level(10).target));
  });

  group('thưởng', () {
    late GameState s;
    setUp(() => s = GameState.newGame(nowMillis: 0));

    test('chơi lại màn đã đạt: KHÔNG thưởng thêm (chống farm)', () {
      final first = applyMatch3Result(s, 1, 3, incomePerSecond: 100);
      expect(first.$1, greaterThan(0));
      expect(first.$2, Balance.m3ThreeStarGems);

      final money = s.money, gems = s.gems;
      final again = applyMatch3Result(s, 1, 3, incomePerSecond: 100);
      expect(again, (0.0, 0));
      expect(s.money, money);
      expect(s.gems, gems);
    });

    test('phá kỷ lục cũ chỉ trả phần sao chênh lệch', () {
      applyMatch3Result(s, 1, 1, incomePerSecond: 100);
      final money = s.money;
      final up = applyMatch3Result(s, 1, 3, incomePerSecond: 100);
      expect(s.m3Stars[0], 3);
      // 2 sao chênh lệch, không phải trả lại đủ 3.
      expect(up.$1, closeTo(100.0 * Balance.m3RewardIncomeSeconds * 2, 0.001));
      expect(s.money, greaterThan(money));
      expect(up.$2, Balance.m3ThreeStarGems, reason: '💎 3 sao trả lần đầu');
    });

    test('không đạt sao nào thì không ghi gì', () {
      expect(applyMatch3Result(s, 3, 0, incomePerSecond: 100), (0.0, 0));
      expect(s.m3Stars, isEmpty);
    });

    test('lưu được sao ở màn xa mà không cần chơi các màn trước', () {
      applyMatch3Result(s, 5, 2, incomePerSecond: 1);
      expect(s.m3Stars.length, 5);
      expect(starsOf(s.m3Stars, 5), 2);
      expect(starsOf(s.m3Stars, 4), 0);
    });

    test('sao đi theo save (qua JSON)', () {
      applyMatch3Result(s, 2, 3, incomePerSecond: 1);
      final back = GameState.fromJson(s.toJson());
      expect(back.m3Stars, s.m3Stars);
      // Save cũ không có khoá này vẫn đọc được.
      final json = s.toJson()..remove('m3Stars');
      expect(GameState.fromJson(json).m3Stars, isEmpty);
    });
  });
}
