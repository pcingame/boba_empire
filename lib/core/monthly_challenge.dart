/// Thử thách tháng — 3 mục tiêu dài hơi cho người chơi lâu năm (tháng UTC), thưởng lớn + rương tháng.
/// Không thêm điểm hook: tiến độ = bộ đếm TÍCH LŨY có sẵn (chạm, nâng cấp, phụ kiện đã sưu tập) trừ mốc chụp
/// lúc sang tháng, nên chỉ cần `rollMonthlyChallenge` mỗi lần mở app. Các bộ đếm này không bao giờ giảm
/// (kể cả khi Nhượng quyền) và tự động chạm không tính (xem Balance.autoTapPerSecond). Mọi con số là ước lượng
/// chưa playtest. Hàm thuần; chỉ mutate [GameState] ở các hàm ghi rõ MUTATE.
library;

import 'models.dart';

enum MonthlyKind { tap, buy, collect }

const Map<MonthlyKind, int> monthlyTargets = {
  MonthlyKind.tap: 3000,
  MonthlyKind.buy: 1000,
  MonthlyKind.collect: 4,
};

const int monthlyQuestRewardGems = 150;
const int monthlyChestGems = 500;

/// Chỉ số tháng UTC (năm × 12 + tháng − 1).
int monthIndex(int nowMillis) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMillis, isUtc: true);
  return d.year * 12 + d.month - 1;
}

/// Giây còn lại tới 00:00 UTC ngày 1 tháng kế tiếp.
int monthlySecondsLeft(int nowMillis) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMillis, isUtc: true);
  return DateTime.utc(d.year, d.month + 1).millisecondsSinceEpoch ~/ 1000 - nowMillis ~/ 1000;
}

/// Giá trị tích lũy hiện tại của bộ đếm tương ứng [k].
double _current(GameState s, MonthlyKind k) => switch (k) {
      MonthlyKind.tap => s.tapCount.toDouble(),
      MonthlyKind.buy => s.buyCount.toDouble(),
      MonthlyKind.collect => (s.ownedAccessories.length + s.ownedLimited.length).toDouble(),
    };

int monthlyProgress(GameState s, MonthlyKind k) {
  final v = _current(s, k) - (s.monthlyBase[k.name] ?? 0);
  return v.isFinite && v > 0 ? v.floor() : 0;
}

bool monthlyDone(GameState s, MonthlyKind k) => monthlyProgress(s, k) >= monthlyTargets[k]!;
bool monthlyClaimed(GameState s, MonthlyKind k) => s.monthlyClaimed.contains(k.name);

/// Sang tháng mới (hoặc lần đầu có tính năng) thì chụp lại mốc, xoá cờ đã nhận. True nếu vừa đổi. MUTATE.
bool rollMonthlyChallenge(GameState s, int nowMillis) {
  final m = monthIndex(nowMillis);
  if (m == s.monthlyMonth) return false;
  s.monthlyMonth = m;
  s.monthlyBase
    ..clear()
    ..addEntries([for (final k in MonthlyKind.values) MapEntry(k.name, _current(s, k))]);
  s.monthlyClaimed.clear();
  s.monthlyChestClaimed = false;
  return true;
}

/// Nhận thưởng mục [k]: trả 💎 (0 nếu chưa xong/đã nhận). MUTATE.
int claimMonthly(GameState s, MonthlyKind k) {
  if (!monthlyDone(s, k) || monthlyClaimed(s, k)) return 0;
  s.monthlyClaimed.add(k.name);
  s.gems += monthlyQuestRewardGems;
  return monthlyQuestRewardGems;
}

bool monthlyChestAvailable(GameState s) =>
    !s.monthlyChestClaimed && MonthlyKind.values.every((k) => monthlyClaimed(s, k));

/// Mở rương tháng đúng một lần: +[monthlyChestGems] 💎 (phụ kiện do controller trao). 0 nếu chưa đủ điều kiện. MUTATE.
int claimMonthlyChest(GameState s) {
  if (!monthlyChestAvailable(s)) return 0;
  s.monthlyChestClaimed = true;
  s.gems += monthlyChestGems;
  return monthlyChestGems;
}

/// Số thứ đang chờ nhận (chấm đỏ).
int monthlyClaimableCount(GameState s) {
  var n = MonthlyKind.values.where((k) => monthlyDone(s, k) && !monthlyClaimed(s, k)).length;
  if (monthlyChestAvailable(s)) n++;
  return n;
}
