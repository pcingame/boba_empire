// Lõi Hội: tuần thứ Hai UTC, cộng điểm từ nhiệm vụ, reset tuần, lưu JSON.
import 'package:boba_empire/core/daily_quests.dart';
import 'package:boba_empire/core/event_quests.dart';
import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

int _ms(DateTime d) => d.millisecondsSinceEpoch;

void main() {
  group('guildWeekIndex', () {
    test('đổi tuần ĐÚNG lúc 00:00 UTC thứ Hai (khớp date_trunc(week) Postgres)',
        () {
      final mon = DateTime.utc(2026, 10, 5); // thứ Hai
      expect(mon.weekday, DateTime.monday);
      final w = guildWeekIndex(_ms(mon));
      expect(guildWeekIndex(_ms(mon.subtract(const Duration(milliseconds: 1)))),
          w - 1);
      expect(guildWeekIndex(_ms(DateTime.utc(2026, 10, 11, 23, 59, 59))), w);
      expect(guildWeekIndex(_ms(DateTime.utc(2026, 10, 12))), w + 1);
    });

    test('quét 3 năm: chỉ tăng đúng vào ngày thứ Hai, mỗi tuần tăng đúng 1', () {
      var prev = guildWeekIndex(_ms(DateTime.utc(2026, 1, 1)));
      for (var d = DateTime.utc(2026, 1, 2);
          d.isBefore(DateTime.utc(2029, 1, 1));
          d = d.add(const Duration(days: 1))) {
        final w = guildWeekIndex(_ms(d));
        if (d.weekday == DateTime.monday) {
          expect(w, prev + 1, reason: '$d');
        } else {
          expect(w, prev, reason: '$d');
        }
        prev = w;
      }
    });
  });

  group('điểm hoạt động', () {
    final s = GameState.newGame(nowMillis: 0);
    test('chạm 1, mèo/VIP 50, loại khác 0', () {
      expect(guildActivityPoints(DailyQuestKind.tap, 3), 3);
      expect(guildActivityPoints(DailyQuestKind.cat, 2), 100);
      expect(guildActivityPoints(DailyQuestKind.vip, 1), 50);
      for (final k in [DailyQuestKind.buy, DailyQuestKind.spin, DailyQuestKind.earn]) {
        expect(guildActivityPoints(k, 99), 0, reason: k.name);
      }
    });

    test('mirror từ addDailyProgress (không cần hook thêm)', () {
      addDailyProgress(s, DailyQuestKind.tap, 10);
      addDailyProgress(s, DailyQuestKind.cat, 1);
      addDailyProgress(s, DailyQuestKind.buy, 500);
      expect(guildScore(s), 60);
    });

    test('CÙNG công thức với điểm sự kiện (eventScoreOf)', () {
      final g = GameState.newGame(nowMillis: 0);
      final progress = <String, double>{};
      void both(DailyQuestKind k, double n) {
        addGuildProgress(g, k, n);
        progress[k.name] = (progress[k.name] ?? 0) + n;
      }

      both(DailyQuestKind.tap, 123);
      both(DailyQuestKind.cat, 4);
      both(DailyQuestKind.vip, 7);
      both(DailyQuestKind.buy, 1000);
      expect(guildScore(g), eventScoreOf(progress));
    });

    test('số hỏng (Infinity/NaN) không làm hỏng điểm tuần', () {
      final g = GameState.newGame(nowMillis: 0);
      addGuildProgress(g, DailyQuestKind.tap, 5);
      addGuildProgress(g, DailyQuestKind.tap, double.infinity);
      addGuildProgress(g, DailyQuestKind.tap, double.nan);
      expect(guildScore(g), 5);
      g.guildWeekScore = double.nan;
      expect(guildScore(g), 0);
    });
  });

  test('rollGuildWeek: reset khi sang tuần, giữ nguyên trong cùng tuần', () {
    final g = GameState.newGame(nowMillis: 0);
    final mon = _ms(DateTime.utc(2026, 10, 5));
    expect(rollGuildWeek(g, mon), isTrue); // tuần đầu tiên so với mặc định
    g.guildWeekScore = 700;
    expect(rollGuildWeek(g, mon + 3 * 86400000), isFalse); // cùng tuần
    expect(g.guildWeekScore, 700);
    expect(rollGuildWeek(g, mon + 7 * 86400000), isTrue); // tuần sau
    expect(g.guildWeekScore, 0);
  });

  test('lưu/đọc JSON giữ tuần và điểm; save cũ (thiếu field) → 0', () {
    final g = GameState.newGame(nowMillis: 0)
      ..guildWeek = 2900
      ..guildWeekScore = 1234;
    final r = GameState.fromJson(g.toJson());
    expect((r.guildWeek, r.guildWeekScore), (2900, 1234));
    final old = g.toJson()
      ..remove('guildWeek')
      ..remove('guildWeekScore');
    final o = GameState.fromJson(old);
    expect((o.guildWeek, o.guildWeekScore), (0, 0));
  });

  test('mốc thưởng: tăng dần, chỉ mốc cuối có phụ kiện, thưởng dương', () {
    expect(guildMilestones.length, 3);
    for (var i = 1; i < guildMilestones.length; i++) {
      expect(guildMilestones[i].threshold,
          greaterThan(guildMilestones[i - 1].threshold));
    }
    expect(guildMilestones.map((m) => m.accessory), [false, false, true]);
    expect(guildMilestones.every((m) => m.gems > 0), isTrue);
  });
}
