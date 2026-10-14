// Nhiệm vụ công thức xen vào bộ ngày/tuần: ngày/tuần cũ giữ nguyên, từ mốc bắt đầu thì thay nhiệm vụ cuối.
import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const legacyDaily = [
    DailyQuestKind.tap,
    DailyQuestKind.buy,
    DailyQuestKind.earn,
    DailyQuestKind.cat,
    DailyQuestKind.vip,
    DailyQuestKind.spin,
  ];
  const legacyWeekly = [
    WeeklyQuestKind.prestige,
    WeeklyQuestKind.m3Win,
    WeeklyQuestKind.trade,
    WeeklyQuestKind.dailyDone,
    WeeklyQuestKind.spin,
    WeeklyQuestKind.buy,
  ];

  group('nhiệm vụ ngày', () {
    test('TRƯỚC mốc bắt đầu: bộ chọn y hệt thuật toán cũ (không đổi ngày/test đã qua)', () {
      for (var day = 0; day < recipeQuestsStartDay; day += 37) {
        final rng = Random(day * 2654435761 ^ 0x5bd1e995);
        final expected = ([...legacyDaily]..shuffle(rng)).take(Balance.dailyQuestCount).toList();
        expect(dailyQuestsFor(day, 1000).map((q) => q.kind).toList(), expected, reason: 'ngày $day');
      }
    });

    test('từ mốc: ngày chẵn có đúng 1 nhiệm vụ công thức ở vị trí cuối; ngày lẻ không có', () {
      for (var day = recipeQuestsStartDay; day < recipeQuestsStartDay + 60; day++) {
        final kinds = dailyQuestsFor(day, 1000).map((q) => q.kind).toList();
        expect(kinds.length, Balance.dailyQuestCount);
        expect(kinds.toSet().length, kinds.length, reason: 'không trùng loại, ngày $day');
        expect(kinds.where((k) => k == DailyQuestKind.recipe).length, day.isEven ? 1 : 0, reason: 'ngày $day');
        if (day.isEven) expect(kinds.last, DailyQuestKind.recipe);
      }
      final q = dailyQuestsFor(recipeQuestsStartDay + (recipeQuestsStartDay.isEven ? 0 : 1), 1000).last;
      expect((q.kind, q.target, q.rewardGems), (DailyQuestKind.recipe, 1.0, Balance.dailyQuestRewardGems));
    });

    test('tiến độ công thức cộng và nhận thưởng như nhiệm vụ khác', () {
      final day = recipeQuestsStartDay.isEven ? recipeQuestsStartDay : recipeQuestsStartDay + 1;
      final s = GameState.newGame(nowMillis: 0)..dailyQuestDay = day;
      final idx = currentDailyQuests(s).indexWhere((q) => q.kind == DailyQuestKind.recipe);
      expect(idx, isNonNegative);
      expect(claimDailyQuest(s, idx), 0); // chưa xong
      addDailyProgress(s, DailyQuestKind.recipe, 1);
      expect(claimDailyQuest(s, idx), Balance.dailyQuestRewardGems);
      expect(claimDailyQuest(s, idx), 0); // đã nhận
    });
  });

  group('nhiệm vụ tuần', () {
    int startWeek() => (recipeQuestsStartDay + 3) ~/ 7;

    test('TRƯỚC tuần bắt đầu: bộ chọn y hệt thuật toán cũ', () {
      for (var w = 0; w < startWeek(); w += 11) {
        final expected = ([...legacyWeekly]..shuffle(Random(w * 2246822519 ^ 0x27d4eb2f)))
            .take(weeklyQuestCount)
            .toList();
        expect(weeklyQuestsFor(w).map((q) => q.kind).toList(), expected, reason: 'tuần $w');
      }
    });

    test('từ tuần bắt đầu: nhiệm vụ cuối là công thức, luân phiên buổi/lên bậc theo tuần', () {
      for (var w = startWeek(); w < startWeek() + 12; w++) {
        final qs = weeklyQuestsFor(w);
        expect(qs.length, weeklyQuestCount);
        expect(qs.map((q) => q.kind).toSet().length, qs.length);
        expect(qs.last.kind, w.isEven ? WeeklyQuestKind.recipeSessions : WeeklyQuestKind.recipeLevels, reason: 'tuần $w');
        expect(qs.last.target, greaterThan(0));
      }
    });

    test('mọi loại tuần đều có mục tiêu (không null khi tra bảng)', () {
      for (var w = 0; w < startWeek() + 30; w++) {
        for (final q in weeklyQuestsFor(w)) {
          expect(q.target, greaterThan(0));
        }
      }
    });
  });
}
