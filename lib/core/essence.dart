/// 🧪 Tinh chất (kiếm từ trò nhỏ) và "Bí quyết" (tiêu Tinh chất để tăng thu nhập theo giai đoạn).
/// Hàm thuần trên [GameState] — lý do thiết kế và con số: PROPOSAL_ESSENCE_MASTERY.md.
library;

import 'balance.dart';
import 'models.dart';

/// Số bậc Bí quyết đang có ở [stage], kẹp trong [0, masteryMaxTier] (dữ liệu hỏng/lạ không vượt trần).
int masteryTier(Map<int, int> tiers, int stage) =>
    (tiers[stage] ?? 0).clamp(0, Balance.masteryMaxTier);

/// Hệ số nhân thu nhập của các nguồn thuộc [stage]: 1 + bậc × [Balance.masteryPerTier] ∈ [1, 1.4].
double masteryMultiplier(Map<int, int> tiers, int stage) =>
    1 + masteryTier(tiers, stage) * Balance.masteryPerTier;

/// Giá nâng lên bậc kế tiếp từ [tier] hiện có; null nếu đã đầy.
int? masteryNextCost(int tier) =>
    tier >= Balance.masteryMaxTier || tier < 0 ? null : Balance.masteryTierCosts[tier];

/// Mua một bậc Bí quyết ở [stage]. False nếu giai đoạn không tồn tại, đã đầy bậc hoặc thiếu Tinh chất.
bool buyMastery(GameState s, int stage) {
  if (stage < 1 || stage > Balance.stages.length) return false;
  final cost = masteryNextCost(masteryTier(s.masteryTiers, stage));
  if (cost == null || s.essence < cost) return false;
  s.essence -= cost;
  s.masteryTiers[stage] = masteryTier(s.masteryTiers, stage) + 1;
  return true;
}

/// Tổng Tinh chất đã kiếm được (đang có + đã tiêu vào Bí quyết) — thước đo tiến độ để so hai save.
int essenceProgress({required int essence, required Map<int, int> tiers}) {
  var spent = 0;
  for (final t in tiers.values) {
    final tier = t.clamp(0, Balance.masteryMaxTier);
    for (var i = 0; i < tier; i++) {
      spent += Balance.masteryTierCosts[i];
    }
  }
  return essence + spent;
}

/// Cùng thước đo, đọc từ JSON save (cloud) — thiếu/sai kiểu thì tính là 0.
int essenceProgressFromJson(Map<String, dynamic> json) {
  final e = json['essence'];
  final m = json['masteryTiers'];
  return essenceProgress(
    essence: e is num ? e.toInt() : 0,
    tiers: {
      if (m is Map)
        for (final entry in m.entries)
          if (int.tryParse('${entry.key}') != null && entry.value is num)
            int.parse('${entry.key}'): (entry.value as num).toInt(),
    },
  );
}

/// Đưa bộ đếm trong ngày về 0 khi sang ngày mới ([today] = dayIndex UTC).
void _rollDay(GameState s, int today) {
  if (s.essenceDay == today) return;
  s.essenceDay = today;
  s.essenceOrdersToday = 0;
  s.essenceRepeatableToday = 0;
}

/// Cộng Tinh chất nguồn MỘT-LẦN (bậc Công thức, sao Ghép 3): không trần ngày vì tự giới hạn tổng đời.
int grantEssenceOnce(GameState s, int amount) {
  if (amount <= 0) return 0;
  s.essence += amount;
  return amount;
}

/// Cộng Tinh chất cho đơn Pha theo đơn: kẹp theo cả trần riêng của đơn lẫn trần chung. Trả số thực cộng.
int grantEssenceOrder(GameState s, int today, int amount) {
  if (amount <= 0) return 0;
  _rollDay(s, today);
  final room = [
    amount,
    Balance.essenceOrdersDailyCap - s.essenceOrdersToday,
    Balance.essenceRepeatableDailyCap - s.essenceRepeatableToday,
  ].reduce((a, b) => a < b ? a : b);
  if (room <= 0) return 0;
  s.essenceOrdersToday += room;
  s.essenceRepeatableToday += room;
  s.essence += room;
  return room;
}

/// Cộng Tinh chất cho Thử thách ngày hoặc phần nhân đôi bằng QC: chỉ chịu trần chung. Trả số thực cộng.
int grantEssenceRepeatable(GameState s, int today, int amount) {
  if (amount <= 0) return 0;
  _rollDay(s, today);
  final room = Balance.essenceRepeatableDailyCap - s.essenceRepeatableToday;
  final granted = amount < room ? amount : room;
  if (granted <= 0) return 0;
  s.essenceRepeatableToday += granted;
  s.essence += granted;
  return granted;
}
