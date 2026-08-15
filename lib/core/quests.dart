/// Chuỗi nhiệm vụ ngắn, tuần tự — dẫn dắt người chơi qua các mốc nhỏ. Hàm thuần;
/// tiến độ suy từ [GameState] (có thêm tapCount/buyCount), chỉ persist questIndex.
library;

import 'models.dart';

enum QuestMetric { tap, buy, earn, levels, stage, prestige }

class Quest {
  const Quest(this.metric, this.threshold, this.rewardGems);

  final QuestMetric metric;
  final num threshold;
  final int rewardGems;
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

/// Nhiệm vụ hiện tại (null nếu đã xong hết chuỗi).
Quest? currentQuest(GameState s) =>
    s.questIndex < quests.length ? quests[s.questIndex] : null;

/// Nhiệm vụ hiện tại đã đủ điều kiện để nhận chưa.
bool currentQuestDone(GameState s) {
  final q = currentQuest(s);
  return q != null && questProgress(s, q.metric) >= q.threshold;
}

/// Nhận thưởng nhiệm vụ hiện tại nếu đã đạt: cộng gems + sang nhiệm vụ kế. Trả
/// về gems nhận (0 nếu chưa đạt / hết chuỗi). MUTATE [s].
int claimQuest(GameState s) {
  if (!currentQuestDone(s)) return 0;
  final gems = quests[s.questIndex].rewardGems;
  s.gems += gems;
  s.questIndex += 1;
  return gems;
}
