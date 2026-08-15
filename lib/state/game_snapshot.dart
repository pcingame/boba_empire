/// Ảnh chụp BẤT BIẾN của trạng thái game để phát cho tầng UI.
///
/// Controller phát một snapshot mới sau mỗi thay đổi; widget dùng
/// `ref.watch(gameControllerProvider.select((s) => s.money))` để chỉ rebuild
/// đúng phần dữ liệu mình quan tâm (mục tối ưu Riverpod).
library;

import '../core/achievements.dart';
import '../core/quests.dart';

class GameSnapshot {
  const GameSnapshot({
    required this.money,
    required this.gems,
    required this.incomePerSecond,
    required this.prestigeStars,
    required this.prestigeStarsAvailable,
    required this.offlineEarned,
    required this.catVisible,
    required this.boostRemainingSeconds,
    required this.vipVisible,
    required this.gemBoostLevel,
    required this.offlineCapLevel,
    required this.stage,
    required this.adsRemoved,
    required this.starterPackOwned,
    required this.tutorialSeen,
    required this.dailyAvailable,
    required this.newAchievements,
    required this.lifetimeEarnings,
    required this.achievementsClaimed,
    required this.prestigeStarsSpendable,
    required this.prestigeIncomeLevel,
    required this.prestigeTapLevel,
    required this.currentQuest,
    required this.questProgress,
    required this.questDone,
    required this.doubleIncomeOwned,
    required this.x2IncomeRemainingSeconds,
    required this.piggyGems,
    required this.adFree,
    required this.vipActive,
    required this.vipRemainingSeconds,
    required this.freeSpinAvailable,
    required Map<String, int> levels,
  }) : _levels = levels;

  final double money;
  final double gems;

  /// Số Xu vừa kiếm lúc vắng mặt, >0 khi cần bật popup; UI gọi
  /// `acknowledgeOffline()` để về 0 sau khi đã hiển thị.
  final double offlineEarned;

  /// Thu nhập tự động mỗi giây (đã tính bonus prestige) — để hiển thị "+X/s".
  final double incomePerSecond;

  final int prestigeStars;

  /// Số Sao sẽ nhận nếu prestige ngay bây giờ (để bật/mờ nút Nhượng quyền).
  final int prestigeStarsAvailable;

  /// Con mèo Mưa vàng đang hiện trên màn hình hay không.
  final bool catVisible;

  /// Số giây còn lại của boost Mưa vàng (0 nếu không có) — để hiện đồng hồ ×3.
  final double boostRemainingSeconds;

  /// Khách VIP đang đứng chờ trên màn hình hay không.
  final bool vipVisible;

  /// Cấp vật phẩm Kim Cương "Tăng thu nhập" / "Kho lạnh offline".
  final int gemBoostLevel;
  final int offlineCapLevel;

  /// Giai đoạn kinh doanh hiện tại (1..3).
  final int stage;

  /// Đã mua "Gỡ quảng cáo" — UI bỏ qua QC và tự trao thưởng.
  final bool adsRemoved;

  /// Đã sở hữu "Gói khởi động" — cửa hàng ẩn/khoá mục này.
  final bool starterPackOwned;

  /// Đã xem hướng dẫn "Cách chơi" — quyết định có tự hiện lần đầu không.
  final bool tutorialSeen;

  /// Có phần thưởng đăng nhập hằng ngày chờ nhận (đã sang ngày mới).
  final bool dailyAvailable;

  /// Thành tựu vừa mở khoá (chờ UI báo rồi gọi acknowledgeAchievements()).
  final List<Achievement> newAchievements;

  /// Tổng thu nhập cả đời — dùng cho tiến độ thành tựu "Kiếm X Xu".
  final double lifetimeEarnings;

  /// Id thành tựu đã mở khoá — để bảng Thành tựu tô đã đạt/khoá.
  final List<String> achievementsClaimed;

  /// Số ⭐ Sao còn có thể tiêu trong kho prestige.
  final int prestigeStarsSpendable;

  /// Cấp perk "Siêu thu nhập" / "Siêu chạm" (kho Sao).
  final int prestigeIncomeLevel;
  final int prestigeTapLevel;

  /// Nhiệm vụ hiện tại (null = đã xong chuỗi), tiến độ, và đã đủ điều kiện nhận.
  final Quest? currentQuest;
  final num questProgress;
  final bool questDone;

  /// Đã mua x2 thu nhập vĩnh viễn (IAP) & số giây còn lại của x2 24h (xem QC).
  final bool doubleIncomeOwned;
  final double x2IncomeRemainingSeconds;

  /// Kim Cương đang tích trong heo đất (chờ "đập" bằng IAP).
  final double piggyGems;

  /// Được bỏ qua quảng cáo (đã mua Gỡ QC HOẶC đang VIP) — dùng để gate rewarded.
  final bool adFree;

  /// Đang VIP Pass & số giây còn lại của VIP.
  final bool vipActive;
  final double vipRemainingSeconds;

  /// Còn lượt quay Vòng quay miễn phí hôm nay không.
  final bool freeSpinAvailable;

  final Map<String, int> _levels;

  /// Cấp hiện tại của một nguồn thu. Trả `int` nên `.select` so sánh được,
  /// và không lộ map ra ngoài để tránh mutate ngoài ý muốn.
  int levelOf(String id) => _levels[id] ?? 0;
}
