/// Pure-Dart data models for the game core.
///
/// Không import `flutter` hay `rive` — tầng này là "linh hồn" mô phỏng, phải
/// chạy được và test được mà không cần UI.
library;

/// Cấu hình bất biến của một nguồn thu tự động (một món / quầy pha chế).
///
/// Đây là DATA, không phải logic: mọi con số balance nằm ở [balance.dart].
class GeneratorConfig {
  const GeneratorConfig({
    required this.id,
    required this.name,
    required this.baseCost,
    required this.costGrowth,
    required this.incomePerLevelPerSecond,
    this.stage = 1,
  });

  /// Khóa ổn định để tra cứu trong [GameState.levels] và khi serialize.
  final String id;

  /// Tên hiển thị (tiếng Việt).
  final String name;

  /// Giá nâng cấp ở cấp 0 → 1.
  final double baseCost;

  /// Hệ số tăng giá mỗi cấp (mục toán học: chi_phí = base * growth^level).
  final double costGrowth;

  /// Thu nhập mỗi giây cộng thêm cho mỗi cấp của nguồn thu này.
  final double incomePerLevelPerSecond;

  /// Giai đoạn mở khóa nguồn thu này (1..3).
  final int stage;
}

/// Cấu hình một giai đoạn kinh doanh (Xe đẩy → Kiosk → Chuỗi cafe).
class StageConfig {
  const StageConfig({
    required this.stage,
    required this.name,
    required this.unlockCost,
  });

  /// Số thứ tự giai đoạn (1..3).
  final int stage;

  /// Tên hiển thị.
  final String name;

  /// Số Xu cần để mở khóa giai đoạn này (giai đoạn 1 = 0, có sẵn).
  final double unlockCost;
}

/// Toàn bộ trạng thái động của một ván chơi.
///
/// Mutable có chủ đích: đây là đối tượng "sổ cái" được controller cập nhật mỗi
/// tick. Các hàm thuần trong [economy.dart] tính toán trên trạng thái này mà
/// không thay đổi nó; [simulation.dart] là nơi duy nhất được phép mutate.
class GameState {
  GameState({
    required this.money,
    required this.gems,
    required this.tapValue,
    required this.levels,
    required this.lifetimeEarnings,
    required this.prestigeStars,
    required this.lastSeenMillis,
    required this.gemBoostLevel,
    required this.offlineCapLevel,
    required this.stage,
    this.adsRemoved = false,
    this.starterPackOwned = false,
    this.tutorialSeen = false,
    this.lastDailyDay = 0,
    this.dailyStreak = 0,
    this.prestigeIncomeLevel = 0,
    this.prestigeTapLevel = 0,
    this.tapCount = 0,
    this.buyCount = 0,
    this.questIndex = 0,
    List<String>? achievementsClaimed,
  }) : achievementsClaimed = achievementsClaimed ?? [];

  /// Ván mới tinh.
  factory GameState.newGame({int? nowMillis}) => GameState(
        money: 0,
        gems: 0,
        tapValue: 1,
        levels: {},
        lifetimeEarnings: 0,
        prestigeStars: 0,
        lastSeenMillis: nowMillis ?? DateTime.now().millisecondsSinceEpoch,
        gemBoostLevel: 0,
        offlineCapLevel: 0,
        stage: 1,
      );

  /// Tiền tệ thường (Xu). Dùng `double` để không tràn ở số lớn (mục 10).
  double money;

  /// Tiền tệ cao cấp (Kim Cương).
  double gems;

  /// Số Xu nhận được mỗi lần chạm ly (giai đoạn đầu).
  double tapValue;

  /// Cấp hiện tại của từng nguồn thu: generatorId -> level. Vắng mặt = cấp 0.
  final Map<String, int> levels;

  /// Tổng Xu kiếm được cả đời (KHÔNG reset khi prestige) — dùng để quy đổi Sao.
  double lifetimeEarnings;

  /// Số "Sao nhượng quyền" đã tích lũy (bonus vĩnh viễn).
  int prestigeStars;

  /// Mốc thời gian lần cuối còn hoạt động (epoch ms) — dùng tính tiền offline.
  int lastSeenMillis;

  /// Cấp vật phẩm "Tăng thu nhập" mua bằng Kim Cương (+% vĩnh viễn).
  int gemBoostLevel;

  /// Cấp vật phẩm "Kho lạnh offline" (nâng trần tiền offline).
  int offlineCapLevel;

  /// Giai đoạn kinh doanh hiện tại (1..3).
  int stage;

  /// Đã mua "Gỡ quảng cáo" (IAP non-consumable) — bỏ qua QC, tự trao thưởng.
  bool adsRemoved;

  /// Đã nhận "Gói khởi động" (IAP non-consumable, một lần) — chống trao trùng.
  bool starterPackOwned;

  /// Đã xem hướng dẫn "Cách chơi" (tự hiện lần đầu, sau đó chỉ mở bằng nút ?).
  bool tutorialSeen;

  /// Chỉ số ngày (UTC) của lần nhận thưởng đăng nhập gần nhất; 0 = chưa nhận.
  int lastDailyDay;

  /// Chuỗi ngày điểm danh liên tiếp hiện tại.
  int dailyStreak;

  /// Id các thành tựu đã mở khoá & nhận thưởng (chống trao trùng).
  final List<String> achievementsClaimed;

  /// Cấp perk "Siêu thu nhập" mua bằng ⭐ Sao (kho prestige) — +% income vĩnh viễn.
  int prestigeIncomeLevel;

  /// Cấp perk "Siêu chạm" mua bằng ⭐ Sao — +% giá trị mỗi lần chạm vĩnh viễn.
  int prestigeTapLevel;

  /// Số lần chạm ly & số nâng cấp đã mua (đếm cho nhiệm vụ).
  int tapCount;
  int buyCount;

  /// Số nhiệm vụ đã hoàn thành (= chỉ số nhiệm vụ hiện tại trong chuỗi).
  int questIndex;

  Map<String, dynamic> toJson() => {
        'money': money,
        'gems': gems,
        'tapValue': tapValue,
        'levels': levels,
        'lifetimeEarnings': lifetimeEarnings,
        'prestigeStars': prestigeStars,
        'lastSeenMillis': lastSeenMillis,
        'gemBoostLevel': gemBoostLevel,
        'offlineCapLevel': offlineCapLevel,
        'stage': stage,
        'adsRemoved': adsRemoved,
        'starterPackOwned': starterPackOwned,
        'tutorialSeen': tutorialSeen,
        'lastDailyDay': lastDailyDay,
        'dailyStreak': dailyStreak,
        'achievementsClaimed': achievementsClaimed,
        'prestigeIncomeLevel': prestigeIncomeLevel,
        'prestigeTapLevel': prestigeTapLevel,
        'tapCount': tapCount,
        'buyCount': buyCount,
        'questIndex': questIndex,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        money: (json['money'] as num).toDouble(),
        gems: (json['gems'] as num).toDouble(),
        tapValue: (json['tapValue'] as num).toDouble(),
        levels: (json['levels'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toInt()),
        ),
        lifetimeEarnings: (json['lifetimeEarnings'] as num).toDouble(),
        prestigeStars: (json['prestigeStars'] as num).toInt(),
        lastSeenMillis: (json['lastSeenMillis'] as num).toInt(),
        // Mặc định 0 cho save cũ chưa có các trường này.
        gemBoostLevel: (json['gemBoostLevel'] as num?)?.toInt() ?? 0,
        offlineCapLevel: (json['offlineCapLevel'] as num?)?.toInt() ?? 0,
        stage: (json['stage'] as num?)?.toInt() ?? 1,
        adsRemoved: (json['adsRemoved'] as bool?) ?? false,
        starterPackOwned: (json['starterPackOwned'] as bool?) ?? false,
        tutorialSeen: (json['tutorialSeen'] as bool?) ?? false,
        lastDailyDay: (json['lastDailyDay'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        achievementsClaimed:
            (json['achievementsClaimed'] as List?)?.cast<String>().toList(),
        prestigeIncomeLevel:
            (json['prestigeIncomeLevel'] as num?)?.toInt() ?? 0,
        prestigeTapLevel: (json['prestigeTapLevel'] as num?)?.toInt() ?? 0,
        tapCount: (json['tapCount'] as num?)?.toInt() ?? 0,
        buyCount: (json['buyCount'] as num?)?.toInt() ?? 0,
        questIndex: (json['questIndex'] as num?)?.toInt() ?? 0,
      );
}
