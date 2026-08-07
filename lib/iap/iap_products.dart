/// Danh mục sản phẩm mua bằng tiền thật (IAP).
///
/// [id] phải KHỚP product id tạo trong Play Console / App Store Connect
/// (xem SETUP.md). Đổi id ở đây là đổi luôn cho toàn app.
library;

import '../core/balance.dart';

enum IapKind { consumable, nonConsumable }

enum IapProduct {
  /// Các gói Kim Cương (consumable) — bậc giá tăng dần, mua lại nhiều lần.
  gemsSmall('boba_gems_small', IapKind.consumable, gems: Balance.iapGemsSmall),
  gemsMedium('boba_gems_medium', IapKind.consumable,
      gems: Balance.iapGemsMedium),
  gemsLarge('boba_gems_large', IapKind.consumable, gems: Balance.iapGemsLarge),

  /// Gỡ quảng cáo — mua một lần, vĩnh viễn.
  removeAds('boba_remove_ads', IapKind.nonConsumable),

  /// Gói khởi động — mua một lần.
  starterPack('boba_starter_pack', IapKind.nonConsumable);

  const IapProduct(this.id, this.kind, {this.gems = 0});

  final String id;
  final IapKind kind;

  /// Số Kim Cương gói này trao (0 nếu không phải gói gems).
  final double gems;

  bool get isGems => gems > 0;

  static IapProduct? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
