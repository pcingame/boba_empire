/// Chuỗi nhiệm vụ ngắn, tuần tự — dẫn dắt người chơi qua các mốc nhỏ. Hàm thuần;
/// tiến độ suy từ [GameState] (có thêm tapCount/buyCount), chỉ persist questIndex.
library;

import 'dart:math';

import 'balance.dart';
import 'models.dart';

enum QuestMetric { tap, buy, earn, levels, stage, prestige }

class Quest {
  const Quest(this.metric, this.threshold, this.rewardGems,
      {this.repeatable = false});

  final QuestMetric metric;
  final num threshold;
  final int rewardGems;

  /// Nhiệm vụ "kiếm THÊM" thuộc vùng lặp lại (sau chuỗi 10 bước) — tiến độ đếm
  /// từ [GameState.repeatQuestBaseline] chứ không từ 0.
  final bool repeatable;
}

/// Chuỗi nhiệm vụ (làm theo thứ tự). Đầu game nhỏ & nhanh, sau tăng dần.
const List<Quest> quests = [
  Quest(QuestMetric.tap, 25, 5),
  Quest(QuestMetric.buy, 3, 5),
  Quest(QuestMetric.earn, 1000, 8),
  Quest(QuestMetric.levels, 15, 8),
  Quest(QuestMetric.stage, 2, 15),
  Quest(QuestMetric.buy, 25, 10),
  Quest(QuestMetric.earn, 100000, 15),
  Quest(QuestMetric.levels, 60, 20),
  Quest(QuestMetric.prestige, 1, 25),
  Quest(QuestMetric.earn, 10000000, 40),
];

num questProgress(GameState s, QuestMetric metric) => switch (metric) {
      QuestMetric.tap => s.tapCount,
      QuestMetric.buy => s.buyCount,
      QuestMetric.earn => s.lifetimeEarnings,
      QuestMetric.levels => s.levels.values.fold<int>(0, (a, b) => a + b),
      QuestMetric.stage => s.stage,
      QuestMetric.prestige => s.prestigeStars,
    };

/// Nhiệm vụ LẶP LẠI thứ [cycle] (0, 1, 2…): "kiếm thêm base·10^cycle Xu".
///
/// PHẢI dùng `10.0` (double): `pow(10, cycle)` với 2 số nguyên trả về INT 64-bit
/// và tràn im lặng — từ vòng 19 ngưỡng thành số âm/sai, từ vòng 64 thành đúng 0
/// ("Kiếm thêm 0 Xu", nhận thưởng vô hạn). Kẹp ở trần kinh tế để không thành
/// Infinity (hiển thị "0" và so sánh sai).
Quest _repeatQuest(int cycle) => Quest(
      QuestMetric.earn,
      min(Balance.questRepeatBaseEarn * pow(10.0, cycle),
          Balance.economyOverflowGuardCap),
      Balance.questRepeatRewardGems,
      repeatable: true,
    );

/// Vòng lặp CAO NHẤT mà một người chơi đã kiếm được [lifetime] Xu có thể đang ở:
/// để xong vòng 0..n-1 cần tổng base·(10^n − 1)/9 Xu, nên đang ở vòng n khi
/// tổng đó ≤ lifetime < tổng cho vòng n+1.
int maxLegitRepeatCycle(double lifetime) {
  if (!lifetime.isFinite || lifetime <= 0) return 0;
  var n = 0;
  var sum = 0.0;
  while (n < 400) {
    final t = min(Balance.questRepeatBaseEarn * pow(10.0, n),
        Balance.economyOverflowGuardCap);
    if (sum + t > lifetime) return n;
    sum += t;
    n++;
  }
  return n;
}

/// Sửa save đã bị đẩy lên vòng nhiệm vụ lặp CAO HƠN mức kiếm được (lỗi tràn
/// `pow(10, cycle)` từng cho nhận thưởng vô hạn — xem int-pow-overflow-quest-zero):
/// đưa về đúng vòng theo tổng Xu đã kiếm và tính "kiếm thêm" lại từ 0. Save hợp
/// lệ không đổi (vòng của họ luôn <= [maxLegitRepeatCycle]). Trả true nếu đã sửa.
bool sanitizeRepeatQuest(GameState s) {
  if (s.questIndex < quests.length) return false;
  final cycle = s.questIndex - quests.length;
  final legit = maxLegitRepeatCycle(s.lifetimeEarnings);
  if (cycle <= legit) return false;
  s.questIndex = quests.length + legit;
  s.repeatQuestBaseline = s.lifetimeEarnings;
  return true;
}

/// Nhiệm vụ hiện tại. Sau chuỗi 10 bước → chuỗi "kiếm thêm" vô hạn.
Quest currentQuest(GameState s) => s.questIndex < quests.length
    ? quests[s.questIndex]
    : _repeatQuest(s.questIndex - quests.length);

/// Tiến độ nhiệm vụ hiện tại (nhiệm vụ lặp đếm "kiếm thêm" từ baseline).
num currentQuestProgress(GameState s) {
  final q = currentQuest(s);
  if (q.repeatable) return s.lifetimeEarnings - s.repeatQuestBaseline;
  return questProgress(s, q.metric);
}

/// Nhiệm vụ hiện tại đã đủ điều kiện để nhận chưa.
bool currentQuestDone(GameState s) =>
    currentQuestProgress(s) >= currentQuest(s).threshold;

/// Nhận thưởng nhiệm vụ hiện tại nếu đã đạt: cộng gems + sang nhiệm vụ kế. Trả
/// về gems nhận (0 nếu chưa đạt). MUTATE [s].
int claimQuest(GameState s) {
  if (!currentQuestDone(s)) return 0;
  final gems = currentQuest(s).rewardGems;
  s.gems += gems;
  s.questIndex += 1;
  // Vào/tiến trong vùng lặp → chốt mốc để nhiệm vụ kế đếm "kiếm thêm" từ 0.
  if (s.questIndex >= quests.length) {
    s.repeatQuestBaseline = s.lifetimeEarnings;
  }
  return gems;
}
