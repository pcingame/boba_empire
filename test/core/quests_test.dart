import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quests (chuỗi nhiệm vụ)', () {
    test('nhiệm vụ đầu tiên = chạm 25 lần', () {
      final s = GameState.newGame(nowMillis: 0);
      expect(currentQuest(s).metric, QuestMetric.tap);
      expect(currentQuestDone(s), isFalse);
    });

    test('đủ điều kiện → claim cộng gems & sang nhiệm vụ kế', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 25;
      expect(currentQuestDone(s), isTrue);
      final g = claimQuest(s);
      expect(g, quests[0].rewardGems);
      expect(s.gems, quests[0].rewardGems.toDouble());
      expect(s.questIndex, 1);
      expect(currentQuest(s).metric, QuestMetric.buy);
    });

    test('chưa đạt thì claim không làm gì', () {
      final s = GameState.newGame(nowMillis: 0)..tapCount = 10;
      expect(claimQuest(s), 0);
      expect(s.questIndex, 0);
    });

    test('tiến độ dùng đúng metric theo questIndex', () {
      final s = GameState.newGame(nowMillis: 0)
        ..questIndex = 1 // nhiệm vụ "mua 3 nâng cấp"
        ..buyCount = 3;
      expect(currentQuest(s).metric, QuestMetric.buy);
      expect(currentQuestDone(s), isTrue);
    });

    test('hết chuỗi → nhiệm vụ lặp "kiếm thêm", đếm từ baseline', () {
      final s = GameState.newGame(nowMillis: 0)
        ..questIndex = quests.length
        ..lifetimeEarnings = 1e9 // đã kiếm nhiều từ trước
        ..repeatQuestBaseline = 1e9; // mốc vừa chốt
      final q = currentQuest(s);
      expect(q.repeatable, isTrue);
      expect(q.metric, QuestMetric.earn);
      expect(currentQuestDone(s), isFalse); // chưa kiếm thêm

      s.lifetimeEarnings += q.threshold.toDouble(); // kiếm đủ "thêm"
      expect(currentQuestDone(s), isTrue);
      final g = claimQuest(s);
      expect(g, q.rewardGems);
      expect(s.questIndex, quests.length + 1);
      // Mốc mới = lifetime hiện tại → nhiệm vụ kế lại đếm từ 0.
      expect(s.repeatQuestBaseline, s.lifetimeEarnings);
      expect(currentQuestDone(s), isFalse);
    });

    test('nhiệm vụ lặp thứ n có ngưỡng ×10^n', () {
      final s0 = GameState.newGame(nowMillis: 0)..questIndex = quests.length;
      final s1 = GameState.newGame(nowMillis: 0)..questIndex = quests.length + 1;
      expect(currentQuest(s1).threshold, currentQuest(s0).threshold * 10);
    });

    // HỒI QUY "Kiếm thêm 0 Xu nhận kim cương": pow(10, cycle) trên số nguyên tràn
    // int64 — vòng 19 âm, vòng 64+ bằng 0 nên luôn nhận được thưởng.
    test('ngưỡng nhiệm vụ lặp luôn dương, hữu hạn, không giảm ở MỌI vòng (kể cả vòng 19, 64, 400)', () {
      var prev = 0.0;
      for (var cycle = 0; cycle <= 400; cycle++) {
        final s = GameState.newGame(nowMillis: 0)..questIndex = quests.length + cycle;
        final t = currentQuest(s).threshold.toDouble();
        expect(t, greaterThan(0), reason: 'vòng $cycle');
        expect(t.isFinite, isTrue, reason: 'vòng $cycle');
        expect(t, greaterThanOrEqualTo(prev), reason: 'vòng $cycle');
        prev = t;
      }
    });

    test('ngưỡng bằng đúng base·10^vòng khi còn trong tầm double chính xác, kẹp ở trần kinh tế', () {
      for (final cycle in [0, 1, 5, 18, 19, 20, 63, 64, 65]) {
        final s = GameState.newGame(nowMillis: 0)..questIndex = quests.length + cycle;
        expect(currentQuest(s).threshold,
            closeTo(Balance.questRepeatBaseEarn * pow(10.0, cycle), Balance.questRepeatBaseEarn * pow(10.0, cycle) * 1e-12),
            reason: 'vòng $cycle');
      }
      final s = GameState.newGame(nowMillis: 0)..questIndex = quests.length + 400;
      expect(currentQuest(s).threshold, Balance.economyOverflowGuardCap);
    });

    test('không thể nhận thưởng nhiệm vụ lặp khi chưa kiếm thêm gì (kể cả vòng 64+)', () {
      for (final cycle in [19, 40, 64, 100, 400]) {
        final s = GameState.newGame(nowMillis: 0)
          ..questIndex = quests.length + cycle
          ..lifetimeEarnings = 1e30
          ..repeatQuestBaseline = 1e30;
        expect(currentQuestDone(s), isFalse, reason: 'vòng $cycle');
        expect(claimQuest(s), 0, reason: 'vòng $cycle');
      }
    });
  });
}
