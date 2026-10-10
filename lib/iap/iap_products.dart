/// Danh mục sản phẩm mua bằng tiền thật (IAP).
///
/// [id] phải KHỚP product id tạo trong Play Console / App Store Connect
/// (xem SETUP.md). Đổi id ở đây là đổi luôn cho toàn app.
library;

import '../core/balance.dart';

enum IapKind { consumable, nonConsumable }

enum IapProduct {
  /// Các gói Kim Cương (consumable) — bậc giá tăng dần, mua lại nhiều lần.
  gemsSmall('boba_gems_small', IapKind.consumable, gems: Balance.iapGemsSmall, vipExp: 100),
  gemsMedium('boba_gems_medium', IapKind.consumable,
      gems: Balance.iapGemsMedium, vipExp: 500),
  gemsLarge('boba_gems_large', IapKind.consumable, gems: Balance.iapGemsLarge, vipExp: 1000),
  gemsHuge('boba_gems_huge', IapKind.consumable, gems: Balance.iapGemsHuge, vipExp: 1760),
  gemsMega('boba_gems_mega', IapKind.consumable, gems: Balance.iapGemsMega, vipExp: 2400),

  /// Gỡ quảng cáo — mua một lần, vĩnh viễn.
  removeAds('boba_remove_ads', IapKind.nonConsumable, vipExp: 300),

  /// x2 thu nhập vĩnh viễn — mua một lần, nhân đôi mọi thu nhập tự động.
  doubleIncome('boba_double_income', IapKind.nonConsumable, vipExp: 500),

  /// Đập heo đất — nhận toàn bộ Kim Cương đã tích. Consumable (mua lại khi heo
  /// đầy lại). Số gems trao là biến (theo heo lúc mua), không cố định.
  piggyBreak('boba_piggy', IapKind.consumable, vipExp: 200),

  /// VIP Pass 30 ngày (gỡ QC + x2 thu nhập + 💎/ngày + trần offline). Consumable
  /// để mua lại khi hết hạn; app lưu mốc hết hạn (client-only, không cần server).
  vip30('boba_vip30', IapKind.consumable, vipExp: 500),

  /// Gói khởi động — mua một lần.
  starterPack('boba_starter_pack', IapKind.nonConsumable, vipExp: 100),

  /// Kho lạnh vĩnh viễn — +[Balance.coldStorageBonusSeconds] trần offline, một lần.
  coldStorage('boba_cold_storage', IapKind.nonConsumable, vipExp: 300),

  /// Combo gỡ QC + x2 thu nhập vĩnh viễn (rẻ hơn mua riêng) — một lần.
  comboNoAdsX2('boba_combo_noads_x2', IapKind.nonConsumable, vipExp: 600);

  const IapProduct(this.id, this.kind, {this.gems = 0, this.vipExp = 0});

  final String id;
  final IapKind kind;

  /// VIP EXP cộng khi mua (≈ 100/USD, gói 💎 lớn +10–20%) — xem core/topup.dart. Ước lượng.
  final int vipExp;

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
