/// Nhiệm vụ hằng ngày — 3 nhiệm vụ/ngày, chọn XÁC ĐỊNH theo ngày (UTC, cùng quy
/// ước `daily.dart`) nên kill/mở lại app không đổi bộ. Hàm thuần: thời gian bơm
/// từ ngoài, chỉ mutate [GameState] ở các hàm ghi rõ MUTATE.
///
/// Tiến độ nằm ở [GameState.dailyProgress] (khoá = `DailyQuestKind.name`), được
/// cộng ngay tại nơi sự kiện xảy ra (xem game_controller.dart và `_credit`).
library;

import 'dart:math';

import 'balance.dart';
import 'daily.dart' show dayIndex;
import 'models.dart';

enum DailyQuestKind { tap, buy, earn, cat, vip, spin }

class DailyQuest {
  const DailyQuest(this.kind, this.target, this.rewardGems);

  final DailyQuestKind kind;

  /// Số cần đạt. Với [DailyQuestKind.earn] là số Xu (đã chốt lúc sang ngày).
  final double target;
  final int rewardGems;
}

/// Bộ 3 nhiệm vụ của ngày [day]. [earnTarget] chỉ ảnh hưởng ngưỡng "Kiếm Xu",
/// KHÔNG ảnh hưởng việc chọn loại nào (cùng ngày luôn cùng bộ loại).
List<DailyQuest> dailyQuestsFor(int day, double earnTarget) {
  final rng = Random(day * 2654435761 ^ 0x5bd1e995);
  final kinds = [...DailyQuestKind.values]..shuffle(rng);
  final chosen = kinds.take(Balance.dailyQuestCount);
  // Rút các số ngẫu nhiên theo thứ tự cố định để kết quả không phụ thuộc loại nào
  // được chọn trước.
  final tapTarget = 100 + rng.nextInt(3) * 100; // 100..300
  final buyTarget = 10 + rng.nextInt(4) * 10; // 10..40
  return [
    for (final k in chosen)
      switch (k) {
        DailyQuestKind.tap =>
          DailyQuest(k, tapTarget.toDouble(), Balance.dailyQuestRewardGems),
        DailyQuestKind.buy =>
          DailyQuest(k, buyTarget.toDouble(), Balance.dailyQuestRewardGems),
        DailyQuestKind.earn => DailyQuest(
            k,
            max(earnTarget, Balance.dailyEarnMinTarget),
            Balance.dailyQuestEarnRewardGems),
        DailyQuestKind.cat ||
        DailyQuestKind.vip ||
        DailyQuestKind.spin =>
          DailyQuest(k, 1, Balance.dailyQuestRewardGems),
      },
  ];
}

List<DailyQuest> currentDailyQuests(GameState s) =>
    dailyQuestsFor(s.dailyQuestDay, s.dailyEarnTarget);

double dailyQuestProgress(GameState s, DailyQuestKind k) =>
    s.dailyProgress[k.name] ?? 0;

bool dailyQuestDone(GameState s, DailyQuest q) =>
    dailyQuestProgress(s, q.kind) >= q.target;

bool dailyQuestClaimed(GameState s, DailyQuest q) =>
    s.dailyClaimed.contains(q.kind.name);

/// Cộng tiến độ [n] cho loại [k]. Cộng cho MỌI loại kể cả loại không nằm trong bộ
/// hôm nay (rẻ, và đơn giản hơn phải tra bộ ở mọi điểm hook). MUTATE.
void addDailyProgress(GameState s, DailyQuestKind k, double n) {
  if (n <= 0 || !n.isFinite) return;
  final v = (s.dailyProgress[k.name] ?? 0) + n;
  if (v.isFinite) s.dailyProgress[k.name] = v;
}

/// Sang ngày mới thì đổi bộ: xoá tiến độ + cờ đã nhận, chốt ngưỡng "Kiếm Xu" theo
/// thu nhập lúc này (~30 phút thu nhập; cố định cả ngày dù thu nhập tăng sau đó
/// — kinh tế trải từ ~1e2 tới ~1e80 nên ngưỡng cố định sẽ vô nghĩa). Trả về true
/// nếu vừa đổi ngày. MUTATE.
bool rollDailyQuests(GameState s, int nowMillis, double incomePerSecond) {
  final today = dayIndex(nowMillis);
  if (today == s.dailyQuestDay) return false;
  s.dailyQuestDay = today;
  s.dailyProgress.clear();
  s.dailyClaimed.clear();
  s.dailyBonusClaimed = false;
  final t = incomePerSecond * Balance.dailyEarnIncomeSeconds;
  s.dailyEarnTarget = t.isFinite && t > 0 ? t : 0;
  return true;
}

/// Nhận thưởng nhiệm vụ thứ [index]. Trả về 💎 nhận (0 nếu chưa xong/đã nhận/index
/// sai). MUTATE.
int claimDailyQuest(GameState s, int index) {
  final list = currentDailyQuests(s);
  if (index < 0 || index >= list.length) return 0;
  final q = list[index];
  if (!dailyQuestDone(s, q) || dailyQuestClaimed(s, q)) return 0;
  s.dailyClaimed.add(q.kind.name);
  s.dailyQuestEverClaimed = true;
  s.gems += q.rewardGems;
  return q.rewardGems;
}

/// Xong và đã nhận cả bộ, chưa nhận thưởng thêm.
bool dailyBonusAvailable(GameState s) =>
    !s.dailyBonusClaimed &&
    currentDailyQuests(s).every((q) => dailyQuestClaimed(s, q));

/// Nhận thưởng "xong cả 3" đúng một lần. Trả về 💎 (0 nếu chưa đủ điều kiện). MUTATE.
int claimDailyQuestBonus(GameState s) {
  if (!dailyBonusAvailable(s)) return 0;
  s.dailyBonusClaimed = true;
  s.gems += Balance.dailyQuestBonusGems;
  return Balance.dailyQuestBonusGems;
}

/// Số thứ đang chờ nhận (để hiện chấm đỏ): nhiệm vụ xong chưa nhận + bonus.
int dailyClaimableCount(GameState s) {
  var n = 0;
  for (final q in currentDailyQuests(s)) {
    if (dailyQuestDone(s, q) && !dailyQuestClaimed(s, q)) n++;
  }
  if (dailyBonusAvailable(s)) n++;
  return n;
}
