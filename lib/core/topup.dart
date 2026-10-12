/// VIP EXP & cấp VIP. EXP đến từ hai nguồn: nạp IAP (≈ 100 EXP/USD, xem
/// [IapProduct.vipExp]) và mua bằng Kim Cương (10 💎 = 1 EXP, có trần). Cấp VIP =
/// số bậc [topupTiers] đã đạt; mỗi cấp có thưởng mốc một lần, buff thu nhập vĩnh
/// viễn và quà theo ngày/tuần/tháng. Lưu trong save — client tự khai nên làm giả
/// được; chỉ là huy hiệu + thưởng, không phải thanh toán. Mọi con số là ước lượng
/// chưa playtest.
library;

import 'accessories.dart';
import 'daily.dart' show dayIndex;

class TopupTier {
  const TopupTier(this.exp, this.gems, {this.accessory});

  /// EXP tích lũy cần đạt (bậc này cũng là cấp VIP thứ i+1).
  final int exp;
  final double gems;

  /// Kèm một phụ kiện từ độ hiếm này trở lên (huyền thoại = đúng huyền thoại).
  final AccessoryRarity? accessory;
}

// VIP 3-10 giảm 20% ngưỡng EXP (2026-10-13, góp ý "VIP 10 khó quá"); VIP 1-2 giữ nguyên. Ngưỡng PHẢI khớp
// `vip_level_for_exp` trong supabase/accessory_market_schema.sql (test/core/vip_sql_test.dart so khớp).
const List<TopupTier> topupTiers = [
  TopupTier(500, 100),
  TopupTier(1500, 200),
  TopupTier(2400, 400, accessory: AccessoryRarity.rare),
  TopupTier(4800, 800),
  TopupTier(8000, 1500, accessory: AccessoryRarity.epic),
  TopupTier(16000, 3000),
  TopupTier(28000, 5000),
  TopupTier(40000, 8000, accessory: AccessoryRarity.legendary),
  TopupTier(60000, 12000, accessory: AccessoryRarity.epic),
  TopupTier(80000, 20000, accessory: AccessoryRarity.legendary),
];

/// +% thu nhập tự động cho MỖI cấp VIP.
const double vipIncomeBonusPerLevel = 0.02;

/// Từ cấp này, người chơi có thêm dòng danh hiệu ở mọi bảng xếp hạng, và được báo
/// online cho cả server (supabase: vip_ping có cùng ngưỡng 5 — test khớp).
const int vipTitleMinLevel = 5;

/// Mua EXP bằng 💎: mỗi khối [vipExpBlock] EXP giá [vipExpBlockGems] 💎 (8 💎/EXP —
/// vẫn đắt hơn nạp IAP cùng giá trị; giảm từ 10 💎/EXP sau góp ý "1000💎 chỉ được 100 EXP" 2026-10-13).
/// Tổng EXP mua bằng 💎 chặn ở [vipExpGemCap] (≈ tới VIP 6) để cấp cao chỉ đạt được bằng nạp thật.
const int vipExpBlock = 100;
const int vipExpBlockGems = 800;
const int vipExpGemCap = 20000;

/// Cấp VIP (0 = chưa đủ bậc đầu) theo [exp].
int topupVipLevel(int exp) => topupTiers.where((t) => exp >= t.exp).length;

/// Hệ số nhân thu nhập theo cấp VIP của [exp].
double vipIncomeMultiplier(int exp) =>
    1 + topupVipLevel(exp) * vipIncomeBonusPerLevel;

/// Có mua thêm được một khối EXP bằng 💎 không (đủ 💎 và chưa chạm trần).
bool canBuyVipExp(double gems, int expFromGems) =>
    gems >= vipExpBlockGems && expFromGems + vipExpBlock <= vipExpGemCap;

// --- Quà theo kỳ (ngày / tuần / tháng), tăng theo cấp VIP ---

enum VipPeriod { daily, weekly, monthly }

class VipBenefit {
  const VipBenefit(this.gems, [this.accessory]);
  final double gems;

  /// Phụ kiện kèm theo (null = không). Huyền thoại = đúng huyền thoại.
  final AccessoryRarity? accessory;
}

/// Quà của [period] ở cấp [level] (1..10). Null nếu level < 1.
/// Ngày: 10💎×cấp. Tuần: 70💎×cấp + 1 phụ kiện (hiếm→sử thi→huyền thoại theo cấp).
/// Tháng: 300💎×cấp + 1 phụ kiện (hiếm; sử thi từ cấp 5; huyền thoại từ cấp 8).
VipBenefit? vipBenefit(VipPeriod period, int level) {
  if (level < 1) return null;
  final l = level.clamp(1, topupTiers.length);
  switch (period) {
    case VipPeriod.daily:
      return VipBenefit(10.0 * l);
    case VipPeriod.weekly:
      return VipBenefit(
        70.0 * l,
        l >= 9
            ? AccessoryRarity.legendary
            : l >= 6
                ? AccessoryRarity.epic
                : l >= 3
                    ? AccessoryRarity.rare
                    : AccessoryRarity.common,
      );
    case VipPeriod.monthly:
      return VipBenefit(
        300.0 * l,
        l >= 8
            ? AccessoryRarity.legendary
            : l >= 5
                ? AccessoryRarity.epic
                : AccessoryRarity.rare,
      );
  }
}

/// Chỉ số kỳ hiện tại (UTC): ngày kể từ epoch; tuần bắt đầu thứ Hai; tháng theo
/// lịch (năm×12 + tháng).
int vipPeriodIndex(VipPeriod period, int nowMillis) {
  switch (period) {
    case VipPeriod.daily:
      return dayIndex(nowMillis);
    case VipPeriod.weekly:
      return (dayIndex(nowMillis) + 3) ~/ 7; // 1/1/1970 là thứ Năm
    case VipPeriod.monthly:
      final d = DateTime.fromMillisecondsSinceEpoch(nowMillis, isUtc: true);
      return d.year * 12 + d.month;
  }
}
