/// Mốc sưu tập THEO BỘ: gom đủ mọi món của một bộ (4 độ hiếm + 4 họ buff, chỉ tính 160 món
/// bộ chính) thì nhận Xu Chợ MỘT LẦN. Server giữ danh sách món của từng bộ và bảng thưởng — xem
/// claim_collection_set trong supabase/accessory_market_schema.sql (test khớp cả hai).
library;

import 'accessories.dart';
import 'accessory_loadout.dart';
import 'models.dart';

class CollectionSet {
  const CollectionSet(this.id, this.coins, {this.rarity, this.family});

  /// `rarity_<tên>` hoặc `family_<tên>` — cũng là khoá lưu và khoá gửi server.
  final String id;
  final int coins;
  final AccessoryRarity? rarity;
  final AccessoryFamily? family;

  bool has(Accessory a) =>
      rarity != null ? a.rarity == rarity : accessoryFamilyOf(a.id) == family;

  /// Id các món thuộc bộ (chỉ trong 160 món chính).
  List<String> get members => [for (final a in accessories) if (has(a)) a.id];
}

const collectionSets = [
  CollectionSet('rarity_legendary', 150, rarity: AccessoryRarity.legendary),
  CollectionSet('rarity_epic', 300, rarity: AccessoryRarity.epic),
  CollectionSet('rarity_rare', 400, rarity: AccessoryRarity.rare),
  CollectionSet('rarity_common', 400, rarity: AccessoryRarity.common),
  CollectionSet('family_tap', 400, family: AccessoryFamily.tap),
  CollectionSet('family_income', 400, family: AccessoryFamily.income),
  CollectionSet('family_offline', 400, family: AccessoryFamily.offline),
  CollectionSet('family_discount', 400, family: AccessoryFamily.discount),
];

/// Số món đã sưu tầm của bộ.
int setOwnedCount(GameState s, CollectionSet set) =>
    set.members.where(s.ownedAccessories.contains).length;

bool setComplete(GameState s, CollectionSet set) =>
    setOwnedCount(s, set) == set.members.length;

bool setClaimed(GameState s, CollectionSet set) =>
    s.collectionSetsClaimed.contains(set.id);

int setsClaimable(GameState s) =>
    collectionSets.where((x) => setComplete(s, x) && !setClaimed(s, x)).length;
