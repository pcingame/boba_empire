/// Phụ kiện sưu tập (2026-10-01) — cosmetic thuần, không ảnh hưởng số liệu.
/// Rớt ngẫu nhiên khi nhận thưởng "xong cả 3 nhiệm vụ ngày" (xem
/// claimDailyQuestBonus trong game_controller.dart). Tên hiển thị ở l10n_ext
/// (cùng khuôn achievements.dart) — file này chỉ giữ id + emoji + độ hiếm.
library;

import 'dart:math';

import 'balance.dart';
import 'models.dart';

enum AccessoryRarity { common, rare, epic, legendary }

class Accessory {
  const Accessory(this.id, this.rarity, this.emoji);

  final String id;
  final AccessoryRarity rarity;
  final String emoji;
}

/// 50 món, chia theo độ hiếm (25 thường · 13 hiếm · 9 sử thi · 3 huyền
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
  Accessory('crystal_ball', AccessoryRarity.epic, '🔮'),
  Accessory('lantern', AccessoryRarity.epic, '🏮'),
  Accessory('unicorn', AccessoryRarity.epic, '🦄'),
  Accessory('magic_wand', AccessoryRarity.epic, '🪄'),
  Accessory('trident', AccessoryRarity.epic, '🔱'),
  Accessory('peacock', AccessoryRarity.epic, '🦚'),
  Accessory('comet', AccessoryRarity.epic, '☄️'),
  Accessory('butterfly', AccessoryRarity.epic, '🦋'),
  Accessory('angel_wing', AccessoryRarity.epic, '🪽'),
  Accessory('dragon', AccessoryRarity.legendary, '🐉'),
  Accessory('phoenix', AccessoryRarity.legendary, '🔥'),
  Accessory('galaxy', AccessoryRarity.legendary, '🌌'),
];

Accessory accessoryById(String id) =>
    accessories.firstWhere((a) => a.id == id);

int _rarityWeight(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => Balance.accessoryWeightCommon,
      AccessoryRarity.rare => Balance.accessoryWeightRare,
      AccessoryRarity.epic => Balance.accessoryWeightEpic,
      AccessoryRarity.legendary => Balance.accessoryWeightLegendary,
    };

/// Chọn độ hiếm theo trọng số từ [roll01] trong [0,1) — cùng khuôn
/// [spinWheel] ở wheel.dart.
AccessoryRarity _rollRarity(double roll01) {
  final total =
      AccessoryRarity.values.fold<int>(0, (a, r) => a + _rarityWeight(r));
  var r = roll01 * total;
  for (final rarity in AccessoryRarity.values) {
    r -= _rarityWeight(rarity);
    if (r < 0) return rarity;
  }
  return AccessoryRarity.values.last;
}

/// Rớt 1 món ngẫu nhiên: [rarityRoll01] chọn độ hiếm, [itemRoll01] chọn món
/// trong độ hiếm đó (đều xác suất). Thuần — không mutate.
Accessory rollAccessory(double rarityRoll01, double itemRoll01) {
  final rarity = _rollRarity(rarityRoll01);
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
Accessory rollAccessoryWith(Random random) =>
    rollAccessory(random.nextDouble(), random.nextDouble());
