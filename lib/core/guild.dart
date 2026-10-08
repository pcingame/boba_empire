/// Hội (Guild): điểm đóng góp TUẦN + mốc thưởng. Phần server ở
/// supabase/guild_schema.sql — các hằng số dưới đây PHẢI khớp (test
/// test/guild/guild_sql_test.dart so khớp). Hàm thuần: thời gian bơm từ ngoài.
library;

import 'daily.dart' show dayIndex;
import 'daily_quests.dart' show DailyQuestKind;
import 'models.dart';

const int guildMaxMembers = 30;

/// Phí tạo hội (💎). Trừ SAU khi server tạo thành công; vào hội thì miễn phí.
const int guildCreateCostGems = 2000; // ⚠️ chưa playtest

/// Điểm cá nhân tối thiểu trong tuần để được nhận thưởng mốc (chống ăn theo).
const int guildMinPointsToClaim = 300;

class GuildMilestone {
  const GuildMilestone(this.threshold, this.gems, {this.accessory = false});

  /// Tổng điểm CẢ HỘI trong tuần.
  final int threshold;
  final int gems;

  /// Mốc cuối còn thưởng thêm 1 phụ kiện ngẫu nhiên.
  final bool accessory;
}

/// Chỉ số 0-based của mốc = số `p_milestone - 1` ở server.
const List<GuildMilestone> guildMilestones = [
  GuildMilestone(10000, 20),
  GuildMilestone(40000, 40),
  GuildMilestone(120000, 60, accessory: true),
];

/// Tuần tính từ thứ Hai 00:00 UTC (khớp `date_trunc('week')` của Postgres).
/// 1970-01-05 (ngày epoch số 4) là thứ Hai.
int guildWeekIndex(int nowMillis) => (dayIndex(nowMillis) - 4) ~/ 7;

/// Điểm hoạt động của [n] lượt [k]: chạm 1, mèo/VIP 50, loại khác 0. CÙNG công
/// thức `eventScoreOf` (event_quests.dart) — cố ý không tính "Nâng cấp" (xem ghi
/// chú ở đó).
double guildActivityPoints(DailyQuestKind k, double n) => switch (k) {
      DailyQuestKind.tap => n,
      DailyQuestKind.cat || DailyQuestKind.vip => 50 * n,
      _ => 0,
    };

/// Cộng điểm tuần (gọi từ addDailyProgress). MUTATE.
void addGuildProgress(GameState s, DailyQuestKind k, double n) {
  final v = s.guildWeekScore + guildActivityPoints(k, n);
  if (v.isFinite) s.guildWeekScore = v;
}

/// Sang tuần mới thì xoá điểm tuần. Trả true nếu vừa đổi tuần. MUTATE.
bool rollGuildWeek(GameState s, int nowMillis) {
  final w = guildWeekIndex(nowMillis);
  if (w == s.guildWeek) return false;
  s.guildWeek = w;
  s.guildWeekScore = 0;
  return true;
}

int guildScore(GameState s) =>
    s.guildWeekScore.isFinite ? s.guildWeekScore.floor() : 0;
