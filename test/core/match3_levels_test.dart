// Lõi Hành trình Ghép 3: mốc sao, mở khoá, bàn tất định, và — quan trọng nhất —
// thưởng KHÔNG lặp lại (bàn tất định nên chơi lại được đúng điểm cũ).
import 'dart:math' show pow;

import 'package:boba_empire/arena/match3_rules.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _nextStarTests();
  _collectTests();
  test('mốc sao bám theo Balance.m3Star2Mult/m3Star3Mult, kiểm ở BIÊN', () {
    const target = 1000;
    final two = (target * Balance.m3Star2Mult).round();
    final three = (target * Balance.m3Star3Mult).round();

    expect(match3Stars(target - 1, target), 0);
    expect(match3Stars(target, target), 1); // biên dưới
    expect(match3Stars(two - 1, target), 1);
    expect(match3Stars(two, target), 2);
    expect(match3Stars(three - 1, target), 2);
    expect(match3Stars(three, target), 3);
    expect(match3Stars(100, 0), 0); // mục tiêu 0 không cho sao chùa
  });

  test('80 màn: mục tiêu hợp lệ, không giảm dần, màn điểm không vượt trần', () {
    expect(Balance.m3LevelCount, 80);
    var prevScore = 0;
    for (var id = 1; id <= Balance.m3LevelCount; id++) {
      final lv = Match3Level(id);
      expect(lv.target, greaterThan(0), reason: 'màn $id');
      if (lv.goal == Match3GoalKind.score) {
        expect(lv.target, lessThanOrEqualTo(Balance.m3TargetCap.round()),
            reason: 'màn $id vượt trần');
        expect(lv.target, greaterThanOrEqualTo(prevScore),
            reason: 'màn điểm $id dễ hơn màn trước');
        prevScore = lv.target;
      }
      // Bàn đầu của MỌI màn phải đi được ngay (không bí từ đầu).
      final board = Match3Board.initial(lv.seq(), specials: true);
      if (!board.hasAnyMove()) board.reshuffle();
      expect(board.hasAnyMove(), isTrue, reason: 'màn $id bí từ đầu');
    }
  });

  test('trần mục tiêu: dưới trần thì theo công thức, chạm trần thì đứng yên', () {
    final savedCap = Balance.m3TargetCap;
    addTearDown(() => Balance.m3TargetCap = savedCap);
    Balance.m3TargetCap = 5000;
    final scoreIds = [for (var i = 1; i <= 80; i++) if (Match3Level(i).goal == Match3GoalKind.score) i];
    expect(Match3Level(scoreIds.first).target, 900, reason: 'màn 1 dưới trần');
    expect(Match3Level(scoreIds.last).target, 5000);
    expect(Match3Level(80 - 1).target, lessThanOrEqualTo(5000));
    // Trần rất cao thì không còn tác dụng: quay về công thức thuần.
    Balance.m3TargetCap = 1e12;
    expect(Match3Level(70).goal, Match3GoalKind.score);
    expect(Match3Level(70).target,
        (Balance.m3TargetBase * pow(Balance.m3TargetGrowth, 69)).round());
  });

  test('mốc sao phải tăng dần (2 sao không được dễ hơn 1, 3 không dễ hơn 2)',
      () {
    expect(Balance.m3Star2Mult, greaterThanOrEqualTo(1));
    expect(Balance.m3Star3Mult, greaterThan(Balance.m3Star2Mult));
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

  test('mục tiêu tăng dần theo màn (trong cùng một kiểu mục tiêu)', () {
    // Chỉ so các màn tính ĐIỂM với nhau: màn thu thập đếm số ô, so chéo hai
    // kiểu là vô nghĩa (28 ô vs 2496 điểm).
    final scoreLevels = [
      for (var id = 1; id <= 40; id++)
        if (Match3Level(id).goal == Match3GoalKind.score) Match3Level(id),
    ];
    for (var i = 1; i < scoreLevels.length; i++) {
      expect(scoreLevels[i].target, greaterThan(scoreLevels[i - 1].target),
          reason: 'màn ${scoreLevels[i].id}');
    }
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

// --- Màn kiểu "thu thập N ô loại X" ---
void _collectTests() {
  late int savedEvery;
  setUp(() => savedEvery = Balance.m3CollectEvery);
  tearDown(() => Balance.m3CollectEvery = savedEvery);

  test('cứ m3CollectEvery màn thì một màn là thu thập', () {
    Balance.m3CollectEvery = 3;
    expect(const Match3Level(1).goal, Match3GoalKind.score);
    expect(const Match3Level(2).goal, Match3GoalKind.score);
    expect(const Match3Level(3).goal, Match3GoalKind.collect);
    expect(const Match3Level(6).goal, Match3GoalKind.collect);
    expect(const Match3Level(7).goal, Match3GoalKind.score);
  });

  test('đặt 0 là tắt hẳn màn thu thập (không chia cho 0)', () {
    Balance.m3CollectEvery = 0;
    for (var id = 1; id <= 12; id++) {
      expect(Match3Level(id).goal, Match3GoalKind.score, reason: 'màn $id');
    }
  });

  test('loại ô cần thu xoay vòng qua các màn thu thập', () {
    Balance.m3CollectEvery = 3;
    final types = [
      for (var i = 1; i <= m3Types + 1; i++)
        Match3Level(i * 3).collectType,
    ];
    expect(types.take(m3Types).toSet().length, m3Types,
        reason: 'phải đi hết 5 loại trước khi lặp');
    expect(types[m3Types], types[0], reason: 'rồi quay vòng');
    expect(types.every((t) => t >= 0 && t < m3Types), isTrue);
  });

  test('số ô cần thu tăng dần và luôn dương', () {
    Balance.m3CollectEvery = 3;
    final a = const Match3Level(3).target;
    final b = const Match3Level(6).target;
    final c = const Match3Level(30).target;
    expect(a, greaterThan(0));
    expect(b, greaterThan(a));
    expect(c, greaterThan(b));
  });

  test('thang sao dùng chung: 1x / 1.5x / 2x số ô cần thu', () {
    Balance.m3CollectEvery = 3;
    final target = const Match3Level(3).target;
    expect(match3Stars(target - 1, target), 0);
    expect(match3Stars(target, target), 1);
    expect(match3Stars((target * Balance.m3Star3Mult).ceil(), target), 3);
  });
}

// --- Gợi ý "còn thiếu N nữa là X sao" ---
void _nextStarTests() {
  test('ngưỡng từng mốc sao', () {
    expect(match3StarThreshold(1000, 1), 1000);
    expect(match3StarThreshold(1000, 2),
        (1000 * Balance.m3Star2Mult).round());
    expect(match3StarThreshold(1000, 3),
        (1000 * Balance.m3Star3Mult).round());
    expect(match3StarThreshold(1000, 4), 0);
  });

  test('còn thiếu bao nhiêu nữa là lên sao', () {
    const target = 1000;
    final two = match3StarThreshold(target, 2);
    final three = match3StarThreshold(target, 3);

    expect(match3NextStar(0, target), (1, target));
    expect(match3NextStar(target - 10, target), (1, 10));
    expect(match3NextStar(target, target), (2, two - target));
    expect(match3NextStar(two, target), (3, three - two));
  });

  test('đã 3 sao thì không còn gì để săn', () {
    const target = 1000;
    expect(match3NextStar(match3StarThreshold(target, 3), target), isNull);
    expect(match3NextStar(999999, target), isNull);
  });

  test('mục tiêu không hợp lệ / số thiếu không bao giờ <= 0', () {
    expect(match3NextStar(0, 0), isNull);
    // Ngay tại biên vừa đủ sao kế: phải báo số dương, không phải 0.
    const target = 1000;
    final two = match3StarThreshold(target, 2);
    final at = match3NextStar(two - 1, target)!;
    expect(at.$1, 2);
    expect(at.$2, greaterThan(0));
  });
}
