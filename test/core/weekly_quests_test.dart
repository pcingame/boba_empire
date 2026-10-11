import 'dart:convert';

import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/weekly_quests.dart';
import 'package:flutter_test/flutter_test.dart';

int _ms(int y, int m, int d, [int h = 0]) =>
    DateTime.utc(y, m, d, h).millisecondsSinceEpoch;

void main() {
  group('tuần', () {
    test('tuần bắt đầu thứ Hai 00:00 UTC (2026-10-12 là thứ Hai)', () {
      expect(DateTime.utc(2026, 10, 12).weekday, DateTime.monday);
      final sun = weekIndex(_ms(2026, 10, 11, 23));
      final mon = weekIndex(_ms(2026, 10, 12));
      expect(mon, sun + 1);
      expect(weekIndex(_ms(2026, 10, 18, 23)), mon); // Chủ nhật cuối tuần
      expect(weekIndex(_ms(2026, 10, 19)), mon + 1);
    });

    test('đếm ngược tới thứ Hai kế tiếp', () {
      expect(weeklySecondsLeft(_ms(2026, 10, 18, 23)), 3600);
      expect(weeklySecondsLeft(_ms(2026, 10, 12)), 7 * 24 * 3600);
      expect(
        weeklySecondsLeft(_ms(2026, 10, 14, 12)),
        4 * 24 * 3600 + 12 * 3600,
      );
    });

    test(
      'mỗi tuần 3 loại khác nhau, xác định theo tuần, mọi loại đều xuất hiện',
      () {
        final seen = <WeeklyQuestKind>{};
        for (var w = 2900; w < 3100; w++) {
          final a = weeklyQuestsFor(w);
          expect(a.length, 3);
          expect(a.map((q) => q.kind).toSet().length, 3, reason: 'tuần $w');
          expect(weeklyQuestsFor(w).map((q) => q.kind), a.map((q) => q.kind));
          expect(a.every((q) => q.target > 0), isTrue);
          seen.addAll(a.map((q) => q.kind));
        }
        expect(seen, WeeklyQuestKind.values.toSet());
      },
    );
  });

  group('nhận thưởng', () {
    GameState week(int w) => GameState.newGame(nowMillis: 0)
      ..weeklyQuestWeek = w
      ..gems = 0;

    void finishAll(GameState s) {
      for (final q in currentWeeklyQuests(s)) {
        addWeeklyProgress(s, q.kind, q.target);
      }
    }

    test('chưa xong thì không nhận; xong nhận đúng một lần', () {
      final s = week(3000);
      expect(claimWeeklyQuest(s, 0), 0);
      final q = currentWeeklyQuests(s)[0];
      addWeeklyProgress(s, q.kind, q.target - 1);
      expect(claimWeeklyQuest(s, 0), 0);
      addWeeklyProgress(s, q.kind, 1);
      expect(weeklyClaimableCount(s), 1);
      expect(claimWeeklyQuest(s, 0), weeklyQuestRewardGems);
      expect(claimWeeklyQuest(s, 0), 0);
      expect(s.gems, weeklyQuestRewardGems.toDouble());
      expect(weeklyClaimableCount(s), 0);
    });

    test('index sai không làm gì', () {
      final s = week(3000);
      finishAll(s);
      expect(claimWeeklyQuest(s, -1), 0);
      expect(claimWeeklyQuest(s, 3), 0);
    });

    test('rương chỉ mở khi đã nhận đủ 3, và chỉ một lần', () {
      final s = week(3000);
      finishAll(s);
      expect(claimWeeklyChest(s), 0);
      for (var i = 0; i < 3; i++) {
        expect(weeklyChestAvailable(s), isFalse);
        claimWeeklyQuest(s, i);
      }
      expect(weeklyChestAvailable(s), isTrue);
      expect(weeklyClaimableCount(s), 1);
      expect(claimWeeklyChest(s), weeklyChestGems);
      expect(claimWeeklyChest(s), 0);
      expect(s.gems, (3 * weeklyQuestRewardGems + weeklyChestGems).toDouble());
    });

    test('sang tuần mới: đổi bộ, xoá tiến độ + cờ; cùng tuần thì giữ', () {
      final s = week(weekIndex(_ms(2026, 10, 12)));
      finishAll(s);
      claimWeeklyQuest(s, 0);
      expect(rollWeeklyQuests(s, _ms(2026, 10, 18, 23)), isFalse);
      expect(s.weeklyClaimed, isNotEmpty);
      expect(rollWeeklyQuests(s, _ms(2026, 10, 19)), isTrue);
      expect(s.weeklyProgress, isEmpty);
      expect(s.weeklyClaimed, isEmpty);
      expect(s.weeklyBonusClaimed, isFalse);
      expect(s.weeklyQuestWeek, weekIndex(_ms(2026, 10, 19)));
    });

    test('tiến độ chống số xấu (âm, NaN, vô cực)', () {
      final s = week(3000);
      for (final bad in [-5, 0, double.nan, double.infinity]) {
        addWeeklyProgress(s, WeeklyQuestKind.spin, bad);
      }
      expect(s.weeklyProgress, isEmpty);
    });
  });

  group('móc nối với nhiệm vụ ngày', () {
    test(
      'quay vòng quay + mua nâng cấp đẩy tiến độ tuần; loại khác thì không',
      () {
        final s = GameState.newGame(nowMillis: 0);
        addDailyProgress(s, DailyQuestKind.spin, 1);
        addDailyProgress(s, DailyQuestKind.buy, 7);
        addDailyProgress(s, DailyQuestKind.tap, 100);
        expect(s.weeklyProgress, {'spin': 1.0, 'buy': 7.0});
      },
    );

    test('nhận thưởng nhiệm vụ ngày tính vào dailyDone', () {
      final s = GameState.newGame(nowMillis: 0)..dailyQuestDay = 20000;
      final q = currentDailyQuests(s)[0];
      s.dailyProgress[q.kind.name] = q.target;
      expect(claimDailyQuest(s, 0), greaterThan(0));
      expect(s.weeklyProgress['dailyDone'], 1.0);
      expect(claimDailyQuest(s, 0), 0); // nhận lặp không đếm thêm
      expect(s.weeklyProgress['dailyDone'], 1.0);
    });
  });

  group('lưu', () {
    test('khứ hồi JSON giữ nguyên; save cũ thiếu trường → rỗng', () {
      final s = GameState.newGame(nowMillis: 0)
        ..weeklyQuestWeek = 3001
        ..weeklyBonusClaimed = true
        ..weeklyProgress['spin'] = 4
        ..weeklyClaimed.add('spin');
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect(back.weeklyQuestWeek, 3001);
      expect(back.weeklyBonusClaimed, isTrue);
      expect(back.weeklyProgress, {'spin': 4.0});
      expect(back.weeklyClaimed, ['spin']);

      final old = Map<String, dynamic>.from(s.toJson())
        ..remove('weeklyQuestWeek')
        ..remove('weeklyBonusClaimed')
        ..remove('weeklyProgress')
        ..remove('weeklyClaimed');
      final o = GameState.fromJson(old);
      expect(o.weeklyQuestWeek, 0);
      expect(o.weeklyProgress, isEmpty);
      expect(o.weeklyClaimed, isEmpty);
      expect(o.weeklyBonusClaimed, isFalse);
    });
  });
}
