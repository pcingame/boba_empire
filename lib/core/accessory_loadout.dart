/// Bộ trang bị phụ kiện (loadout): mỗi món thuộc đúng MỘT họ, mỗi họ cho một loại buff; mang
/// món nào quyết định buff nào. Hàm thuần — xem PROPOSAL_ACCESSORY_LOADOUT.md cho lý do thiết kế
/// và Balance.loadout* cho các con số (ước lượng, chưa playtest).
library;

import 'accessories.dart';
import 'accessory_refine.dart';
import 'balance.dart';

/// Bốn họ phụ kiện. Chia luân phiên TRONG từng độ hiếm để họ nào cũng có đủ mọi độ hiếm (gán theo
/// chủ đề thì họ "ngọt" gần như không có Sử thi/Huyền thoại) — nên tên họ trung tính, không theo hình.
enum AccessoryFamily {
  /// 🔥 Nhiệt huyết: giá trị chạm.
  tap('🔥'),

  /// ✨ Lấp lánh: thu nhập tự động.
  income('✨'),

  /// 🌿 Yên bình: thu nhập offline.
  offline('🌿'),

  /// 💎 Tinh tế: giảm giá nâng cấp.
  discount('💎');

  const AccessoryFamily(this.emoji);
  final String emoji;
}

// 216 món = 160 bộ chính + 28 lễ hội + 12 cửa hàng Hội + 8 cửa hàng VIP + 8 Thẻ Mùa. Thêm món MỚI thì PHẢI
// thêm vào một danh sách dưới đây — test `accessory_loadout_test` khoá việc mỗi món có đúng một họ.
const List<String> _tapIds = [
    'mint_leaf', 'candle', 'balloon', 'teapot', 'wind_chime', 'yarn', 'ladybug', 'ice_cream',
    'peach', 'tangerine', 'croissant', 'cake_slice', 'watermelon', 'banana', 'bucket',
    'avocado', 'rice_ball', 'taco', 'egg', 'seashell', 'key', 'anchor', 'ring', 'scroll',
    'camera', 'piano', 'ringed_planet', 'ferris_wheel', 'chess_pawn', 'roller_skate', 'dna',
    'crystal_ball', 'trident', 'angel_wing', 'disco_ball', 'owl', 'pinata', 'panda', 'penguin',
    'dragon', 'thunderbolt', 'eagle', 'bat', 'santa', 'fireworks', 'red_envelope',
    'love_letter', 'princess', 'full_moon', 'guild_flag', 'guild_fox', 'guild_boar',
    'vip_watch', 'vip_racecar',
    'season_sakura', 'season_autumn_leaf',
];

const List<String> _incomeIds = [
    'cupcake', 'scarf', 'bowtie', 'bell', 'clover', 'fan', 'donut', 'strawberry', 'popcorn',
    'chestnut', 'pancakes', 'pie', 'pineapple', 'apple', 'carrot', 'coconut', 'dumpling',
    'pizza', 'bread', 'mask', 'diamond_stone', 'feather', 'compass', 'microphone', 'shield',
    'saxophone', 'crescent_moon', 'carousel', 'dart', 'skateboard', 'trophy', 'lantern',
    'peacock', 'amphora', 'shining_star', 'whale', 'castle', 'giraffe', 'sauropod', 'phoenix',
    'genie', 'jack_o_lantern', 'snowman', 'golden_sparkler', 'apricot_blossom', 'rose',
    'tulip', 'lion_dance', 'guild_castle', 'guild_tiger', 'guild_bear', 'vip_luggage',
    'vip_heli',
    'season_paper_lantern', 'season_moon_view',
];

const List<String> _offlineIds = [
    'cookie', 'kite', 'sunglasses', 'ribbon', 'bubble', 'basket', 'lollipop', 'cherry',
    'honey_pot', 'maple_leaf', 'waffle', 'candy', 'mango', 'teddy', 'corn', 'blueberries',
    'sushi', 'hot_dog', 'butter', 'drum', 'music_note', 'hourglass', 'rocket', 'lotus',
    'guitar', 'banjo', 'bow_arrow', 'puzzle', 'bowling', 'satellite', 'unicorn', 'comet',
    'rainbow', 'swan', 'crown', 'leopard', 'turtle', 'galaxy', 'volcano', 'ghost',
    'christmas_tree', 'champagne', 'golden_goat', 'chocolate', 'bouquet', 'mooncake',
    'guild_wolf', 'guild_shark', 'guild_scorpion', 'vip_briefcase', 'vip_yacht',
    'season_sunflower', 'season_snowflake',
];

const List<String> _discountIds = [
    'potted_plant', 'cap', 'umbrella', 'bookmark', 'sticker', 'bead', 'pretzel', 'lemon',
    'milk_glass', 'ice_cube', 'bagel', 'grapes', 'kiwi', 'crayon', 'tomato', 'pear', 'ramen',
    'fries', 'palette', 'telescope', 'map', 'violin', 'jellyfish', 'trumpet', 'microscope',
    'mirror', 'dice', 'yo_yo', 'alembic', 'magic_wand', 'butterfly', 'fairy', 'flamingo',
    'circus_tent', 'elephant', 'koala', 'kraken', 'mermaid', 'witch', 'reindeer',
    'party_popper', 'firecracker', 'cupid_arrow', 'lipstick', 'rabbit', 'guild_dragon',
    'guild_trex', 'guild_moai', 'vip_tophat', 'vip_jet',
    'season_island', 'season_mountain',
];

final Map<String, AccessoryFamily> _familyById = {
  for (final id in _tapIds) id: AccessoryFamily.tap,
  for (final id in _incomeIds) id: AccessoryFamily.income,
  for (final id in _offlineIds) id: AccessoryFamily.offline,
  for (final id in _discountIds) id: AccessoryFamily.discount,
};

/// Họ của món; null nếu id lạ (món của bản app mới hơn) — khi đó không buff gì, không crash.
AccessoryFamily? accessoryFamilyOf(String id) => _familyById[id];

/// Điểm của một món theo độ hiếm.
double accessoryPoints(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => Balance.loadoutPointCommon,
      AccessoryRarity.rare => Balance.loadoutPointRare,
      AccessoryRarity.epic => Balance.loadoutPointEpic,
      AccessoryRarity.legendary => Balance.loadoutPointLegendary,
    };

/// Hệ số combo theo số món cùng họ đang mang.
double loadoutComboMultiplier(int sameFamily) => switch (sameFamily) {
      <= 1 => 1.0,
      2 => Balance.loadoutCombo2,
      3 => Balance.loadoutCombo3,
      _ => Balance.loadoutCombo4,
    };

/// Buff từ bộ trang bị, dạng PHẦN TRĂM CỘNG THÊM (0.125 = +12.5%), đã kẹp trần.
class LoadoutBuffs {
  const LoadoutBuffs({
    this.tap = 0,
    this.income = 0,
    this.offline = 0,
    this.discount = 0,
    this.combo = const {},
  });

  static const none = LoadoutBuffs();

  final double tap;
  final double income;
  final double offline;
  final double discount;

  /// Hệ số combo đang áp theo họ (chỉ họ có ≥ 2 món).
  final Map<AccessoryFamily, double> combo;

  double get tapMultiplier => 1 + tap;
  double get incomeMultiplier => 1 + income;
  double get offlineMultiplier => 1 + offline;

  double of(AccessoryFamily f) => switch (f) {
        AccessoryFamily.tap => tap,
        AccessoryFamily.income => income,
        AccessoryFamily.offline => offline,
        AccessoryFamily.discount => discount,
      };

  bool get isEmpty => tap == 0 && income == 0 && offline == 0 && discount == 0;
}

/// Tính buff từ danh sách id đang mang. Món trùng id chỉ tính một lần; id lạ bị bỏ qua. [refine] = cấp tinh luyện
/// (nhân điểm từng món; trần họ vẫn giữ nguyên).
LoadoutBuffs loadoutBuffs(Iterable<String> equipped, {Map<String, int> refine = const {}}) {
  final points = <AccessoryFamily, double>{};
  final counts = <AccessoryFamily, int>{};
  for (final id in equipped.toSet()) {
    final a = accessoryOrNull(id);
    final f = accessoryFamilyOf(id);
    if (a == null || f == null) continue;
    points[f] = (points[f] ?? 0) + accessoryPoints(a.rarity) * refineMultiplier(refine, id);
    counts[f] = (counts[f] ?? 0) + 1;
  }
  if (points.isEmpty) return LoadoutBuffs.none;

  double pct(AccessoryFamily f, double perPoint, double cap) {
    final p = points[f];
    if (p == null) return 0;
    final v = p * perPoint * loadoutComboMultiplier(counts[f] ?? 0);
    return v > cap ? cap : v;
  }

  return LoadoutBuffs(
    tap: pct(AccessoryFamily.tap, Balance.loadoutTapPerPoint, Balance.loadoutTapCap),
    income: pct(AccessoryFamily.income, Balance.loadoutIncomePerPoint, Balance.loadoutIncomeCap),
    offline: pct(AccessoryFamily.offline, Balance.loadoutOfflinePerPoint, Balance.loadoutOfflineCap),
    discount: pct(AccessoryFamily.discount, Balance.loadoutDiscountPerPoint, Balance.loadoutDiscountCap),
    combo: {
      for (final e in counts.entries)
        if (e.value >= 2) e.key: loadoutComboMultiplier(e.value),
    },
  );
}
