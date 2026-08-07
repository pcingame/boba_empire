/// Danh mục sản phẩm mua bằng tiền thật (IAP).
///
/// [id] phải KHỚP product id tạo trong Play Console / App Store Connect
/// (xem SETUP.md). Đổi id ở đây là đổi luôn cho toàn app.
library;

enum IapKind { consumable, nonConsumable }

enum IapProduct {
  /// Gói Kim Cương — mua lại nhiều lần.
  gems('boba_gems_small', IapKind.consumable),

  /// Gỡ quảng cáo — mua một lần, vĩnh viễn.
  removeAds('boba_remove_ads', IapKind.nonConsumable),

  /// Gói khởi động — mua một lần.
  starterPack('boba_starter_pack', IapKind.nonConsumable);

  const IapProduct(this.id, this.kind);

  final String id;
  final IapKind kind;

  static IapProduct? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
