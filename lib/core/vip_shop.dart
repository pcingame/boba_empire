/// Cửa hàng VIP: "Xu VIP" kiếm được khi nhận quà VIP hằng ngày/tuần/tháng, đổi lấy phụ kiện
/// độc quyền VIP (cosmetic thuần, lưu ở [GameState.ownedLimited] như món lễ hội/hội — không vào bộ
/// sưu tập chính/Chợ). Mỗi món đòi một cấp VIP tối thiểu. Mọi con số là ước lượng chưa playtest.
library;

import 'accessories.dart';
import 'topup.dart' show VipPeriod;

class VipShopItem {
  const VipShopItem(this.accessory, this.price, this.minLevel);

  final Accessory accessory;

  /// Giá bằng Xu VIP.
  final int price;

  /// Cấp VIP tối thiểu để mua.
  final int minLevel;

  String get id => accessory.id;
}

/// 8 món, tăng dần theo giá và cấp. Id có tiền tố `vip_` (khác bộ chính/lễ hội/hội). Tên dịch ở
/// l10n_ext (accessoryName). Tránh hình ảnh cờ bạc (quy định App Store về giả lập đánh bạc).
const List<VipShopItem> vipShopItems = [
  VipShopItem(Accessory('vip_watch', AccessoryRarity.rare, '⌚'), 150, 1),
  VipShopItem(Accessory('vip_luggage', AccessoryRarity.rare, '🧳'), 250, 2),
  VipShopItem(Accessory('vip_briefcase', AccessoryRarity.epic, '💼'), 400, 3),
  VipShopItem(Accessory('vip_tophat', AccessoryRarity.epic, '🎩'), 600, 4),
  VipShopItem(Accessory('vip_racecar', AccessoryRarity.epic, '🏎️'), 900, 5),
  VipShopItem(Accessory('vip_heli', AccessoryRarity.legendary, '🚁'), 1300, 6),
  VipShopItem(Accessory('vip_yacht', AccessoryRarity.legendary, '🛥️'), 1800, 7),
  VipShopItem(Accessory('vip_jet', AccessoryRarity.legendary, '🛩️'), 2500, 8),
];

List<Accessory> get vipAccessories => [for (final i in vipShopItems) i.accessory];

/// Xu VIP nhận kèm quà [period] ở cấp [level] (0 nếu chưa có cấp): ngày 5×cấp, tuần 35×cấp,
/// tháng 150×cấp — tương ứng quà 💎 10/70/300 × cấp ở [vipBenefit].
int vipCoinsFor(VipPeriod period, int level) {
  if (level < 1) return 0;
  return switch (period) {
    VipPeriod.daily => 5 * level,
    VipPeriod.weekly => 35 * level,
    VipPeriod.monthly => 150 * level,
  };
}

enum VipShopResult { ok, unknownItem, locked, alreadyOwned, notEnoughCoins }
