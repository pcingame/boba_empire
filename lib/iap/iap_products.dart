/// Danh mục sản phẩm mua bằng tiền thật (IAP).
///
/// [id] phải KHỚP product id tạo trong Play Console / App Store Connect
/// (xem SETUP.md). Đổi id ở đây là đổi luôn cho toàn app.
library;

enum IapKind { consumable, nonConsumable }

enum IapProduct {
  /// Gói Kim Cương — mua lại nhiều lần.
  gems('boba_gems_small', IapKind.consumable, 'Túi Kim Cương',
      'Nạp thêm Kim Cương để mua vật phẩm trong Cửa hàng.'),

  /// Gỡ quảng cáo — mua một lần, vĩnh viễn.
  removeAds('boba_remove_ads', IapKind.nonConsumable, 'Gỡ quảng cáo',
      'Bỏ qua mọi quảng cáo — vẫn nhận đủ thưởng, không cần xem.'),

  /// Gói khởi động — mua một lần.
  starterPack('boba_starter_pack', IapKind.nonConsumable, 'Gói khởi động',
      'Một lần: nhận ngay một túi Kim Cương lớn.');

  const IapProduct(this.id, this.kind, this.title, this.description);

  final String id;
  final IapKind kind;
  final String title;
  final String description;

  static IapProduct? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
