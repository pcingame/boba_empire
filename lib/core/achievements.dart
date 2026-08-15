/// Hệ thống Thành tựu — hàm thuần, mọi điều kiện suy ra từ [GameState] hiện có
/// (không cần đếm/persist thêm), chỉ lưu danh sách id đã nhận để chống trao trùng.
library;

import 'models.dart';

/// Chỉ số dùng để xét thành tựu (đều suy ra được từ state).
enum AchievementMetric { earn, stage, levels, prestige }

class Achievement {
  const Achievement(
    this.id,
    this.metric,
    this.threshold,
    this.rewardGems,
    this.emoji,
  );

  final String id;
  final AchievementMetric metric;
  final num threshold;
  final int rewardGems;
  final String emoji;
}

/// Danh sách thành tựu (tăng dần độ khó). Mô tả hiển thị dựng ở l10n_ext.
const List<Achievement> achievements = [
  Achievement('earn_1k', AchievementMetric.earn, 1000, 5, '💰'),
  Achievement('earn_1m', AchievementMetric.earn, 1000000, 15, '💰'),
  Achievement('earn_1b', AchievementMetric.earn, 1000000000, 40, '💰'),
  Achievement('levels_50', AchievementMetric.levels, 50, 10, '⬆️'),
  Achievement('levels_200', AchievementMetric.levels, 200, 30, '⬆️'),
  Achievement('stage_2', AchievementMetric.stage, 2, 10, '🏬'),
  Achievement('stage_3', AchievementMetric.stage, 3, 25, '🏢'),
  Achievement('stage_4', AchievementMetric.stage, 4, 40, '🏭'),
  Achievement('stage_5', AchievementMetric.stage, 5, 70, '🏙️'),
  Achievement('stage_6', AchievementMetric.stage, 6, 120, '🌍'),
  Achievement('prestige_1', AchievementMetric.prestige, 1, 20, '⭐'),
];

/// Giá trị hiện tại của một [metric] trên [s].
num achievementProgress(GameState s, AchievementMetric metric) => switch (metric) {
      AchievementMetric.earn => s.lifetimeEarnings,
      AchievementMetric.stage => s.stage,
      AchievementMetric.levels =>
        s.levels.values.fold<int>(0, (a, b) => a + b),
      AchievementMetric.prestige => s.prestigeStars,
    };

/// Đã đạt điều kiện thành tựu chưa.
bool achievementDone(GameState s, Achievement a) =>
    achievementProgress(s, a.metric) >= a.threshold;

bool achievementClaimed(GameState s, Achievement a) =>
    s.achievementsClaimed.contains(a.id);

/// Trao mọi thành tựu vừa đạt mà chưa nhận: cộng gems + ghi vào claimed. Trả về
/// danh sách thành tựu vừa mở khoá (để UI báo). MUTATE [s].
List<Achievement> grantNewAchievements(GameState s) {
  final newly = <Achievement>[];
  for (final a in achievements) {
    if (!achievementClaimed(s, a) && achievementDone(s, a)) {
      s.achievementsClaimed.add(a.id);
      s.gems += a.rewardGems;
      newly.add(a);
    }
  }
  return newly;
}
