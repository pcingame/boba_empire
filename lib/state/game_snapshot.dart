/// Ảnh chụp BẤT BIẾN của trạng thái game để phát cho tầng UI.
///
/// Controller phát một snapshot mới sau mỗi thay đổi; widget dùng
/// `ref.watch(gameControllerProvider.select((s) => s.money))` để chỉ rebuild
/// đúng phần dữ liệu mình quan tâm (mục tối ưu Riverpod).
library;

import '../core/achievements.dart';
import '../core/daily_quests.dart';
import '../core/quests.dart';
import '../core/rival.dart';

/// Ảnh chụp bất biến của một nhiệm vụ ngày cho UI.
class DailyQuestView {
  const DailyQuestView({
    required this.kind,
    required this.target,
    required this.progress,
    required this.rewardGems,
    required this.claimed,
  });

  final DailyQuestKind kind;
  final double target;
  final double progress;
  final int rewardGems;
  final bool claimed;

  bool get done => progress >= target;
}

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
    required this.eventActive,
    required this.eventRemainingSeconds,
    required this.eventMultiplier,
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
    required this.m3Stars,
    required this.ownedAccessories,
    required this.accessorySpares,
    required this.equippedAccessories,
    required this.m3HowToSeen,
    required this.prestigeStarsSpendable,
    required this.prestigeIncomeLevel,
    required this.prestigeTapLevel,
    required this.prestigeOfflineLevel,
    required this.prestigeStartCashLevel,
    required this.prestigeKeepStageLevel,
    required this.prestigeDiscountLevel,
    required this.prestigeAutoBuyLevel,
    required this.autoBuyEnabled,
    required this.upgradeCostMult,
    required this.globalMilestoneMult,
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
    required this.gemTimeSkipRemainingToday,
    required this.storyChapter,
    required this.pendingStoryChapterId,
    required this.storyChoiceA,
    required this.storyChoiceB,
    required this.storyCompleteSeconds,
    required this.storyExtCompleteSeconds,
    required this.storyThirdActCompleteSeconds,
    required this.rivalActive,
    required this.rivalDefeated,
    required this.rivalStanding,
    required this.rivalPowerRatio,
    required this.pendingRivalEvent,
    required this.rivalModifierRemainingSeconds,
    required this.rivalModifierMult,
    required this.dailyQuests,
    required this.dailyBonusAvailable,
    required this.dailyBonusClaimed,
    required this.dailyClaimableCount,
    required this.ascensionCount,
    required this.ascensionPointsAvailable,
    required this.ascensionPointsSpendable,
    required this.ascensionProgress,
    required this.ascensionIncomeLevel,
    required this.ascensionStarBonusLevel,
    required this.ascensionStarGainLevel,
    required Map<String, int> levels,
  }) : _levels = levels;

  final double money;
  final double gems;

  /// Số Xu vừa kiếm lúc vắng mặt, >0 khi cần bật popup; UI gọi
  /// `acknowledgeOffline()` để về 0 sau khi đã hiển thị.
  final double offlineEarned;

  /// Thu nhập tự động mỗi giây (đã tính bonus prestige) — để hiển thị "+X/s".
  final double incomePerSecond;

  final double prestigeStars;

  /// Số Sao sẽ nhận nếu prestige ngay bây giờ (để bật/mờ nút Nhượng quyền).
  final double prestigeStarsAvailable;

  /// Con mèo Mưa vàng đang hiện trên màn hình hay không.
  final bool catVisible;

  /// Số giây còn lại của boost Mưa vàng (0 nếu không có) — để hiện đồng hồ ×3.
  final double boostRemainingSeconds;

  /// Khách VIP đang đứng chờ trên màn hình hay không.
  final bool vipVisible;

  /// Sự kiện giới hạn thời gian (Remote Config) đang chạy hay không.
  final bool eventActive;

  /// Số giây còn lại tới lúc sự kiện kết thúc — 0 nếu [eventActive] false.
  final int eventRemainingSeconds;

  /// Hệ số sự kiện hiện tại (1.0 nếu không có sự kiện) — cho banner hiện
  /// đúng số ("×2") thay vì hardcode.
  final double eventMultiplier;

  /// Cấp vật phẩm Kim Cương "Tăng thu nhập" / "Kho lạnh offline".
  final int gemBoostLevel;
  final int offlineCapLevel;

  /// Giai đoạn kinh doanh hiện tại (1..6).
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

  /// Sao Hành trình Ghép 3 (chỉ số = màn - 1, giá trị 0..3).
  final List<int> m3Stars;

  /// Id phụ kiện sưu tập đã có (xem `core/accessories.dart`).
  final List<String> ownedAccessories;

  /// Bản sao dư mỗi món (xem GameState.accessorySpares).
  final Map<String, int> accessorySpares;

  /// Phụ kiện đang trưng bày quanh cốc (xem GameState.equippedAccessories).
  final List<String> equippedAccessories;

  /// Đã xem hướng dẫn Trân Châu Rơi chưa.
  final bool m3HowToSeen;

  /// Số ⭐ Sao còn có thể tiêu trong kho prestige.
  final double prestigeStarsSpendable;

  /// Cấp các perk kho Sao.
  final int prestigeIncomeLevel;
  final int prestigeTapLevel;
  final int prestigeOfflineLevel;
  final int prestigeStartCashLevel;
  final int prestigeKeepStageLevel;
  final int prestigeDiscountLevel;

  /// Perk "Tự động mua" (0/1) + công tắc auto-buy đang bật.
  final int prestigeAutoBuyLevel;
  final bool autoBuyEnabled;

  /// Hệ số nhân giá nâng cấp nguồn thu (≤ 1) từ perk "Mua sỉ" — UI nhân vào giá
  /// hiển thị + kiểm tra đủ tiền.
  final double upgradeCostMult;

  /// Hệ số thu nhập toàn cục từ "mốc vàng" (≥ 1) — hiển thị ở đầu shop.
  final double globalMilestoneMult;

  /// Nhiệm vụ hiện tại (luôn có — sau chuỗi 10 bước là chuỗi "kiếm thêm" vô hạn),
  /// tiến độ, và đã đủ điều kiện nhận.
  final Quest currentQuest;
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

  /// Số lượt "Tua nhanh" (💎) còn lại hôm nay (xem Balance.maxGemTimeSkipPerDay).
  final int gemTimeSkipRemainingToday;

  /// Chương cốt truyện cao nhất đã xem, và chương cần hiển thị ngay (null nếu
  /// không có) — UI bật cutscene rồi gọi `acknowledgeStoryBeat()` / `makeStoryChoice()`.
  final int storyChapter;
  final int? pendingStoryChapterId;

  /// Lựa chọn nhánh đã ghi (Chương 6 / Chương 8) — null nếu chưa chọn.
  final String? storyChoiceA;
  final String? storyChoiceB;

  /// Số giây hoàn thành cốt truyện (xem Chương 18 lần đầu) — null nếu chưa
  /// hoàn thành. Dùng cho Bảng xếp hạng tốc độ (story_speedrun_page.dart).
  final int? storyCompleteSeconds;

  /// Như [storyCompleteSeconds] nhưng tới Chương 28 — cho bảng "Hồi 2".
  final int? storyExtCompleteSeconds;

  /// Như [storyCompleteSeconds] nhưng tới Chương 36 — cho bảng "Hồi 3".
  final int? storyThirdActCompleteSeconds;

  /// Đối thủ đang "hoạt động" (Chương 3+ và chưa bị hạ) & đã bị hạ.
  final bool rivalActive;
  final bool rivalDefeated;

  /// Thế trận + tỉ số sức_ép/kỳ_vọng (cho chip ⚔️ và thanh đo ở header).
  final RivalStanding rivalStanding;
  final double rivalPowerRatio;

  /// Sự kiện đối thủ đang chờ trả lời (null nếu không) — UI bật dialog rồi gọi
  /// `resolveRivalEvent()` / `ignoreRivalEvent()`.
  final RivalEventType? pendingRivalEvent;

  /// Buff/debuff tạm sau lựa chọn đối phó: số giây còn lại + hệ số (1.0 = không).
  final double rivalModifierRemainingSeconds;
  final double rivalModifierMult;

  /// Kỷ Nguyên (prestige tầng 2): số lần đã hoá, Điểm nhận được nếu hoá ngay,
  /// Điểm còn tiêu được, tiến độ tới ngưỡng mở (0..1), và cấp 3 perk.
  /// Nhiệm vụ hằng ngày hôm nay (3 mục), thưởng "xong cả bộ", và số thứ đang chờ
  /// nhận (chấm đỏ ở màn chính).
  final List<DailyQuestView> dailyQuests;
  final bool dailyBonusAvailable;
  final bool dailyBonusClaimed;
  final int dailyClaimableCount;

  final int ascensionCount;
  final int ascensionPointsAvailable;
  final int ascensionPointsSpendable;
  final double ascensionProgress;
  final int ascensionIncomeLevel;
  final int ascensionStarBonusLevel;
  final int ascensionStarGainLevel;

  final Map<String, int> _levels;

  /// Cấp hiện tại của một nguồn thu. Trả `int` nên `.select` so sánh được,
  /// và không lộ map ra ngoài để tránh mutate ngoài ý muốn.
  int levelOf(String id) => _levels[id] ?? 0;
}
