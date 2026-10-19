/// Chi nhánh các thành phố: mở/nâng cấp chi nhánh bằng Xu, mỗi chi nhánh tự tích doanh thu (tối đa 8 giờ,
/// kể cả lúc offline) để bạn "thu" bất cứ lúc nào, thi thoảng gặp giờ cao điểm ×3. Mọi con số là ước lượng chưa playtest.
///
/// Doanh thu tính theo GIÂY THU NHẬP CỦA QUÁN CHÍNH (không phải số Xu cố định) và đổi ra Xu lúc thu — nên kinh tế
/// trải từ 1e2 tới 1e80 vẫn cân. Giá cũng tính theo giờ thu nhập tại lúc mua.
library;

import 'dart:math' as math;

/// Hiệu ứng signature của chi nhánh: mạnh dần theo cấp (đủ ở cấp 10), cộng dồn giữa các thành phố có cùng loại.
enum BranchPerk { cap, rush, collect, discount, rate }

/// Giá trị ở cấp tối đa của MỖI chi nhánh: cap = giờ cộng thêm vào kho; còn lại là tỉ lệ (0.03 = +3%).
const Map<BranchPerk, double> branchPerkMax = {
  BranchPerk.cap: 1.0,
  BranchPerk.rush: 0.03,
  BranchPerk.collect: 0.04,
  BranchPerk.discount: 0.03,
  BranchPerk.rate: 0.02,
};

class BranchCity {
  const BranchCity(
    this.id,
    this.emoji,
    this.signature,
    this.color,
    this.perk,
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

  /// Hiệu ứng signature (xem [BranchPerk]).
  final BranchPerk perk;

  /// Giai đoạn tối thiểu để MỞ chi nhánh (đã mở rồi thì giữ nguyên dù sau Nhượng quyền giai đoạn tụt).
  final int minStage;
  final double rateMult;
  final double costMult;
}

/// 17 chi nhánh, mở dần mỗi giai đoạn từ GĐ2 tới GĐ18 (id cũ giữ nguyên để không mất save).
const List<BranchCity> branchCities = [
  BranchCity('saigon', '🛵', '☕', 0xFFE57373, BranchPerk.rush, 2, 1.0, 1.0),
  BranchCity('danang', '🌉', '🥥', 0xFF4DB6AC, BranchPerk.cap, 3, 1.05, 1.25),
  BranchCity('hanoi', '🏮', '🍵', 0xFFFFB74D, BranchPerk.discount, 4, 1.1, 1.5),
  BranchCity(
    'singapore',
    '🦁',
    '🍹',
    0xFFF06292,
    BranchPerk.rate,
    5,
    1.15,
    1.8,
  ),
  BranchCity('tokyo', '🗼', '🍡', 0xFFBA68C8, BranchPerk.collect, 6, 1.2, 2.2),
  BranchCity('hongkong', '🏯', '🥧', 0xFFFF8A65, BranchPerk.rush, 7, 1.25, 2.6),
  BranchCity('seoul', '🎤', '🍓', 0xFF7986CB, BranchPerk.rate, 8, 1.3, 3.0),
  BranchCity('sydney', '🦘', '🥝', 0xFF4FC3F7, BranchPerk.cap, 9, 1.35, 3.5),
  BranchCity('bangkok', '🛕', '🍊', 0xFFFFD54F, BranchPerk.rush, 10, 1.4, 4.0),
  BranchCity(
    'istanbul',
    '🕌',
    '🍯',
    0xFF9575CD,
    BranchPerk.discount,
    11,
    1.45,
    4.7,
  ),
  BranchCity('paris', '🥐', '🍫', 0xFF90A4AE, BranchPerk.collect, 12, 1.5, 5.5),
  BranchCity('london', '🎡', '🍰', 0xFF81C784, BranchPerk.cap, 13, 1.55, 6.4),
  BranchCity('newyork', '🗽', '🥨', 0xFF64B5F6, BranchPerk.rush, 14, 1.6, 7.5),
  BranchCity('rio', '🎭', '🍍', 0xFF66BB6A, BranchPerk.discount, 15, 1.7, 8.7),
  BranchCity(
    'dubai',
    '🏙️',
    '🌴',
    0xFFFFCA28,
    BranchPerk.collect,
    16,
    1.8,
    10.0,
  ),
  BranchCity('cairo', '🏺', '🍋', 0xFFD4A24C, BranchPerk.cap, 17, 1.95, 12.0),
  BranchCity('moon', '🌙', '⭐', 0xFF5C6BC0, BranchPerk.rate, 18, 2.2, 15.0),
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

/// Tổng hiệu ứng [k] hiện có từ mọi chi nhánh đã mở (mỗi nơi: giá trị tối đa × cấp / [branchMaxLevel]).
double branchPerk(Map<String, int> levels, BranchPerk k) {
  var v = 0.0;
  for (final c in branchCities) {
    if (c.perk == k) {
      v += branchPerkMax[k]! * branchLevel(levels, c.id) / branchMaxLevel;
    }
  }
  return v;
}

/// Giá trị hiệu ứng của riêng [c] ở cấp [level].
double branchPerkValue(BranchCity c, int level) =>
    branchPerkMax[c.perk]! * level.clamp(0, branchMaxLevel) / branchMaxLevel;

/// Quản lý chi nhánh (thuê bằng 💎, theo ngày): tự thu mọi chi nhánh định kỳ khi mở app / khi quay lại,
/// và giữ kho tới 24 giờ khi bạn vắng. Mọi con số là ước lượng chưa playtest.
const int branchManagerGems = 120;
const int branchManagerDays = 7;
const int branchManagerMaxDays = 30;
const int branchManagerCapSeconds = 24 * 3600;

/// Khi đang mở app, quản lý tự thu mỗi chừng này giây.
const int branchManagerCollectEverySeconds = 600;

/// Trần kho (giây) thực tế: 8 giờ (24 giờ nếu có [manager]) + hiệu ứng "Kho chứa".
double branchCapFor(Map<String, int> levels, {bool manager = false}) =>
    (manager ? branchManagerCapSeconds : branchCapSeconds) +
    branchPerk(levels, BranchPerk.cap) * 3600;

int branchLevel(Map<String, int> levels, String id) =>
    (levels[id] ?? 0).clamp(0, branchMaxLevel);

/// Tỉ lệ thu nhập quán chính/giây mà chi nhánh [c] ở cấp [level] đem lại.
double branchRate(BranchCity c, int level) =>
    level <= 0 ? 0 : branchRatePerLevel * level * c.rateMult;

/// Giá lên cấp [level] (1-based) của [c] khi thu nhập quán chính là [incomePerSecond].
double branchCost(
  BranchCity c,
  int level,
  double incomePerSecond, {
  double discount = 0,
}) {
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
  final v = math.max(raw, floor) * (1 - discount.clamp(0.0, 0.9));
  return v.isFinite ? v : double.maxFinite;
}

/// Số giây đã tích (đã kẹp trần) của chi nhánh [c], nhân tỉ lệ → "giây thu nhập quán chính" chờ thu.
double branchPendingIncomeSeconds(
  Map<String, int> levels,
  Map<String, int> sinceMap,
  BranchCity c,
  int nowMillis, {
  bool manager = false,
}) {
  final lvl = branchLevel(levels, c.id);
  final since = sinceMap[c.id];
  if (lvl <= 0 || since == null) return 0;
  final elapsed = ((nowMillis - since) / 1000)
      .clamp(0, branchCapFor(levels, manager: manager))
      .toDouble();
  return elapsed * branchRate(c, lvl) * (1 + branchPerk(levels, BranchPerk.rate));
}

/// Chi nhánh đã đầy trần chưa (nhắc thu kẻo phí).
bool branchFull(
  Map<String, int> levels,
  Map<String, int> sinceMap,
  BranchCity c,
  int nowMillis, {
  bool manager = false,
}) {
  final since = sinceMap[c.id];
  return branchLevel(levels, c.id) > 0 &&
      since != null &&
      (nowMillis - since) / 1000 >= branchCapFor(levels, manager: manager);
}

/// Có chi nhánh nào tích ≥ [minSeconds] giây thu nhập quán chính (mặc định 5 phút) để thu không (chấm đỏ).
bool branchesReady(
  Map<String, int> levels,
  Map<String, int> since,
  int nowMillis, {
  double minSeconds = 300,
  bool manager = false,
}) => branchCities.any(
  (c) =>
      branchPendingIncomeSeconds(levels, since, c, nowMillis, manager: manager) >=
      minSeconds,
);

/// Chi nhánh tiếp theo có thể MỞ (chưa mở, đủ giai đoạn); null nếu không còn.
BranchCity? nextOpenableBranch(Map<String, int> levels, int stage) {
  for (final c in branchCities) {
    if (branchLevel(levels, c.id) == 0 && stage >= c.minStage) return c;
  }
  return null;
}

/// Kho của [c] đầy bao nhiêu (0..1) — theo thời gian đã tích so với trần kho.
double branchFill(
  Map<String, int> levels,
  Map<String, int> sinceMap,
  BranchCity c,
  int nowMillis, {
  bool manager = false,
}) {
  final since = sinceMap[c.id];
  if (branchLevel(levels, c.id) <= 0 || since == null) return 0;
  return ((nowMillis - since) / 1000 / branchCapFor(levels, manager: manager)).clamp(0.0, 1.0);
}

/// Bộ sưu tập theo châu lục: mở đủ chi nhánh trong bộ (mốc 1) / đưa tất cả lên cấp tối đa (mốc 2, thưởng ×2).
/// Mỗi mốc nhận MỘT lần. [id] 'all' = cả 17 nơi. Thưởng: 💎 + [seconds] giây thu nhập quán chính. Chưa playtest.
class BranchSet {
  const BranchSet(this.id, this.cityIds, this.gems, this.seconds);
  final String id;
  final List<String> cityIds;
  final int gems;
  final int seconds;
}

const List<BranchSet> branchSets = [
  BranchSet('asia', ['saigon', 'danang', 'hanoi', 'singapore', 'tokyo', 'hongkong', 'seoul', 'bangkok', 'dubai'], 120, 7200),
  BranchSet('europe', ['istanbul', 'paris', 'london'], 40, 3600),
  BranchSet('africa', ['cairo'], 15, 1800),
  BranchSet('northamerica', ['newyork'], 15, 1800),
  BranchSet('southamerica', ['rio'], 15, 1800),
  BranchSet('oceania', ['sydney'], 15, 1800),
  BranchSet('space', ['moon'], 30, 3600),
  BranchSet('all', [
    'saigon', 'danang', 'hanoi', 'singapore', 'tokyo', 'hongkong', 'seoul', 'sydney', 'bangkok', 'istanbul', 'paris', 'london',
    'newyork', 'rio', 'dubai', 'cairo', 'moon', //
  ], 200, 21600),
];

/// Khoá nhận thưởng lưu trong save: 'asia:1' (mở đủ), 'asia:2' (tối đa cấp).
String branchSetKey(BranchSet set, int tier) => '${set.id}:$tier';

/// Khoá hợp lệ (chống save hỏng/lạ).
bool isBranchSetKey(String k) =>
    branchSets.any((s) => k == branchSetKey(s, 1) || k == branchSetKey(s, 2));

/// Số chi nhánh của [set] đạt mốc [tier] (1: đã mở, 2: cấp tối đa).
int branchSetDone(Map<String, int> levels, BranchSet set, int tier) =>
    set.cityIds.where((id) => branchLevel(levels, id) >= (tier == 1 ? 1 : branchMaxLevel)).length;

bool branchSetComplete(Map<String, int> levels, BranchSet set, int tier) =>
    branchSetDone(levels, set, tier) == set.cityIds.length;

/// Thưởng mốc [tier] (mốc 2 gấp đôi).
({int gems, int seconds}) branchSetReward(BranchSet set, int tier) =>
    (gems: set.gems * tier, seconds: set.seconds * tier);

/// Các mốc đã đạt mà chưa nhận (chấm đỏ + nút Nhận).
List<String> branchSetsClaimable(Map<String, int> levels, Iterable<String> claimed) => [
      for (final set in branchSets)
        for (final tier in const [1, 2])
          if (branchSetComplete(levels, set, tier) && !claimed.contains(branchSetKey(set, tier))) branchSetKey(set, tier),
    ];

// ---- Chuyên ngành (cấp 10) ----
/// Ở cấp tối đa chọn 1 trong 2 chuyên ngành: 1 = Xuất khẩu (thu về +25% riêng chi nhánh đó),
/// 2 = Du lịch (+20% cơ hội giờ cao điểm riêng chi nhánh đó). Lần đầu miễn phí, đổi lại tốn 💎. Ước lượng chưa playtest.
const double branchSpecCollectBonus = 0.25;
const double branchSpecRushBonus = 0.20;
const int branchSpecRespecGems = 30;

// ---- Sự kiện chi nhánh ----
/// Mỗi [branchEventSlotSeconds] giây có 1 sự kiện ở 1 chi nhánh ĐÃ MỞ (chọn xác định theo ô thời gian, không cần server).
/// Loại sự kiện = thưởng giờ thu nhập (nhân (1 + cấp/10)). Nhận 1 lần/ô, qua ô là mất.
const int branchEventSlotSeconds = 3 * 3600;
const List<int> branchEventSeconds = [3600, 5400, 7200]; // 0 lễ hội, 1 đoàn khách, 2 ngôi sao
const List<String> branchEventEmoji = ['🎉', '🧳', '🎤'];

int branchEventSlot(int nowMillis) => nowMillis ~/ (branchEventSlotSeconds * 1000);

/// Sự kiện của ô [slot]: (cityId, type) hoặc null nếu chưa mở chi nhánh nào.
({String cityId, int type})? branchEventFor(Map<String, int> levels, int slot) {
  final open = [for (final c in branchCities) if (branchLevel(levels, c.id) > 0) c.id];
  if (open.isEmpty) return null;
  final h = ((slot * 2654435761) & 0x7fffffff) ^ (slot >> 3);
  return (cityId: open[h % open.length], type: (h ~/ 7) % 3);
}

/// Giây thu nhập thưởng của sự kiện loại [type] ở chi nhánh cấp [level].
double branchEventRewardSeconds(int type, int level) => branchEventSeconds[type] * (1 + level / 10);

// ---- Skin bản đồ ----
/// 0 cổ điển, 1 mùa đông, 2 Tết, 3 hoa anh đào. Chỉ đổi màu phủ + hạt trang trí.
const int branchMapSkinCount = 4;
