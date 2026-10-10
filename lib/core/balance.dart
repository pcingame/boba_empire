/// Bảng cân bằng game — toàn bộ con số nằm ở đây, tách khỏi logic (mục 9).
///
/// Muốn tune game chỉ cần sửa file này, không đụng tới mã mô phỏng.
///
/// Một số nút vặn nóng KHÔNG `const` (bonusPerStar, prestigeK, milestoneStep,
/// milestoneFactor, milestoneGlobalBonus, maxOfflineSeconds, cat/vipSpawn*Ms,
/// dailyQuest*Gems): chúng có thể bị Firebase Remote Config ghi đè lúc chạy để
/// tune mà không phải nộp bản mới lên store — xem `lib/data/remote_balance.dart`
/// (ở đó cũng khai báo khoảng hợp lệ của từng nút).
library;

import 'accessories.dart' show AccessoryRarity;
import 'models.dart';

class Balance {
  Balance._();

  /// Trần thời gian tính tiền offline (8 giờ) — buộc người chơi quay lại và
  /// tạo chỗ để bán vật phẩm "tăng giới hạn offline".
  static int maxOfflineSeconds = 8 * 60 * 60;

  /// Chỉ hiện popup "Chào mừng quay lại" khi vắng ít nhất ngần này giây. Ngắn hơn
  /// (đổi app vài giây, mở lại ngay) thì Xu vẫn được cộng nhưng KHÔNG chặn người
  /// chơi bằng popup — trước đây cứ quay lại là bật popup.
  static const int offlineDialogMinSeconds = 120;

  /// % thu nhập cộng thêm cho mỗi Sao nhượng quyền (bonus vĩnh viễn).
  static double bonusPerStar = 0.02; // +2%/sao

  /// Bậc thưởng Kim Cương theo hạng trên Bảng xếp hạng (lặp lại mỗi 24h nếu
  /// còn giữ hạng — xem `leaderboard_claim_reward()` trong
  /// leaderboard_schema.sql). CHỈ dùng để HIỂN THỊ gợi ý trên UI — Kim
  /// Cương thật do server cấp qua hàm đó; đổi 1 bên thì PHẢI đổi cả hai.
  /// (rank tối đa, số Kim Cương) — tra theo thứ tự, hạng đầu tiên khớp.
  static const List<(int, int)> leaderboardRewardTiers = [
    (1, 100),
    (3, 50),
    (10, 20),
  ];

  /// Hệ số quy đổi Sao: sao = floor(k * sqrt(tổng_thu_nhập_cả_đời)).
  /// Giảm từ 0.05 → 0.02 (2026-09-12): phản hồi trực tiếp từ chơi thật —
  /// Sao tăng quá nhanh (save test lên tới ~7,3 TỶ Sao = +146 tỷ % thu
  /// nhập, rõ ràng lệch xa ý đồ "mỗi Sao +2%, đáng kể nhưng không phá vỡ
  /// game"). Còn phải giảm hơn nữa hay không cần xem sau khi có dữ liệu
  /// phiên chơi thật (xem PROPOSAL_ANALYTICS.md) — đây là điều chỉnh dựa
  /// trên quan sát chơi thật, không phải đoán mù, nhưng vẫn chưa phải số
  /// liệu thống kê đầy đủ.
  static double prestigeK = 0.02;

  /// Mốc nhân bội cho mỗi nguồn thu: cứ mỗi [milestoneStep] cấp, thu nhập của
  /// nguồn đó ×[milestoneFactor] (mặc định mới: 50→×2, 100→×4, 150→×8...).
  /// Đây là "củ cà rốt" khiến người chơi dồn cấp một nguồn thay vì rải đều —
  /// chiều sâu tối ưu.
  ///
  /// milestoneStep tăng 25 → 50 (2026-09-12, cùng đợt với prestigeK ở trên):
  /// đây là công thức TĂNG NHANH NHẤT trong toàn bộ nền kinh tế — số nhân
  /// ở cấp cao (VD cấp 1000, trần Balance.maxGeneratorLevel) từng là
  /// 2^(1000/25)=2^40≈1,1 nghìn tỷ; giờ chỉ còn 2^(1000/50)=2^20≈1 triệu.
  /// Đây chính là nguồn gốc khiến Xu cả đời (và do đó Sao, vì Sao = f(Xu
  /// cả đời)) tăng phi mã theo phản hồi chơi thật.
  static int milestoneStep = 50;
  static double milestoneFactor = 2.0;

  /// Trần an toàn kỹ thuật cho `nextLevelCost`/`bulkCost`/
  /// `generatorMilestoneMultiplier` (lib/core/economy.dart) — CHẶN TRÀN SỐ
  /// double, KHÔNG phải số cân bằng (không ai nên chạm được trần này qua
  /// chơi bình thường). `costGrowth^level` (1.15^level) tràn double quanh
  /// cấp ~5077, `2^(level/25)` tràn quanh cấp ~25650 — cả hai đều thấp hơn
  /// nhiều so với double.maxFinite (~1.8e308) nếu không chặn, dẫn tới bug
  /// Xu âm đã gặp (xem memory "negative-money-overflow-bug"). Đặt ở 1e100
  /// để còn dư RẤT nhiều khoảng trống nhân thêm prestige/gem/x2 phía trên
  /// mà vẫn không chạm Infinity.
  static const double economyOverflowGuardCap = 1e100;

  /// Trần CỨNG số cấp tối đa 1 nguồn thu có thể mua tới — phòng thủ chính,
  /// đơn giản và triệt để hơn hẳn việc chỉ ép trần giá trị trả về của công
  /// thức: giữ `level` luôn trong phạm vi mà `costGrowth^level` (tràn ~cấp
  /// 5077) KHÔNG BAO GIỜ cần ép trần — nghĩa là `bulkCost` mua số lượng lớn
  /// vẫn tăng đơn điệu đúng bản chất kinh tế (mua nhiều hơn luôn đắt hơn),
  /// không bị vỡ tính đơn điệu như khi chỉ ép trần tổng giá cho count lớn.
  /// Đặt xa mọi tiến trình người chơi bình thường chạm tới (mốc nhân bội chỉ
  /// mới ×2^40 ở cấp 1000) — không phải số cân bằng, chỉ là lưới an toàn.
  static const int maxGeneratorLevel = 1000;

  /// Hiệu ứng thứ 2 của mốc ("Mốc vàng"): từ mốc thứ [milestoneGlobalFreeTiers]+1
  /// (mặc định = mốc cấp 50) trở đi, MỖI mốc bất kỳ nguồn thu đạt cộng thêm
  /// [milestoneGlobalBonus] vào hệ số thu nhập TOÀN CỤC (cộng dồn, vĩnh viễn).
  /// → thưởng cho việc dồn sâu 1 nguồn mà KHÔNG đổi đường cong income của nguồn.
  static const int milestoneGlobalFreeTiers = 1;
  static double milestoneGlobalBonus = 0.03;

  // --- Hành trình Ghép 3 (chơi đơn, lib/core/match3_levels.dart) ---

  /// Số nước mỗi màn. Cố định; độ khó tăng bằng mục tiêu điểm.
  static int m3Moves = 25;

  /// Mục tiêu 1 sao của màn 1, và hệ số tăng mỗi màn (màn n = base·growth^(n-1)).
  static double m3TargetBase = 900;
  static double m3TargetGrowth = 1.08;

  /// Trần mục tiêu 1 sao của màn ĐIỂM. Không có trần thì mục tiêu tăng theo cấp số
  /// nhân tới mức không ai đạt nổi: mô phỏng tham lam (1 bước nhìn trước) chỉ được
  /// ~15-20k điểm trong 25 nước ở MỌI màn, trong khi 900·1.08^(n-1) vượt 20k từ
  /// màn ~42 và đạt 393k ở màn 80. 24k nằm hơi trên mức đó: vẫn cần chơi tốt/có
  /// kẹo đặc biệt hoặc xem QC thêm nước. (⚠️ chưa playtest.)
  static double m3TargetCap = 24000;

  /// Tổng số màn. Màn sinh bằng công thức nên tăng số này là có thêm màn.
  static int m3LevelCount = 80;

  /// Mốc 2 sao và 3 sao, tính theo bội của mục tiêu 1 sao.
  ///
  /// Hạ từ 1.5x/2.0x xuống 1.25x/1.6x (2026-09-28) — phản hồi chơi thật: chấm
  /// sao khắt khe quá, gần như màn nào cũng chỉ được 1 sao. Cộng thêm việc màn
  /// kết thúc ngay khi chạm mục tiêu, người chơi phải chủ động bấm "Chơi nốt"
  /// mới có cơ hội lên sao, nên hai mốc này càng không nên đặt cao.
  static double m3Star2Mult = 1.2;
  static double m3Star3Mult = 1.45;

  /// Cứ mỗi [m3CollectEvery] màn thì có một màn kiểu "thu thập N ô loại X"
  /// thay vì "đạt X điểm" — xen kẽ cho đỡ đơn điệu. Đặt 0 = tắt hẳn.
  static int m3CollectEvery = 3;

  /// Số ô cần thu thập ở màn thu thập đầu tiên, và hệ số tăng mỗi màn thu thập.
  static double m3CollectBase = 12;
  static double m3CollectGrowth = 1.07;

  /// Thưởng 💎 khi đạt 3 sao một màn (chỉ trả LẦN ĐẦU — bàn tất định nên chơi
  /// lại mà vẫn thưởng là máy in 💎). 60 màn x 3 = 180 💎 trọn đời.
  static int m3ThreeStarGems = 3;

  /// Xem quảng cáo thưởng để chơi tiếp: cộng chừng này nước. CHỈ 1 lần mỗi lượt
  /// chơi — không giới hạn thì xem đủ quảng cáo là qua được mọi màn, mục tiêu
  /// điểm mất hết ý nghĩa.
  static const int m3AdExtraMoves = 5;

  /// Thưởng Xu lần đầu đạt mỗi mốc sao = thu nhập/giây x chừng này giây x số sao.
  /// Ngưỡng TƯƠNG ĐỐI vì kinh tế trải 1e2..1e80 (cùng cách nhiệm vụ ngày làm).
  static int m3RewardIncomeSeconds = 600;

  /// Mức sàn cho thưởng trên: người chơi mới có thu nhập/giây = 0 (chưa mua
  /// nguồn thu nào) nên công thức tương đối trả về đúng 0 — qua màn mà không
  /// được gì. 100 Xu đủ mua nguồn thu đầu tiên (15 Xu) vài lần.
  static double m3RewardMinCash = 100;

  /// Nhiệm vụ LẶP LẠI sau khi hết chuỗi 10 bước: "kiếm thêm X Xu" với X =
  /// [questRepeatBaseEarn] · 10^vòng. Thưởng cố định [questRepeatRewardGems] 💎.
  static const double questRepeatBaseEarn = 50000000; // 50M
  static const int questRepeatRewardGems = 30;

  // --- Sự kiện Mưa vàng (Golden Rush) ---

  /// Hệ số tăng tốc khi kích hoạt Mưa vàng.
  static const double goldenRushMultiplier = 3.0;

  /// Thời lượng boost (2 phút).
  static const int goldenRushDurationMs = 2 * 60 * 1000;

  /// Con mèo xuất hiện cách nhau ngẫu nhiên trong khoảng [min, max].
  static int catSpawnMinMs = 3 * 60 * 1000;
  static int catSpawnMaxMs = 5 * 60 * 1000;

  /// Con mèo tự biến mất sau chừng này nếu người chơi không chạm.
  static const int catLingerMs = 12 * 1000;

  /// "Tiền tức thì": xem quảng cáo để nhận ngay chừng này giây sản xuất.
  static const int instantCashSeconds = 15 * 60; // 15 phút

  // --- Khách VIP (đi ô tô, tip Kim Cương) ---

  /// VIP xuất hiện cách nhau ngẫu nhiên trong khoảng [min, max] (hiếm hơn mèo).
  static int vipSpawnMinMs = 4 * 60 * 1000;
  static int vipSpawnMaxMs = 7 * 60 * 1000;

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

  /// Trần CỨNG số cấp tối đa cho "Tăng thu nhập"/"Kho lạnh offline" — cùng
  /// nguyên tắc phòng thủ với [maxGeneratorLevel], nhưng SỐ KHÁC HẲN vì hai
  /// công thức tăng nhanh khác nhau nhiều: gemBoostCost/offlineCapCost dùng
  /// growth=2.0 (gấp đôi mỗi cấp) nên tràn thành `double.infinity` sớm hơn
  /// NHIỀU so với các nguồn thu chính (growth chỉ 1.15) — verify thực tế:
  /// `5 * pow(2.0, 1023)` đã là Infinity, và `.ceil()` trên Infinity NÉM LỖI
  /// (`UnsupportedError`) thay vì bão hoà êm như các phép tính khác trong
  /// game — nghĩa là chỉ cần MỞ Cửa hàng Kim Cương (không cần đủ gems để
  /// mua) cũng đã crash nếu cấp vượt trần này. Chưa ai đạt tới trong thực tế
  /// (gems tích rất chậm), nhưng đây đúng lớp lỗi gốc đã gây bug "Xu âm" đầu
  /// phiên — không nên tin "chưa ai đạt tới" mãi mãi. 200 dư sức an toàn xa
  /// mốc 1023 mà vẫn dư thừa so với tiến trình gems bình thường.
  static const int maxGemShopLevel = 200;

  /// Vật phẩm "Tăng thu nhập": +10% thu nhập vĩnh viễn mỗi cấp.
  static const int gemBoostBaseCost = 5;
  static const double gemBoostPerLevel = 0.10;

  /// Vật phẩm "Kho lạnh offline": +2 giờ trần tiền offline mỗi cấp.
  static const int offlineCapBaseCost = 10;
  static const int offlineCapPerLevelSeconds = 2 * 60 * 60;

  /// "Mở giai đoạn tức thì" bằng 💎 — bỏ qua bức tường Xu. Giá theo giai đoạn sắp
  /// mở (index = stage - 2, tức mở GĐ2 tốn `[0]`). Là chỗ tiêu 💎 lớn nhất.
  ///
  /// GĐ2→12 giữ đúng giá cũ (GĐ6→12 đều 1500, trước đây do clamp cuối danh sách);
  /// GĐ13→18 tăng dần vì mở giai đoạn sâu hơn thì "bỏ qua bức tường Xu" đáng
  /// giá hơn. Danh sách PHẢI đủ (số giai đoạn - 1) phần tử — test kiểm tra.
  static const List<int> instantStageGemCost = [
    40, 120, 300, 700, 1500, 1500, 1500, 1500, 1500, 1500, 1500, //
    2500, 3500, 5000, 7000, 10000, 14000,
  ];

  /// "Tua nhanh" bằng 💎 (không cần xem QC): giá cố định cho mỗi lần nhận
  /// [gemTimeSkipSeconds] giây sản xuất. Sink 💎 lặp lại.
  static const int gemTimeSkipCost = 30;
  static const int gemTimeSkipSeconds = 4 * 60 * 60; // 4 giờ

  /// Trần số lần mua "Tua nhanh" mỗi ngày (2026-09-12) — trước đây KHÔNG có
  /// giới hạn, khác MỌI nguồn thưởng tương tự khác trong game (thưởng ngày:
  /// 1 lần/ngày; VIP: hẹn giờ; quảng cáo thưởng: phụ thuộc mạng quảng cáo có
  /// sẵn hay không; Vòng quay: 1 lượt free/ngày) — người nhiều 💎 có thể mua
  /// liên tiếp không giới hạn để bỏ qua hoàn toàn nhịp chờ vốn có của game
  /// idle. 8 lần/ngày = tối đa 32 giờ sản xuất/ngày qua đường này, vẫn là
  /// sink 💎 hấp dẫn nhưng không xoá sạch nhịp độ. Xem
  /// gemTimeSkipRemainingToday() trong simulation.dart.
  static const int maxGemTimeSkipPerDay = 8;

  // --- Mua bằng tiền thật (IAP) ---

  /// Kim Cương nhận theo từng gói gems (consumable) — bậc giá tăng dần.
  static const double iapGemsSmall = 100; // ~$0.99
  static const double iapGemsMedium = 600; // ~$4.99 (bonus theo giá)
  static const double iapGemsLarge = 1300; // ~$9.99
  static const double iapGemsHuge = 4000; // ~$15.99
  static const double iapGemsMega = 10000; // ~$19.99

  /// "Kho lạnh vĩnh viễn" (IAP, mua một lần): cộng thẳng vào trần offline.
  static const int coldStorageBonusSeconds = 8 * 60 * 60;

  /// Kim Cương tặng kèm trong "Gói khởi động" (một lần).
  static const double iapStarterGems = 300;

  /// Trần hệ số boost thời gian cộng dồn (Mưa vàng ×3 · x2-24h · VIP ×2). Chặn
  /// stack quá tay nếu sau này thêm nguồn boost.
  static const double maxTimeBoostMultiplier = 12.0;

  // --- Kiếm thêm (rewarded ads) ---
  /// "x2 thu nhập" tạm thời khi xem QC: hệ số + thời lượng.
  static const double rewardedX2Multiplier = 2.0;
  static const int rewardedX2DurationMs = 24 * 60 * 60 * 1000; // 24 giờ
  /// Kim Cương nhận mỗi lần xem QC ở mục "Nhận 💎 miễn phí".
  static const int rewardedFreeGems = 15;
  /// "Tua nhanh": xem QC nhận ngay chừng này giây sản xuất.
  static const int rewardedTimeSkipSeconds = 4 * 60 * 60; // 4 giờ

  // --- Heo đất (Piggy Bank) ---
  /// Heo tự tích Kim Cương theo THỜI GIAN chơi/vắng (không theo Xu — vì thu nhập
  /// lớn thì fill tức thì, mất cảm giác chờ). Đầy sau [piggyFillHours] giờ; tới
  /// trần thì dừng — đầy thì trả tiền "đập" (IAP boba_piggy) nhận hết.
  static const double piggyMaxGems = 300;
  static const double piggyFillHours = 24;
  static double get piggyGemsPerSecond =>
      piggyMaxGems / (piggyFillHours * 3600);
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

  /// "Siêu offline": +25% thu nhập lúc vắng mặt mỗi cấp.
  static const int prestigeOfflineBaseCost = 3;
  static const double prestigeOfflinePerLevel = 0.25;

  /// "Vốn khởi nghiệp": sau khi Nhượng quyền nhận ngay Xu = 50 · 25^cấp (cấp 0 =
  /// 0) — mua lại các cấp đầu tức thì, giảm cảm giác "về mo".
  static const int prestigeStartCashBaseCost = 4;

  /// "Giữ giai đoạn": sau Nhượng quyền giữ lại tới giai đoạn (1 + cấp). Cấp 5 =
  /// giữ trọn 6 giai đoạn. Không có perk này → prestige reset về giai đoạn 1.
  static const int prestigeKeepStageBaseCost = 8;
  static const int prestigeKeepStageMaxLevel = 5;

  /// "Mua sỉ": −3% giá nâng cấp mọi nguồn thu mỗi cấp (sàn ×0.4).
  static const int prestigeDiscountBaseCost = 5;
  static const double prestigeDiscountPerLevel = 0.03;
  static const double prestigeDiscountFloor = 0.4;

  /// "Tự động mua": mở khoá công tắc auto-buy nguồn "đáng mua nhất". 1 cấp.
  static const int prestigeAutoBuyBaseCost = 12;
  static const int prestigeAutoBuyMaxLevel = 1;

  /// Xem QC lúc nhượng quyền: sau reset được cộng chừng này giây thu nhập (trước
  /// reset) làm Xu khởi đầu. KHÔNG thưởng Sao — Sao = tổng theo lifetime trừ Sao
  /// hiện có nên Sao tặng sẽ bị trừ ngược, và vượt trần server của bảng xếp hạng.
  static const int prestigeAdBonusSeconds = 600;

  // --- Nhiệm vụ hằng ngày (2026-09-26) — ⚠️ số là ƯỚC LƯỢNG, chưa playtest ---
  static const int dailyQuestCount = 3;
  static int dailyQuestRewardGems = 8;
  static const int dailyQuestEarnRewardGems = 10;

  /// Thưởng thêm khi xong (và nhận) cả bộ — nhận một lần/ngày.
  static int dailyQuestBonusGems = 15;

  /// Ngưỡng "Kiếm Xu" = max([dailyEarnMinTarget], thu nhập/giây × giây) chốt lúc
  /// sang ngày (~30 phút thu nhập).
  static const double dailyEarnMinTarget = 500;
  static const int dailyEarnIncomeSeconds = 30 * 60;

  // --- Phụ kiện sưu tập (2026-10-01) — ⚠️ số là ƯỚC LƯỢNG, chưa playtest ---
  //
  // Rớt khi nhận thưởng "xong cả 3 nhiệm vụ ngày" (xem claimDailyQuestBonus
  // trong game_controller.dart) — không đụng chuỗi nhiệm vụ chính (đã có lịch
  // sử bug tràn số, xem int-pow-overflow-quest-zero memory).

  /// Trọng số chọn ĐỘ HIẾM khi rớt phụ kiện (không phải trọng số từng món —
  /// trong cùng 1 độ hiếm thì đều xác suất giữa các món). Tổng không cần = 100.
  static const int accessoryWeightCommon = 66;
  static const int accessoryWeightRare = 24;
  static const int accessoryWeightEpic = 8;
  static const int accessoryWeightLegendary = 2;

  /// Sự kiện cuối tuần: trọng số rớt món Sử thi + Huyền thoại nhân lên bấy nhiêu
  /// (12→24, 3→6: Huyền thoại 3% → ~5,2%, Sử thi 12% → ~20,9%).
  static const int weekendHighRarityMultiplier = 2;

  /// Số phụ kiện tối đa trưng bày quanh cốc ở màn chính (thuần trang trí).
  static const int maxEquippedAccessories = 3;

  /// Mốc Trân Châu Rơi tặng phụ kiện lần ĐẦU qua màn (id màn → độ hiếm tối thiểu
  /// của món). Mốc 60 từng là màn cuối (nay còn 20 màn sau nó).
  static const Map<int, AccessoryRarity> m3AccessoryMilestones = {
    10: AccessoryRarity.rare,
    30: AccessoryRarity.epic,
    60: AccessoryRarity.legendary,
  };

  /// Số món tối đa trong danh sách muốn có (khớp `set_accessory_wishlist`).
  static const int maxWishlist = 10;

  /// Mỗi lần Kỷ Nguyên hoá rớt 1 món Sử thi; xác suất này là Huyền thoại.
  static const double ascensionLegendaryChance = 0.15;

  /// Rớt trúng món đã có (trùng) → quy đổi 💎 thay vì lãng phí lượt rớt.
  static const int duplicateAccessoryGems = 2;

  /// Gói phụ kiện mua bằng 💎 (⚠️ giá ước lượng, chưa playtest): Thường = rớt như
  /// thường; Hiếm = bảo đảm từ Hiếm; Sử thi = bảo đảm từ Sử thi.
  static const int accessoryPackBasicGems = 30;
  static const int accessoryPackRareGems = 80;
  static const int accessoryPackEpicGems = 200;

  /// Dịp lễ (xem `festivals` trong accessories.dart): giảm giá gói + tăng tỉ lệ
  /// Sử thi/Huyền thoại, và mở bán Gói Lễ Hội (phụ kiện độc quyền).
  static const double seasonPackDiscount = 0.25;
  static const int festivalPackGems = 80; // ⚠️ ước lượng, chưa playtest

  /// Nhiệm vụ sự kiện (event_quests.dart): mỗi nhiệm vụ cho 💎 + điểm đổi món lễ hội.
  static const int eventQuestGems = 15; // ⚠️ ước lượng, chưa playtest
  static const int eventQuestPoints = 25;

  /// Buff doanh thu trong dịp lễ (thu nhập/giây + chạm ly, KHÔNG áp offline —
  /// cùng quy ước các boost tạm khác). ⚠️ ước lượng, chưa playtest.
  static const double festivalIncomeMult = 1.25;

  /// Buff thu nhập CẢ HỘI mua bằng Xu Hội (guild_shop.dart): +10% khi còn hạn.
  /// Không áp offline. ⚠️ ước lượng, chưa playtest.
  static const double guildBuffMult = 1.10;

  /// Vòng quay phụ kiện: mỗi lượt = 1 QC hoặc [accessorySpinGems] 💎, rớt như
  /// thường (cùng tỉ lệ rớt chung). Lượt xem QC giới hạn/ngày để không biến thành
  /// máy in phụ kiện (bản dư bán được ở Chợ).
  static const int accessorySpinGems = 30;
  static const int accessorySpinAdsPerDay = 10;

  /// Chỗ trưng bày thêm cho VIP.
  static const int vipExtraEquipSlots = 1;

  // --- Chợ Phụ kiện: đổi Xu/💎 lấy Xu Chợ (2026-10-01) — MỘT CHIỀU, xem
  // credit_market_coins() trong accessory_market_schema.sql. Phí sàn 1%
  // (làm tròn lên, tối thiểu 1) áp ở buy_listing(), không phải ở đây — đây
  // chỉ là tỉ giá NẠP, không phải giao dịch mua bán.

  /// 1 💎 = 10 Xu Chợ — số cố định được vì 💎 ít co giãn hơn Xu nhiều.
  static const int marketCoinsPerGem = 10;

  /// 1 Xu Chợ = [marketCoinsIncomeSeconds] giây thu nhập/giây HIỆN TẠI —
  /// KHÔNG dùng tỉ giá Xu cố định vì Xu trải ~1e2 tới ~1e100 suốt game (cùng
  /// lý do ngưỡng nhiệm vụ "Kiếm Xu" ở §19 GAME_DESIGN dùng tương đối, không
  /// tuyệt đối). Đối xứng với "Tua nhanh" (claimTimeSkip) đã có, chiều ngược
  /// lại: đổi vài phút thu nhập lấy Xu Chợ thay vì đổi 💎 lấy vài phút thu nhập.
  static const int marketCoinsIncomeSeconds = 60;
  //
  // Mặc định TẮT (start = end = 0, xem eventMultiplierAt() trong economy.dart)
  // — chỉ bật khi cả 3 nút này được đặt qua Remote Config. Người vặn số đặt
  // 1 cửa sổ thời gian (VD cuối tuần) + hệ số, publish, hết hạn thì TỰ tắt —
  // không cần nhớ quay lại tắt tay, và không cần nộp bản mới cho mỗi đợt.

  /// Hệ số nhân thu nhập trong lúc sự kiện đang chạy (KHÔNG áp cho offline —
  /// xem ghi chú ở eventMultiplierAt()).
  static double eventIncomeMult = 1.0;

  /// Mốc bắt đầu/kết thúc sự kiện (epoch ms, giờ UTC). `double` dù về bản
  /// chất là số nguyên — khớp kiểu của mọi nút vặn khác trong RemoteBalance
  /// (đọc/ghi qua `double`), và epoch ms tới tận năm ~2100 vẫn nằm gọn trong
  /// phần nguyên chính xác của double (< 2^53).
  static double eventStartMillis = 0;
  static double eventEndMillis = 0;

  // --- Kỷ Nguyên (Ascension) — prestige tầng 2 (2026-09-26) ---
  // ⚠️ Mọi số dưới đây là ƯỚC LƯỢNG, chưa playtest.

  /// Lifetime kiếm THÊM (tính từ lần Kỷ Nguyên trước) tối thiểu để được Kỷ
  /// Nguyên hoá — bằng đúng mức mở giai đoạn 18. Dùng lifetime chứ không dùng
  /// `stage` vì Nhượng quyền reset stage về 1.
  static const double ascensionMinLifetime = 5e35;

  /// Điểm Kỷ Nguyên = floor(sqrt(lifetimeThêm / ascensionMinLifetime)).
  /// Perk: giá cấp = base · 2^cấp điểm, hiệu ứng tuyến tính theo cấp, cấp có
  /// trần (chặn vòng lặp thưởng không giới hạn → tràn số, xem
  /// economyOverflowGuardCap).
  static const int ascensionIncomeBaseCost = 1;
  static const double ascensionIncomePerLevel = 0.5; // +50% thu nhập / cấp
  static const int ascensionIncomeMaxLevel = 20;

  static const int ascensionStarBonusBaseCost = 2;
  static const double ascensionStarBonusPerLevel = 0.25; // bonus/Sao ×(1+0.25·cấp)
  static const int ascensionStarBonusMaxLevel = 20;

  static const int ascensionStarGainBaseCost = 3;
  static const double ascensionStarGainPerLevel = 0.10; // k ×(1+0.10·cấp)
  /// TRẦN CỨNG vì server: leaderboard_schema.sql chặn
  /// `prestige_stars > floor(0.05·sqrt(lifetime))`. k hiệu dụng =
  /// prestigeK·(1+0.10·10) = 0.04 < 0.05. Tăng trần này tới mức k_eff > 0.05 thì
  /// người chơi thật bị bảng xếp hạng chặn nhầm — phải nâng SQL trước. Có test.
  static const int ascensionStarGainMaxLevel = 10;

  // --- Cốt truyện: perk từ lựa chọn nhánh (Chương 6 & 8) ---
  // Mỗi nhánh cộng thêm chừng này vào MỘT trục (thu nhập hoặc chạm), vĩnh viễn,
  // KHÔNG reset khi prestige. Giữ nhỏ để không phá cân bằng — cần playtest.
  static const double storyPerkBonus = 0.08; // +8%

  // --- Đối thủ cạnh tranh (rival) ---
  // "Sức ép" của đối thủ = sqrt(rivalPressureSeconds) · [rivalPowerK]. Giây sức
  // ép KHÔNG cộng theo tổng thời gian chơi — chỉ nhích khi có sự kiện đang chờ
  // trả lời, và nhảy/giảm theo cách người chơi đối phó. → không phụ thuộc việc
  // cày lâu hay ngắn, dễ tune.
  static const double rivalPowerK = 1.0;

  /// Mốc sức ép "hoà" kỳ vọng theo giai đoạn (index = stage - 1). Giai đoạn 1–2
  /// đối thủ chưa xuất hiện nên để lớn. Vượt [rivalBehindRatio] lần mốc này =
  /// "đang thua"; dưới [rivalAheadRatio] lần = "đang thắng".
  static const List<double> rivalExpectedPower = [999, 999, 60, 90, 120, 150];
  static const double rivalAheadRatio = 0.8;
  static const double rivalBehindRatio = 1.2;

  /// Sự kiện đối thủ xuất hiện cách nhau ngẫu nhiên trong khoảng này (như VIP).
  static const int rivalEventSpawnMinMs = 5 * 60 * 1000;
  static const int rivalEventSpawnMaxMs = 8 * 60 * 1000;

  /// Trong lúc sự kiện đang chờ trả lời, đối thủ "lấn tới": +1 giây sức ép mỗi
  /// giây trôi. Nhỏ — chủ yếu tạo cảm giác gấp.
  static const double rivalPendingPressurePerSecond = 1.0;

  /// Phớt lờ một sự kiện: đối thủ cộng chừng này giây sức ép + debuff tạm.
  static const double rivalIgnorePressureSeconds = 2400;
  static const double rivalIgnoreDebuffMult = 0.9;
  static const int rivalIgnoreDebuffSeconds = 120;

  /// Giai đoạn kinh doanh (index = stage - 1). Giai đoạn 1 có sẵn.
  ///
  /// Giai đoạn 7-12 (2026-09-12, mở rộng thế giới): tiếp nối sau "Đế chế toàn
  /// cầu" bằng hồi truyện IPO/tập đoàn đa ngành — xem story.dart chương 9-18.
  /// unlockCost tiếp tục đúng nhịp ×100 đã có từ giai đoạn 3 trở đi.
  static const List<StageConfig> stages = [
    StageConfig(stage: 1, name: 'Xe đẩy vỉa hè', unlockCost: 0),
    StageConfig(stage: 2, name: 'Kiosk cửa hàng nhỏ', unlockCost: 2000),
    StageConfig(stage: 3, name: 'Chuỗi cafe sang trọng', unlockCost: 500000),
    StageConfig(stage: 4, name: 'Xưởng trà sữa nướng', unlockCost: 50000000),
    StageConfig(stage: 5, name: 'Nhà máy phô mai tươi', unlockCost: 5000000000),
    StageConfig(stage: 6, name: 'Đế chế toàn cầu', unlockCost: 500000000000),
    StageConfig(
        stage: 7, name: 'Niêm yết sàn chứng khoán', unlockCost: 5e13),
    StageConfig(stage: 8, name: 'Tập đoàn đa ngành', unlockCost: 5e15),
    StageConfig(stage: 9, name: 'Quỹ đầu tư toàn cầu', unlockCost: 5e17),
    StageConfig(
        stage: 10, name: 'Chuỗi cung ứng nông trại', unlockCost: 5e19),
    StageConfig(stage: 11, name: 'Đế chế công nghệ AI', unlockCost: 5e21),
    StageConfig(stage: 12, name: 'Huyền thoại trà sữa', unlockCost: 5e23),
    StageConfig(
        stage: 13, name: 'Học viện Trà Sữa', unlockCost: 5e25),
    StageConfig(
        stage: 14, name: 'Thành phố Trà Sữa', unlockCost: 5e27),
    StageConfig(
        stage: 15, name: 'Quốc gia Trà Sữa', unlockCost: 5e29),
    StageConfig(
        stage: 16, name: 'Liên minh thế giới', unlockCost: 5e31),
    StageConfig(
        stage: 17, name: 'Hành tinh Trà Sữa', unlockCost: 5e33),
    StageConfig(
        stage: 18, name: 'Chân lý Trà Sữa', unlockCost: 5e35),
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
    // Giai đoạn 7-12 (2026-09-12, mở rộng thế giới) — tiếp đúng nhịp tăng
    // ~×3.3 (giá)/×3.2 (thu nhập) đã có từ "galaxy" trở về trước.
    // Giai đoạn 7 — Niêm yết sàn chứng khoán.
    GeneratorConfig(
      id: 'quantum_tea',
      name: 'Trà sữa lượng tử',
      baseCost: 50000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 1700000,
      stage: 7,
    ),
    GeneratorConfig(
      id: 'ai_tea',
      name: 'Trà sữa AI',
      baseCost: 160000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 5500000,
      stage: 7,
    ),
    // Giai đoạn 8 — Tập đoàn đa ngành.
    GeneratorConfig(
      id: 'parallel_tea',
      name: 'Trà sữa vũ trụ song song',
      baseCost: 530000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 18000000,
      stage: 8,
    ),
    GeneratorConfig(
      id: 'nft_tea',
      name: 'Trà sữa NFT',
      baseCost: 1700000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 58000000,
      stage: 8,
    ),
    // Giai đoạn 9 — Quỹ đầu tư toàn cầu.
    GeneratorConfig(
      id: 'time_tea',
      name: 'Trà sữa xuyên thời gian',
      baseCost: 5600000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 190000000,
      stage: 9,
    ),
    GeneratorConfig(
      id: 'multidim_tea',
      name: 'Trà sữa đa chiều',
      baseCost: 18000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 610000000,
      stage: 9,
    ),
    // Giai đoạn 10 — Chuỗi cung ứng nông trại.
    GeneratorConfig(
      id: 'blackhole_tea',
      name: 'Trà sữa hố đen',
      baseCost: 60000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 2000000000,
      stage: 10,
    ),
    GeneratorConfig(
      id: 'light_tea',
      name: 'Trà sữa ánh sáng',
      baseCost: 200000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 6400000000,
      stage: 10,
    ),
    // Giai đoạn 11 — Đế chế công nghệ AI.
    GeneratorConfig(
      id: 'robot_tea',
      name: 'Trà sữa robot',
      baseCost: 660000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 20000000000,
      stage: 11,
    ),
    GeneratorConfig(
      id: 'hologram_tea',
      name: 'Trà sữa hologram',
      baseCost: 2200000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 64000000000,
      stage: 11,
    ),
    // Giai đoạn 12 — Huyền thoại trà sữa.
    GeneratorConfig(
      id: 'legend_tea',
      name: 'Trà sữa huyền thoại',
      baseCost: 7200000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 200000000000,
      stage: 12,
    ),
    GeneratorConfig(
      id: 'eternal_tea',
      name: 'Trà sữa vĩnh cửu',
      baseCost: 24000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 640000000000,
      stage: 12,
    ),
    // Giai đoạn 13-18 (2026-09-26, mở rộng thế giới đợt 2) — tiếp đúng nhịp
    // ~×3.3 (giá)/×3.2 (thu nhập) từ giai đoạn 7-12.
    // Giai đoạn 13 — Học viện Trà Sữa.
    GeneratorConfig(
      id: 'academy_tea',
      name: 'Trà sữa học viện',
      baseCost: 79000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 2000000000000,
      stage: 13,
    ),
    GeneratorConfig(
      id: 'scholar_tea',
      name: 'Trà sữa học giả',
      baseCost: 260000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 6600000000000,
      stage: 13,
    ),
    // Giai đoạn 14 — Thành phố Trà Sữa.
    GeneratorConfig(
      id: 'city_tea',
      name: 'Trà sữa đô thị',
      baseCost: 860000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 21000000000000,
      stage: 14,
    ),
    GeneratorConfig(
      id: 'metro_tea',
      name: 'Trà sữa siêu đô thị',
      baseCost: 2800000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 67000000000000,
      stage: 14,
    ),
    // Giai đoạn 15 — Quốc gia Trà Sữa.
    GeneratorConfig(
      id: 'nation_tea',
      name: 'Trà sữa quốc gia',
      baseCost: 9400000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 210000000000000,
      stage: 15,
    ),
    GeneratorConfig(
      id: 'treaty_tea',
      name: 'Trà sữa hiệp ước',
      baseCost: 31000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 690000000000000,
      stage: 15,
    ),
    // Giai đoạn 16 — Liên minh thế giới.
    GeneratorConfig(
      id: 'union_tea',
      name: 'Trà sữa liên minh',
      baseCost: 100000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 2200000000000000,
      stage: 16,
    ),
    GeneratorConfig(
      id: 'world_tea',
      name: 'Trà sữa hoà bình thế giới',
      baseCost: 340000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 7000000000000000,
      stage: 16,
    ),
    // Giai đoạn 17 — Hành tinh Trà Sữa.
    GeneratorConfig(
      id: 'planet_tea',
      name: 'Trà sữa hành tinh',
      baseCost: 1100000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 23000000000000000,
      stage: 17,
    ),
    GeneratorConfig(
      id: 'terraform_tea',
      name: 'Trà sữa cải tạo hành tinh',
      baseCost: 3700000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 72000000000000000,
      stage: 17,
    ),
    // Giai đoạn 18 — Chân lý Trà Sữa.
    GeneratorConfig(
      id: 'truth_tea',
      name: 'Trà sữa chân lý',
      baseCost: 12000000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 230000000000000000,
      stage: 18,
    ),
    GeneratorConfig(
      id: 'ultimate_tea',
      name: 'Trà sữa tối thượng',
      baseCost: 40000000000000000000,
      costGrowth: 1.15,
      incomePerLevelPerSecond: 740000000000000000,
      stage: 18,
    ),
  ];
}
