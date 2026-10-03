// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Đế Chế Trà Sữa';

  @override
  String get tapBrew => 'Chạm pha trà';

  @override
  String get coinsSuffix => ' Xu';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / giây';
  }

  @override
  String get instantCashButton => 'Tiền tức thì';

  @override
  String instantCashSnack(String amount) {
    return 'Tiền tức thì! +$amount Xu';
  }

  @override
  String get adNotReadySnack => 'Quảng cáo chưa sẵn sàng, thử lại sau nhé';

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Mở khóa $cost Xu';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Xu/giây mỗi cấp';
  }

  @override
  String buyButton(String cost) {
    return '$cost Xu';
  }

  @override
  String get buyModeMax => 'MAX';

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'Khách VIP! +$cash Xu, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Đã nhận +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Đã gỡ quảng cáo. Cảm ơn bạn!';

  @override
  String iapStarterSnack(String amount) {
    return 'Gói khởi động: +$amount 💎';
  }

  @override
  String get genTraDen => 'Trà đen';

  @override
  String get genTranChau => 'Trân châu';

  @override
  String get genThach => 'Thạch';

  @override
  String get genPudding => 'Pudding';

  @override
  String get genKemNuong => 'Trà sữa kem nướng';

  @override
  String get genMatcha => 'Matcha xô';

  @override
  String get stage1 => 'Xe đẩy vỉa hè';

  @override
  String get stage2 => 'Kiosk cửa hàng nhỏ';

  @override
  String get stage3 => 'Chuỗi cafe sang trọng';

  @override
  String gemShopTitle(String gems) {
    return 'Cửa Hàng 💎 (có $gems)';
  }

  @override
  String get gemBoostName => 'Tăng thu nhập';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% thu nhập vĩnh viễn mỗi cấp';
  }

  @override
  String get offlineCapName => 'Kho lạnh offline';

  @override
  String offlineCapDesc(int hours) {
    return '+$hours giờ trần tiền offline mỗi cấp';
  }

  @override
  String gemItemLevel(String name, int level) {
    return '$name  Lv.$level';
  }

  @override
  String gemCost(int cost) {
    return '$cost 💎';
  }

  @override
  String get gemInstantStageName => 'Mở giai đoạn tức thì';

  @override
  String gemInstantStageDesc(String stage) {
    return 'Mở $stage ngay, bỏ qua chi phí Xu';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return 'Đã mở $stage!';
  }

  @override
  String get gemTimeSkipName => 'Tua nhanh';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Nhận ngay $hours giờ sản xuất';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return 'Còn $remaining/$max lượt hôm nay';
  }

  @override
  String get iapSectionTitle => 'Nạp bằng tiền thật';

  @override
  String get restorePurchases => 'Khôi phục giao dịch';

  @override
  String get close => 'Đóng';

  @override
  String get iapGemsDesc =>
      'Nạp thêm Kim Cương để mua vật phẩm trong Cửa hàng.';

  @override
  String get iapRemoveAdsTitle => 'Gỡ quảng cáo';

  @override
  String get iapRemoveAdsDesc =>
      'Bỏ qua mọi quảng cáo — vẫn nhận đủ thưởng, không cần xem.';

  @override
  String get iapStarterTitle => 'Gói khởi động';

  @override
  String get iapStarterDesc => 'Một lần: nhận ngay một túi Kim Cương lớn.';

  @override
  String get prestigeTitle => 'Nhượng Quyền 🏪';

  @override
  String prestigeIntro(String percent) {
    return 'Mỗi ⭐ Sao cho +$percent% thu nhập vĩnh viễn.';
  }

  @override
  String get prestigeStarsNow => 'Sao hiện có';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Nhượng quyền bây giờ';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Tổng bonus sau đó';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Reset Xu, cấp nâng cấp và giai đoạn (perk kho Sao có thể giữ lại một phần).';

  @override
  String get cancel => 'Huỷ';

  @override
  String prestigeConfirm(String stars) {
    return 'Nhượng quyền (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Chưa đủ';

  @override
  String prestigeSuccess(String stars) {
    return 'Nhượng quyền thành công! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'Chào mừng trở lại! 🧋';

  @override
  String offlineBody(String amount) {
    return 'Quán vẫn bán trong lúc bạn vắng mặt.\nBạn kiếm được $amount Xu.';
  }

  @override
  String get offlineClaim => 'Nhận';

  @override
  String get offlineDoubleButton => 'Xem QC ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'Nhân đôi! +$amount Xu';
  }

  @override
  String get howToPlayTitle => 'Cách chơi';

  @override
  String get htpTap => '🧋 Chạm ly để pha trà và kiếm Xu.';

  @override
  String get htpBuy => '🛒 Mua nâng cấp để có thu nhập tự động mỗi giây.';

  @override
  String get htpStage =>
      '🏪 Đủ Xu thì mở khóa giai đoạn mới, bán món cao cấp hơn.';

  @override
  String get htpCat =>
      '🐱 Chạm mèo may mắn để nhận Mưa vàng ×3 trong chốc lát.';

  @override
  String get htpVip => '🚗 Đón khách VIP đi ô tô để nhận Kim Cương 💎.';

  @override
  String get htpGems =>
      '💎 Dùng Kim Cương trong Cửa hàng mua nâng cấp vĩnh viễn.';

  @override
  String get htpPrestige =>
      '⭐ Nhượng quyền để chơi lại và nhận Sao — bonus thu nhập vĩnh viễn.';

  @override
  String get htpOffline =>
      '😴 Quán vẫn bán khi bạn thoát — quay lại nhận tiền offline.';

  @override
  String get htpNumberFormat =>
      '🔢 Số lớn viết tắt: K=nghìn, M=triệu, B=tỷ, T=nghìn tỷ, rồi tới aa, bb, cc... — mỗi bước gấp 1.000 lần bước trước.';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get dailyTitle => 'Điểm danh hằng ngày';

  @override
  String get dailyPrompt => 'Nhận quà đăng nhập hôm nay!';

  @override
  String get dailyClaim => 'Nhận quà';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Chuỗi $days ngày 🔥';
  }

  @override
  String get achievementsTitle => 'Thành tựu';

  @override
  String achEarn(String amount) {
    return 'Kiếm tổng $amount Xu';
  }

  @override
  String achStage(int n) {
    return 'Đạt giai đoạn $n';
  }

  @override
  String achLevels(int n) {
    return 'Sở hữu tổng $n cấp nâng cấp';
  }

  @override
  String achPrestige(int n) {
    return 'Nhượng quyền ($n★ trở lên)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 Mở khoá thành tựu! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'Kho Sao ⭐';

  @override
  String prestigeShopSpendable(String stars) {
    return 'Còn $stars ⭐ để tiêu';
  }

  @override
  String get prestigeIncomeName => 'Siêu thu nhập';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% thu nhập vĩnh viễn mỗi cấp';
  }

  @override
  String get prestigeTapName => 'Siêu chạm';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% giá trị chạm mỗi cấp';
  }

  @override
  String get prestigeOfflineName => 'Siêu offline';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% thu nhập lúc vắng mỗi cấp';
  }

  @override
  String get prestigeStartCashName => 'Vốn khởi nghiệp';

  @override
  String get prestigeStartCashDesc =>
      'Nhận Xu ngay sau Nhượng quyền (tăng mỗi cấp)';

  @override
  String get prestigeKeepStageName => 'Giữ giai đoạn';

  @override
  String get prestigeKeepStageDesc =>
      'Sau Nhượng quyền giữ thêm 1 giai đoạn mỗi cấp';

  @override
  String get prestigeDiscountName => 'Mua sỉ';

  @override
  String prestigeDiscountDesc(int percent) {
    return '−$percent% giá nâng cấp nguồn thu mỗi cấp';
  }

  @override
  String get prestigeAutoBuyName => 'Tự động mua';

  @override
  String get prestigeAutoBuyDesc =>
      'Mở khoá công tắc tự mua nguồn đáng mua nhất';

  @override
  String get autoBuyLabel => 'Tự động mua';

  @override
  String prestigeStarCost(String cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'Chạm pha trà $n lần';
  }

  @override
  String questBuy(int n) {
    return 'Mua $n nâng cấp';
  }

  @override
  String questRepeatEarn(String amount) {
    return 'Kiếm thêm $amount Xu';
  }

  @override
  String get questClaim => 'Nhận';

  @override
  String get iapDoubleTitle => 'x2 Thu nhập (vĩnh viễn)';

  @override
  String get iapDoubleDesc => 'Gấp đôi mọi thu nhập tự động, mãi mãi';

  @override
  String get iapDoubleSnack => 'Đã bật x2 thu nhập vĩnh viễn!';

  @override
  String get rewardsTitle => 'Kiếm thêm 🎁';

  @override
  String get rewardsChip => 'Kiếm thêm';

  @override
  String get rewardX2Name => 'x2 thu nhập 24 giờ';

  @override
  String rewardX2Active(int hours) {
    return 'Đang bật · còn ${hours}h';
  }

  @override
  String get rewardX2Snack => 'Đã bật x2 thu nhập 24 giờ!';

  @override
  String rewardGemsName(int gems) {
    return 'Nhận $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'Tua nhanh $hours giờ';
  }

  @override
  String get watchAd => 'Xem QC';

  @override
  String get piggyName => 'Heo đất';

  @override
  String get piggyBreak => 'Đập';

  @override
  String piggySnack(String gems) {
    return 'Đập heo: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'VIP Pass 30 ngày 👑';

  @override
  String get iapVipDesc => 'Gỡ QC + x2 thu nhập + 50💎/ngày + trần offline+';

  @override
  String get iapVipSnack => 'Đã kích hoạt VIP 30 ngày! 👑';

  @override
  String get genDuongDen => 'Sữa tươi đường đen';

  @override
  String get genBrulee => 'Trà sữa nướng';

  @override
  String get genCheeseFoam => 'Kem phô mai';

  @override
  String get genTraTraiCay => 'Trà trái cây';

  @override
  String get genBobaVang => 'Boba vàng';

  @override
  String get genGalaxy => 'Trà sữa ngân hà';

  @override
  String get genQuantumTea => 'Trà sữa lượng tử';

  @override
  String get genAiTea => 'Trà sữa AI';

  @override
  String get genParallelTea => 'Trà sữa vũ trụ song song';

  @override
  String get genNftTea => 'Trà sữa NFT';

  @override
  String get genTimeTea => 'Trà sữa xuyên thời gian';

  @override
  String get genMultidimTea => 'Trà sữa đa chiều';

  @override
  String get genBlackholeTea => 'Trà sữa hố đen';

  @override
  String get genLightTea => 'Trà sữa ánh sáng';

  @override
  String get genRobotTea => 'Trà sữa robot';

  @override
  String get genHologramTea => 'Trà sữa hologram';

  @override
  String get genLegendTea => 'Trà sữa huyền thoại';

  @override
  String get genEternalTea => 'Trà sữa vĩnh cửu';

  @override
  String get stage4 => 'Xưởng trà sữa nướng';

  @override
  String get stage5 => 'Nhà máy phô mai tươi';

  @override
  String get stage6 => 'Đế chế toàn cầu';

  @override
  String get stage7 => 'Niêm yết sàn chứng khoán';

  @override
  String get stage8 => 'Tập đoàn đa ngành';

  @override
  String get stage9 => 'Quỹ đầu tư toàn cầu';

  @override
  String get stage10 => 'Chuỗi cung ứng nông trại';

  @override
  String get stage11 => 'Đế chế công nghệ AI';

  @override
  String get stage12 => 'Huyền thoại trà sữa';

  @override
  String get stage13 => 'Học viện Trà Sữa';

  @override
  String get stage14 => 'Thành phố Trà Sữa';

  @override
  String get stage15 => 'Quốc gia Trà Sữa';

  @override
  String get stage16 => 'Liên minh thế giới';

  @override
  String get stage17 => 'Hành tinh Trà Sữa';

  @override
  String get stage18 => 'Chân lý Trà Sữa';

  @override
  String get genAcademyTea => 'Trà sữa học viện';

  @override
  String get genScholarTea => 'Trà sữa học giả';

  @override
  String get genCityTea => 'Trà sữa đô thị';

  @override
  String get genMetroTea => 'Trà sữa siêu đô thị';

  @override
  String get genNationTea => 'Trà sữa quốc gia';

  @override
  String get genTreatyTea => 'Trà sữa hiệp ước';

  @override
  String get genUnionTea => 'Trà sữa liên minh';

  @override
  String get genWorldTea => 'Trà sữa hoà bình thế giới';

  @override
  String get genPlanetTea => 'Trà sữa hành tinh';

  @override
  String get genTerraformTea => 'Trà sữa cải tạo hành tinh';

  @override
  String get genTruthTea => 'Trà sữa chân lý';

  @override
  String get genUltimateTea => 'Trà sữa tối thượng';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsSound => 'Âm thanh';

  @override
  String get settingsReset => 'Chơi lại từ đầu';

  @override
  String get settingsResetConfirm => 'Xoá toàn bộ tiến trình và bắt đầu lại?';

  @override
  String get navHome => 'Nhà';

  @override
  String get navShop => 'Cửa hàng';

  @override
  String get navPrestige => 'Nhượng quyền';

  @override
  String get navAchievements => 'Thành tựu';

  @override
  String get wheelName => 'Vòng quay may mắn 🎡';

  @override
  String get spinFree => 'Quay miễn phí';

  @override
  String get spinAd => 'Xem QC để quay';

  @override
  String storyChapterLabel(int n) {
    return 'Chương $n';
  }

  @override
  String get storyContinue => 'Tiếp tục';

  @override
  String get storyChoosePrompt => 'Chọn hướng đi — không đổi lại được:';

  @override
  String get storyLogTitle => 'Cốt truyện';

  @override
  String get storyLogLocked => 'Chương chưa mở';

  @override
  String storyUnlockWhen(String cond) {
    return 'Mở khi: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return 'Mở sau $chapter';
  }

  @override
  String storyCondFirst(String name) {
    return '$name lần đầu';
  }

  @override
  String get storyCondRival => 'Đánh bại đối thủ';

  @override
  String storyCondAscension(int n, String name) {
    return '$name lần $n';
  }

  @override
  String storyCondM3(int n, String game) {
    return 'Qua màn $n của $game';
  }

  @override
  String get rivalEventTitle => 'Đối thủ ra tay!';

  @override
  String get rivalEventIgnore => 'Phớt lờ';

  @override
  String get rivalMeterAhead => 'Đang dẫn trước';

  @override
  String get rivalMeterEven => 'Ngang sức';

  @override
  String get rivalMeterBehind => 'Đang bị lấn';

  @override
  String get rivalResolvedSnack => 'Đã đối phó. Đối thủ chùn lại.';

  @override
  String get rivalIgnoredSnack => 'Bạn làm ngơ — đối thủ được đà lấn tới.';

  @override
  String get navArena => 'Đấu Trường';

  @override
  String get navCompete => 'Thi đấu';

  @override
  String get arenaTitle => 'Đấu Trường';

  @override
  String get arenaIntro =>
      'Đấu 1v1 trong 60 giây — ai kiếm nhiều Xu hơn thắng!';

  @override
  String get arenaStartButton => 'Tìm đối thủ';

  @override
  String get arenaModeTap => 'Đua chạm';

  @override
  String get arenaModeMatch3 => 'Trân Châu Rơi';

  @override
  String get arenaMatch3Intro =>
      'Ghép 3 hình giống nhau trong 60 giây — ăn nhiều điểm hơn đối thủ thì thắng!';

  @override
  String get arenaMatch3Stuck => 'Hết nước đi!';

  @override
  String get arenaQueueWaiting => 'Đang tìm đối thủ…';

  @override
  String get arenaCancelButton => 'Huỷ';

  @override
  String get arenaTapButton => 'Chạm ly';

  @override
  String get arenaResolving => 'Đang chốt trận…';

  @override
  String arenaTierButton(String cost) {
    return 'Nâng ×2 ($cost Xu)';
  }

  @override
  String arenaTimeLeft(int seconds) {
    return 'Còn ${seconds}s';
  }

  @override
  String arenaOnlineCount(int count) {
    return '$count người đang online';
  }

  @override
  String get arenaYourScore => 'Điểm của bạn';

  @override
  String get arenaOpponentScore => 'Đối thủ';

  @override
  String get arenaResultWin => 'Bạn thắng! 🎉';

  @override
  String get arenaResultLose => 'Bạn thua rồi';

  @override
  String get arenaResultDraw => 'Hoà';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'Đóng';

  @override
  String get redeemTitle => 'Nhập mã quà tặng';

  @override
  String get redeemHint => 'Nhập mã';

  @override
  String get redeemButton => 'Nhận quà';

  @override
  String redeemSuccess(int gems) {
    return 'Nhận thành công +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => 'Mã này bạn đã nhận rồi';

  @override
  String get redeemInvalid => 'Mã không hợp lệ';

  @override
  String get cloudSaveMenuTitle => 'Sao lưu tiến trình';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Đã liên kết: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Chưa liên kết — có thể mất tiến trình nếu gỡ app';

  @override
  String get cloudSaveTitle => 'Sao lưu tiến trình';

  @override
  String get cloudSaveIntro =>
      'Liên kết email để khôi phục được tiến trình nếu gỡ app hoặc đổi máy.';

  @override
  String get cloudSaveEmailHint => 'Email của bạn';

  @override
  String get cloudSaveSendCode => 'Gửi mã';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Đã gửi mã xác nhận tới $email';
  }

  @override
  String get cloudSaveCodeHint => 'Mã xác nhận';

  @override
  String get cloudSaveVerify => 'Xác nhận';

  @override
  String get cloudSaveChangeEmail => 'Đổi email khác';

  @override
  String get cloudSaveResend => 'Gửi lại mã';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'Gửi lại mã (${seconds}s)';
  }

  @override
  String get cloudSaveConflictTitle => 'Tìm thấy save khác trên cloud';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'Máy này: $amount Xu cả đời';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'Trên cloud: $amount Xu cả đời';
  }

  @override
  String get cloudSaveRestoreButton => 'Khôi phục từ cloud';

  @override
  String get cloudSaveKeepLocalButton => 'Giữ máy này';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'Đã liên kết: $email';
  }

  @override
  String get cloudSaveDisconnect => 'Ngắt kết nối';

  @override
  String get cloudSaveRetry => 'Thử lại';

  @override
  String get leaderboardMenuTitle => 'Bảng xếp hạng';

  @override
  String get leaderboardTitle => 'Bảng xếp hạng';

  @override
  String get leaderboardNicknameIntro =>
      'Đặt tên hiển thị trên bảng xếp hạng (đổi được sau):';

  @override
  String get leaderboardNicknameHint => 'Tên của bạn';

  @override
  String get leaderboardSubmit => 'Xác nhận';

  @override
  String leaderboardYourRank(int rank) {
    return 'Hạng của bạn: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => 'Chưa có ai trên bảng xếp hạng — là bạn đây!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 Bạn đang giữ hạng cao! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'Top 1: $top1💎 · Top 2-3: $top23💎 · Top 4-10: $top410💎 — mỗi 24 giờ nếu còn giữ hạng';
  }

  @override
  String get leaderboardChangeName => 'Đổi tên';

  @override
  String get leaderboardRetry => 'Thử lại';

  @override
  String get storySpeedrunMenuTitle => 'Tốc độ hoàn thành';

  @override
  String get storySpeedrunTitle => 'Bảng xếp hạng tốc độ';

  @override
  String get storySpeedrunNotCompletedYet =>
      'Bạn chưa hoàn thành cốt truyện — hoàn thành Chương 18 để được xếp hạng.';

  @override
  String get storySpeedrunTabMain => 'Hồi 1';

  @override
  String get storySpeedrunTabExt => 'Hồi 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'Bạn chưa hoàn thành Hồi 2 — hoàn thành Chương 28 để được xếp hạng.';

  @override
  String get storySpeedrunTabExt2 => 'Hồi 3';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      'Bạn chưa hoàn thành Hồi 3 — hoàn thành Chương 36 để được xếp hạng.';

  @override
  String get accessoryMenuTitle => 'Sưu tập';

  @override
  String get collectionChip => 'Bộ sưu tập';

  @override
  String get accessoryInventoryTitle => 'Kho phụ kiện';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return 'Đã có $owned/$total';
  }

  @override
  String get accessoryRarityCommon => 'Thường';

  @override
  String get accessoryRarityRare => 'Hiếm';

  @override
  String get accessoryRarityEpic => 'Sử thi';

  @override
  String get accessoryRarityLegendary => 'Huyền thoại';

  @override
  String get accessoryLbTitle => 'Bảng xếp hạng Sưu tập';

  @override
  String accessoryLbCount(int n) {
    return '$n phụ kiện';
  }

  @override
  String get accessoryLbTopTitle => 'Nhà Sưu Tầm';

  @override
  String get accessoryLbTitleKing => 'Vua Phụ Kiện';

  @override
  String get accessoryLbTitleMaster => 'Cao Thủ Sưu Tầm';

  @override
  String get accessoryLbEmpty =>
      'Chưa ai lên bảng. Sưu tập 1 món là có tên ngay!';

  @override
  String get accessoryLbNoOwned =>
      'Bạn chưa có phụ kiện nào — hoàn thành đủ 3 nhiệm vụ ngày để có cơ hội nhận.';

  @override
  String get accessoryLbError =>
      'Không tải được bảng xếp hạng, thử lại sau nhé.';

  @override
  String get accessoryMintLeaf => 'Lá bạc hà';

  @override
  String get accessoryCupcake => 'Bánh cupcake';

  @override
  String get accessoryCookie => 'Bánh quy';

  @override
  String get accessoryPottedPlant => 'Chậu cây nhỏ';

  @override
  String get accessoryCandle => 'Nến thơm';

  @override
  String get accessoryScarf => 'Khăn quàng';

  @override
  String get accessoryKite => 'Diều giấy';

  @override
  String get accessoryCap => 'Mũ lưỡi trai';

  @override
  String get accessorySeashell => 'Vỏ sò';

  @override
  String get accessoryMask => 'Mặt nạ';

  @override
  String get accessoryDrum => 'Trống nhỏ';

  @override
  String get accessoryPalette => 'Bảng màu';

  @override
  String get accessoryCrystalBall => 'Quả cầu pha lê';

  @override
  String get accessoryLantern => 'Đèn lồng cổ';

  @override
  String get accessoryUnicorn => 'Kỳ lân nhỏ';

  @override
  String get accessoryDragon => 'Rồng nhỏ';

  @override
  String get accessoryBalloon => 'Bong bóng';

  @override
  String get accessoryBowtie => 'Nơ bướm';

  @override
  String get accessorySunglasses => 'Kính râm';

  @override
  String get accessoryUmbrella => 'Dù nhỏ';

  @override
  String get accessoryTeapot => 'Ấm trà nhỏ';

  @override
  String get accessoryBell => 'Chuông nhỏ';

  @override
  String get accessoryRibbon => 'Ruy băng';

  @override
  String get accessoryBookmark => 'Bookmark xinh';

  @override
  String get accessoryWindChime => 'Chuông gió';

  @override
  String get accessoryClover => 'Cỏ bốn lá';

  @override
  String get accessoryBubble => 'Bong bóng xà phòng';

  @override
  String get accessorySticker => 'Nhãn dán';

  @override
  String get accessoryYarn => 'Cuộn len';

  @override
  String get accessoryFan => 'Quạt giấy';

  @override
  String get accessoryBasket => 'Giỏ mây';

  @override
  String get accessoryBead => 'Chuỗi hạt';

  @override
  String get accessoryLadybug => 'Bọ rùa nhỏ';

  @override
  String get accessoryKey => 'Chìa khoá cổ';

  @override
  String get accessoryDiamondStone => 'Viên đá kim cương';

  @override
  String get accessoryMusicNote => 'Nốt nhạc nhỏ';

  @override
  String get accessoryTelescope => 'Kính viễn vọng';

  @override
  String get accessoryAnchor => 'Mỏ neo';

  @override
  String get accessoryFeather => 'Lông vũ';

  @override
  String get accessoryHourglass => 'Đồng hồ cát';

  @override
  String get accessoryMap => 'Bản đồ cổ';

  @override
  String get accessoryRing => 'Nhẫn nhỏ';

  @override
  String get accessoryMagicWand => 'Đũa phép';

  @override
  String get accessoryTrident => 'Đinh ba biển cả';

  @override
  String get accessoryPeacock => 'Công nhỏ';

  @override
  String get accessoryComet => 'Sao chổi';

  @override
  String get accessoryButterfly => 'Bướm pha lê';

  @override
  String get accessoryAngelWing => 'Cánh thiên thần';

  @override
  String get accessoryPhoenix => 'Phượng hoàng lửa';

  @override
  String get accessoryGalaxy => 'Dải ngân hà';

  @override
  String get marketTitle => 'Chợ Phụ kiện';

  @override
  String get marketTabBrowse => 'Chợ';

  @override
  String get marketTabMine => 'Của tôi';

  @override
  String get marketRecentSalesHeader => 'Vừa bán';

  @override
  String get marketMerchantTitle => 'Thương gia tuần';

  @override
  String get marketFilterAll => 'Tất cả';

  @override
  String get marketFilterMissing => 'Chưa có';

  @override
  String get marketSortPriceAsc => 'Giá thấp';

  @override
  String get marketBadgeNew => 'MỚI';

  @override
  String marketNeedMore(int n) {
    return 'Thiếu $n Xu Chợ';
  }

  @override
  String get marketNoFilterResults => 'Không có món nào khớp bộ lọc.';

  @override
  String accessoryRevealNew(String name) {
    return 'Nhận được phụ kiện mới: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return 'Trùng $name: +$gems 💎 và 1 bản dư bán được ở Chợ';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return 'Trưng bày $n/$max — chạm một món đã có để đặt quanh cốc';
  }

  @override
  String accessoryEquipFull(int max) {
    return 'Đã đủ $max món trưng bày — bỏ chọn một món trước';
  }

  @override
  String get accessoryFlairHint =>
      'Giữ lâu một món để đặt làm huy hiệu bảng xếp hạng';

  @override
  String accessoryFlairSet(String name) {
    return 'Đã đặt $name làm huy hiệu bảng xếp hạng';
  }

  @override
  String get accessoryFlairCleared => 'Đã gỡ huy hiệu bảng xếp hạng';

  @override
  String get accessoryFlairFailed =>
      'Không đặt được huy hiệu — món này chưa đồng bộ lên máy chủ hoặc mất mạng';

  @override
  String get marketStarterTitle => 'Gói Khởi Nghiệp Chợ';

  @override
  String get marketStarterBody =>
      'Tặng 1 phụ kiện Thường + 1 bản dư để bán + 10 Xu Chợ. Chỉ nhận một lần.';

  @override
  String get marketStarterClaim => 'Nhận quà';

  @override
  String get marketStarterDone => 'Đã nhận Gói Khởi Nghiệp! Xem món trong Kho.';

  @override
  String get marketStarterErrCap =>
      'Hôm nay quà đã hết lượt toàn server — mai quay lại nhé.';

  @override
  String get marketStarterErrNet =>
      'Không nhận được — kiểm tra mạng rồi thử lại.';

  @override
  String get marketIntroTitle => 'Chào mừng đến Chợ!';

  @override
  String get marketIntroStep1 =>
      '1. Đổi 💎 hoặc Xu lấy Xu Chợ (nút Đổi) — Xu Chợ chỉ dùng trong Chợ và không đổi ngược lại.';

  @override
  String get marketIntroStep2 =>
      '2. Mua phụ kiện người khác đăng bán để hoàn thiện bộ sưu tập.';

  @override
  String get marketIntroStep3 => '3. Bán bản dư ở tab Của tôi. Phí sàn chỉ 1%.';

  @override
  String get marketIntroOk => 'Đã hiểu';

  @override
  String get collectionTitle10 => 'Người sưu tầm';

  @override
  String get collectionTitle25 => 'Nhà sưu tầm';

  @override
  String get collectionTitle40 => 'Chuyên gia sưu tầm';

  @override
  String get collectionTitle50 => 'Huyền thoại sưu tầm';

  @override
  String collectionTitleLabel(String title) {
    return 'Danh hiệu: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return 'Nhận +$coins';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count món · $coins Xu Chợ';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return 'Nhận $coins Xu Chợ và danh hiệu mới!';
  }

  @override
  String get collectionMilestoneErrNet =>
      'Không nhận được — kiểm tra mạng rồi thử lại.';

  @override
  String marketPriceLast(int n) {
    return 'Bán gần nhất: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return 'Rẻ nhất đang bán: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return 'TB 7 ngày: $n';
  }

  @override
  String get marketWishAdd => 'Thêm vào danh sách muốn có';

  @override
  String get marketWishRemove => 'Bỏ khỏi danh sách muốn có';

  @override
  String marketWishFull(int max) {
    return 'Danh sách muốn có đã đầy ($max món)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return 'Cuối tuần miễn phí: bạn nhận đủ $proceeds Xu Chợ';
  }

  @override
  String get marketWeekendBanner =>
      '🎉 Cuối tuần: phí Chợ 0% & tăng tỉ lệ rớt phụ kiện hiếm!';

  @override
  String collectionPeekTitle(String name) {
    return 'Bộ sưu tập của $name';
  }

  @override
  String get collectionPeekError =>
      'Không tải được bộ sưu tập — thử lại sau nhé.';

  @override
  String get collectionShareTooltip => 'Khoe bộ sưu tập';

  @override
  String collectionShareText(int owned, int total, String items) {
    return 'Tôi đã sưu tầm $owned/$total phụ kiện trong Boba Empire! $items';
  }

  @override
  String get collectionShareCopied => 'Đã sao chép — dán vào tin nhắn để khoe!';

  @override
  String get collectionCardTitle => 'Thẻ khoe bộ sưu tập';

  @override
  String get collectionShareImage => 'Chia sẻ ảnh';

  @override
  String get collectionShareCopy => 'Sao chép chữ';

  @override
  String get collectionShareFailed =>
      'Không chia sẻ được — thử sao chép chữ nhé.';

  @override
  String whatsNewTitle(String version) {
    return 'Có gì mới ở $version';
  }

  @override
  String get whatsNewCollection =>
      '🎀 Bộ sưu tập: 50 phụ kiện, trưng bày quanh cốc, huy hiệu bảng xếp hạng, mốc thưởng';

  @override
  String get whatsNewMarket =>
      '🛒 Chợ phụ kiện: mua bán bằng Xu Chợ, giá tham khảo, danh sách muốn có, báo khi bán được';

  @override
  String get whatsNewWheel =>
      '🎡 Vòng quay có ô rương phụ kiện. Cuối tuần: phí Chợ 0% và dễ rớt đồ hiếm hơn';

  @override
  String get whatsNewStory => '📖 Hồi 3 cốt truyện: 8 chương mới';

  @override
  String get whatsNewLook =>
      '🎨 Giao diện pastel, mượt hơn, chia sẻ bộ sưu tập thành ảnh';

  @override
  String get whatsNewLater => 'Để sau';

  @override
  String get whatsNewOpen => 'Xem bộ sưu tập';

  @override
  String marketWallet(int n) {
    return '$n Xu Chợ';
  }

  @override
  String get marketError => 'Không tải được Chợ, thử lại sau nhé.';

  @override
  String get marketEmptyBrowse => 'Chợ chưa có ai đăng bán gì.';

  @override
  String get marketBuyButton => 'Mua';

  @override
  String get marketBoughtToast => 'Đã mua!';

  @override
  String marketConfirmBuy(int price) {
    return 'Mua với giá $price Xu Chợ?';
  }

  @override
  String marketPriceTag(int price) {
    return '$price Xu Chợ';
  }

  @override
  String get marketMyListingsHeader => 'Đang đăng bán';

  @override
  String get marketEmptyMine => 'Bạn chưa đăng bán món nào.';

  @override
  String get marketCancelButton => 'Huỷ đăng';

  @override
  String get marketCancelledToast => 'Đã huỷ đăng.';

  @override
  String get marketSellableHeader => 'Phụ kiện có thể đăng bán';

  @override
  String get marketEmptySellable => 'Bạn chưa có phụ kiện nào để đăng bán.';

  @override
  String get marketListedToast => 'Đã đăng bán!';

  @override
  String get marketListButton => 'Đăng bán';

  @override
  String get marketPriceLabel => 'Giá (Xu Chợ)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return 'Bạn sẽ nhận $proceeds Xu Chợ sau khi trừ phí sàn 1% (−$fee)';
  }

  @override
  String get marketConvertButton => 'Đổi';

  @override
  String get marketConvertTitle => 'Đổi lấy Xu Chợ';

  @override
  String get marketConvertAmountLabel => 'Số Xu Chợ muốn đổi';

  @override
  String marketConvertCostGems(String cost) {
    return 'Tốn: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return 'Tốn: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => 'Đã đổi!';

  @override
  String get marketConvertFailToast =>
      'Đổi thất bại — không đủ số dư hoặc lỗi mạng.';

  @override
  String get storySpeedrunEmpty =>
      'Chưa có ai hoàn thành cốt truyện — là bạn đây!';

  @override
  String get arenaLeaderboardMenuTitle => 'Bảng xếp hạng PK';

  @override
  String get arenaLeaderboardTitle => 'Bảng xếp hạng PK';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'Bạn chưa đấu trận nào — thắng 1 trận Đấu Trường để xuất hiện ở đây.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '$wins thắng - $losses bại';
  }

  @override
  String get ascensionTitle => 'Kỷ Nguyên';

  @override
  String get ascensionOpen => 'Kỷ Nguyên ⏳';

  @override
  String get ascensionIntro =>
      'Đổi toàn bộ Sao và perk Kho Sao lấy ⏳ Điểm Kỷ Nguyên — perk vĩnh viễn mạnh hơn. Bạn sẽ chơi lại từ đầu.';

  @override
  String ascensionProgress(int percent) {
    return 'Tiến độ tới ngưỡng mở: $percent%';
  }

  @override
  String get ascensionPointsNow => 'Điểm đang có';

  @override
  String get ascensionPointsGain => 'Nhận nếu Kỷ Nguyên hoá';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ Reset Sao, mọi perk Kho Sao, Xu, cấp nâng cấp và giai đoạn. Giữ 💎, thành tựu, cốt truyện. Sao trên bảng xếp hạng về 0 (thứ hạng theo tổng thu nhập không đổi).';

  @override
  String ascensionConfirm(int points) {
    return 'Kỷ Nguyên hoá (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'Chưa đủ điều kiện';

  @override
  String ascensionSuccess(int points) {
    return 'Bắt đầu Kỷ Nguyên mới! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'Perk Kỷ Nguyên ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return 'Còn $points ⏳ để tiêu';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => 'Tối đa';

  @override
  String get ascensionIncomeName => 'Nguồn năng lượng';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% thu nhập mỗi cấp';
  }

  @override
  String get ascensionStarBonusName => 'Ngôi sao rực rỡ';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% sức mạnh mỗi Sao, mỗi cấp';
  }

  @override
  String get ascensionStarGainName => 'Tinh tú dồi dào';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% tốc độ tích Sao, mỗi cấp';
  }

  @override
  String get achAscend => 'Kỷ Nguyên hoá lần đầu';

  @override
  String get dailyQuestsTitle => 'Nhiệm vụ ngày';

  @override
  String get dailyQuestsChip => 'Nhiệm vụ';

  @override
  String get dailyQuestsBonusLabel => 'Xong cả 3 nhiệm vụ';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'Đổi nhiệm vụ sau $time';
  }

  @override
  String get dailyQuestClaimed => 'Đã nhận';

  @override
  String dqTap(int n) {
    return 'Chạm ly $n lần';
  }

  @override
  String dqBuy(int n) {
    return 'Nâng cấp $n lần';
  }

  @override
  String dqEarn(Object amount) {
    return 'Kiếm $amount Xu';
  }

  @override
  String get dqCat => 'Bắt mèo Mưa vàng';

  @override
  String get dqVip => 'Phục vụ khách VIP';

  @override
  String get dqSpin => 'Quay vòng quay may mắn';

  @override
  String get notifyOfflineFullTitle => 'Kho Xu đã đầy! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'Quán ngừng tích Xu mất rồi — ghé nhận và mở ca mới nào.';

  @override
  String get notifyDailyTitle => 'Ngày mới, việc mới 📋';

  @override
  String get notifyDailyBody =>
      'Điểm danh, 1 lượt quay miễn phí và 3 nhiệm vụ hôm nay đang chờ bạn.';

  @override
  String get notifyD3Title => 'Quán vắng bạn 3 ngày rồi 🧋';

  @override
  String get notifyD3Body =>
      'Kho Xu đã đầy từ lâu, đơn hàng vẫn đang chờ — ghé qua thu dọn nhé.';

  @override
  String get notifyD7Title => 'Đã 1 tuần rồi đó! 🧋';

  @override
  String get notifyD7Body =>
      'Kỷ Nguyên, Trân Châu Rơi và bao nhiêu thứ mới đang chờ bạn quay lại.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 Sự kiện: ×$mult thu nhập! Còn $timeLeft';
  }

  @override
  String get navMatch3 => 'Trân châu';

  @override
  String get m3Title => 'Trân Châu Rơi';

  @override
  String m3Level(int n) {
    return 'Màn $n';
  }

  @override
  String get m3Locked => 'Chưa mở';

  @override
  String m3MovesLeft(int n) {
    return 'Còn $n nước';
  }

  @override
  String get m3Score => 'Điểm';

  @override
  String get m3Win => 'Qua màn!';

  @override
  String get m3Lose => 'Chưa đạt mục tiêu';

  @override
  String get m3Retry => 'Chơi lại';

  @override
  String get m3Next => 'Màn sau';

  @override
  String get m3Back => 'Danh sách màn';

  @override
  String get m3Reward => 'Thưởng';

  @override
  String get m3NoReward => 'Đã nhận thưởng màn này rồi';

  @override
  String m3AdMoves(int n) {
    return 'Xem QC: +$n nước';
  }

  @override
  String get m3KeepPlaying => 'Chơi nốt';

  @override
  String get m3Pause => 'Tạm nghỉ';

  @override
  String get m3GoalReached => 'Đạt mục tiêu!';

  @override
  String m3NeedScore(String n, int star) {
    return 'Còn thiếu $n điểm nữa là $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return 'Còn thiếu $n ô $icon nữa là $star★';
  }

  @override
  String get m3HowToTitle => 'Chơi Trân Châu Rơi';

  @override
  String get m3HtpSwap =>
      '🔄 Đổi hai ô KỀ NHAU (chạm ô này rồi chạm ô kia, hoặc vuốt) để xếp 3 ô cùng loại trở lên. Nước không tạo được dãy thì không tính.';

  @override
  String get m3HtpGoal =>
      '🎯 Mỗi màn có một mục tiêu: đạt đủ điểm, hoặc thu thập đủ số ô của một loại. Mục tiêu hiện ngay trên thanh đầu màn.';

  @override
  String get m3HtpMoves =>
      '👣 Số nước có hạn. Hết nước là kết thúc màn, nên ưu tiên nước ăn được nhiều ô.';

  @override
  String get m3HtpChain =>
      '⛓️ Ô bị xoá làm các ô trên rơi xuống; nếu chúng lại tạo dãy mới thì nổ dây chuyền — bước sau ăn điểm gấp bội.';

  @override
  String get m3HtpSpecial =>
      '💥 Xếp 4 ô tạo BOM CHÉO (nổ cả hàng và cột). Xếp từ 5 ô tạo BOM MÀU 🌈 (nổ sạch mọi ô cùng loại). Ghép chúng như ô thường để kích nổ.';

  @override
  String get m3HtpStars =>
      '⭐ Ba ngôi sao trên thanh là ba mốc. Chạm mốc đầu là qua màn; muốn thêm sao thì bấm \"Chơi nốt\" để dùng nốt số nước còn lại.';

  @override
  String get m3HtpReward =>
      '🎁 Thưởng chỉ trả LẦN ĐẦU đạt mỗi mốc sao. Chơi lại màn cũ để luyện thì không nhận thêm.';

  @override
  String get m3LbTitle => 'BXH Trân Châu Rơi';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty => 'Chưa có ai lên bảng. Chơi vài màn là bạn đứng đầu!';

  @override
  String get m3LbNoStars =>
      'Bạn chưa có sao nào — qua một màn là được lên bảng.';

  @override
  String m3LbLevels(int n) {
    return '$n màn';
  }

  @override
  String get m3LbError => 'Không tải được bảng xếp hạng, thử lại sau nhé.';
}
