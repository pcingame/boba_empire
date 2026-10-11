/// Nhiệm vụ tuần — 3 mục tiêu lớn mỗi tuần (tuần bắt đầu thứ Hai 00:00 UTC), chọn XÁC ĐỊNH theo
/// tuần như nhiệm vụ ngày. Xong và nhận cả bộ thì mở rương (💎 + 1 phụ kiện, phụ kiện do controller
/// trao). Hàm thuần; thời gian bơm từ ngoài. Tiến độ cộng ngay tại nơi sự kiện xảy ra.
library;

import 'dart:math';

import 'daily.dart' show dayIndex;
import 'daily_quests.dart' show DailyQuestKind;
import 'models.dart';

enum WeeklyQuestKind { prestige, m3Win, trade, dailyDone, spin, buy }

class WeeklyQuest {
  const WeeklyQuest(this.kind, this.target);
  final WeeklyQuestKind kind;
  final int target;

  int get rewardGems => weeklyQuestRewardGems;
}

const int weeklyQuestCount = 3;
const int weeklyQuestRewardGems = 50;
const int weeklyChestGems = 150;

const Map<WeeklyQuestKind, int> _targets = {
  WeeklyQuestKind.prestige: 2,
  WeeklyQuestKind.m3Win: 5,
  WeeklyQuestKind.trade: 3,
  WeeklyQuestKind.dailyDone: 5,
  WeeklyQuestKind.spin: 10,
  WeeklyQuestKind.buy: 300,
};

/// Chỉ số tuần (thứ Hai là ngày đầu: 1970-01-01 là thứ Năm nên lệch 3 ngày).
int weekIndex(int nowMillis) => (dayIndex(nowMillis) + 3) ~/ 7;

/// Giây còn lại tới 00:00 UTC thứ Hai kế tiếp.
int weeklySecondsLeft(int nowMillis) {
  const msPerDay = 24 * 60 * 60 * 1000;
  final nextWeekStartDay = (weekIndex(nowMillis) + 1) * 7 - 3;
  return ((nextWeekStartDay * msPerDay - nowMillis) / 1000).ceil();
}

List<WeeklyQuest> weeklyQuestsFor(int week) {
  final kinds = [...WeeklyQuestKind.values]
    ..shuffle(Random(week * 2246822519 ^ 0x27d4eb2f));
  return [
    for (final k in kinds.take(weeklyQuestCount)) WeeklyQuest(k, _targets[k]!),
  ];
}

List<WeeklyQuest> currentWeeklyQuests(GameState s) =>
    weeklyQuestsFor(s.weeklyQuestWeek);

int weeklyQuestProgress(GameState s, WeeklyQuestKind k) =>
    (s.weeklyProgress[k.name] ?? 0).floor();

bool weeklyQuestDone(GameState s, WeeklyQuest q) =>
    weeklyQuestProgress(s, q.kind) >= q.target;

bool weeklyQuestClaimed(GameState s, WeeklyQuest q) =>
    s.weeklyClaimed.contains(q.kind.name);

/// Cộng tiến độ [n] cho loại [k]. MUTATE.
void addWeeklyProgress(GameState s, WeeklyQuestKind k, num n) {
  if (n <= 0 || !n.isFinite) return;
  final v = (s.weeklyProgress[k.name] ?? 0) + n;
  if (v.isFinite) s.weeklyProgress[k.name] = v.toDouble();
}

/// Nhiệm vụ ngày nào cũng đẩy luôn tiến độ tuần tương ứng (dùng chung điểm hook của
/// `addDailyProgress`). Loại không liên quan thì bỏ qua. MUTATE.
void addWeeklyFromDaily(GameState s, DailyQuestKind k, double n) {
  switch (k) {
    case DailyQuestKind.spin:
      addWeeklyProgress(s, WeeklyQuestKind.spin, n);
    case DailyQuestKind.buy:
      addWeeklyProgress(s, WeeklyQuestKind.buy, n);
    default:
  }
}

/// Sang tuần mới thì đổi bộ, xoá tiến độ + cờ đã nhận. True nếu vừa đổi tuần. MUTATE.
bool rollWeeklyQuests(GameState s, int nowMillis) {
  final w = weekIndex(nowMillis);
  if (w == s.weeklyQuestWeek) return false;
  s.weeklyQuestWeek = w;
  s.weeklyProgress.clear();
  s.weeklyClaimed.clear();
  s.weeklyBonusClaimed = false;
  return true;
}

/// Nhận thưởng nhiệm vụ thứ [index]. Trả về 💎 (0 nếu chưa xong/đã nhận/index sai). MUTATE.
int claimWeeklyQuest(GameState s, int index) {
  final list = currentWeeklyQuests(s);
  if (index < 0 || index >= list.length) return 0;
  final q = list[index];
  if (!weeklyQuestDone(s, q) || weeklyQuestClaimed(s, q)) return 0;
  s.weeklyClaimed.add(q.kind.name);
  s.gems += q.rewardGems;
  return q.rewardGems;
}

/// Đã nhận cả bộ, chưa mở rương.
bool weeklyChestAvailable(GameState s) =>
    !s.weeklyBonusClaimed &&
    currentWeeklyQuests(s).every((q) => weeklyQuestClaimed(s, q));

/// Mở rương tuần đúng một lần: +[weeklyChestGems] 💎 (phụ kiện do controller trao). 0 nếu chưa đủ
/// điều kiện. MUTATE.
int claimWeeklyChest(GameState s) {
  if (!weeklyChestAvailable(s)) return 0;
  s.weeklyBonusClaimed = true;
  s.gems += weeklyChestGems;
  return weeklyChestGems;
}

/// Số thứ đang chờ nhận (chấm đỏ): nhiệm vụ xong chưa nhận + rương.
int weeklyClaimableCount(GameState s) {
  var n = 0;
  for (final q in currentWeeklyQuests(s)) {
    if (weeklyQuestDone(s, q) && !weeklyQuestClaimed(s, q)) n++;
  }
  if (weeklyChestAvailable(s)) n++;
  return n;
}
