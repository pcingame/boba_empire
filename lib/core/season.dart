/// Thẻ Mùa: mùa 28 ngày (UTC, neo theo `dayIndex ~/ 28`), 30 bậc × 100 XP. XP đến từ các hoạt động có sẵn
/// (nhiệm vụ, trò nhỏ, Phó bản, Đấu Trường…) có trần [seasonXpDailyCap]/ngày để không cày. Mỗi bậc có thưởng
/// MIỄN PHÍ; mua "đường Cao cấp" bằng 💎 ([seasonPremiumGems]) mở thêm thưởng thứ hai. Sang mùa mới tiến độ và
/// quyền Cao cấp reset (thưởng chưa nhận mất). Mọi con số là ước lượng chưa playtest: tổng 💎 của đường Cao cấp
/// cố ý NHỎ HƠN giá mua — người chơi trả 💎 để lấy phụ kiện/Tinh chất, không phải để lãi 💎.
library;

import 'accessories.dart';
import 'daily.dart' show dayIndex;
import 'models.dart';

const int seasonLengthDays = 28;
const int seasonTiers = 30;
const int seasonXpPerTier = 100;
const int seasonXpDailyCap = 150;
const int seasonPremiumGems = 600;

/// Nguồn XP và lượng mỗi lần.
enum SeasonSource {
  login(10),
  dailyQuest(10),
  dailyBonus(30),
  challengeBonus(20),
  weeklyQuest(40),
  weeklyChest(60),
  recipe(15),
  match3(15),
  arena(15),
  dungeon(40);

  const SeasonSource(this.xp);
  final int xp;
}

int seasonIdFor(int nowMillis) => dayIndex(nowMillis) ~/ seasonLengthDays;

/// Số ngày còn lại của mùa (tính cả hôm nay, tối thiểu 1).
int seasonDaysLeft(int nowMillis) => seasonLengthDays - dayIndex(nowMillis) % seasonLengthDays;

/// Sang mùa mới thì xoá tiến độ. MUTATE. Gọi trước mọi đọc/ghi Thẻ Mùa.
void seasonSync(GameState s, int nowMillis) {
  final id = seasonIdFor(nowMillis);
  if (s.seasonId == id) return;
  s.seasonId = id;
  s.seasonXp = 0;
  s.seasonPremium = false;
  s.seasonFreeClaimed.clear();
  s.seasonPremiumClaimed.clear();
  s.seasonXpToday = 0;
  s.seasonXpDay = 0;
}

/// Cộng XP từ [src] (kẹp theo trần ngày). Trả XP thực nhận. MUTATE.
int seasonEarn(GameState s, SeasonSource src, int nowMillis) {
  seasonSync(s, nowMillis);
  final today = dayIndex(nowMillis);
  if (s.seasonXpDay != today) {
    s.seasonXpDay = today;
    s.seasonXpToday = 0;
  }
  final room = seasonXpDailyCap - s.seasonXpToday;
  final gain = room < src.xp ? (room < 0 ? 0 : room) : src.xp;
  s.seasonXpToday += gain;
  s.seasonXp += gain;
  return gain;
}

/// Bậc đã đạt (0..[seasonTiers]).
int seasonTier(GameState s) {
  final t = s.seasonXp ~/ seasonXpPerTier;
  return t > seasonTiers ? seasonTiers : t;
}

/// Phụ kiện ĐỘC QUYỀN theo mùa: mỗi mùa 1 món Sử thi (bậc 20 đường miễn phí) + 1 món Huyền thoại (bậc 30 đường Cao cấp).
/// Vòng 4 mùa (`seasonId % 4`) nên mỗi món quay lại sau 112 ngày. Thuộc nhóm độc quyền (như lễ hội/Hội/VIP): KHÔNG tính vào
/// bộ sưu tập chính, không đăng bán ở Chợ; trùng → đổi 💎 (xem [grantFestivalItem]).
class SeasonItems {
  const SeasonItems(this.free, this.premium);
  final Accessory free;
  final Accessory premium;
}

const List<SeasonItems> seasonItemCycle = [
  SeasonItems(Accessory('season_sakura', AccessoryRarity.epic, '🌸'),
      Accessory('season_paper_lantern', AccessoryRarity.legendary, '🎋')),
  SeasonItems(Accessory('season_sunflower', AccessoryRarity.epic, '🌻'),
      Accessory('season_island', AccessoryRarity.legendary, '🏝️')),
  SeasonItems(Accessory('season_autumn_leaf', AccessoryRarity.epic, '🍂'),
      Accessory('season_moon_view', AccessoryRarity.legendary, '🎑')),
  SeasonItems(Accessory('season_snowflake', AccessoryRarity.epic, '❄️'),
      Accessory('season_mountain', AccessoryRarity.legendary, '🏔️')),
];

SeasonItems seasonItemsFor(int seasonId) => seasonItemCycle[seasonId % seasonItemCycle.length];

/// Mọi món độc quyền theo mùa (cho Kho + `limitedAccessories`).
List<Accessory> get seasonAccessories => [for (final i in seasonItemCycle) ...[i.free, i.premium]];

/// Thưởng một bậc: 💎 + (tuỳ chọn) 1 phụ kiện từ độ hiếm [accessory] trở lên + Tinh chất; [exclusive] = món độc quyền của mùa.
class SeasonReward {
  const SeasonReward({this.gems = 0, this.accessory, this.essence = 0, this.exclusive = false});
  final int gems;
  final AccessoryRarity? accessory;
  final int essence;
  final bool exclusive;
}

/// Thưởng miễn phí của bậc [tier] (1..30).
SeasonReward seasonFreeReward(int tier) => SeasonReward(
      gems: tier == seasonTiers ? 50 : 5,
      accessory: switch (tier) {
        5 || 15 || 25 => AccessoryRarity.common,
        10 => AccessoryRarity.rare,
        30 => AccessoryRarity.epic,
        _ => null,
      },
      exclusive: tier == 20, // món Sử thi độc quyền của mùa
      essence: tier % 6 == 0 && tier != seasonTiers ? 20 : 0,
    );

/// Thưởng đường Cao cấp của bậc [tier] (1..30). Bậc cuối: món HUYỀN THOẠI độc quyền của mùa.
SeasonReward seasonPremiumReward(int tier) => SeasonReward(
      gems: 8 + (tier % 10 == 0 ? 40 : 0),
      accessory: switch (tier) {
        5 || 10 => AccessoryRarity.rare,
        15 || 20 || 25 => AccessoryRarity.epic,
        _ => null,
      },
      exclusive: tier == seasonTiers, // món Huyền thoại độc quyền của mùa
      essence: tier % 3 == 0 ? 20 : 0,
    );

bool seasonCanClaim(GameState s, int tier, {required bool premium}) {
  if (tier < 1 || tier > seasonTiers || seasonTier(s) < tier) return false;
  if (premium && !s.seasonPremium) return false;
  return !(premium ? s.seasonPremiumClaimed : s.seasonFreeClaimed).contains(tier);
}

/// Số bậc đang nhận được (chấm đỏ).
int seasonClaimable(GameState s) {
  var n = 0;
  for (var t = 1; t <= seasonTier(s); t++) {
    if (seasonCanClaim(s, t, premium: false)) n++;
    if (seasonCanClaim(s, t, premium: true)) n++;
  }
  return n;
}

/// Thước đo tiến độ Thẻ Mùa từ JSON save (để so máy ↔ cloud): XP + 1000 nếu đã mua Cao cấp + 10 mỗi bậc đã nhận.
/// Thiếu/sai kiểu = 0. Chỉ có nghĩa khi hai save CÙNG mùa — xem [seasonIdFromJson].
int seasonProgressFromJson(Map<String, dynamic> json) {
  int n(Object? v) => v is num ? v.toInt() : 0;
  int len(Object? v) => v is List ? v.length : 0;
  return n(json['seasonXp']).clamp(0, 1 << 30) +
      (json['seasonPremium'] == true ? 1000 : 0) +
      10 * (len(json['seasonFreeClaimed']) + len(json['seasonPremiumClaimed']));
}

int seasonIdFromJson(Map<String, dynamic> json) => json['seasonId'] is num ? (json['seasonId'] as num).toInt() : 0;
