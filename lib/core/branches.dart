/// Chi nhánh các thành phố: mở/nâng cấp chi nhánh bằng Xu, mỗi chi nhánh tự tích doanh thu (tối đa 8 giờ,
/// kể cả lúc offline) để bạn "thu" bất cứ lúc nào, thi thoảng gặp giờ cao điểm ×3. Mọi con số là ước lượng chưa playtest.
///
/// Doanh thu tính theo GIÂY THU NHẬP CỦA QUÁN CHÍNH (không phải số Xu cố định) và đổi ra Xu lúc thu — nên kinh tế
/// trải từ 1e2 tới 1e80 vẫn cân. Giá cũng tính theo giờ thu nhập tại lúc mua.
library;

import 'dart:math' as math;

class BranchCity {
  const BranchCity(
    this.id,
    this.emoji,
    this.signature,
    this.color,
    this.minStage,
    this.rateMult,
    this.costMult,
  );
  final String id;

  /// Biểu tượng thành phố (landmark) — hiện lớn trên thẻ.
  final String emoji;

  /// Biểu tượng "signature" của chi nhánh: món đặc trưng của vùng, hiện làm huy hiệu nhỏ cạnh landmark.
  final String signature;

  /// Màu chủ đạo (ARGB) của thẻ chi nhánh.
  final int color;

  /// Giai đoạn tối thiểu để MỞ chi nhánh (đã mở rồi thì giữ nguyên dù sau Nhượng quyền giai đoạn tụt).
  final int minStage;
  final double rateMult;
  final double costMult;
}

/// 17 chi nhánh, mở dần mỗi giai đoạn từ GĐ2 tới GĐ18 (id cũ giữ nguyên để không mất save).
const List<BranchCity> branchCities = [
  BranchCity('saigon', '🛵', '☕', 0xFFE57373, 2, 1.0, 1.0),
  BranchCity('danang', '🌉', '🥥', 0xFF4DB6AC, 3, 1.05, 1.25),
  BranchCity('hanoi', '🏮', '🍵', 0xFFFFB74D, 4, 1.1, 1.5),
  BranchCity('singapore', '🦁', '🍹', 0xFFF06292, 5, 1.15, 1.8),
  BranchCity('tokyo', '🗼', '🍡', 0xFFBA68C8, 6, 1.2, 2.2),
  BranchCity('hongkong', '🏯', '🥧', 0xFFFF8A65, 7, 1.25, 2.6),
  BranchCity('seoul', '🎤', '🍓', 0xFF7986CB, 8, 1.3, 3.0),
  BranchCity('sydney', '🦘', '🥝', 0xFF4FC3F7, 9, 1.35, 3.5),
  BranchCity('bangkok', '🛕', '🍊', 0xFFFFD54F, 10, 1.4, 4.0),
  BranchCity('istanbul', '🕌', '🍯', 0xFF9575CD, 11, 1.45, 4.7),
  BranchCity('paris', '🥐', '🍫', 0xFF90A4AE, 12, 1.5, 5.5),
  BranchCity('london', '🎡', '🍰', 0xFF81C784, 13, 1.55, 6.4),
  BranchCity('newyork', '🗽', '🥨', 0xFF64B5F6, 14, 1.6, 7.5),
  BranchCity('rio', '🎭', '🍍', 0xFF66BB6A, 15, 1.7, 8.7),
  BranchCity('dubai', '🏙️', '🌴', 0xFFFFCA28, 16, 1.8, 10.0),
  BranchCity('cairo', '🏺', '🍋', 0xFFD4A24C, 17, 1.95, 12.0),
  BranchCity('moon', '🌙', '⭐', 0xFF5C6BC0, 18, 2.2, 15.0),
];

BranchCity? branchCityById(String id) {
  for (final c in branchCities) {
    if (c.id == id) return c;
  }
  return null;
}

const int branchMaxLevel = 10;

/// Doanh thu tích tối đa (giây) — như trần offline: quên thu vài ngày cũng chỉ mất phần vượt 8 giờ.
const int branchCapSeconds = 8 * 3600;

/// Mỗi cấp thêm 1.2% thu nhập quán chính mỗi giây (× hệ số thành phố).
const double branchRatePerLevel = 0.012;

/// Giá cấp 1 = 0.5 giờ thu nhập; mỗi cấp sau ×1.4 (× hệ số thành phố). Sàn cho người mới thu nhập rất nhỏ.
const double branchCostHours = 0.5;
const double branchCostGrowth = 1.4;
const double branchCostFloor = 1000;

/// Giờ cao điểm: xác suất mỗi lần thu một chi nhánh, và hệ số.
const double branchRushChance = 0.15;
const int branchRushMult = 3;

/// Lễ khai trương (mở chi nhánh lần đầu): tặng ngay ngần này giây thu nhập.
const int branchGalaSeconds = 1800;

int branchLevel(Map<String, int> levels, String id) =>
    (levels[id] ?? 0).clamp(0, branchMaxLevel);

/// Tỉ lệ thu nhập quán chính/giây mà chi nhánh [c] ở cấp [level] đem lại.
double branchRate(BranchCity c, int level) =>
    level <= 0 ? 0 : branchRatePerLevel * level * c.rateMult;

/// Giá lên cấp [level] (1-based) của [c] khi thu nhập quán chính là [incomePerSecond].
double branchCost(BranchCity c, int level, double incomePerSecond) {
  final inc = incomePerSecond.isFinite && incomePerSecond > 0
      ? incomePerSecond
      : 0.0;
  final raw =
      inc *
      3600 *
      branchCostHours *
      math.pow(branchCostGrowth, level - 1) *
      c.costMult;
  final floor =
      branchCostFloor * math.pow(branchCostGrowth, level - 1) * c.costMult;
  final v = math.max(raw, floor);
  return v.isFinite ? v : double.maxFinite;
}

/// Số giây đã tích (đã kẹp trần) của chi nhánh [c], nhân tỉ lệ → "giây thu nhập quán chính" chờ thu.
double branchPendingIncomeSeconds(
  Map<String, int> levels,
  Map<String, int> sinceMap,
  BranchCity c,
  int nowMillis,
) {
  final lvl = branchLevel(levels, c.id);
  final since = sinceMap[c.id];
  if (lvl <= 0 || since == null) return 0;
  final elapsed = ((nowMillis - since) / 1000)
      .clamp(0, branchCapSeconds)
      .toDouble();
  return elapsed * branchRate(c, lvl);
}

/// Chi nhánh đã đầy trần chưa (nhắc thu kẻo phí).
bool branchFull(
  Map<String, int> levels,
  Map<String, int> sinceMap,
  BranchCity c,
  int nowMillis,
) {
  final since = sinceMap[c.id];
  return branchLevel(levels, c.id) > 0 &&
      since != null &&
      (nowMillis - since) / 1000 >= branchCapSeconds;
}

/// Có chi nhánh nào tích ≥ [minSeconds] giây thu nhập quán chính (mặc định 5 phút) để thu không (chấm đỏ).
bool branchesReady(
  Map<String, int> levels,
  Map<String, int> since,
  int nowMillis, {
  double minSeconds = 300,
}) => branchCities.any(
  (c) => branchPendingIncomeSeconds(levels, since, c, nowMillis) >= minSeconds,
);

/// Chi nhánh tiếp theo có thể MỞ (chưa mở, đủ giai đoạn); null nếu không còn.
BranchCity? nextOpenableBranch(Map<String, int> levels, int stage) {
  for (final c in branchCities) {
    if (branchLevel(levels, c.id) == 0 && stage >= c.minStage) return c;
  }
  return null;
}
