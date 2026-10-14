// Kế hoạch nhắc ôn công thức: một lần lúc 20:00 giờ máy; chuỗi sắp mất ưu tiên hơn món đến hạn; người chưa luyện không bị nhắc.
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/recipe_mastery.dart';
import 'package:boba_empire/notify/recipe_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

int _dayOf(DateTime utc) => dayIndex(utc.millisecondsSinceEpoch);

void main() {
  const some = {1: RecipeProgress(box: 1, dueDay: 0, best: 1)};

  group('nextRecipeEvening', () {
    test('trước 19:00 giờ máy → 20:00 hôm nay; từ 19:00 trở đi → 20:00 ngày mai', () {
      expect(nextRecipeEvening(DateTime(2026, 10, 14, 9)), DateTime(2026, 10, 14, 20).toUtc());
      expect(nextRecipeEvening(DateTime(2026, 10, 14, 18, 59)), DateTime(2026, 10, 14, 20).toUtc());
      expect(nextRecipeEvening(DateTime(2026, 10, 14, 19)), DateTime(2026, 10, 15, 20).toUtc()); // đúng 1 giờ: không đủ
      expect(nextRecipeEvening(DateTime(2026, 10, 14, 23, 30)), DateTime(2026, 10, 15, 20).toUtc());
    });

    test('luôn ở tương lai ít nhất 1 giờ', () {
      for (var h = 0; h < 24; h++) {
        final now = DateTime(2026, 10, 14, h, 17);
        expect(nextRecipeEvening(now).difference(now.toUtc()), greaterThan(const Duration(hours: 1)));
      }
    });
  });

  group('planRecipeReminder', () {
    final now = DateTime(2026, 10, 14, 10);
    final day = _dayOf(nextRecipeEvening(now));

    test('chưa từng luyện (không có món nào trong bản lưu) → không nhắc, kể cả có chuỗi', () {
      expect(planRecipeReminder(now: now, streak: RecipeStreak(days: 5, lastDay: day - 1, best: 5), progress: {}), isNull);
    });

    test('chuỗi ≥ 2 mà hôm nhắc chưa ôn (lần ôn cuối là hôm trước) → nhắc "chuỗi sắp mất" kèm số ngày', () {
      final p = planRecipeReminder(
          now: now, streak: RecipeStreak(days: 4, lastDay: day - 1, best: 4), progress: some)!;
      expect((p.kind, p.n), (RecipeReminderKind.streak, 4));
      expect(p.at, nextRecipeEvening(now));
    });

    test('chuỗi đã ôn đúng hôm nhắc, hoặc đã đứt từ trước, hoặc chỉ 1 ngày → không nhắc chuỗi', () {
      // Ôn hôm nhắc: không nguy cơ → rơi về "món đến hạn" nếu có.
      final reviewed = planRecipeReminder(
          now: now, streak: RecipeStreak(days: 4, lastDay: day, best: 4), progress: {1: RecipeProgress(dueDay: day + 100)});
      expect(reviewed, isNull);
      final lost = planRecipeReminder(
          now: now, streak: RecipeStreak(days: 4, lastDay: day - 3, best: 4), progress: {1: RecipeProgress(dueDay: day + 100)});
      expect(lost, isNull);
      final one = planRecipeReminder(
          now: now, streak: RecipeStreak(days: 1, lastDay: day - 1, best: 1), progress: {1: RecipeProgress(dueDay: day + 100)});
      expect(one, isNull);
    });

    test('không có chuỗi nguy cơ nhưng có món đến hạn vào hôm nhắc → nhắc "N món đến hạn" (đếm đúng)', () {
      final progress = {
        1: RecipeProgress(box: 1, dueDay: day, best: 1), // đến hạn đúng hôm đó
        2: RecipeProgress(box: 1, dueDay: day - 5, best: 1), // quá hạn
        3: RecipeProgress(box: 2, dueDay: day + 1, best: 2), // chưa
      };
      final p = planRecipeReminder(now: now, streak: const RecipeStreak(), progress: progress)!;
      expect((p.kind, p.n), (RecipeReminderKind.due, 2));
    });

    test('chuỗi nguy cơ ưu tiên hơn món đến hạn', () {
      final p = planRecipeReminder(
          now: now,
          streak: RecipeStreak(days: 3, lastDay: day - 1, best: 3),
          progress: {1: RecipeProgress(dueDay: day - 1)})!;
      expect(p.kind, RecipeReminderKind.streak);
    });

    test('không có gì đến hạn → không nhắc', () {
      expect(planRecipeReminder(now: now, streak: const RecipeStreak(), progress: {1: RecipeProgress(dueDay: day + 3)}), isNull);
    });
  });
}
