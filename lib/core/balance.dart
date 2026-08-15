/// Bảng cân bằng game — toàn bộ con số nằm ở đây, tách khỏi logic (mục 9).
///
/// Muốn tune game chỉ cần sửa file này; sau này có thể nạp từ JSON / Remote
/// Config mà không đụng tới mã mô phỏng.
library;

import 'models.dart';

class Balance {
  Balance._();

  /// Trần thời gian tính tiền offline (8 giờ) — buộc người chơi quay lại và
  /// tạo chỗ để bán vật phẩm "tăng giới hạn offline".
  static const int maxOfflineSeconds = 8 * 60 * 60;

  /// % thu nhập cộng thêm cho mỗi Sao nhượng quyền (bonus vĩnh viễn).
  static const double bonusPerStar = 0.02; // +2%/sao

  /// Hệ số quy đổi Sao: sao = floor(k * sqrt(tổng_thu_nhập_cả_đời)).
  /// Placeholder — cần tune bằng bảng số ở giai đoạn balancing.
  static const double prestigeK = 0.05;

  /// Mốc nhân bội cho mỗi nguồn thu: cứ mỗi [milestoneStep] cấp, thu nhập của
  /// nguồn đó ×[milestoneFactor] (25→×2, 50→×4, 75→×8...). Đây là "củ cà rốt"
  /// khiến người chơi dồn cấp một nguồn thay vì rải đều — chiều sâu tối ưu.
  static const int milestoneStep = 25;
  static const double milestoneFactor = 2.0;

  // --- Sự kiện Mưa vàng (Golden Rush) ---

  /// Hệ số tăng tốc khi kích hoạt Mưa vàng.
  static const double goldenRushMultiplier = 3.0;

  /// Thời lượng boost (2 phút).
  static const int goldenRushDurationMs = 2 * 60 * 1000;

  /// Con mèo xuất hiện cách nhau ngẫu nhiên trong khoảng [min, max].
  static const int catSpawnMinMs = 3 * 60 * 1000;
  static const int catSpawnMaxMs = 5 * 60 * 1000;

  /// Con mèo tự biến mất sau chừng này nếu người chơi không chạm.
  static const int catLingerMs = 12 * 1000;

  /// "Tiền tức thì": xem quảng cáo để nhận ngay chừng này giây sản xuất.
  static const int instantCashSeconds = 15 * 60; // 15 phút

  // --- Khách VIP (đi ô tô, tip Kim Cương) ---

  /// VIP xuất hiện cách nhau ngẫu nhiên trong khoảng [min, max] (hiếm hơn mèo).
  static const int vipSpawnMinMs = 4 * 60 * 1000;
  static const int vipSpawnMaxMs = 7 * 60 * 1000;

  /// Xe VIP đợi chừng này rồi rời đi nếu không được phục vụ.
  static const int vipLingerMs = 15 * 1000;

  /// Tiền VIP trả (theo giây sản xuất); "x10 tiền" một ly làm sàn tối thiểu.
  static const int vipCashSeconds = 60;

  /// Số Kim Cương VIP tip mỗi lần (ngẫu nhiên trong [min, max]).
  static const int vipGemsMin = 1;
  static const int vipGemsMax = 3;

  // --- Cửa hàng Kim Cương (chỗ tiêu gems) ---

  /// Hệ số tăng giá gems mỗi cấp (dùng chung cho các vật phẩm).
  static const double gemCostGrowth = 2.0;

  /// Vật phẩm "Tăng thu nhập": +10% thu nhập vĩnh viễn mỗi cấp.
  static const int gemBoostBaseCost = 5;
  static const double gemBoostPerLevel = 0.10;

  /// Vật phẩm "Kho lạnh offline": +2 giờ trần tiền offline mỗi cấp.
  static const int offlineCapBaseCost = 10;
  static const int offlineCapPerLevelSeconds = 2 * 60 * 60;

  // --- Mua bằng tiền thật (IAP) ---

  /// Kim Cương nhận theo từng gói gems (consumable) — bậc giá tăng dần.
  static const double iapGemsSmall = 100; // ~$0.99
  static const double iapGemsMedium = 600; // ~$4.99 (bonus theo giá)
  static const double iapGemsLarge = 1300; // ~$9.99

  /// Kim Cương tặng kèm trong "Gói khởi động" (một lần).
  static const double iapStarterGems = 300;

  // --- Kiếm thêm (rewarded ads) ---
  /// "x2 thu nhập" tạm thời khi xem QC: hệ số + thời lượng.
  static const double rewardedX2Multiplier = 2.0;
  static const int rewardedX2DurationMs = 24 * 60 * 60 * 1000; // 24 giờ
  /// Kim Cương nhận mỗi lần xem QC ở mục "Nhận 💎 miễn phí".
  static const int rewardedFreeGems = 15;
  /// "Tua nhanh": xem QC nhận ngay chừng này giây sản xuất.
  static const int rewardedTimeSkipSeconds = 4 * 60 * 60; // 4 giờ

  // --- Heo đất (Piggy Bank) ---
  /// Heo tự tích Kim Cương theo Xu kiếm được (fill nhanh dần khi thu nhập cao),
  /// tới trần thì dừng — đầy thì trả tiền "đập" (IAP boba_piggy) nhận hết.
  static const double piggyGemsPerCoin = 0.0001;
  static const double piggyMaxGems = 300;
  /// Cần tích tối thiểu chừng này mới cho đập (để không mua heo rỗng).
  static const double piggyMinBreak = 40;

  // --- VIP Pass (vé 30 ngày, mua lại) ---
  static const int vipDurationMs = 30 * 24 * 60 * 60 * 1000; // 30 ngày
  /// Trong lúc VIP: nhân đôi thu nhập + gỡ QC + trần offline + Kim Cương/ngày.
  static const double vipIncomeMultiplier = 2.0;
  static const int vipDailyGems = 50;
  static const int vipOfflineBonusSeconds = 4 * 60 * 60; // +4h trần offline

  // --- Kho Sao (tiêu ⭐ prestige mua perk vĩnh viễn) ---
  // Giá mỗi cấp = base * 2^cấp. Passive +2%/sao GIỮ NGUYÊN; tiêu Sao ở đây là
  // "chi tiêu" riêng (spendable = tổng Sao - đã tiêu), không đụng accounting
  // prestige nên không thể "tiêu rồi prestige lấy lại".

  /// "Siêu thu nhập": +25% thu nhập tự động vĩnh viễn mỗi cấp.
  static const int prestigeIncomeBaseCost = 3;
  static const double prestigeIncomePerLevel = 0.25;

  /// "Siêu chạm": +100% giá trị mỗi lần chạm vĩnh viễn mỗi cấp.
  static const int prestigeTapBaseCost = 5;
  static const double prestigeTapPerLevel = 1.0;

  /// Ba giai đoạn kinh doanh (index = stage - 1). Giai đoạn 1 có sẵn.
  static const List<StageConfig> stages = [
    StageConfig(stage: 1, name: 'Xe đẩy vỉa hè', unlockCost: 0),
    StageConfig(stage: 2, name: 'Kiosk cửa hàng nhỏ', unlockCost: 2000),
    StageConfig(stage: 3, name: 'Chuỗi cafe sang trọng', unlockCost: 500000),
    StageConfig(stage: 4, name: 'Xưởng trà sữa nướng', unlockCost: 50000000),
    StageConfig(stage: 5, name: 'Nhà máy phô mai tươi', unlockCost: 5000000000),
    StageConfig(stage: 6, name: 'Đế chế toàn cầu', unlockCost: 500000000000),
  ];

  static StageConfig stageConfig(int stage) => stages[stage - 1];

  /// Cấu hình giai đoạn kế tiếp, hoặc null nếu đã ở giai đoạn cuối.
  static StageConfig? nextStageConfig(int currentStage) =>
      currentStage < stages.length ? stages[currentStage] : null;

  /// Danh sách nguồn thu, gắn theo giai đoạn mở khóa (chủ đề trà sữa).
  static const List<GeneratorConfig> generators = [
    // Giai đoạn 1 — Xe đẩy vỉa hè.
    GeneratorConfig(
      id: 'tra_den',
      name: 'Trà đen',
      baseCost: 15,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 0.5,
      stage: 1,
    ),
    // Giai đoạn 2 — Kiosk (topping).
    GeneratorConfig(
      id: 'tran_chau',
      name: 'Trân châu',
      baseCost: 100,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 4,
      stage: 2,
    ),
    GeneratorConfig(
      id: 'thach',
      name: 'Thạch',
      baseCost: 330,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 14,
      stage: 2,
    ),
    GeneratorConfig(
      id: 'pudding',
      name: 'Pudding',
      baseCost: 1100,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 45,
      stage: 2,
    ),
    // Giai đoạn 3 — Chuỗi cafe sang trọng (cao cấp).
    GeneratorConfig(
      id: 'kem_nuong',
      name: 'Trà sữa kem nướng',
      baseCost: 4000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 160,
      stage: 3,
    ),
    GeneratorConfig(
      id: 'matcha',
      name: 'Matcha xô',
      baseCost: 12000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 500,
      stage: 3,
    ),
    // Giai đoạn 4 — Xưởng trà sữa nướng (trend đường đen / brûlée).
    GeneratorConfig(
      id: 'duong_den',
      name: 'Sữa tươi đường đen',
      baseCost: 40000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 1600,
      stage: 4,
    ),
    GeneratorConfig(
      id: 'brulee',
      name: 'Trà sữa nướng',
      baseCost: 130000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 5000,
      stage: 4,
    ),
    // Giai đoạn 5 — Nhà máy phô mai tươi (cheese foam / trà trái cây).
    GeneratorConfig(
      id: 'cheese_foam',
      name: 'Kem phô mai',
      baseCost: 430000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 16000,
      stage: 5,
    ),
    GeneratorConfig(
      id: 'tra_trai_cay',
      name: 'Trà trái cây',
      baseCost: 1400000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 50000,
      stage: 5,
    ),
    // Giai đoạn 6 — Đế chế toàn cầu (cao cấp nhất).
    GeneratorConfig(
      id: 'boba_vang',
      name: 'Boba vàng',
      baseCost: 4600000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 160000,
      stage: 6,
    ),
    GeneratorConfig(
      id: 'galaxy',
      name: 'Trà sữa ngân hà',
      baseCost: 15000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 520000,
      stage: 6,
    ),
  ];
}
