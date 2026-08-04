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

  /// Ba giai đoạn kinh doanh (index = stage - 1). Giai đoạn 1 có sẵn.
  static const List<StageConfig> stages = [
    StageConfig(stage: 1, name: 'Xe đẩy vỉa hè', unlockCost: 0),
    StageConfig(stage: 2, name: 'Kiosk cửa hàng nhỏ', unlockCost: 2000),
    StageConfig(stage: 3, name: 'Chuỗi cafe sang trọng', unlockCost: 500000),
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
  ];
}
