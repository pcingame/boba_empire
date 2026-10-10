/// Mốc nạp & cấp VIP theo TỔNG NẠP tích lũy (IAP). "Điểm nạp" ≈ số USD đã nạp
/// (mỗi sản phẩm một giá trị cố định ở [IapProduct.topup], không đọc giá cửa
/// hàng vì giá theo vùng). Lưu trong save (`GameState.topupPoints`) — client tự
/// khai nên làm giả được; chỉ là huy hiệu + thưởng, không phải thanh toán.
library;

import 'accessories.dart';

class TopupTier {
  const TopupTier(this.points, this.gems, {this.accessory});

  /// Điểm nạp tích lũy cần đạt (bậc này cũng là cấp VIP thứ i+1).
  final int points;
  final double gems;

  /// Kèm một phụ kiện từ độ hiếm này trở lên (huyền thoại = đúng huyền thoại).
  final AccessoryRarity? accessory;
}

/// Cấp VIP tối đa = số bậc. Các con số là ước lượng chưa playtest.
const List<TopupTier> topupTiers = [
  TopupTier(5, 100),
  TopupTier(15, 200),
  TopupTier(30, 400, accessory: AccessoryRarity.rare),
  TopupTier(60, 800),
  TopupTier(100, 1500, accessory: AccessoryRarity.epic),
  TopupTier(200, 3000),
  TopupTier(350, 5000),
  TopupTier(500, 8000, accessory: AccessoryRarity.legendary),
];

/// +% thu nhập tự động cho MỖI cấp VIP.
const double vipIncomeBonusPerLevel = 0.02;

/// Cấp VIP (0 = chưa nạp đủ bậc đầu) theo [points].
int topupVipLevel(int points) =>
    topupTiers.where((t) => points >= t.points).length;

/// Hệ số nhân thu nhập theo cấp VIP của [points].
double vipIncomeMultiplier(int points) =>
    1 + topupVipLevel(points) * vipIncomeBonusPerLevel;
