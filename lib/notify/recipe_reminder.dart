/// Lập kế hoạch nhắc ôn công thức (thuần, không đụng plugin thông báo — test được).
///
/// Một lần nhắc duy nhất lúc 20:00 giờ máy (hôm nay nếu còn ≥ 1 giờ nữa, không thì ngày mai):
///  - Chuỗi ôn ≥ 2 ngày sẽ đứt nếu hôm đó không ôn → "chuỗi sắp mất";
///  - nếu không, có món đã học đến hạn ôn → "N món đến hạn".
/// Người chưa từng luyện (chưa có món nào trong bản lưu) KHÔNG bị nhắc — không làm phiền người chưa chơi.
library;

import '../core/daily.dart' show dayIndex;
import '../core/recipe_mastery.dart';

enum RecipeReminderKind { streak, due }

class RecipeReminderPlan {
  const RecipeReminderPlan(this.at, this.kind, this.n);

  /// Thời điểm nhắc (UTC).
  final DateTime at;
  final RecipeReminderKind kind;

  /// Số ngày chuỗi (kind = streak) hoặc số món đến hạn (kind = due).
  final int n;
}

/// 20:00 giờ máy kế tiếp cách [now] ít nhất 1 giờ.
DateTime nextRecipeEvening(DateTime now) {
  final local = now.toLocal();
  var t = DateTime(local.year, local.month, local.day, 20);
  if (!t.isAfter(local.add(const Duration(hours: 1)))) t = DateTime(local.year, local.month, local.day + 1, 20);
  return t.toUtc();
}

RecipeReminderPlan? planRecipeReminder({
  required DateTime now,
  required RecipeStreak streak,
  required Map<int, RecipeProgress> progress,
}) {
  if (progress.isEmpty) return null; // chưa từng luyện
  final at = nextRecipeEvening(now);
  final day = dayIndex(at.millisecondsSinceEpoch);
  if (streak.days >= 2 && streak.lastDay == day - 1) {
    return RecipeReminderPlan(at, RecipeReminderKind.streak, streak.days);
  }
  final due = progress.values.where((p) => p.dueDay <= day).length;
  return due > 0 ? RecipeReminderPlan(at, RecipeReminderKind.due, due) : null;
}
