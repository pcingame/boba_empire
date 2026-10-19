/// Pure-Dart data models for the game core.
///
/// Không import `flutter` hay `rive` — tầng này là "linh hồn" mô phỏng, phải
/// chạy được và test được mà không cần UI.
library;

import 'branches.dart' show isBranchSetKey;

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

  /// Giai đoạn mở khóa nguồn thu này (1..6).
  final int stage;
}

/// Cấu hình một giai đoạn kinh doanh (Xe đẩy → Kiosk → … → Đế chế toàn cầu).
class StageConfig {
  const StageConfig({
    required this.stage,
    required this.name,
    required this.unlockCost,
  });

  /// Số thứ tự giai đoạn (1..12).
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
    this.m3HowToSeen = false,
    this.lastDailyDay = 0,
    this.dailyStreak = 0,
    this.prestigeIncomeLevel = 0,
    this.prestigeTapLevel = 0,
    this.prestigeOfflineLevel = 0,
    this.prestigeStartCashLevel = 0,
    this.prestigeKeepStageLevel = 0,
    this.prestigeDiscountLevel = 0,
    this.prestigeAutoBuyLevel = 0,
    this.dailyQuestDay = 0,
    this.dailyEarnTarget = 0,
    this.dailyBonusClaimed = false,
    this.weeklyQuestWeek = 0,
    this.weeklyBonusClaimed = false,
    Map<String, double>? weeklyProgress,
    List<String>? weeklyClaimed,
    Map<String, List<int>>? recipeProgress,
    List<int>? recipeMilestonesClaimed,
    List<int>? recipeOrderPerfect,
    this.recipeDailyDay = -1,
    this.recipeDailyScore = 0,
    this.recipeDailyCount = 0,
    this.recipeStreak = 0,
    this.recipeStreakLastDay = 0,
    this.recipeStreakBest = 0,
    this.accessoryAdDropDay = 0,
    this.accessoryAdSpinDay = 0,
    this.accessoryAdSpins = 0,
    this.dailyQuestEverClaimed = false,
    this.starterPackClaimed = false,
    Map<String, double>? dailyProgress,
    List<String>? dailyClaimed,
    this.ascensionCount = 0,
    this.ascensionPointsEarned = 0,
    this.ascensionLifetime = 0,
    this.ascensionIncomeLevel = 0,
    this.ascensionStarBonusLevel = 0,
    this.ascensionStarGainLevel = 0,
    this.autoBuyEnabled = false,
    this.storyChapter = 0,
    this.storyChoiceA,
    this.storyChoiceB,
    this.storyChoiceC,
    this.storyChoiceD,
    this.storyChoiceE,
    this.storyChoiceF,
    this.storyChoiceG,
    this.storyChoiceH,
    this.rivalDefeated = false,
    this.rivalPressureSeconds = 0,
    this.repeatQuestBaseline = 0,
    this.tapCount = 0,
    this.buyCount = 0,
    this.questIndex = 0,
    this.doubleIncomeOwned = false,
    this.coldStorageOwned = false,
    this.vipExp = 0,
    this.vipCoins = 0,
    this.dealClaimedDay = 0,
    this.dailyItemDay = 0,
    this.seasonId = 0,
    this.seasonXp = 0,
    this.seasonPremium = false,
    List<int>? seasonFreeClaimed,
    List<int>? seasonPremiumClaimed,
    this.seasonXpDay = 0,
    this.seasonXpToday = 0,
    this.referralRedeemed = false,
    this.referralStageSent = false,
    this.vipTitleChoice = -1,
    List<String>? firstBuyClaimed,
    this.vipExpFromGems = 0,
    this.vipClaimDay = 0,
    this.vipClaimWeek = 0,
    this.vipClaimMonth = 0,
    List<int>? topupClaimed,
    this.x2IncomeUntilMillis = 0,
    this.autoTapUntilMillis = 0,
    this.boostUntilMillis = 0,
    this.piggyGems = 0,
    this.vipUntilMillis = 0,
    this.equipLockUntilMillis = 0,
    this.essence = 0,
    this.essenceDay = 0,
    this.essenceOrdersToday = 0,
    this.essenceRepeatableToday = 0,
    this.vipLastGemDay = 0,
    this.lastFreeSpinDay = 0,
    this.gemTimeSkipDay = 0,
    this.gemTimeSkipUsedToday = 0,
    int? firstPlayedMillis,
    this.firstPlayedIsEstimate = false,
    this.storyCompleteSeconds,
    this.storyExtCompleteSeconds,
    this.storyThirdActCompleteSeconds,
    this.storyFourthActCompleteSeconds,
    List<String>? achievementsClaimed,
    List<int>? m3Stars,
    List<String>? redeemedCodes,
    List<String>? ownedAccessories,
    List<String>? howToSeen,
    List<String>? ownedLimited,
    this.eventId = '',
    this.guildWeek = 0,
    this.guildWeekScore = 0,
    this.dungeonWeek = 0,
    this.dungeonTap = 0,
    this.dungeonOffline = 0,
    this.dungeonRecipe = 0,
    this.guildJoined = false,
    this.guildVipBonusPct = 0,
    this.guildBuffUntilMillis = 0,
    this.eventPoints = 0,
    Map<String, double>? eventProgress,
    List<String>? eventClaimed,
    Map<String, int>? accessorySpares,
    Map<int, int>? masteryTiers,
    Map<String, int>? refineLevels,
    Map<String, int>? branchLevels,
    Map<String, int>? branchSince,
    List<String>? branchSetClaims,
    this.branchManagerUntilMillis = 0,
    Map<String, int>? branchSpecs,
    this.branchEventClaimedSlot = -1,
    this.branchMapSkin = 0,
    this.branchQuestDayKey = -1,
    List<int>? branchQuestProgress,
    this.branchQuestClaimed = 0,
    List<String>? equippedAccessories,
    List<int>? collectionMilestonesClaimed,
    List<String>? collectionSetsClaimed,
    List<String>? wishlist,
  })  : achievementsClaimed = achievementsClaimed ?? [],
        m3Stars = m3Stars ?? [],
        redeemedCodes = redeemedCodes ?? [],
        ownedAccessories = ownedAccessories ?? [],
        howToSeen = howToSeen ?? [],
        ownedLimited = ownedLimited ?? [],
        topupClaimed = topupClaimed ?? [],
        firstBuyClaimed = firstBuyClaimed ?? [],
        eventProgress = eventProgress ?? {},
        eventClaimed = eventClaimed ?? [],
        accessorySpares = accessorySpares ?? {},
        masteryTiers = masteryTiers ?? {},
        refineLevels = refineLevels ?? {},
        branchLevels = branchLevels ?? {},
        branchSince = branchSince ?? {},
        branchSetClaims = branchSetClaims ?? [],
        branchSpecs = branchSpecs ?? {},
        branchQuestProgress = branchQuestProgress ?? [0, 0, 0, 0],
        equippedAccessories = equippedAccessories ?? [],
        collectionMilestonesClaimed = collectionMilestonesClaimed ?? [],
        collectionSetsClaimed = collectionSetsClaimed ?? [],
        seasonFreeClaimed = seasonFreeClaimed ?? [],
        seasonPremiumClaimed = seasonPremiumClaimed ?? [],
        wishlist = wishlist ?? [],
        dailyProgress = dailyProgress ?? {},
        dailyClaimed = dailyClaimed ?? [],
        weeklyProgress = weeklyProgress ?? {},
        weeklyClaimed = weeklyClaimed ?? [],
        recipeProgress = recipeProgress ?? {},
        recipeMilestonesClaimed = recipeMilestonesClaimed ?? [],
        recipeOrderPerfect = recipeOrderPerfect ?? [],
        firstPlayedMillis = firstPlayedMillis ?? lastSeenMillis;

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
  ///
  /// `double` chứ KHÔNG phải `int`: Sao = k·√lifetime, mà lifetime cuối tuyến
  /// đã ~1e68 trên máy người chơi thật → Sao ~2e32, vượt xa trần int64
  /// (9,2e18). `.floor()` trên double lớn hơn int64 KHÔNG ném lỗi mà KẸP im
  /// lặng ở 9223372036854775807 — đo được trên 77/1184 người chơi ngày
  /// 2026-09-29: Sao đứng yên vĩnh viễn, `prestigeStarsAvailable` = 0, Nhượng
  /// quyền mất sạch ý nghĩa (và cộng thêm 1 là quay vòng thành SỐ ÂM).
  /// Mất độ chính xác nguyên trên 2^53 chấp nhận được: ở mức đó Sao chỉ còn là
  /// thang đo, UI vốn đã in bằng hậu tố.
  double prestigeStars;

  /// Mốc thời gian lần cuối còn hoạt động (epoch ms) — dùng tính tiền offline.
  int lastSeenMillis;

  /// Cấp vật phẩm "Tăng thu nhập" mua bằng Kim Cương (+% vĩnh viễn).
  int gemBoostLevel;

  /// Cấp vật phẩm "Kho lạnh offline" (nâng trần tiền offline).
  int offlineCapLevel;

  /// Giai đoạn kinh doanh hiện tại (1..12).
  int stage;

  /// Đã mua "Gỡ quảng cáo" (IAP non-consumable) — bỏ qua QC, tự trao thưởng.
  bool adsRemoved;

  /// Đã nhận "Gói khởi động" (IAP non-consumable, một lần) — chống trao trùng.
  bool starterPackOwned;

  /// Đã xem hướng dẫn "Cách chơi" (tự hiện lần đầu, sau đó chỉ mở bằng nút ?).
  bool tutorialSeen;

  /// Đã xem hướng dẫn riêng của Trân Châu Rơi (tự hiện lần đầu mở tab).
  bool m3HowToSeen;

  /// Chỉ số ngày (UTC) của lần nhận thưởng đăng nhập gần nhất; 0 = chưa nhận.
  int lastDailyDay;

  /// Chuỗi ngày điểm danh liên tiếp hiện tại.
  int dailyStreak;

  /// Id các thành tựu đã mở khoá & nhận thưởng (chống trao trùng).
  final List<String> achievementsClaimed;

  /// Sao đã đạt ở Hành trình Ghép 3: chỉ số = màn - 1, giá trị 0..3. Danh sách
  /// dài dần theo tiến độ (không cấp phát sẵn đủ số màn). KHÔNG reset khi
  /// Nhượng quyền / Kỷ Nguyên — cùng nhóm với thành tựu, cốt truyện.
  final List<int> m3Stars;

  /// Mã quà tặng đã nhận (VD mã bù đắp sự cố) — chống nhận trùng. Xem
  /// `core/redeem.dart`.
  final List<String> redeemedCodes;

  /// Id phụ kiện sưu tập đã có (xem `core/accessories.dart`), KHÔNG lặp —
  /// rớt trùng quy đổi 💎 thay vì thêm vào đây. Không reset khi Nhượng
  /// quyền/Kỷ Nguyên, cùng nhóm với thành tựu, cốt truyện.
  final List<String> ownedAccessories;

  /// Hướng dẫn trò chơi nhỏ đã tự hiện lần đầu: 'recipes' | 'orders' | 'daily' (xem minigame_how_to_dialogs.dart).
  /// (Trân Châu Rơi có cờ riêng [m3HowToSeen] từ trước.) Save cũ → rỗng.
  final List<String> howToSeen;

  /// Phụ kiện độc quyền theo dịp lễ (xem accessories.dart `festivals`) — tách khỏi
  /// [ownedAccessories] để không dính số đếm bộ sưu tập / BXH / Chợ.
  final List<String> ownedLimited;

  /// Nhiệm vụ sự kiện theo dịp lễ (event_quests.dart): id dịp đang theo dõi
  /// ('' = không có), tiến độ cộng dồn, nhiệm vụ đã nhận, điểm đổi món.
  String eventId;

  /// Hội (guild.dart): chỉ số tuần (thứ Hai UTC) và điểm hoạt động tuần này.
  int guildWeek;
  double guildWeekScore;

  /// Phó bản Hội (guild_dungeon.dart): tuần đang đếm và ba bộ đếm LUỸ KẾ trong tuần (chạm / giây offline /
  /// điểm Công thức) — báo lên server dạng tổng luỹ kế, nên chỉ reset khi sang tuần mới.
  int dungeonWeek;
  int dungeonTap;
  double dungeonOffline;
  int dungeonRecipe;

  /// Đang ở một hội (cập nhật khi mở màn Hội) — quyết định có hỏi server về buff hội
  /// lúc mở app hay không — và mốc (đồng hồ máy, ms) hết buff thu nhập cả hội.
  bool guildJoined;

  /// % thu nhập cộng thêm từ thành viên VIP trong hội (server báo; chỉ áp khi [guildJoined]).
  int guildVipBonusPct;
  int guildBuffUntilMillis;
  int eventPoints;
  final Map<String, double> eventProgress;
  final List<String> eventClaimed;

  /// Số bản SAO DƯ ngoài bản đầu của mỗi món (id → n ≥ 1; không có khoá = 0
  /// dư). Rớt trùng cộng vào đây (xem grantAccessory) — bản dư bán được ở Chợ
  /// mà không mất món đang sưu tập.
  final Map<String, int> accessorySpares;

  /// 🧪 Tinh chất đang có (kiếm từ trò nhỏ, xem essence.dart). Giữ qua Nhượng quyền và Kỷ Nguyên.
  int essence;

  /// Bậc Bí quyết đã mua theo giai đoạn (giai đoạn → 1..[Balance.masteryMaxTier]). Giữ qua Nhượng quyền/Kỷ Nguyên.
  final Map<int, int> masteryTiers;

  /// Cấp tinh luyện từng phụ kiện (0–3, xem accessory_refine.dart). Chỉ lưu món > 0. Giữ qua Nhượng quyền/Kỷ Nguyên.
  final Map<String, int> refineLevels;

  /// Chi nhánh thành phố (core/branches.dart): cấp (0 = chưa mở) và mốc (epoch ms) lần thu gần nhất.
  final Map<String, int> branchLevels;
  final Map<String, int> branchSince;

  /// Mốc bộ sưu tập chi nhánh đã nhận ('asia:1'…) và hạn hợp đồng Quản lý chi nhánh (epoch ms, 0 = chưa thuê).
  final List<String> branchSetClaims;
  int branchManagerUntilMillis;

  /// Chuyên ngành đã chọn (id → 1/2), ô sự kiện chi nhánh đã nhận gần nhất, skin bản đồ (0..3).
  final Map<String, int> branchSpecs;
  int branchEventClaimedSlot;
  int branchMapSkin;

  /// Nhiệm vụ chi nhánh trong ngày: khoá ngày (UTC), tiến độ 4 nhiệm vụ, mặt nạ bit đã nhận.
  int branchQuestDayKey;
  List<int> branchQuestProgress;
  int branchQuestClaimed;

  /// Bộ đếm Tinh chất nguồn lặp lại trong ngày [essenceDay] (dayIndex UTC): riêng đơn Pha theo đơn, và chung.
  int essenceDay;
  int essenceOrdersToday;
  int essenceRepeatableToday;

  /// Id phụ kiện đang TRƯNG BÀY quanh cốc ở màn chính (≤ Balance.maxEquippedAccessories,
  /// đều phải đang sở hữu). Vừa trưng bày vừa cho buff theo họ (accessory_loadout.dart).
  final List<String> equippedAccessories;

  /// Mốc sưu tập đã nhận thưởng (xem collection_milestones.dart). Server mới là
  /// nguồn sự thật — đây chỉ để ẩn nút nhận.
  final List<int> collectionMilestonesClaimed;

  /// Bộ sưu tập đã nhận thưởng (id của CollectionSet).
  final List<String> collectionSetsClaimed;

  /// Món muốn có (≤ Balance.maxWishlist) — đồng bộ lên server để đẩy thông báo
  /// khi có người đăng bán.
  final List<String> wishlist;

  /// Cấp perk "Siêu thu nhập" mua bằng ⭐ Sao (kho prestige) — +% income vĩnh viễn.
  int prestigeIncomeLevel;

  /// Cấp perk "Siêu chạm" mua bằng ⭐ Sao — +% giá trị mỗi lần chạm vĩnh viễn.
  int prestigeTapLevel;

  /// Cấp perk "Siêu offline" — +% thu nhập lúc vắng mặt.
  int prestigeOfflineLevel;

  /// Cấp perk "Vốn khởi nghiệp" — Xu nhận ngay sau Nhượng quyền.
  int prestigeStartCashLevel;

  /// Cấp perk "Giữ giai đoạn" — giữ tới giai đoạn (1 + cấp) sau Nhượng quyền.
  int prestigeKeepStageLevel;

  /// Cấp perk "Mua sỉ" — giảm % giá nâng cấp mọi nguồn thu.
  int prestigeDiscountLevel;

  /// Cấp perk "Tự động mua" (0/1) — mở khoá công tắc [autoBuyEnabled].
  int prestigeAutoBuyLevel;

  /// Nhiệm vụ hằng ngày (xem daily_quests.dart): ngày (UTC) của bộ đang có, ngưỡng
  /// "Kiếm Xu" đã chốt, tiến độ theo loại (khoá = DailyQuestKind.name), loại đã
  /// nhận thưởng, và đã nhận thưởng "xong cả bộ" chưa. Reset khi sang ngày; KHÔNG
  /// bị reset bởi Nhượng quyền/Kỷ Nguyên. Save cũ thiếu → rỗng/0.
  int dailyQuestDay;
  double dailyEarnTarget;
  bool dailyBonusClaimed;

  /// Ngày (UTC, [dayIndex]) đã nhận lượt rớt phụ kiện thưởng xem QC — 1 lần/ngày.
  int accessoryAdDropDay;

  /// Vòng quay phụ kiện: ngày (UTC) + số lượt xem-QC đã dùng trong ngày đó.
  int accessoryAdSpinDay;
  int accessoryAdSpins;

  /// Đã từng nhận thưởng ≥1 nhiệm vụ ngày (điều kiện Gói Khởi Nghiệp Chợ).
  bool dailyQuestEverClaimed;

  /// Đã nhận Gói Khởi Nghiệp Chợ (server cũng chặn, xem claim_starter_pack).
  bool starterPackClaimed;
  final Map<String, double> dailyProgress;
  final List<String> dailyClaimed;

  /// Nhiệm vụ tuần (xem weekly_quests.dart): tuần của bộ đang có, tiến độ theo loại
  /// (khoá = WeeklyQuestKind.name), loại đã nhận, và đã mở rương chưa. Giữ qua Nhượng quyền/Kỷ Nguyên.
  int weeklyQuestWeek;
  bool weeklyBonusClaimed;
  final Map<String, double> weeklyProgress;
  final List<String> weeklyClaimed;

  /// Bậc thuộc công thức pha chế (xem recipe_mastery.dart): id món → `[box, dueDay, best]`.
  final Map<String, List<int>> recipeProgress;

  /// Các mốc rương phụ kiện công thức đã nhận (số món Thạo), xem `recipeAccessoryMilestones`.
  final List<int> recipeMilestonesClaimed;

  /// Id các món đã TỪNG pha hoàn hảo ở chế độ "Pha theo đơn" mà không nhìn công thức mẫu (không gợi ý, không
  /// bậc Mới) — nguồn của bảng xếp hạng Pha theo đơn. Không trùng, chỉ tăng.
  final List<int> recipeOrderPerfect;

  /// Thử thách hằng ngày của Pha theo đơn: ngày (dayIndex) đã làm gần nhất (-1 = chưa bao giờ) và điểm hôm đó.
  /// Mỗi ngày chỉ làm một lần.
  int recipeDailyDay;
  int recipeDailyScore;

  /// Tổng số NGÀY đã làm Thử thách hằng ngày (mốc cho Chương 40/44 của Hồi 4). Chỉ tăng.
  int recipeDailyCount;

  /// Chuỗi ngày ôn công thức (xem recipe_mastery.dart): số ngày, ngày ôn gần nhất (dayIndex), kỷ lục.
  int recipeStreak;
  int recipeStreakLastDay;
  int recipeStreakBest;

  /// Kỷ Nguyên (prestige tầng 2, xem Balance.ascension*): số lần đã Kỷ Nguyên
  /// hoá, tổng Điểm đã nhận (đã tiêu = suy ra từ cấp perk, giống Kho Sao), và
  /// [ascensionLifetime] — lifetime kiếm được KỂ TỪ lần Kỷ Nguyên gần nhất.
  ///
  /// Là bộ tích lũy RIÊNG chứ không phải `lifetimeEarnings − baseline`: sau khi
  /// Kỷ Nguyên hoá, lifetimeEarnings đã ~1e37 nên mỗi tick cộng vài Xu bị double
  /// nuốt hoàn toàn (ulp ~1e21) → phép trừ sẽ đứng yên ở 0 rất lâu và Sao không
  /// tích được. Chỉ dùng khi [ascensionCount] > 0 (trước đó dùng thẳng
  /// lifetimeEarnings, nên save cũ và test cũ không đổi). Save cũ thiếu → 0.
  int ascensionCount;
  int ascensionPointsEarned;
  double ascensionLifetime;

  /// Cấp 3 perk Kỷ Nguyên: thu nhập / bonus mỗi Sao / tốc độ tích Sao.
  int ascensionIncomeLevel;
  int ascensionStarBonusLevel;
  int ascensionStarGainLevel;

  /// Công tắc auto-buy đang bật (chỉ có tác dụng khi có perk).
  bool autoBuyEnabled;

  /// Chương cốt truyện cao nhất đã xem (0 = chưa có gì). KHÔNG reset khi prestige
  /// — cốt truyện là tiến trình meta, giống thành tựu / lifetimeEarnings.
  int storyChapter;

  /// Lựa chọn nhánh Chương 6 ('craft' | 'scale' | null) và Chương 8
  /// ('acquire' | 'identity' | null). Ghi một lần, không đổi được. Mỗi lựa chọn
  /// cộng một perk nhỏ vĩnh viễn (xem [Balance.storyPerkBonus]).
  String? storyChoiceA;
  String? storyChoiceB;

  /// Lựa chọn nhánh Chương 13 ('independent' | 'merger' | null) và Chương 18
  /// ('soul' | 'global' | null) — hồi truyện mở rộng (mục "thế giới lớn hơn"),
  /// cùng cơ chế/perk như storyChoiceA/B.
  String? storyChoiceC;
  String? storyChoiceD;

  /// Lựa chọn nhánh Chương 23 ('heritage' | 'export' | null) và Chương 28
  /// ('recipe' | 'people' | null) — hồi mở rộng giai đoạn 13-18, cùng cơ chế/perk
  /// như A-D. Save cũ thiếu 2 trường này → null (chưa chọn).
  String? storyChoiceE;
  String? storyChoiceF;

  /// Lựa chọn nhánh Chương 36 ('secret' | 'open' | null) — Hồi 3 (Kỷ Nguyên +
  /// Trân Châu Rơi làm bài luyện tay nghề). Save cũ thiếu trường này → null.
  String? storyChoiceG;

  /// Lựa chọn nhánh Chương 46 ('mastery' | 'spirit' | null) — Hồi 4 (Đại Hội Tay Nghề). Save cũ → null.
  String? storyChoiceH;

  /// Mốc thời gian (epoch ms) lần đầu tạo save — đặt 1 lần ở [GameState.newGame],
  /// KHÔNG đổi sau đó (kể cả prestige). Dùng làm mốc "bắt đầu" để tính
  /// [storyCompleteSeconds] cho bảng xếp hạng tốc độ hoàn thành cốt truyện.
  int firstPlayedMillis;

  /// true nếu [firstPlayedMillis] là GIÁ TRỊ ĐOÁN (save cũ trước khi trường
  /// này tồn tại, gán tạm = `lastSeenMillis` lúc nạp) chứ không phải mốc thật.
  ///
  /// Bug thật đã gặp (2026-09-29, xem speedrun-one-second-entries memory):
  /// giá trị đoán này gần "bây giờ" nên nếu người chơi hoàn thành cốt truyện
  /// ngay sau đó, `now - firstPlayedMillis` ra một con số nhỏ giả tạo (86s,
  /// 150s...) dù họ đã chơi thật hàng giờ/ngày trước đó để lên tới GĐ12 —
  /// TRÔNG như gian lận nhưng không phải, chỉ là mất dấu mốc thật. Cờ này
  /// chặn việc chốt mốc tốc độ khi không tin được số liệu, thay vì cố tính
  /// ra một con số (dù đúng hướng "cao hơn thực tế" như bản vá cũ) — con số
  /// nhỏ giả tạo còn tệ hơn nhiều so với không hiện lên bảng xếp hạng.
  bool firstPlayedIsEstimate;

  /// Số giây thực tế (epoch, không phải giờ chơi) từ [firstPlayedMillis] tới
  /// lúc xem xong Chương 18 lần đầu — null nếu chưa hoàn thành cốt truyện.
  /// Ghi một lần, không đổi được (giống storyChoiceA/B/C/D).
  int? storyCompleteSeconds;

  /// Như [storyCompleteSeconds] nhưng tới lúc xem xong Chương 28 (hồi 2, mở rộng
  /// 2026-09-26) — cho bảng "Hồi 2". Tổng thời gian từ [firstPlayedMillis], null
  /// nếu chưa xong. Ghi một lần, không đổi được.
  int? storyExtCompleteSeconds;

  /// Như [storyCompleteSeconds] nhưng tới lúc xem xong Chương 36 (Hồi 3) — cho
  /// bảng "Hồi 3". Tổng thời gian từ [firstPlayedMillis], null nếu chưa xong.
  int? storyThirdActCompleteSeconds;

  /// Như [storyCompleteSeconds] nhưng tới lúc xem xong Chương 46 (Hồi 4) — cho bảng "Hồi 4".
  int? storyFourthActCompleteSeconds;

  /// Đã "hạ" đối thủ (đạt điều kiện ở giai đoạn 6) — chốt lại, mở Chương 8 và
  /// dừng các sự kiện đối thủ.
  bool rivalDefeated;

  /// "Giây sức ép" tích lại của đối thủ (xem [Balance.rivalPowerK]). Chỉ nhích
  /// khi có sự kiện đang chờ trả lời, và nhảy/giảm theo cách đối phó — không cộng
  /// theo tổng thời gian chơi.
  double rivalPressureSeconds;

  /// Mốc `lifetimeEarnings` khi bắt đầu vùng nhiệm vụ lặp lại — nhiệm vụ lặp đếm
  /// "kiếm THÊM" từ mốc này.
  double repeatQuestBaseline;

  /// Số lần chạm ly & số nâng cấp đã mua (đếm cho nhiệm vụ).
  int tapCount;
  int buyCount;

  /// Số nhiệm vụ đã hoàn thành (= chỉ số nhiệm vụ hiện tại trong chuỗi).
  int questIndex;

  /// Đã mua IAP "x2 thu nhập vĩnh viễn" — nhân đôi mọi thu nhập tự động.
  bool doubleIncomeOwned;

  /// Đã mua IAP "Kho lạnh vĩnh viễn" (+[Balance.coldStorageBonusSeconds] trần offline).
  bool coldStorageOwned;

  /// VIP EXP tích lũy (xem core/topup.dart), phần trong đó mua bằng 💎 (chặn trần),
  /// các bậc đã nhận thưởng mốc (chỉ số trong [topupTiers]) và chỉ số kỳ
  /// ngày/tuần/tháng đã nhận quà VIP gần nhất (0 = chưa từng).
  int vipExp;
  int vipExpFromGems;

  /// Xu VIP (kiếm từ quà VIP theo kỳ, đổi phụ kiện độc quyền ở Cửa hàng VIP).
  int vipCoins;

  /// Chỉ số ngày (UTC) đã mua "Ưu đãi hôm nay" gần nhất; 0 = chưa từng.
  int dealClaimedDay;

  /// Ngày (UTC) đã mua "Món của ngày".
  int dailyItemDay;

  /// Thẻ Mùa (xem core/season.dart).
  int seasonId;
  int seasonXp;
  bool seasonPremium;
  final List<int> seasonFreeClaimed;
  final List<int> seasonPremiumClaimed;
  int seasonXpDay;
  int seasonXpToday;

  /// Đã nhập mã mời của người khác / đã báo giai đoạn cho server (xem referral_controller).
  bool referralRedeemed;
  bool referralStageSent;

  /// Danh hiệu VIP hiển thị dưới tên ở BXH: -1 tự động (cấp cao nhất), 0 ẩn, 1..cấp =
  /// danh hiệu của cấp đó (người chơi tự chọn, xem setVipTitle).
  int vipTitleChoice;
  int vipClaimDay;
  int vipClaimWeek;
  int vipClaimMonth;
  final List<int> topupClaimed;

  /// Id các gói 💎 đã nhận thưởng "mua lần đầu gấp đôi" (mỗi gói một lần).
  final List<String> firstBuyClaimed;

  /// Mốc (epoch ms) hết hạn boost "x2 thu nhập 24h" từ xem QC; 0 = không có.
  int x2IncomeUntilMillis;

  /// Mốc (epoch ms) hết hạn "tự động chạm" bật bằng xem QC; 0 = không có. VIP đủ cấp được bật
  /// vĩnh viễn nên không cần mốc này (xem Balance.autoTapVipLevel).
  int autoTapUntilMillis;

  /// Mốc (epoch ms) hết hạn Mưa vàng ×3 (chạm mèo); 0 = không có. Trước đây
  /// runtime-only ở GameController, kill app giữa buff là mất — nay persist
  /// giống x2IncomeUntilMillis (xem GAME_DESIGN.md §14.3).
  int boostUntilMillis;

  /// Kim Cương đã tích trong heo đất (chờ "đập" bằng IAP). Trần ở Balance.
  double piggyGems;

  /// Mốc (epoch ms) hết hạn VIP Pass; VIP còn hiệu lực khi now < mốc này.
  int vipUntilMillis;

  /// Mốc (epoch ms) trước đó KHÔNG được tháo/thay phụ kiện đang mang (lấp ô trống thì luôn được).
  /// Đặt = now + [Balance.equipSwapLockMinutes] mỗi lần tháo/thay; xem QC để về 0. 0 = không khoá.
  int equipLockUntilMillis;

  /// Chỉ số ngày (UTC) lần cuối nhận Kim Cương VIP hằng ngày.
  int vipLastGemDay;

  /// Chỉ số ngày (UTC) lần cuối quay Vòng quay miễn phí.
  int lastFreeSpinDay;

  /// Chỉ số ngày (UTC) mà [gemTimeSkipUsedToday] đang đếm cho — reset về 0
  /// khi sang ngày mới (xem gemTimeSkipRemainingToday() trong simulation.dart).
  int gemTimeSkipDay;

  /// Số lần đã mua "Tua nhanh" (💎) trong ngày [gemTimeSkipDay] — trần
  /// [Balance.maxGemTimeSkipPerDay], thêm 2026-09-12 vì đây là nguồn thưởng
  /// DUY NHẤT không có cổng nhịp độ nào (xem Balance.maxGemTimeSkipPerDay).
  int gemTimeSkipUsedToday;

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
        'm3HowToSeen': m3HowToSeen,
        'lastDailyDay': lastDailyDay,
        'dailyStreak': dailyStreak,
        'achievementsClaimed': achievementsClaimed,
        'm3Stars': m3Stars,
        'redeemedCodes': redeemedCodes,
        'ownedAccessories': ownedAccessories,
        'howToSeen': howToSeen,
        'ownedLimited': ownedLimited,
        'eventId': eventId,
        'guildWeek': guildWeek,
        'guildWeekScore': guildWeekScore,
        'dungeonWeek': dungeonWeek,
        'dungeonTap': dungeonTap,
        'dungeonOffline': dungeonOffline,
        'dungeonRecipe': dungeonRecipe,
        'guildJoined': guildJoined,
        'guildVipBonusPct': guildVipBonusPct,
        'guildBuffUntilMillis': guildBuffUntilMillis,
        'eventPoints': eventPoints,
        'eventProgress': eventProgress,
        'eventClaimed': eventClaimed,
        'accessorySpares': accessorySpares,
        'essence': essence,
        'masteryTiers': {for (final e in masteryTiers.entries) '${e.key}': e.value},
        'refineLevels': refineLevels,
        'branchLevels': branchLevels,
        'branchSince': branchSince,
        'branchSetClaims': branchSetClaims,
        'branchManagerUntilMillis': branchManagerUntilMillis,
        'branchSpecs': branchSpecs,
        'branchEventClaimedSlot': branchEventClaimedSlot,
        'branchMapSkin': branchMapSkin,
        'branchQuestDayKey': branchQuestDayKey,
        'branchQuestProgress': branchQuestProgress,
        'branchQuestClaimed': branchQuestClaimed,
        'essenceDay': essenceDay,
        'essenceOrdersToday': essenceOrdersToday,
        'essenceRepeatableToday': essenceRepeatableToday,
        'equippedAccessories': equippedAccessories,
        'collectionMilestonesClaimed': collectionMilestonesClaimed,
        'collectionSetsClaimed': collectionSetsClaimed,
        'wishlist': wishlist,
        'prestigeIncomeLevel': prestigeIncomeLevel,
        'prestigeTapLevel': prestigeTapLevel,
        'prestigeOfflineLevel': prestigeOfflineLevel,
        'prestigeStartCashLevel': prestigeStartCashLevel,
        'prestigeKeepStageLevel': prestigeKeepStageLevel,
        'prestigeDiscountLevel': prestigeDiscountLevel,
        'prestigeAutoBuyLevel': prestigeAutoBuyLevel,
        'dailyQuestDay': dailyQuestDay,
        'dailyEarnTarget': dailyEarnTarget,
        'dailyBonusClaimed': dailyBonusClaimed,
        'accessoryAdDropDay': accessoryAdDropDay,
        'accessoryAdSpinDay': accessoryAdSpinDay,
        'accessoryAdSpins': accessoryAdSpins,
        'dailyQuestEverClaimed': dailyQuestEverClaimed,
        'starterPackClaimed': starterPackClaimed,
        'dailyProgress': dailyProgress,
        'dailyClaimed': dailyClaimed,
        'weeklyQuestWeek': weeklyQuestWeek,
        'weeklyBonusClaimed': weeklyBonusClaimed,
        'weeklyProgress': weeklyProgress,
        'weeklyClaimed': weeklyClaimed,
        'recipeProgress': recipeProgress,
        'recipeMilestonesClaimed': recipeMilestonesClaimed,
        'recipeOrderPerfect': recipeOrderPerfect,
        'recipeDailyDay': recipeDailyDay,
        'recipeDailyScore': recipeDailyScore,
        'recipeDailyCount': recipeDailyCount,
        'recipeStreak': recipeStreak,
        'recipeStreakLastDay': recipeStreakLastDay,
        'recipeStreakBest': recipeStreakBest,
        'ascensionCount': ascensionCount,
        'ascensionPointsEarned': ascensionPointsEarned,
        'ascensionLifetime': ascensionLifetime,
        'ascensionIncomeLevel': ascensionIncomeLevel,
        'ascensionStarBonusLevel': ascensionStarBonusLevel,
        'ascensionStarGainLevel': ascensionStarGainLevel,
        'autoBuyEnabled': autoBuyEnabled,
        'storyChapter': storyChapter,
        'storyChoiceA': storyChoiceA,
        'storyChoiceB': storyChoiceB,
        'storyChoiceC': storyChoiceC,
        'storyChoiceD': storyChoiceD,
        'storyChoiceE': storyChoiceE,
        'storyChoiceF': storyChoiceF,
        'storyChoiceG': storyChoiceG,
        'storyChoiceH': storyChoiceH,
        'firstPlayedMillis': firstPlayedMillis,
        'firstPlayedIsEstimate': firstPlayedIsEstimate,
        'storyCompleteSeconds': storyCompleteSeconds,
        'storyExtCompleteSeconds': storyExtCompleteSeconds,
        'storyThirdActCompleteSeconds': storyThirdActCompleteSeconds,
        'storyFourthActCompleteSeconds': storyFourthActCompleteSeconds,
        'rivalDefeated': rivalDefeated,
        'rivalPressureSeconds': rivalPressureSeconds,
        'repeatQuestBaseline': repeatQuestBaseline,
        'tapCount': tapCount,
        'buyCount': buyCount,
        'questIndex': questIndex,
        'doubleIncomeOwned': doubleIncomeOwned,
        'coldStorageOwned': coldStorageOwned,
        'vipExp': vipExp,
        'vipExpFromGems': vipExpFromGems,
        'vipCoins': vipCoins,
        'dealClaimedDay': dealClaimedDay,
        'dailyItemDay': dailyItemDay,
        'seasonId': seasonId,
        'seasonXp': seasonXp,
        'seasonPremium': seasonPremium,
        'seasonFreeClaimed': seasonFreeClaimed,
        'seasonPremiumClaimed': seasonPremiumClaimed,
        'seasonXpDay': seasonXpDay,
        'seasonXpToday': seasonXpToday,
        'referralRedeemed': referralRedeemed,
        'referralStageSent': referralStageSent,
        'vipTitleChoice': vipTitleChoice,
        'vipClaimDay': vipClaimDay,
        'vipClaimWeek': vipClaimWeek,
        'vipClaimMonth': vipClaimMonth,
        'topupClaimed': topupClaimed,
        'firstBuyClaimed': firstBuyClaimed,
        'x2IncomeUntilMillis': x2IncomeUntilMillis,
        'autoTapUntilMillis': autoTapUntilMillis,
        'boostUntilMillis': boostUntilMillis,
        'piggyGems': piggyGems,
        'vipUntilMillis': vipUntilMillis,
        'equipLockUntilMillis': equipLockUntilMillis,
        'vipLastGemDay': vipLastGemDay,
        'lastFreeSpinDay': lastFreeSpinDay,
        'gemTimeSkipDay': gemTimeSkipDay,
        'gemTimeSkipUsedToday': gemTimeSkipUsedToday,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        money: _sanitizeMoney(json['money'] as num),
        gems: (json['gems'] as num).toDouble(),
        tapValue: (json['tapValue'] as num).toDouble(),
        levels: (json['levels'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toInt()),
        ),
        lifetimeEarnings: (json['lifetimeEarnings'] as num).toDouble(),
        // Đọc được cả save cũ (int, kể cả bản đã kẹp trần) — không cần
        // migration: `prestigeStarsAvailable` = total − prestigeStars sẽ tự
        // trả lại phần Sao bị trần nuốt ở lần Nhượng quyền kế tiếp.
        prestigeStars: (json['prestigeStars'] as num).toDouble(),
        lastSeenMillis: (json['lastSeenMillis'] as num).toInt(),
        // Mặc định 0 cho save cũ chưa có các trường này.
        gemBoostLevel: (json['gemBoostLevel'] as num?)?.toInt() ?? 0,
        offlineCapLevel: (json['offlineCapLevel'] as num?)?.toInt() ?? 0,
        stage: (json['stage'] as num?)?.toInt() ?? 1,
        adsRemoved: (json['adsRemoved'] as bool?) ?? false,
        starterPackOwned: (json['starterPackOwned'] as bool?) ?? false,
        tutorialSeen: (json['tutorialSeen'] as bool?) ?? false,
        m3HowToSeen: (json['m3HowToSeen'] as bool?) ?? false,
        lastDailyDay: (json['lastDailyDay'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        achievementsClaimed:
            (json['achievementsClaimed'] as List?)?.cast<String>().toList(),
        m3Stars: (json['m3Stars'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        redeemedCodes:
            (json['redeemedCodes'] as List?)?.cast<String>().toList(),
        ownedAccessories:
            (json['ownedAccessories'] as List?)?.cast<String>().toList(),
        howToSeen: [
          if (json['howToSeen'] is List) ...{for (final e in json['howToSeen'] as List) if (e is String) e},
        ],
        ownedLimited: (json['ownedLimited'] as List?)?.cast<String>().toList(),
        eventId: (json['eventId'] as String?) ?? '',
        guildWeek: (json['guildWeek'] as num?)?.toInt() ?? 0,
        guildWeekScore: (json['guildWeekScore'] as num?)?.toDouble() ?? 0,
        dungeonWeek: (json['dungeonWeek'] as num?)?.toInt() ?? 0,
        dungeonTap: ((json['dungeonTap'] as num?)?.toInt() ?? 0).clamp(0, 1 << 40),
        dungeonOffline: ((json['dungeonOffline'] as num?)?.toDouble() ?? 0).clamp(0.0, 1e12),
        dungeonRecipe: ((json['dungeonRecipe'] as num?)?.toInt() ?? 0).clamp(0, 1 << 40),
        guildJoined: json['guildJoined'] == true,
        guildVipBonusPct: (json['guildVipBonusPct'] as num?)?.toInt() ?? 0,
        guildBuffUntilMillis: (json['guildBuffUntilMillis'] as num?)?.toInt() ?? 0,
        eventPoints: (json['eventPoints'] as num?)?.toInt() ?? 0,
        eventProgress: (json['eventProgress'] as Map?)
            ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        eventClaimed: (json['eventClaimed'] as List?)?.cast<String>().toList(),
        // load() nuốt mọi lỗi thành "ván mới" — trường phụ này sai kiểu/giá trị
        // lạ phải bị BỎ QUA chứ không được ném, nếu không mất cả save.
        wishlist: [
          if (json['wishlist'] is List)
            for (final e in json['wishlist'] as List)
              if (e is String) e,
        ],
        collectionMilestonesClaimed: [
          if (json['collectionMilestonesClaimed'] is List)
            for (final e in json['collectionMilestonesClaimed'] as List)
              if (e is num) e.toInt(),
        ],
        collectionSetsClaimed: [
          if (json['collectionSetsClaimed'] is List)
            for (final e in json['collectionSetsClaimed'] as List)
              if (e is String) e,
        ],
        equippedAccessories: [
          if (json['equippedAccessories'] is List)
            for (final e in json['equippedAccessories'] as List)
              if (e is String) e,
        ],
        accessorySpares: {
          if (json['accessorySpares'] is Map)
            for (final e in (json['accessorySpares'] as Map).entries)
              if (e.key is String &&
                  e.value is num &&
                  (e.value as num).isFinite &&
                  (e.value as num) >= 1)
                e.key as String: (e.value as num).clamp(1, 999).toInt(),
        },
        essence: ((json['essence'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
        masteryTiers: {
          if (json['masteryTiers'] is Map)
            for (final e in (json['masteryTiers'] as Map).entries)
              if (int.tryParse('${e.key}') != null && e.value is num && (e.value as num).isFinite)
                int.parse('${e.key}'): (e.value as num).clamp(0, 99).toInt(), // trần thật kẹp ở masteryTier()
        },
        refineLevels: {
          if (json['refineLevels'] is Map)
            for (final e in (json['refineLevels'] as Map).entries)
              if (e.key is String && e.value is num && (e.value as num) > 0)
                e.key as String: (e.value as num).toInt().clamp(1, 3),
        },
        branchLevels: {
          if (json['branchLevels'] is Map)
            for (final e in (json['branchLevels'] as Map).entries)
              if (e.key is String && e.value is num && (e.value as num).isFinite && (e.value as num) > 0)
                e.key as String: (e.value as num).toInt().clamp(1, 10),
        },
        branchSince: {
          if (json['branchSince'] is Map)
            for (final e in (json['branchSince'] as Map).entries)
              if (e.key is String && e.value is num && (e.value as num).isFinite && (e.value as num) >= 0)
                e.key as String: (e.value as num).toInt(),
        },
        branchSetClaims: {
          if (json['branchSetClaims'] is List)
            for (final e in json['branchSetClaims'] as List)
              if (e is String && isBranchSetKey(e)) e,
        }.toList(),
        branchSpecs: {
          if (json['branchSpecs'] is Map)
            for (final e in (json['branchSpecs'] as Map).entries)
              if (e.value is num && (e.value == 1 || e.value == 2)) '${e.key}': (e.value as num).toInt(),
        },
        branchEventClaimedSlot: (json['branchEventClaimedSlot'] as num?)?.toInt() ?? -1,
        branchQuestDayKey: (json['branchQuestDayKey'] as num?)?.toInt() ?? -1,
        branchQuestProgress: [
          for (var i = 0; i < 4; i++)
            json['branchQuestProgress'] is List && (json['branchQuestProgress'] as List).length > i && (json['branchQuestProgress'] as List)[i] is num
                ? ((json['branchQuestProgress'] as List)[i] as num).toInt().clamp(0, 1 << 30)
                : 0,
        ],
        branchQuestClaimed: ((json['branchQuestClaimed'] as num?)?.toInt() ?? 0) & 31,
        branchMapSkin: ((json['branchMapSkin'] as num?)?.toInt() ?? 0).clamp(0, 3),
        branchManagerUntilMillis: ((json['branchManagerUntilMillis'] as num?)?.toInt() ?? 0).clamp(0, 1 << 52),
        essenceDay: (json['essenceDay'] as num?)?.toInt() ?? 0,
        essenceOrdersToday: (json['essenceOrdersToday'] as num?)?.toInt() ?? 0,
        essenceRepeatableToday: (json['essenceRepeatableToday'] as num?)?.toInt() ?? 0,
        prestigeIncomeLevel:
            (json['prestigeIncomeLevel'] as num?)?.toInt() ?? 0,
        prestigeTapLevel: (json['prestigeTapLevel'] as num?)?.toInt() ?? 0,
        prestigeOfflineLevel:
            (json['prestigeOfflineLevel'] as num?)?.toInt() ?? 0,
        prestigeStartCashLevel:
            (json['prestigeStartCashLevel'] as num?)?.toInt() ?? 0,
        prestigeKeepStageLevel:
            (json['prestigeKeepStageLevel'] as num?)?.toInt() ?? 0,
        prestigeDiscountLevel:
            (json['prestigeDiscountLevel'] as num?)?.toInt() ?? 0,
        prestigeAutoBuyLevel:
            (json['prestigeAutoBuyLevel'] as num?)?.toInt() ?? 0,
        dailyQuestDay: (json['dailyQuestDay'] as num?)?.toInt() ?? 0,
        dailyEarnTarget: (json['dailyEarnTarget'] as num?)?.toDouble() ?? 0,
        dailyBonusClaimed: (json['dailyBonusClaimed'] as bool?) ?? false,
        accessoryAdDropDay: (json['accessoryAdDropDay'] as num?)?.toInt() ?? 0,
        accessoryAdSpinDay: (json['accessoryAdSpinDay'] as num?)?.toInt() ?? 0,
        accessoryAdSpins: (json['accessoryAdSpins'] as num?)?.toInt() ?? 0,
        dailyQuestEverClaimed:
            json['dailyQuestEverClaimed'] == true,
        starterPackClaimed: json['starterPackClaimed'] == true,
        dailyProgress: (json['dailyProgress'] as Map?)
            ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        dailyClaimed: (json['dailyClaimed'] as List?)?.cast<String>().toList(),
        weeklyQuestWeek: (json['weeklyQuestWeek'] as num?)?.toInt() ?? 0,
        weeklyBonusClaimed: json['weeklyBonusClaimed'] == true,
        weeklyProgress: (json['weeklyProgress'] as Map?)
            ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        weeklyClaimed: (json['weeklyClaimed'] as List?)?.cast<String>().toList(),
        recipeProgress: {
          // Bỏ mục hỏng thay vì ném (save cũ / cloud lạ): mất bậc một món tốt hơn mất cả save.
          for (final e in ((json['recipeProgress'] as Map?) ?? const {}).entries)
            if (e.key is String && e.value is List) e.key as String: [...(e.value as List).map((x) => x is num ? x.toInt() : 0)],
        },
        recipeMilestonesClaimed: [
          for (final x in (json['recipeMilestonesClaimed'] as List?) ?? const []) if (x is num) x.toInt(),
        ],
        recipeOrderPerfect: {
          for (final x in (json['recipeOrderPerfect'] as List?) ?? const []) if (x is num) x.toInt(),
        }.toList(),
        recipeDailyDay: ((json['recipeDailyDay'] as num?)?.toInt() ?? -1).clamp(-1, 10000000),
        recipeDailyCount: ((json['recipeDailyCount'] as num?)?.toInt() ?? 0).clamp(0, 100000),
        recipeDailyScore: ((json['recipeDailyScore'] as num?)?.toInt() ?? 0).clamp(0, 300), // = dailyMaxScore (recipe_orders.dart; test so khớp)
        // Giá trị âm/hỏng được kẹp về hợp lệ (save lạ từ cloud không làm hỏng cả game).
        recipeStreak: ((json['recipeStreak'] as num?)?.toInt() ?? 0).clamp(0, 100000),
        recipeStreakLastDay: ((json['recipeStreakLastDay'] as num?)?.toInt() ?? 0).clamp(0, 10000000),
        recipeStreakBest: ((json['recipeStreakBest'] as num?)?.toInt() ?? 0).clamp(0, 100000),
        ascensionCount: (json['ascensionCount'] as num?)?.toInt() ?? 0,
        ascensionPointsEarned:
            (json['ascensionPointsEarned'] as num?)?.toInt() ?? 0,
        ascensionLifetime:
            (json['ascensionLifetime'] as num?)?.toDouble() ?? 0,
        ascensionIncomeLevel:
            (json['ascensionIncomeLevel'] as num?)?.toInt() ?? 0,
        ascensionStarBonusLevel:
            (json['ascensionStarBonusLevel'] as num?)?.toInt() ?? 0,
        ascensionStarGainLevel:
            (json['ascensionStarGainLevel'] as num?)?.toInt() ?? 0,
        autoBuyEnabled: (json['autoBuyEnabled'] as bool?) ?? false,
        storyChapter: (json['storyChapter'] as num?)?.toInt() ?? 0,
        storyChoiceA: json['storyChoiceA'] as String?,
        storyChoiceB: json['storyChoiceB'] as String?,
        storyChoiceC: json['storyChoiceC'] as String?,
        storyChoiceD: json['storyChoiceD'] as String?,
        storyChoiceE: json['storyChoiceE'] as String?,
        storyChoiceF: json['storyChoiceF'] as String?,
        storyChoiceG: json['storyChoiceG'] as String?,
        storyChoiceH: json['storyChoiceH'] as String?,
        // Save cũ (trước khi có trường này) không có firstPlayedMillis — dùng
        // lastSeenMillis của chính save đó làm mốc gần đúng nhất có sẵn (biết
        // là ước tính hụt, không phải lúc thật sự bắt đầu chơi; chấp nhận vì
        // đây chỉ ảnh hưởng bảng xếp hạng tốc độ hoàn thành cốt truyện, không
        // ảnh hưởng gameplay chính).
        firstPlayedMillis: (json['firstPlayedMillis'] as num?)?.toInt() ??
            (json['lastSeenMillis'] as num).toInt(),
        // Suy ra từ chính lần nạp NÀY: cờ chưa từng có ở save cũ, nên tự bắc
        // cầu bằng câu hỏi "JSON có sẵn firstPlayedMillis thật không" — thiếu
        // thì chắc chắn vừa đoán ở dòng trên, có thì tin (kể cả nếu bản thân
        // giá trị đó từng bị đoán ở một lần nạp trước lúc cờ này chưa tồn
        // tại — rủi ro còn sót lại chấp nhận được, chỉ ảnh hưởng vài save rất
        // cũ chưa từng hoàn thành cốt truyện).
        firstPlayedIsEstimate: (json['firstPlayedIsEstimate'] as bool?) ??
            json['firstPlayedMillis'] == null,
        storyCompleteSeconds:
            (json['storyCompleteSeconds'] as num?)?.toInt(),
        storyExtCompleteSeconds:
            (json['storyExtCompleteSeconds'] as num?)?.toInt(),
        storyThirdActCompleteSeconds:
            (json['storyThirdActCompleteSeconds'] as num?)?.toInt(),
        storyFourthActCompleteSeconds:
            (json['storyFourthActCompleteSeconds'] as num?)?.toInt(),
        rivalDefeated: (json['rivalDefeated'] as bool?) ?? false,
        rivalPressureSeconds:
            (json['rivalPressureSeconds'] as num?)?.toDouble() ?? 0,
        repeatQuestBaseline:
            (json['repeatQuestBaseline'] as num?)?.toDouble() ?? 0,
        tapCount: (json['tapCount'] as num?)?.toInt() ?? 0,
        buyCount: (json['buyCount'] as num?)?.toInt() ?? 0,
        questIndex: (json['questIndex'] as num?)?.toInt() ?? 0,
        doubleIncomeOwned: (json['doubleIncomeOwned'] as bool?) ?? false,
        coldStorageOwned: (json['coldStorageOwned'] as bool?) ?? false,
        vipExp: (json['vipExp'] as num?)?.toInt() ?? 0,
        vipExpFromGems: (json['vipExpFromGems'] as num?)?.toInt() ?? 0,
        vipCoins: (json['vipCoins'] as num?)?.toInt() ?? 0,
        dealClaimedDay: (json['dealClaimedDay'] as num?)?.toInt() ?? 0,
        dailyItemDay: (json['dailyItemDay'] as num?)?.toInt() ?? 0,
        seasonId: (json['seasonId'] as num?)?.toInt() ?? 0,
        seasonXp: ((json['seasonXp'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
        seasonPremium: json['seasonPremium'] == true,
        seasonFreeClaimed: _tierList(json['seasonFreeClaimed']),
        seasonPremiumClaimed: _tierList(json['seasonPremiumClaimed']),
        seasonXpDay: (json['seasonXpDay'] as num?)?.toInt() ?? 0,
        seasonXpToday: ((json['seasonXpToday'] as num?)?.toInt() ?? 0).clamp(0, 1 << 30),
        referralRedeemed: (json['referralRedeemed'] as bool?) ?? false,
        referralStageSent: (json['referralStageSent'] as bool?) ?? false,
        vipTitleChoice: (json['vipTitleChoice'] as num?)?.toInt() ?? -1,
        vipClaimDay: (json['vipClaimDay'] as num?)?.toInt() ?? 0,
        vipClaimWeek: (json['vipClaimWeek'] as num?)?.toInt() ?? 0,
        vipClaimMonth: (json['vipClaimMonth'] as num?)?.toInt() ?? 0,
        topupClaimed: (json['topupClaimed'] as List?)?.map((e) => (e as num).toInt()).toList(),
        firstBuyClaimed: (json['firstBuyClaimed'] as List?)?.cast<String>().toList(),
        x2IncomeUntilMillis:
            (json['x2IncomeUntilMillis'] as num?)?.toInt() ?? 0,
        autoTapUntilMillis: (json['autoTapUntilMillis'] as num?)?.toInt() ?? 0,
        boostUntilMillis: (json['boostUntilMillis'] as num?)?.toInt() ?? 0,
        piggyGems: (json['piggyGems'] as num?)?.toDouble() ?? 0,
        vipUntilMillis: (json['vipUntilMillis'] as num?)?.toInt() ?? 0,
        equipLockUntilMillis: (json['equipLockUntilMillis'] as num?)?.toInt() ?? 0,
        vipLastGemDay: (json['vipLastGemDay'] as num?)?.toInt() ?? 0,
        lastFreeSpinDay: (json['lastFreeSpinDay'] as num?)?.toInt() ?? 0,
        gemTimeSkipDay: (json['gemTimeSkipDay'] as num?)?.toInt() ?? 0,
        gemTimeSkipUsedToday:
            (json['gemTimeSkipUsedToday'] as num?)?.toInt() ?? 0,
      );
}

/// Vá lỗi save cũ bị âm/NaN/Infinity (tràn số double do công thức mốc nhân bội
/// tăng vô hạn ở cấp rất cao) — coi save hỏng như 0 Xu thay vì hiển thị số âm.
double _sanitizeMoney(num raw) {
  final v = raw.toDouble();
  return v.isFinite && v >= 0 ? v : 0;
}

/// Danh sách số bậc Thẻ Mùa hợp lệ (1..30, không trùng) từ JSON; phần tử lạ bị bỏ.
List<int> _tierList(Object? v) => v is List
    ? ({for (final e in v) if (e is num && e >= 1 && e <= 30) e.toInt()}.toList()..sort())
    : [];
