/// Phụ kiện sưu tập (2026-10-01) — cosmetic thuần, không ảnh hưởng số liệu.
/// Rớt ngẫu nhiên khi nhận thưởng "xong cả 3 nhiệm vụ ngày" (xem
/// claimDailyQuestBonus trong game_controller.dart). Tên hiển thị ở l10n_ext
/// (cùng khuôn achievements.dart) — file này chỉ giữ id + emoji + độ hiếm.
library;

import 'dart:math';

import 'balance.dart';
import 'guild_shop.dart' show guildAccessories;
import 'daily.dart' show dayIndex;
import 'models.dart';

enum AccessoryRarity { common, rare, epic, legendary }

class Accessory {
  const Accessory(this.id, this.rarity, this.emoji);

  final String id;
  final AccessoryRarity rarity;
  final String emoji;
}

/// 160 món, chia theo độ hiếm (75 thường · 46 hiếm · 30 sử thi · 9 huyền
/// thoại). Mô tả hiển thị dựng ở l10n_ext (accessoryName). Nâng số món thì
/// PHẢI nâng trần CHECK `owned_count` trong accessory_leaderboard_schema.sql
/// trước (xem ghi chú trong file đó).
const List<Accessory> accessories = [
  Accessory('mint_leaf', AccessoryRarity.common, '🌿'),
  Accessory('cupcake', AccessoryRarity.common, '🧁'),
  Accessory('cookie', AccessoryRarity.common, '🍪'),
  Accessory('potted_plant', AccessoryRarity.common, '🪴'),
  Accessory('candle', AccessoryRarity.common, '🕯️'),
  Accessory('scarf', AccessoryRarity.common, '🧣'),
  Accessory('kite', AccessoryRarity.common, '🪁'),
  Accessory('cap', AccessoryRarity.common, '🧢'),
  Accessory('balloon', AccessoryRarity.common, '🎈'),
  Accessory('bowtie', AccessoryRarity.common, '🎀'),
  Accessory('sunglasses', AccessoryRarity.common, '🕶️'),
  Accessory('umbrella', AccessoryRarity.common, '☂️'),
  Accessory('teapot', AccessoryRarity.common, '🫖'),
  Accessory('bell', AccessoryRarity.common, '🔔'),
  Accessory('ribbon', AccessoryRarity.common, '🎗️'),
  Accessory('bookmark', AccessoryRarity.common, '🔖'),
  Accessory('wind_chime', AccessoryRarity.common, '🎐'),
  Accessory('clover', AccessoryRarity.common, '🍀'),
  Accessory('bubble', AccessoryRarity.common, '🫧'),
  Accessory('sticker', AccessoryRarity.common, '🏷️'),
  Accessory('yarn', AccessoryRarity.common, '🧶'),
  Accessory('fan', AccessoryRarity.common, '🪭'),
  Accessory('basket', AccessoryRarity.common, '🧺'),
  Accessory('bead', AccessoryRarity.common, '📿'),
  Accessory('ladybug', AccessoryRarity.common, '🐞'),
  Accessory('donut', AccessoryRarity.common, '🍩'),
  Accessory('lollipop', AccessoryRarity.common, '🍭'),
  Accessory('pretzel', AccessoryRarity.common, '🥨'),
  Accessory('ice_cream', AccessoryRarity.common, '🍦'),
  Accessory('strawberry', AccessoryRarity.common, '🍓'),
  Accessory('cherry', AccessoryRarity.common, '🍒'),
  Accessory('lemon', AccessoryRarity.common, '🍋'),
  Accessory('peach', AccessoryRarity.common, '🍑'),
  Accessory('popcorn', AccessoryRarity.common, '🍿'),
  Accessory('honey_pot', AccessoryRarity.common, '🍯'),
  Accessory('milk_glass', AccessoryRarity.common, '🥛'),
  Accessory('tangerine', AccessoryRarity.common, '🍊'),
  Accessory('chestnut', AccessoryRarity.common, '🌰'),
  Accessory('maple_leaf', AccessoryRarity.common, '🍁'),
  Accessory('ice_cube', AccessoryRarity.common, '🧊'),
  Accessory('croissant', AccessoryRarity.common, '🥐'),
  Accessory('pancakes', AccessoryRarity.common, '🥞'),
  Accessory('waffle', AccessoryRarity.common, '🧇'),
  Accessory('bagel', AccessoryRarity.common, '🥯'),
  Accessory('cake_slice', AccessoryRarity.common, '🍰'),
  Accessory('pie', AccessoryRarity.common, '🥧'),
  Accessory('candy', AccessoryRarity.common, '🍬'),
  Accessory('grapes', AccessoryRarity.common, '🍇'),
  Accessory('watermelon', AccessoryRarity.common, '🍉'),
  Accessory('pineapple', AccessoryRarity.common, '🍍'),
  Accessory('mango', AccessoryRarity.common, '🥭'),
  Accessory('kiwi', AccessoryRarity.common, '🥝'),
  Accessory('banana', AccessoryRarity.common, '🍌'),
  Accessory('apple', AccessoryRarity.common, '🍎'),
  Accessory('teddy', AccessoryRarity.common, '🧸'),
  Accessory('crayon', AccessoryRarity.common, '🖍️'),
  Accessory('bucket', AccessoryRarity.common, '🪣'),
  Accessory('carrot', AccessoryRarity.common, '🥕'),
  Accessory('corn', AccessoryRarity.common, '🌽'),
  Accessory('tomato', AccessoryRarity.common, '🍅'),
  Accessory('avocado', AccessoryRarity.common, '🥑'),
  Accessory('coconut', AccessoryRarity.common, '🥥'),
  Accessory('blueberries', AccessoryRarity.common, '🫐'),
  Accessory('pear', AccessoryRarity.common, '🍐'),
  Accessory('rice_ball', AccessoryRarity.common, '🍙'),
  Accessory('dumpling', AccessoryRarity.common, '🥟'),
  Accessory('sushi', AccessoryRarity.common, '🍣'),
  Accessory('ramen', AccessoryRarity.common, '🍜'),
  Accessory('taco', AccessoryRarity.common, '🌮'),
  Accessory('pizza', AccessoryRarity.common, '🍕'),
  Accessory('hot_dog', AccessoryRarity.common, '🌭'),
  Accessory('fries', AccessoryRarity.common, '🍟'),
  Accessory('egg', AccessoryRarity.common, '🥚'),
  Accessory('bread', AccessoryRarity.common, '🍞'),
  Accessory('butter', AccessoryRarity.common, '🧈'),
  Accessory('seashell', AccessoryRarity.rare, '🐚'),
  Accessory('mask', AccessoryRarity.rare, '🎭'),
  Accessory('drum', AccessoryRarity.rare, '🪘'),
  Accessory('palette', AccessoryRarity.rare, '🎨'),
  Accessory('key', AccessoryRarity.rare, '🗝️'),
  Accessory('diamond_stone', AccessoryRarity.rare, '💠'),
  Accessory('music_note', AccessoryRarity.rare, '🎵'),
  Accessory('telescope', AccessoryRarity.rare, '🔭'),
  Accessory('anchor', AccessoryRarity.rare, '⚓'),
  Accessory('feather', AccessoryRarity.rare, '🪶'),
  Accessory('hourglass', AccessoryRarity.rare, '⏳'),
  Accessory('map', AccessoryRarity.rare, '🗺️'),
  Accessory('ring', AccessoryRarity.rare, '💍'),
  Accessory('compass', AccessoryRarity.rare, '🧭'),
  Accessory('rocket', AccessoryRarity.rare, '🚀'),
  Accessory('violin', AccessoryRarity.rare, '🎻'),
  Accessory('scroll', AccessoryRarity.rare, '📜'),
  Accessory('microphone', AccessoryRarity.rare, '🎙️'),
  Accessory('lotus', AccessoryRarity.rare, '🪷'),
  Accessory('jellyfish', AccessoryRarity.rare, '🪼'),
  Accessory('camera', AccessoryRarity.rare, '📷'),
  Accessory('shield', AccessoryRarity.rare, '🛡️'),
  Accessory('guitar', AccessoryRarity.rare, '🎸'),
  Accessory('trumpet', AccessoryRarity.rare, '🎺'),
  Accessory('piano', AccessoryRarity.rare, '🎹'),
  Accessory('saxophone', AccessoryRarity.rare, '🎷'),
  Accessory('banjo', AccessoryRarity.rare, '🪕'),
  Accessory('microscope', AccessoryRarity.rare, '🔬'),
  Accessory('ringed_planet', AccessoryRarity.rare, '🪐'),
  Accessory('crescent_moon', AccessoryRarity.rare, '🌙'),
  Accessory('bow_arrow', AccessoryRarity.rare, '🏹'),
  Accessory('mirror', AccessoryRarity.rare, '🪞'),
  Accessory('ferris_wheel', AccessoryRarity.rare, '🎡'),
  Accessory('carousel', AccessoryRarity.rare, '🎠'),
  Accessory('puzzle', AccessoryRarity.rare, '🧩'),
  Accessory('dice', AccessoryRarity.rare, '🎲'),
  Accessory('chess_pawn', AccessoryRarity.rare, '♟️'),
  Accessory('dart', AccessoryRarity.rare, '🎯'),
  Accessory('bowling', AccessoryRarity.rare, '🎳'),
  Accessory('yo_yo', AccessoryRarity.rare, '🪀'),
  Accessory('roller_skate', AccessoryRarity.rare, '🛼'),
  Accessory('skateboard', AccessoryRarity.rare, '🛹'),
  Accessory('satellite', AccessoryRarity.rare, '🛰️'),
  Accessory('alembic', AccessoryRarity.rare, '⚗️'),
  Accessory('dna', AccessoryRarity.rare, '🧬'),
  Accessory('trophy', AccessoryRarity.rare, '🏆'),
  Accessory('crystal_ball', AccessoryRarity.epic, '🔮'),
  Accessory('lantern', AccessoryRarity.epic, '🏮'),
  Accessory('unicorn', AccessoryRarity.epic, '🦄'),
  Accessory('magic_wand', AccessoryRarity.epic, '🪄'),
  Accessory('trident', AccessoryRarity.epic, '🔱'),
  Accessory('peacock', AccessoryRarity.epic, '🦚'),
  Accessory('comet', AccessoryRarity.epic, '☄️'),
  Accessory('butterfly', AccessoryRarity.epic, '🦋'),
  Accessory('angel_wing', AccessoryRarity.epic, '🪽'),
  Accessory('amphora', AccessoryRarity.epic, '🏺'),
  Accessory('rainbow', AccessoryRarity.epic, '🌈'),
  Accessory('fairy', AccessoryRarity.epic, '🧚'),
  Accessory('disco_ball', AccessoryRarity.epic, '🪩'),
  Accessory('shining_star', AccessoryRarity.epic, '🌟'),
  Accessory('swan', AccessoryRarity.epic, '🦢'),
  Accessory('flamingo', AccessoryRarity.epic, '🦩'),
  Accessory('owl', AccessoryRarity.epic, '🦉'),
  Accessory('whale', AccessoryRarity.epic, '🐋'),
  Accessory('crown', AccessoryRarity.epic, '👑'),
  Accessory('circus_tent', AccessoryRarity.epic, '🎪'),
  Accessory('pinata', AccessoryRarity.epic, '🪅'),
  Accessory('castle', AccessoryRarity.epic, '🏰'),
  Accessory('leopard', AccessoryRarity.epic, '🐆'),
  Accessory('elephant', AccessoryRarity.epic, '🐘'),
  Accessory('panda', AccessoryRarity.epic, '🐼'),
  Accessory('giraffe', AccessoryRarity.epic, '🦒'),
  Accessory('turtle', AccessoryRarity.epic, '🐢'),
  Accessory('koala', AccessoryRarity.epic, '🐨'),
  Accessory('penguin', AccessoryRarity.epic, '🐧'),
  Accessory('sauropod', AccessoryRarity.epic, '🦕'),
  Accessory('dragon', AccessoryRarity.legendary, '🐉'),
  Accessory('phoenix', AccessoryRarity.legendary, '🔥'),
  Accessory('galaxy', AccessoryRarity.legendary, '🌌'),
  Accessory('kraken', AccessoryRarity.legendary, '🦑'),
  Accessory('thunderbolt', AccessoryRarity.legendary, '⚡'),
  Accessory('genie', AccessoryRarity.legendary, '🧞'),
  Accessory('volcano', AccessoryRarity.legendary, '🌋'),
  Accessory('mermaid', AccessoryRarity.legendary, '🧜'),
  Accessory('eagle', AccessoryRarity.legendary, '🦅'),
];

Accessory accessoryById(String id) => accessories
    .followedBy(limitedAccessories)
    .firstWhere((a) => a.id == id);

int _rarityWeight(AccessoryRarity r, {bool weekend = false}) {
  final boost = weekend ? Balance.weekendHighRarityMultiplier : 1;
  return switch (r) {
    AccessoryRarity.common => Balance.accessoryWeightCommon,
    AccessoryRarity.rare => Balance.accessoryWeightRare,
    AccessoryRarity.epic => Balance.accessoryWeightEpic * boost,
    AccessoryRarity.legendary => Balance.accessoryWeightLegendary * boost,
  };
}

/// Chọn độ hiếm theo trọng số từ [roll01] trong [0,1) — cùng khuôn
/// [spinWheel] ở wheel.dart.
AccessoryRarity _rollRarity(double roll01,
    {bool weekend = false, AccessoryRarity min = AccessoryRarity.common}) {
  final allowed = AccessoryRarity.values.where((r) => r.index >= min.index);
  final total =
      allowed.fold<int>(0, (a, r) => a + _rarityWeight(r, weekend: weekend));
  var r = roll01 * total;
  for (final rarity in allowed) {
    r -= _rarityWeight(rarity, weekend: weekend);
    if (r < 0) return rarity;
  }
  return allowed.last;
}

/// Tỉ lệ rớt từng độ hiếm (tổng = 1) khi bảo đảm từ [min] — để UI công bố rõ
/// (Apple/Google yêu cầu công khai tỉ lệ với gói ngẫu nhiên).
Map<AccessoryRarity, double> accessoryOdds(
    {AccessoryRarity min = AccessoryRarity.common, bool weekend = false}) {
  final allowed = AccessoryRarity.values.where((r) => r.index >= min.index);
  final total =
      allowed.fold<int>(0, (a, r) => a + _rarityWeight(r, weekend: weekend));
  return {for (final r in allowed) r: _rarityWeight(r, weekend: weekend) / total};
}

/// Gói phụ kiện mua bằng 💎: độ hiếm tối thiểu + giá.
enum AccessoryPack {
  basic(AccessoryRarity.common, Balance.accessoryPackBasicGems),
  rare(AccessoryRarity.rare, Balance.accessoryPackRareGems),
  epic(AccessoryRarity.epic, Balance.accessoryPackEpicGems);

  const AccessoryPack(this.minRarity, this.baseGems);
  final AccessoryRarity minRarity;
  final int baseGems;

  /// Giá thực tế: giảm [Balance.seasonPackDiscount] trong mùa sự kiện.
  int cost(DateTime nowUtc) => seasonPackActive(nowUtc)
      ? (baseGems * (1 - Balance.seasonPackDiscount)).round()
      : baseGems;
}

/// Đang trong dịp lễ nào đó (giảm giá gói + boost tỉ lệ).
bool seasonPackActive(DateTime nowUtc) => activeFestival(nowUtc) != null;

/// Số chỗ trưng bày tối đa (VIP có thêm).
int maxEquippedFor({required bool vip}) =>
    Balance.maxEquippedAccessories + (vip ? Balance.vipExtraEquipSlots : 0);

/// Rớt 1 món ngẫu nhiên: [rarityRoll01] chọn độ hiếm, [itemRoll01] chọn món
/// trong độ hiếm đó (đều xác suất). [weekend] = sự kiện cuối tuần (tăng tỉ lệ
/// Sử thi/Huyền thoại, xem [Balance.weekendHighRarityMultiplier]). Thuần.
Accessory rollAccessory(double rarityRoll01, double itemRoll01,
    {bool weekend = false, AccessoryRarity min = AccessoryRarity.common}) {
  final rarity = _rollRarity(rarityRoll01, weekend: weekend, min: min);
  final pool = accessories.where((a) => a.rarity == rarity).toList();
  final i = (itemRoll01 * pool.length).floor().clamp(0, pool.length - 1);
  return pool[i];
}

/// Rớt 1 món THUỘC độ hiếm [rarity] (nguồn rớt có bảo đảm: Kỷ Nguyên, mốc Ghép 3).
Accessory rollAccessoryOfRarity(AccessoryRarity rarity, double itemRoll01) {
  final pool = accessories.where((a) => a.rarity == rarity).toList();
  final i = (itemRoll01 * pool.length).floor().clamp(0, pool.length - 1);
  return pool[i];
}

/// Kết quả một lần rớt phụ kiện (nhiệm vụ ngày / rương vòng quay) — để UI hiện "khoảnh
/// khắc nhận" (mới hay trùng) mà không phải suy ngược từ trạng thái.
class AccessoryDrop {
  const AccessoryDrop(this.accessory, {required this.isNew});

  final Accessory accessory;

  /// false = trùng món đã có (được 💎 + 1 bản dư, xem [grantAccessory]).
  final bool isNew;
}

/// Cấp [a] cho [state]. Đã có thì được [Balance.duplicateAccessoryGems] 💎 VÀ
/// thêm 1 bản dư (`accessorySpares`) bán được ở Chợ. Trả về true nếu là món
/// MỚI. MUTATE.
bool grantAccessory(GameState state, Accessory a) {
  if (state.ownedAccessories.contains(a.id)) {
    state.gems += Balance.duplicateAccessoryGems;
    state.accessorySpares[a.id] = (state.accessorySpares[a.id] ?? 0) + 1;
    return false;
  }
  state.ownedAccessories.add(a.id);
  return true;
}

/// Dùng cho Random thật (không test) — mirror cách game_controller.dart gọi
/// spinWheel(_random.nextDouble()).
Accessory rollAccessoryWith(Random random,
        {bool weekend = false, AccessoryRarity min = AccessoryRarity.common}) =>
    rollAccessory(random.nextDouble(), random.nextDouble(),
        weekend: weekend, min: min);

/// Đủ điều kiện nhận lượt rớt thưởng xem QC: đã nhận thưởng "xong cả bộ"
/// nhiệm vụ hôm nay và chưa nhận lượt này hôm nay.
bool accessoryAdDropAvailable(GameState s, int nowMillis) =>
    s.dailyBonusClaimed &&
    s.dailyQuestDay == dayIndex(nowMillis) &&
    s.accessoryAdDropDay != dayIndex(nowMillis);

/// Số lượt quay xem-QC còn lại hôm nay (reset khi sang ngày UTC mới).
int accessoryAdSpinsLeft(GameState s, int nowMillis) =>
    s.accessoryAdSpinDay == dayIndex(nowMillis)
        ? (Balance.accessorySpinAdsPerDay - s.accessoryAdSpins)
            .clamp(0, Balance.accessorySpinAdsPerDay)
        : Balance.accessorySpinAdsPerDay;

// --- Phụ kiện ĐỘC QUYỀN theo dịp lễ ---------------------------------------
// Tách hẳn khỏi [accessories] (50→80→120→160 món sưu tập chính): KHÔNG tính vào số đếm
// bộ sưu tập / mốc / bảng xếp hạng (SQL có CHECK owned_count), KHÔNG đăng bán ở
// Chợ, không đồng bộ server, không làm huy hiệu BXH. Lưu ở
// [GameState.ownedLimited]; chỉ mua được bằng Gói Lễ Hội trong dịp đó.

class Festival {
  const Festival(this.id, this.start, this.end, this.items);

  /// Khoá ổn định (dùng cho tên dịch `festivalName`).
  final String id;

  /// Khoảng thời gian bán gói (UTC, [start, end)).
  final DateTime start;
  final DateTime end;
  final List<Accessory> items;
}

// DateTime.utc không phải const nên danh sách là `final`. Thêm dịp lễ mới = thêm
// một Festival + tên dịch trong l10n_ext/ARB.
final List<Festival> festivals = [
  Festival('halloween', DateTime.utc(2026, 10, 24), DateTime.utc(2026, 11, 3), const [
    Accessory('bat', AccessoryRarity.rare, '🦇'),
    Accessory('jack_o_lantern', AccessoryRarity.epic, '🎃'),
    Accessory('ghost', AccessoryRarity.epic, '👻'),
    Accessory('witch', AccessoryRarity.legendary, '🧙'),
  ]),
  Festival('christmas', DateTime.utc(2026, 12, 18), DateTime.utc(2026, 12, 28), const [
    Accessory('snowman', AccessoryRarity.rare, '⛄'),
    Accessory('christmas_tree', AccessoryRarity.epic, '🎄'),
    Accessory('reindeer', AccessoryRarity.epic, '🦌'),
    Accessory('santa', AccessoryRarity.legendary, '🎅'),
  ]),
  Festival('new_year', DateTime.utc(2026, 12, 28), DateTime.utc(2027, 1, 4), const [
    Accessory('champagne', AccessoryRarity.rare, '🥂'),
    Accessory('party_popper', AccessoryRarity.epic, '🎉'),
    Accessory('fireworks', AccessoryRarity.epic, '🎆'),
    Accessory('golden_sparkler', AccessoryRarity.legendary, '🎇'),
  ]),
  Festival('tet', DateTime.utc(2027, 1, 30), DateTime.utc(2027, 2, 10), const [
    Accessory('firecracker', AccessoryRarity.rare, '🧨'),
    Accessory('red_envelope', AccessoryRarity.epic, '🧧'),
    Accessory('apricot_blossom', AccessoryRarity.epic, '🌼'),
    Accessory('golden_goat', AccessoryRarity.legendary, '🐐'),
  ]),
  Festival('valentine', DateTime.utc(2027, 2, 10), DateTime.utc(2027, 2, 16), const [
    Accessory('love_letter', AccessoryRarity.rare, '💌'),
    Accessory('rose', AccessoryRarity.epic, '🌹'),
    Accessory('chocolate', AccessoryRarity.epic, '🍫'),
    Accessory('cupid_arrow', AccessoryRarity.legendary, '💘'),
  ]),
  Festival('womens_day', DateTime.utc(2027, 3, 4), DateTime.utc(2027, 3, 10), const [
    Accessory('tulip', AccessoryRarity.rare, '🌷'),
    Accessory('bouquet', AccessoryRarity.epic, '💐'),
    Accessory('lipstick', AccessoryRarity.epic, '💄'),
    Accessory('princess', AccessoryRarity.legendary, '👸'),
  ]),
  Festival('mid_autumn', DateTime.utc(2027, 9, 8), DateTime.utc(2027, 9, 18), const [
    Accessory('mooncake', AccessoryRarity.rare, '🥮'),
    Accessory('rabbit', AccessoryRarity.epic, '🐇'),
    Accessory('full_moon', AccessoryRarity.epic, '🌕'),
    Accessory('lion_dance', AccessoryRarity.legendary, '🦁'),
  ]),
];

List<Accessory> get limitedAccessories => [
      for (final f in festivals) ...f.items,
      ...guildAccessories,
    ];

Festival? activeFestival(DateTime nowUtc) {
  for (final f in festivals) {
    if (!nowUtc.isBefore(f.start) && nowUtc.isBefore(f.end)) return f;
  }
  return null;
}

/// Sở hữu món (sưu tập chính HOẶC độc quyền lễ hội) — dùng cho trưng bày.
bool ownsAccessory(GameState s, String id) =>
    s.ownedAccessories.contains(id) || s.ownedLimited.contains(id);

/// Chọn món cho 1 lượt Gói Lễ Hội: đều trong các món CHƯA có; có đủ rồi thì chọn
/// đều trong cả dịp. [roll01] ∈ [0,1).
Accessory pickFestivalItem(GameState s, Festival f, double roll01) {
  final unowned = f.items.where((a) => !s.ownedLimited.contains(a.id)).toList();
  final pool = unowned.isEmpty ? f.items : unowned;
  return pool[(roll01 * pool.length).floor().clamp(0, pool.length - 1)];
}

/// Trao món độc quyền. Trả về true nếu là món MỚI; trùng (đã đủ bộ) → đổi 💎.
bool grantFestivalItem(GameState s, Accessory a) {
  if (s.ownedLimited.contains(a.id)) {
    s.gems += Balance.duplicateAccessoryGems;
    return false;
  }
  s.ownedLimited.add(a.id);
  return true;
}
