/// Gói Khởi Nghiệp Chợ: 1 phụ kiện Thường + 1 bản dư (+10 Xu Chợ do server
/// cộng). Chỉ mở khi có tiến độ thật — xem claim_starter_pack trong
/// supabase/accessory_market_schema.sql (client tự khai tiến độ, làm giả được;
/// server chặn bằng 1 lần/tài khoản + trần toàn cục mỗi ngày).
library;

import 'accessories.dart';
import 'models.dart';

const starterPackMinStage = 3;
const starterPackMarketCoins = 10;

bool starterPackEligible(GameState s) =>
    !s.starterPackClaimed &&
    s.stage >= starterPackMinStage &&
    s.dailyQuestEverClaimed;

/// Món Thường chưa có đầu tiên; có đủ rồi thì món Thường đầu danh mục (thành
/// bản dư).
Accessory starterPackAccessory(GameState s) {
  final commons = accessories
      .where((a) => a.rarity == AccessoryRarity.common)
      .toList();
  return commons.firstWhere(
    (a) => !s.ownedAccessories.contains(a.id),
    orElse: () => commons.first,
  );
}

/// MUTATE: cấp [item] + 1 bản dư, đánh dấu đã nhận. Không quy đổi 💎 (khác
/// grantAccessory) — bản dư là hàng để bán.
void grantMarketStarter(GameState s, Accessory item) {
  if (!s.ownedAccessories.contains(item.id)) s.ownedAccessories.add(item.id);
  s.accessorySpares[item.id] = (s.accessorySpares[item.id] ?? 0) + 1;
  s.starterPackClaimed = true;
}
