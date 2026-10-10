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
    this.rivalDefeated = false,
    this.rivalPressureSeconds = 0,
    this.repeatQuestBaseline = 0,
    this.tapCount = 0,
    this.buyCount = 0,
    this.questIndex = 0,
    this.doubleIncomeOwned = false,
    this.coldStorageOwned = false,
    this.topupPoints = 0,
    List<int>? topupClaimed,
    this.x2IncomeUntilMillis = 0,
    this.boostUntilMillis = 0,
    this.piggyGems = 0,
    this.vipUntilMillis = 0,
    this.vipLastGemDay = 0,
    this.lastFreeSpinDay = 0,
    this.gemTimeSkipDay = 0,
    this.gemTimeSkipUsedToday = 0,
    int? firstPlayedMillis,
    this.firstPlayedIsEstimate = false,
    this.storyCompleteSeconds,
    this.storyExtCompleteSeconds,
    this.storyThirdActCompleteSeconds,
    List<String>? achievementsClaimed,
    List<int>? m3Stars,
    List<String>? redeemedCodes,
    List<String>? ownedAccessories,
    List<String>? ownedLimited,
    this.eventId = '',
    this.guildWeek = 0,
    this.guildWeekScore = 0,
    this.guildJoined = false,
    this.guildBuffUntilMillis = 0,
    this.eventPoints = 0,
    Map<String, double>? eventProgress,
    List<String>? eventClaimed,
    Map<String, int>? accessorySpares,
    List<String>? equippedAccessories,
    List<int>? collectionMilestonesClaimed,
    List<String>? wishlist,
  })  : achievementsClaimed = achievementsClaimed ?? [],
        m3Stars = m3Stars ?? [],
        redeemedCodes = redeemedCodes ?? [],
        ownedAccessories = ownedAccessories ?? [],
        ownedLimited = ownedLimited ?? [],
        topupClaimed = topupClaimed ?? [],
        eventProgress = eventProgress ?? {},
        eventClaimed = eventClaimed ?? [],
        accessorySpares = accessorySpares ?? {},
        equippedAccessories = equippedAccessories ?? [],
        collectionMilestonesClaimed = collectionMilestonesClaimed ?? [],
        wishlist = wishlist ?? [],
        dailyProgress = dailyProgress ?? {},
        dailyClaimed = dailyClaimed ?? [],
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

  /// Phụ kiện độc quyền theo dịp lễ (xem accessories.dart `festivals`) — tách khỏi
  /// [ownedAccessories] để không dính số đếm bộ sưu tập / BXH / Chợ.
  final List<String> ownedLimited;

  /// Nhiệm vụ sự kiện theo dịp lễ (event_quests.dart): id dịp đang theo dõi
  /// ('' = không có), tiến độ cộng dồn, nhiệm vụ đã nhận, điểm đổi món.
  String eventId;

  /// Hội (guild.dart): chỉ số tuần (thứ Hai UTC) và điểm hoạt động tuần này.
  int guildWeek;
  double guildWeekScore;

  /// Đang ở một hội (cập nhật khi mở màn Hội) — quyết định có hỏi server về buff hội
  /// lúc mở app hay không — và mốc (đồng hồ máy, ms) hết buff thu nhập cả hội.
  bool guildJoined;
  int guildBuffUntilMillis;
  int eventPoints;
  final Map<String, double> eventProgress;
  final List<String> eventClaimed;

  /// Số bản SAO DƯ ngoài bản đầu của mỗi món (id → n ≥ 1; không có khoá = 0
  /// dư). Rớt trùng cộng vào đây (xem grantAccessory) — bản dư bán được ở Chợ
  /// mà không mất món đang sưu tập.
  final Map<String, int> accessorySpares;

  /// Id phụ kiện đang TRƯNG BÀY quanh cốc ở màn chính (≤ Balance.maxEquippedAccessories,
  /// đều phải đang sở hữu). Thuần trang trí — động lực khoe/sưu tập, không buff gì.
  final List<String> equippedAccessories;

  /// Mốc sưu tập đã nhận thưởng (xem collection_milestones.dart). Server mới là
  /// nguồn sự thật — đây chỉ để ẩn nút nhận.
  final List<int> collectionMilestonesClaimed;

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

  /// Tổng điểm nạp tích lũy (≈ USD, xem core/topup.dart) và các bậc đã nhận thưởng
  /// (lưu theo chỉ số trong [topupTiers]).
  int topupPoints;
  final List<int> topupClaimed;

  /// Mốc (epoch ms) hết hạn boost "x2 thu nhập 24h" từ xem QC; 0 = không có.
  int x2IncomeUntilMillis;

  /// Mốc (epoch ms) hết hạn Mưa vàng ×3 (chạm mèo); 0 = không có. Trước đây
  /// runtime-only ở GameController, kill app giữa buff là mất — nay persist
  /// giống x2IncomeUntilMillis (xem GAME_DESIGN.md §14.3).
  int boostUntilMillis;

  /// Kim Cương đã tích trong heo đất (chờ "đập" bằng IAP). Trần ở Balance.
  double piggyGems;

  /// Mốc (epoch ms) hết hạn VIP Pass; VIP còn hiệu lực khi now < mốc này.
  int vipUntilMillis;

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
        'ownedLimited': ownedLimited,
        'eventId': eventId,
        'guildWeek': guildWeek,
        'guildWeekScore': guildWeekScore,
        'guildJoined': guildJoined,
        'guildBuffUntilMillis': guildBuffUntilMillis,
        'eventPoints': eventPoints,
        'eventProgress': eventProgress,
        'eventClaimed': eventClaimed,
        'accessorySpares': accessorySpares,
        'equippedAccessories': equippedAccessories,
        'collectionMilestonesClaimed': collectionMilestonesClaimed,
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
        'firstPlayedMillis': firstPlayedMillis,
        'firstPlayedIsEstimate': firstPlayedIsEstimate,
        'storyCompleteSeconds': storyCompleteSeconds,
        'storyExtCompleteSeconds': storyExtCompleteSeconds,
        'storyThirdActCompleteSeconds': storyThirdActCompleteSeconds,
        'rivalDefeated': rivalDefeated,
        'rivalPressureSeconds': rivalPressureSeconds,
        'repeatQuestBaseline': repeatQuestBaseline,
        'tapCount': tapCount,
        'buyCount': buyCount,
        'questIndex': questIndex,
        'doubleIncomeOwned': doubleIncomeOwned,
        'coldStorageOwned': coldStorageOwned,
        'topupPoints': topupPoints,
        'topupClaimed': topupClaimed,
        'x2IncomeUntilMillis': x2IncomeUntilMillis,
        'boostUntilMillis': boostUntilMillis,
        'piggyGems': piggyGems,
        'vipUntilMillis': vipUntilMillis,
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
        ownedLimited: (json['ownedLimited'] as List?)?.cast<String>().toList(),
        eventId: (json['eventId'] as String?) ?? '',
        guildWeek: (json['guildWeek'] as num?)?.toInt() ?? 0,
        guildWeekScore: (json['guildWeekScore'] as num?)?.toDouble() ?? 0,
        guildJoined: json['guildJoined'] == true,
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
        topupPoints: (json['topupPoints'] as num?)?.toInt() ?? 0,
        topupClaimed: (json['topupClaimed'] as List?)?.map((e) => (e as num).toInt()).toList(),
        x2IncomeUntilMillis:
            (json['x2IncomeUntilMillis'] as num?)?.toInt() ?? 0,
        boostUntilMillis: (json['boostUntilMillis'] as num?)?.toInt() ?? 0,
        piggyGems: (json['piggyGems'] as num?)?.toDouble() ?? 0,
        vipUntilMillis: (json['vipUntilMillis'] as num?)?.toInt() ?? 0,
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
