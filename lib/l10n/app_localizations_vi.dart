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
  String get prestigeAdConfirm => 'Xem QC: nhận thêm Xu khởi đầu';

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
  String get htpTap => 'Chạm ly để pha trà và kiếm Xu.';

  @override
  String get htpBuy => 'Mua nâng cấp để có thu nhập tự động mỗi giây.';

  @override
  String get htpStage =>
      'Đủ Xu thì mở khóa giai đoạn mới, bán món cao cấp hơn.';

  @override
  String get htpCat => 'Chạm mèo may mắn để nhận Mưa vàng ×3 trong chốc lát.';

  @override
  String get htpVip => 'Đón khách VIP đi ô tô để nhận Kim Cương 💎.';

  @override
  String get htpGems => 'Dùng Kim Cương trong Cửa hàng mua nâng cấp vĩnh viễn.';

  @override
  String get htpPrestige =>
      'Nhượng quyền để chơi lại và nhận Sao — bonus thu nhập vĩnh viễn.';

  @override
  String get htpOffline =>
      'Quán vẫn bán khi bạn thoát — quay lại nhận tiền offline.';

  @override
  String get htpNumberFormat =>
      'Số lớn viết tắt: K=nghìn, M=triệu, B=tỷ, T=nghìn tỷ, rồi tới aa, bb, cc... — mỗi bước gấp 1.000 lần bước trước.';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get dailyTitle => 'Điểm danh hằng ngày';

  @override
  String get dailyPrompt => 'Nhận quà đăng nhập hôm nay!';

  @override
  String get adNotReady => 'Quảng cáo chưa sẵn sàng, thử lại sau ít giây.';

  @override
  String get accessoryBat => 'Dơi đêm';

  @override
  String get accessoryJackOLantern => 'Bí ngô ma quái';

  @override
  String get accessoryGhost => 'Bóng ma';

  @override
  String get accessoryWitch => 'Phù thủy';

  @override
  String get accessorySnowman => 'Người tuyết';

  @override
  String get accessoryChristmasTree => 'Cây thông Noel';

  @override
  String get accessoryReindeer => 'Tuần lộc';

  @override
  String get accessorySanta => 'Ông già Noel';

  @override
  String get accessoryFirecracker => 'Pháo Tết';

  @override
  String get accessoryRedEnvelope => 'Bao lì xì';

  @override
  String get accessoryApricotBlossom => 'Hoa mai vàng';

  @override
  String get accessoryGoldenGoat => 'Dê vàng';

  @override
  String get festivalHalloween => 'Halloween';

  @override
  String get festivalChristmas => 'Giáng Sinh';

  @override
  String get festivalTet => 'Tết Nguyên Đán';

  @override
  String get festivalSection => 'Phụ kiện lễ hội (độc quyền)';

  @override
  String festivalPackTitle(String name) {
    return 'Gói $name';
  }

  @override
  String festivalPackDesc(int gems) {
    return 'Mỗi gói nhận 1 món độc quyền CHƯA CÓ, chỉ bán trong dịp lễ. Có đủ rồi thì đổi $gems 💎. Không giao dịch được.';
  }

  @override
  String get accessoryChampagne => 'Ly sâm panh';

  @override
  String get accessoryPartyPopper => 'Pháo giấy';

  @override
  String get accessoryFireworks => 'Pháo hoa';

  @override
  String get accessoryGoldenSparkler => 'Pháo hoa vàng';

  @override
  String get accessoryLoveLetter => 'Thư tình';

  @override
  String get accessoryRose => 'Hoa hồng';

  @override
  String get accessoryChocolate => 'Sô-cô-la';

  @override
  String get accessoryCupidArrow => 'Mũi tên thần tình yêu';

  @override
  String get accessoryTulip => 'Hoa tulip';

  @override
  String get accessoryBouquet => 'Bó hoa';

  @override
  String get accessoryLipstick => 'Son môi';

  @override
  String get accessoryPrincess => 'Công chúa';

  @override
  String get accessoryMooncake => 'Bánh Trung Thu';

  @override
  String get accessoryRabbit => 'Thỏ ngọc';

  @override
  String get accessoryFullMoon => 'Trăng rằm';

  @override
  String get accessoryLionDance => 'Múa lân';

  @override
  String get festivalNewYear => 'Tết Dương lịch';

  @override
  String get festivalValentine => 'Valentine';

  @override
  String get festivalWomensDay => 'Quốc tế Phụ nữ 8/3';

  @override
  String get festivalMidAutumn => 'Tết Trung Thu';

  @override
  String get dailyClaim => 'Nhận quà';

  @override
  String get accessoryWheelTitle => 'Vòng quay phụ kiện';

  @override
  String accessoryWheelAd(int n) {
    return 'Quay: xem QC (còn $n)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return 'Quay $gems 💎';
  }

  @override
  String get accessoryPackButton => 'Gói phụ kiện';

  @override
  String get accessoryPackTitle => 'Gói phụ kiện';

  @override
  String get accessoryPackBasic => 'Gói Thường';

  @override
  String get accessoryPackRare => 'Gói Hiếm (bảo đảm từ Hiếm)';

  @override
  String get accessoryPackEpic => 'Gói Sử Thi (bảo đảm từ Sử thi)';

  @override
  String get accessoryPackSeason =>
      'Sự kiện mùa: giảm 25% giá gói, tỉ lệ Sử thi/Huyền thoại ×2!';

  @override
  String get accessoryAdDropButton => 'Xem QC: thêm 1 phụ kiện';

  @override
  String dailyStreakAtRisk(int days) {
    return 'Bạn bỏ lỡ 1 ngày — chuỗi $days ngày sắp mất!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return 'Cứu chuỗi ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => 'Xem quảng cáo để cứu chuỗi';

  @override
  String get dailySkipRestore => 'Bỏ qua, bắt đầu lại';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'Chuỗi $days ngày 🔥';
  }

  @override
  String dailyMilestoneBonus(String gems) {
    return 'Thưởng mốc chuỗi: +$gems 💎';
  }

  @override
  String dailyVipBonus(int percent) {
    return 'Thưởng VIP: +$percent% 💎';
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
  String get iapColdStorageTitle => 'Kho lạnh vĩnh viễn';

  @override
  String iapColdStorageDesc(Object hours) {
    return 'Tăng thêm $hours giờ trần tiền offline, mãi mãi';
  }

  @override
  String iapColdStorageSnack(Object hours) {
    return 'Đã tăng trần offline thêm $hours giờ!';
  }

  @override
  String get iapComboTitle => 'Combo: Gỡ QC + x2 Thu nhập';

  @override
  String get iapComboDesc =>
      'Gỡ toàn bộ quảng cáo và x2 thu nhập vĩnh viễn, rẻ hơn mua riêng';

  @override
  String get iapComboSnack => 'Đã gỡ quảng cáo và bật x2 thu nhập vĩnh viễn!';

  @override
  String get topupTitle => 'Mốc nạp & VIP';

  @override
  String get topupOpen => '👑 Mốc nạp & VIP';

  @override
  String topupSummary(Object points) {
    return '$points VIP EXP';
  }

  @override
  String topupBuff(Object now, Object percent) {
    return 'Mỗi cấp VIP +$percent% thu nhập (hiện +$now%)';
  }

  @override
  String get topupNote =>
      'Nạp tiền ở cửa hàng: ~100 EXP mỗi USD (gói lớn nhiều hơn). Mua EXP bằng 💎 đắt hơn nhiều và có giới hạn. Mỗi mốc nhận một lần.';

  @override
  String topupTier(Object points) {
    return '$points EXP';
  }

  @override
  String get topupAccessory => '+ phụ kiện';

  @override
  String vipTierPerks(int buff, String daily, String monthly, String weekly) {
    return 'Mỗi ngày +$daily 💎 · tuần +$weekly 💎 · tháng +$monthly 💎 (kèm phụ kiện) · +$buff% thu nhập';
  }

  @override
  String get topupClaim => 'Nhận';

  @override
  String get topupClaimed => 'Đã nhận';

  @override
  String topupClaimSnack(Object gems) {
    return 'Đã nhận +$gems 💎';
  }

  @override
  String get vipName1 => 'Khách quen';

  @override
  String get vipName2 => 'Mê trà';

  @override
  String get vipName3 => 'Sành trà';

  @override
  String get vipName4 => 'Thượng khách';

  @override
  String get vipName5 => 'Chủ tiệm';

  @override
  String get vipName6 => 'Tỉ phú trà sữa';

  @override
  String get vipName7 => 'Ông trùm';

  @override
  String get vipName8 => 'Hoàng gia';

  @override
  String get vipName9 => 'Huyền thoại';

  @override
  String get vipName10 => 'Đế vương';

  @override
  String vipBuyExp(Object exp, Object gems) {
    return 'Mua $exp EXP · $gems 💎';
  }

  @override
  String vipBuyExpSnack(Object exp) {
    return '+$exp VIP EXP';
  }

  @override
  String vipBuyExpCapped(Object cap) {
    return 'EXP mua bằng 💎 đã chạm giới hạn ($cap). Các cấp cao hơn chỉ đạt được bằng nạp tiền.';
  }

  @override
  String get vipBenefitsTitle => 'Quyền lợi VIP';

  @override
  String get vipBenefitsLocked => 'Đạt VIP 1 để mở khoá quà ngày/tuần/tháng.';

  @override
  String get vipDaily => 'Hằng ngày';

  @override
  String get vipWeekly => 'Hằng tuần';

  @override
  String get vipMonthly => 'Hằng tháng';

  @override
  String get vipHowToTitle => 'Hướng dẫn VIP';

  @override
  String get vipHtp1 =>
      '👑 VIP có 10 cấp, mỗi cấp một biệt danh. Cấp hiện thành nhãn \"VIP n\" cạnh tên bạn ở bảng xếp hạng và trong Hội. Từ VIP 5, tên bạn có thêm dòng danh hiệu ở mọi bảng xếp hạng, có chấm xanh khi online và cả server thấy banner khi bạn vào game.';

  @override
  String vipHtp2(Object cap, Object exp, Object gems) {
    return '⭐ EXP VIP: nạp tiền thật trong cửa hàng (~100 EXP mỗi USD, gói 💎 lớn được thêm) hoặc mua bằng 💎 ($gems 💎 → $exp EXP, tối đa $cap EXP — nên VIP 7–10 chỉ đạt được bằng nạp thật).';
  }

  @override
  String vipHtp3(Object percent) {
    return '📈 Quyền lợi: +$percent% thu nhập tự động mỗi cấp (vĩnh viễn) và thưởng mốc một lần cho từng cấp (💎, có cấp kèm phụ kiện).';
  }

  @override
  String get vipHtp4 =>
      '🎁 Quà hằng ngày / tuần / tháng: 💎 tăng theo cấp, quà tuần và tháng kèm một phụ kiện. Đổi kỳ lúc 00:00 UTC (tuần bắt đầu thứ Hai, tháng theo lịch).';

  @override
  String get vipHtp5 =>
      '♻️ Khác VIP Pass 30 ngày: VIP Pass (gỡ QC, x2 thu nhập…) là vé có hạn; cấp VIP này không bao giờ mất và hai thứ cộng dồn.';

  @override
  String get vipHtp6 => '📍 Mở ở Cửa hàng 💎 → nút 👑.';

  @override
  String get vipLbTitle => 'Bảng xếp hạng VIP';

  @override
  String get vipLbEmpty => 'Chưa có ai trong bảng xếp hạng VIP.';

  @override
  String get vipLbNoVip => 'Đạt VIP 1 để có tên trên bảng xếp hạng VIP.';

  @override
  String vipLbExp(Object exp) {
    return '$exp EXP';
  }

  @override
  String vipOnlineBanner(Object nickname, Object title) {
    return '👑 $title $nickname vừa online!';
  }

  @override
  String get emailGateTitle => 'Liên kết email để nạp';

  @override
  String get emailGateBody =>
      'Giao dịch nạp được gắn với tài khoản của bạn để khôi phục được khi đổi máy hoặc có sự cố. Hãy liên kết email trước (miễn phí, mất khoảng một phút).';

  @override
  String get emailGateOnlineTitle => 'Liên kết email để chơi online';

  @override
  String get emailGateOnlineBody =>
      'Hội, Chợ, Đấu Trường và bảng xếp hạng cần tài khoản đã liên kết email — để dữ liệu của bạn được giữ an toàn và khôi phục được khi đổi máy hoặc cài lại. Miễn phí, chỉ mất khoảng một phút.';

  @override
  String get emailGateLink => 'Liên kết email';

  @override
  String iapGemsFirstSnack(Object amount) {
    return 'Nhận +$amount 💎 — thưởng mua lần đầu gấp đôi!';
  }

  @override
  String get iapFirstBuyNote => '🎉 Mua lần đầu: nhận gấp đôi 💎!';

  @override
  String get guildGiftTooltip => 'Tặng 💎';

  @override
  String guildGiftTitle(Object nickname) {
    return 'Tặng 💎 cho $nickname';
  }

  @override
  String guildGiftHint(Object cap, Object days) {
    return 'Tối đa $cap 💎 mỗi ngày. Người nhận có $days ngày để nhận quà.';
  }

  @override
  String guildGiftSent(Object amount, Object nickname) {
    return 'Đã tặng $amount 💎 cho $nickname';
  }

  @override
  String guildGiftInboxTitle(Object count) {
    return '🎁 Quà từ hội viên ($count)';
  }

  @override
  String guildGiftFrom(Object amount, Object nickname) {
    return '$nickname · +$amount 💎';
  }

  @override
  String guildGiftClaimed(Object amount) {
    return 'Đã nhận +$amount 💎';
  }

  @override
  String guildErrGiftLimit(Object receive, Object send) {
    return 'Hôm nay đã hết lượt tặng 💎 (bạn tặng tối đa $send 💎/ngày, một người nhận tối đa $receive 💎/ngày).';
  }

  @override
  String get vipTitlePick => 'Danh hiệu hiển thị dưới tên';

  @override
  String get vipTitleAuto => 'Tự động (cao nhất)';

  @override
  String get vipTitleHide => 'Ẩn';

  @override
  String get marketFilterWish => 'Muốn mua';

  @override
  String get guildErrGemsSpend => 'Không đủ 💎.';

  @override
  String guildCreateVipDiscount(Object percent) {
    return 'Ưu đãi VIP: giảm $percent% phí tạo hội';
  }

  @override
  String get guildLbTabVip => 'VIP';

  @override
  String get guildLbVipEmpty => 'Chưa có hội nào có thành viên VIP trên bảng.';

  @override
  String get guildLbVipNote =>
      'Tổng VIP EXP của các thành viên (chỉ tính người đã đặt biệt danh).';

  @override
  String guildVipExpTotal(Object exp) {
    return '$exp EXP';
  }

  @override
  String guildVipBonusLine(Object members, Object pct) {
    return 'Thưởng VIP: $members thành viên VIP → +$pct% thu nhập cả hội';
  }

  @override
  String guildVipBonusHint(Object cap, Object level, Object per) {
    return 'Mỗi thành viên từ VIP $level cộng +$per% thu nhập cho cả hội (tối đa +$cap%)';
  }

  @override
  String get reminderVipTitle => '👑 Quà VIP đang chờ bạn';

  @override
  String get reminderVipDailyBody =>
      'Quà VIP, điểm danh và nhiệm vụ hôm nay đã sẵn sàng — vào nhận ngay!';

  @override
  String get reminderVipWeeklyBody =>
      'Quà VIP hằng tuần (kèm phụ kiện) đã sẵn sàng!';

  @override
  String get reminderVipMonthlyBody =>
      'Quà VIP hằng tháng đã về — một phần quà lớn đang chờ!';

  @override
  String get reminderVipUnclaimedBody =>
      'Bạn vẫn còn quà VIP chưa nhận hôm nay.';

  @override
  String get dealTitle => 'Ưu đãi hôm nay';

  @override
  String dealResets(Object time) {
    return 'Đổi lúc 00:00 UTC · còn $time';
  }

  @override
  String get dealClaimed => 'Hôm nay đã mua — mai quay lại nhé';

  @override
  String dealGotAccessory(Object name) {
    return 'Nhận $name!';
  }

  @override
  String get dealUnavailable => 'Hiện chưa mua được ưu đãi này.';

  @override
  String get guildBossTitle => 'Boss tuần của Hội';

  @override
  String guildBossTier(Object tier) {
    return 'Bậc $tier';
  }

  @override
  String guildBossProgress(Object damage, Object hp) {
    return '$damage / $hp sát thương';
  }

  @override
  String guildBossClaim(Object coins, Object gems) {
    return 'Nhận rương: +$gems 💎 +$coins Xu Hội';
  }

  @override
  String get guildBossClaimedLabel => 'Đã nhận rương';

  @override
  String guildBossClaimedSnack(Object coins, Object gems) {
    return 'Nhận rương boss: +$gems 💎 +$coins Xu Hội';
  }

  @override
  String get guildBossErrAlive => 'Boss chưa bị hạ.';

  @override
  String get guildBossName1 => 'Rồng Trân Châu';

  @override
  String get guildBossName2 => 'Quái Vật Đá Bào';

  @override
  String get guildBossName3 => 'Mực Khổng Lồ Trà Đen';

  @override
  String get guildBossName4 => 'Gấu Pudding';

  @override
  String get guildBossName5 => 'Hổ Matcha';

  @override
  String get guildBossName6 => 'Phượng Hoàng Kem Phô Mai';

  @override
  String get accessoryVipWatch => 'Đồng Hồ Sang Trọng';

  @override
  String get accessoryVipLuggage => 'Vali Hạng Sang';

  @override
  String get accessoryVipBriefcase => 'Cặp Da Doanh Nhân';

  @override
  String get accessoryVipTophat => 'Mũ Quý Ông';

  @override
  String get accessoryVipRacecar => 'Siêu Xe';

  @override
  String get accessoryVipHeli => 'Trực Thăng';

  @override
  String get accessoryVipYacht => 'Du Thuyền';

  @override
  String get accessoryVipJet => 'Máy Bay Riêng';

  @override
  String get vipShopOpen => '🛍️ Cửa hàng VIP';

  @override
  String get vipShopTitle => 'Cửa hàng VIP';

  @override
  String vipCoinsLabel(Object n) {
    return 'Xu VIP: $n';
  }

  @override
  String vipShopLocked(Object level) {
    return 'Cần VIP $level';
  }

  @override
  String get vipShopOwned => 'Đã có';

  @override
  String get vipShopNeedCoins => 'Không đủ Xu VIP';

  @override
  String vipShopBoughtSnack(Object name) {
    return 'Đã đổi: $name!';
  }

  @override
  String get vipShopHint =>
      'Kiếm Xu VIP bằng cách nhận quà VIP hằng ngày, tuần, tháng.';

  @override
  String vipBenefitSnack(Object coins, Object gems) {
    return 'Nhận +$gems 💎 +$coins Xu VIP';
  }

  @override
  String get vipItemsTitle => 'Độc quyền VIP';

  @override
  String vipShopPrice(Object n) {
    return '$n Xu VIP';
  }

  @override
  String get vipEntryHint => 'Nạp để mở khoá quà VIP hằng ngày, tuần, tháng';

  @override
  String get settingsWebsite => 'Trang web';

  @override
  String get settingsWebGuide => 'Hướng dẫn chơi (trên web)';

  @override
  String get guideOnWeb => 'Xem hướng dẫn đầy đủ trên web';

  @override
  String get webOpenFailed =>
      'Không mở được trang web. Kiểm tra mạng rồi thử lại.';

  @override
  String get webBoardOpenTip => 'Xem bảng xếp hạng này trên web';

  @override
  String get webBoardShareTip => 'Chia sẻ liên kết bảng xếp hạng';

  @override
  String webBoardShareText(Object url) {
    return 'Xem bảng xếp hạng Boba Empire nè: $url';
  }

  @override
  String get settingsShareProfile => 'Chia sẻ hồ sơ xếp hạng của tôi';

  @override
  String profileShareText(String name, String url) {
    return 'Xem thứ hạng của $name trong Boba Empire nè: $url';
  }

  @override
  String profileTitle(String name) {
    return 'Hồ sơ: $name';
  }

  @override
  String get profileBoardIncome => 'Thu nhập';

  @override
  String get profileBoardPearls => 'Trân châu';

  @override
  String get profileBoardCollection => 'Sưu tầm';

  @override
  String get profileBoardSpeed => 'Tốc độ cốt truyện';

  @override
  String get profileBoardVip => 'VIP';

  @override
  String get profileNoRanks => 'Chưa có hạng nào trên bảng xếp hạng.';

  @override
  String get myProfileTitle => 'Hồ sơ của tôi';

  @override
  String get myProfileChangeAvatar => 'Đổi ảnh đại diện';

  @override
  String get myProfileRemoveAvatar => 'Gỡ ảnh';

  @override
  String get myProfileAvatarFail =>
      'Không tải được ảnh. Cần mạng và tài khoản đã liên kết email.';

  @override
  String get myProfileAvatarTooBig => 'Ảnh quá lớn, hãy chọn ảnh khác.';

  @override
  String get myProfileNoNickname =>
      'Chưa đặt biệt danh. Vào một bảng xếp hạng để đặt tên.';

  @override
  String get myProfileStatStage => 'Giai đoạn';

  @override
  String get myProfileStatEarned => 'Tổng thu';

  @override
  String get myProfileStatStars => 'Sao';

  @override
  String get myProfileStatAscend => 'Thăng Thiên';

  @override
  String get myProfileStatVip => 'VIP';

  @override
  String get myProfileStatCollection => 'Sưu tập';

  @override
  String get myProfileStatAchievements => 'Thành tựu';

  @override
  String get myProfileRanks => 'Xem hạng của tôi';

  @override
  String get myProfileShare => 'Chia sẻ hồ sơ';

  @override
  String get avatarReport => 'Báo cáo ảnh';

  @override
  String get avatarReportConfirm =>
      'Báo cáo ảnh đại diện này là vi phạm (hình ảnh không phù hợp)?';

  @override
  String get avatarReportSent => 'Đã gửi báo cáo. Cảm ơn bạn!';

  @override
  String get avatarReportFail =>
      'Không gửi được báo cáo. Cần mạng và tài khoản đã liên kết email.';

  @override
  String get titlePickerTitle => 'Danh hiệu';

  @override
  String get profileGender => 'Giới tính';

  @override
  String get profileGenderMale => 'Nam';

  @override
  String get profileGenderFemale => 'Nữ';

  @override
  String get profileGenderOther => 'Khác';

  @override
  String get profileGenderHint =>
      'Tuỳ chọn, hiện trên hồ sơ công khai. Bấm lại để ẩn.';

  @override
  String get titlePickerNone => 'Không dùng danh hiệu';

  @override
  String get titlePickerHint =>
      'Mở khoá bằng tiến độ. Danh hiệu chọn sẽ hiện trên hồ sơ công khai (cần tài khoản liên kết email).';

  @override
  String get playerTitleTycoon => 'Ông Chủ Chuỗi';

  @override
  String get playerTitleTycoonHint => 'Đạt giai đoạn 5';

  @override
  String get playerTitleMogul => 'Đại Gia';

  @override
  String get playerTitleMogulHint => 'Đạt giai đoạn 10';

  @override
  String get playerTitleLegend => 'Huyền Thoại';

  @override
  String get playerTitleLegendHint => 'Đạt giai đoạn 18';

  @override
  String get playerTitleTimewalker => 'Lữ Khách Thời Gian';

  @override
  String get playerTitleTimewalkerHint => 'Thăng Thiên ít nhất 1 lần';

  @override
  String get playerTitleStargazer => 'Người Hái Sao';

  @override
  String get playerTitleStargazerHint => 'Có 50 Sao';

  @override
  String get playerTitleCollector => 'Nhà Sưu Tập';

  @override
  String get playerTitleCollectorHint => 'Sở hữu 100 phụ kiện';

  @override
  String get playerTitleVip => 'Quý Tộc VIP';

  @override
  String get playerTitleVipHint => 'Đạt VIP 5';

  @override
  String get profileViewButton => 'Hồ sơ';

  @override
  String get profileOpenWeb => 'Xem trên web';

  @override
  String get refEntry => '👥 Mời bạn bè';

  @override
  String refEntryNote(Object gems) {
    return 'Nhận $gems 💎 cho mỗi bạn tham gia';
  }

  @override
  String get refTitle => 'Mời bạn bè';

  @override
  String get refYourCode => 'Mã mời của bạn';

  @override
  String get refCopy => 'Chép mã';

  @override
  String get refCopied => 'Đã chép mã';

  @override
  String get refShare => 'Chia sẻ';

  @override
  String refShareText(Object code) {
    return 'Chơi Boba Empire cùng mình nhé! Nhập mã mời $code để nhận 💎 thưởng: https://bobaempiregame.com';
  }

  @override
  String refStats(Object invited, Object max, Object reached) {
    return 'Đã mời: $invited/$max · đạt mục tiêu: $reached';
  }

  @override
  String refRule(Object gems, Object stage) {
    return 'Bạn nhận $gems 💎 cho mỗi bạn đạt giai đoạn $stage. Bạn của bạn cũng nhận 💎 khi nhập mã.';
  }

  @override
  String refClaim(Object gems) {
    return 'Nhận +$gems 💎';
  }

  @override
  String refClaimedSnack(Object gems) {
    return 'Đã nhận +$gems 💎';
  }

  @override
  String get refEnterTitle => 'Có mã của bạn bè?';

  @override
  String get refEnterHint => 'Mã mời';

  @override
  String get refRedeem => 'Nhập mã';

  @override
  String refRedeemedSnack(Object gems) {
    return 'Mã hợp lệ: +$gems 💎';
  }

  @override
  String get refErrEmail => 'Hãy liên kết email trước.';

  @override
  String get refErrNotFound => 'Không tìm thấy mã này.';

  @override
  String get refErrInvalid => 'Bạn không thể dùng mã này.';

  @override
  String get refErrAlready => 'Bạn đã dùng một mã mời rồi.';

  @override
  String get refErrFull => 'Mã này đã hết lượt mời.';

  @override
  String get refErrNothing => 'Chưa có gì để nhận.';

  @override
  String get refErrNetwork => 'Lỗi mạng, thử lại nhé.';

  @override
  String get vipLbOpen => 'Bảng xếp hạng VIP';

  @override
  String get rewardsTitle => 'Kiếm thêm 🎁';

  @override
  String get dailyHubTitle => 'Nhiệm vụ & Quà';

  @override
  String get dailyHubTabDaily => 'Ngày';

  @override
  String get dailyHubTabWeekly => 'Tuần';

  @override
  String get dailyHubTabRewards => 'Quà 🎁';

  @override
  String get rewardsChip => 'Kiếm thêm';

  @override
  String rewardAutoTapName(int m) {
    return 'Tự động chạm $m phút';
  }

  @override
  String rewardAutoTapActive(String t) {
    return 'Đang bật · còn $t';
  }

  @override
  String rewardAutoTapVip(int n) {
    return 'VIP $n+ được tự động chạm vĩnh viễn';
  }

  @override
  String rewardAutoTapHint(int n) {
    return 'Xem QC để tự chạm cốc trà (VIP $n+ bật vĩnh viễn)';
  }

  @override
  String get rewardAutoTapSnack =>
      'Đã bật tự động chạm! Chỉ cộng Xu, không tính điểm Hội/nhiệm vụ.';

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
  String recipeGroupLocked(String name, int need, int learned) {
    return '🔒 $name — mở khi Thuộc $need món của nhóm trước ($learned/$need)';
  }

  @override
  String recipeGroupLockedFar(String name) {
    return '🔒 $name';
  }

  @override
  String recipeGroupOpened(String name) {
    return '🔓 Đã mở nhóm mới: $name!';
  }

  @override
  String recipeStreak(int n) {
    return '🔥 Chuỗi ôn: $n ngày';
  }

  @override
  String get recipeStreakToday => 'Hôm nay đã ôn ✓';

  @override
  String get recipeStreakPending =>
      'Hôm nay chưa ôn — ôn một buổi để giữ chuỗi';

  @override
  String recipeRescueTitle(int n) {
    return 'Bạn lỡ một ngày — chuỗi $n ngày sắp mất!';
  }

  @override
  String recipeRescueGems(int n) {
    return 'Cứu bằng $n 💎';
  }

  @override
  String get recipeRescueAd => 'Xem quảng cáo để cứu';

  @override
  String get recipeRescued => 'Đã cứu chuỗi!';

  @override
  String get recipeRescueNoGems => 'Không đủ 💎 để cứu chuỗi.';

  @override
  String recipeStreakGems(int n, int gems) {
    return '🔥 Chuỗi $n ngày! +$gems 💎';
  }

  @override
  String recipeStreakFeedback(int n) {
    return '🔥 Chuỗi ôn: $n ngày';
  }

  @override
  String get recipeNotifyTitle => 'Công thức pha chế';

  @override
  String recipeNotifyStreak(int n) {
    return 'Chuỗi ôn $n ngày sắp mất! Ôn một buổi để giữ lại nhé';
  }

  @override
  String recipeNotifyDue(int n) {
    return '$n món công thức đến hạn ôn hôm nay';
  }

  @override
  String get rlbTitle => 'BXH Thợ pha chế';

  @override
  String get lbrBoardRecipes => 'Thợ pha chế';

  @override
  String get rlbEmpty =>
      'Chưa có ai trên bảng. Hãy là người đầu tiên đạt Thạo một công thức!';

  @override
  String get rlbNoMastered =>
      'Bạn chưa có món nào đạt Thạo nên chưa có tên trên bảng.';

  @override
  String rlbMastered(int n) {
    return 'Thạo $n món';
  }

  @override
  String get rlbError => 'Không tải được bảng xếp hạng, thử lại sau nhé.';

  @override
  String recipeMilestone(int n) {
    return 'Thạo $n món — bạn nhận được một phụ kiện!';
  }

  @override
  String get dqRecipe => 'Hoàn thành 1 buổi luyện công thức';

  @override
  String wqRecipeSessions(int n) {
    return 'Hoàn thành $n buổi luyện công thức';
  }

  @override
  String wqRecipeLevels(int n) {
    return 'Lên bậc $n công thức';
  }

  @override
  String get recipeHint => 'Gợi ý (xem quảng cáo)';

  @override
  String get recipeHintNoCount => 'Đã dùng gợi ý nên câu này không tính bậc.';

  @override
  String get recipeDouble => 'Xem quảng cáo, nhân đôi Xu';

  @override
  String get recipeDoubled => 'Đã nhân đôi Xu thưởng!';

  @override
  String get recipeTitle => 'Công thức pha chế';

  @override
  String get recipeEntryNote => 'Học thuộc công thức, nhận thưởng';

  @override
  String get recipeEntryButton => 'Chơi';

  @override
  String recipeMastered(int n, int total) {
    return 'Thạo $n/$total món';
  }

  @override
  String recipeDueToday(int n) {
    return '$n món cần ôn hôm nay';
  }

  @override
  String get recipeAllDone =>
      'Hôm nay bạn đã ôn xong! Vẫn có thể luyện thêm (không tính bậc).';

  @override
  String get recipePractice => 'Luyện tập';

  @override
  String get recipeBox0 => 'Mới';

  @override
  String get recipeBox1 => 'Quen';

  @override
  String get recipeBox2 => 'Thuộc';

  @override
  String get recipeBox3 => 'Thạo';

  @override
  String get recipeReviewToday => 'Ôn lại: hôm nay';

  @override
  String recipeReviewIn(int n) {
    return 'Ôn lại sau $n ngày';
  }

  @override
  String recipeQMissing(String name) {
    return '$name còn thiếu nguyên liệu nào?';
  }

  @override
  String recipeQQuantity(String drink, String ingredient) {
    return '$drink: cần bao nhiêu $ingredient?';
  }

  @override
  String recipeQFull(String name) {
    return 'Công thức đúng của $name là?';
  }

  @override
  String get recipeCorrect => 'Chính xác!';

  @override
  String get recipeWrongShort => 'Chưa đúng — đáp án được tô xanh.';

  @override
  String recipeLevelUp(String box, String name) {
    return '$name lên bậc $box!';
  }

  @override
  String get recipePracticeOnly =>
      'Món này chưa tới hạn ôn nên chỉ để luyện, không tính bậc.';

  @override
  String get recipeNext => 'Câu tiếp';

  @override
  String get recipeSeeResult => 'Xem kết quả';

  @override
  String get recipeResultTitle => 'Kết quả';

  @override
  String recipeScore(int correct, int total) {
    return '$correct/$total câu đúng';
  }

  @override
  String recipeLevelUps(int n) {
    return '$n món lên bậc';
  }

  @override
  String recipeRewardCash(String cash) {
    return 'Thưởng: +$cash Xu';
  }

  @override
  String recipeRewardBoth(String cash, int gems) {
    return 'Thưởng: +$cash Xu, +$gems 💎';
  }

  @override
  String get recipeAgain => 'Luyện tiếp';

  @override
  String get recipeDone => 'Xong';

  @override
  String get recipeDisclaimer =>
      'Công thức mang tính tham khảo cho trò chơi, không phải công thức chuẩn của thương hiệu nào.';

  @override
  String get recipeIngredients => 'Nguyên liệu';

  @override
  String walkerTipSnack(String amount) {
    return 'Khách boa +$amount Xu 🧋';
  }

  @override
  String get settingsEffects => 'Hiệu ứng động';

  @override
  String get settingsEffectsAuto => 'Tự động (theo máy)';

  @override
  String get settingsEffectsHigh => 'Cao';

  @override
  String get settingsEffectsMedium => 'Vừa';

  @override
  String get settingsEffectsLow => 'Thấp (tiết kiệm pin)';

  @override
  String get settingsEffectsOff => 'Tắt';

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
  String get arenaModeRecipe => 'PK Công thức';

  @override
  String get arenaRecipeIntro =>
      'Cùng pha 5 đơn giống nhau — tổng điểm cao hơn đối thủ thì thắng. Xong sớm cả hai sẽ chốt luôn!';

  @override
  String get arenaRecipeStart => 'Vào pha';

  @override
  String arenaRecipeProgress(int done, int theirs) {
    return 'Bạn xong $done/5 đơn · Đối thủ $theirs/5';
  }

  @override
  String get arenaRecipeWaiting => 'Bạn đã pha xong! Đang chờ đối thủ…';

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
  String get arenaGhostBadge =>
      '👻 Bóng ma: bạn đang đấu lại bản ghi của một người chơi. Thưởng giảm, không tính vào BXH.';

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
  String get cloudSaveCheckSpam =>
      'Không thấy email? Hãy kiểm tra cả thư mục Spam / Thư rác.';

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
  String get accessoryDonut => 'Bánh donut';

  @override
  String get accessoryLollipop => 'Kẹo mút';

  @override
  String get accessoryPretzel => 'Bánh quy xoắn';

  @override
  String get accessoryIceCream => 'Kem ốc quế';

  @override
  String get accessoryStrawberry => 'Dâu tây';

  @override
  String get accessoryCherry => 'Anh đào';

  @override
  String get accessoryLemon => 'Chanh vàng';

  @override
  String get accessoryPeach => 'Đào';

  @override
  String get accessoryPopcorn => 'Bắp rang';

  @override
  String get accessoryHoneyPot => 'Hũ mật ong';

  @override
  String get accessoryMilkGlass => 'Ly sữa';

  @override
  String get accessoryTangerine => 'Quýt';

  @override
  String get accessoryChestnut => 'Hạt dẻ';

  @override
  String get accessoryMapleLeaf => 'Lá phong';

  @override
  String get accessoryCompass => 'La bàn';

  @override
  String get accessoryRocket => 'Tên lửa';

  @override
  String get accessoryViolin => 'Đàn violin';

  @override
  String get accessoryScroll => 'Cuộn giấy cổ';

  @override
  String get accessoryMicrophone => 'Micro';

  @override
  String get accessoryLotus => 'Hoa sen';

  @override
  String get accessoryJellyfish => 'Sứa';

  @override
  String get accessoryCamera => 'Máy ảnh';

  @override
  String get accessoryShield => 'Khiên';

  @override
  String get accessoryAmphora => 'Bình cổ';

  @override
  String get accessoryRainbow => 'Cầu vồng';

  @override
  String get accessoryFairy => 'Tiên nữ';

  @override
  String get accessoryDiscoBall => 'Quả cầu disco';

  @override
  String get accessoryShiningStar => 'Ngôi sao sáng';

  @override
  String get accessoryKraken => 'Kraken';

  @override
  String get accessoryThunderbolt => 'Tia chớp thần';

  @override
  String get accessoryIceCube => 'Đá viên';

  @override
  String get accessoryCroissant => 'Bánh sừng bò';

  @override
  String get accessoryPancakes => 'Bánh pancake';

  @override
  String get accessoryWaffle => 'Bánh waffle';

  @override
  String get accessoryBagel => 'Bánh bagel';

  @override
  String get accessoryCakeSlice => 'Miếng bánh kem';

  @override
  String get accessoryPie => 'Bánh nướng';

  @override
  String get accessoryCandy => 'Viên kẹo';

  @override
  String get accessoryGrapes => 'Chùm nho';

  @override
  String get accessoryWatermelon => 'Dưa hấu';

  @override
  String get accessoryPineapple => 'Quả dứa';

  @override
  String get accessoryMango => 'Xoài';

  @override
  String get accessoryKiwi => 'Quả kiwi';

  @override
  String get accessoryBanana => 'Chuối';

  @override
  String get accessoryApple => 'Quả táo';

  @override
  String get accessoryTeddy => 'Gấu bông';

  @override
  String get accessoryCrayon => 'Bút sáp màu';

  @override
  String get accessoryBucket => 'Cái xô';

  @override
  String get accessoryGuitar => 'Đàn guitar';

  @override
  String get accessoryTrumpet => 'Kèn trumpet';

  @override
  String get accessoryPiano => 'Đàn piano';

  @override
  String get accessorySaxophone => 'Kèn saxophone';

  @override
  String get accessoryBanjo => 'Đàn banjo';

  @override
  String get accessoryMicroscope => 'Kính hiển vi';

  @override
  String get accessoryRingedPlanet => 'Hành tinh có vành đai';

  @override
  String get accessoryCrescentMoon => 'Trăng lưỡi liềm';

  @override
  String get accessoryBowArrow => 'Cung tên';

  @override
  String get accessoryMirror => 'Gương soi';

  @override
  String get accessoryFerrisWheel => 'Vòng xoay khổng lồ';

  @override
  String get accessoryCarousel => 'Ngựa quay';

  @override
  String get accessorySwan => 'Thiên nga';

  @override
  String get accessoryFlamingo => 'Hồng hạc';

  @override
  String get accessoryOwl => 'Cú mèo';

  @override
  String get accessoryWhale => 'Cá voi';

  @override
  String get accessoryCrown => 'Vương miện';

  @override
  String get accessoryCircusTent => 'Lều xiếc';

  @override
  String get accessoryPinata => 'Piñata';

  @override
  String get accessoryCastle => 'Lâu đài';

  @override
  String get accessoryGenie => 'Thần đèn';

  @override
  String get accessoryVolcano => 'Núi lửa';

  @override
  String get accessoryCarrot => 'Cà rốt';

  @override
  String get accessoryCorn => 'Bắp ngô';

  @override
  String get accessoryTomato => 'Cà chua';

  @override
  String get accessoryAvocado => 'Quả bơ';

  @override
  String get accessoryCoconut => 'Quả dừa';

  @override
  String get accessoryBlueberries => 'Việt quất';

  @override
  String get accessoryPear => 'Quả lê';

  @override
  String get accessoryRiceBall => 'Cơm nắm';

  @override
  String get accessoryDumpling => 'Bánh bao hấp';

  @override
  String get accessorySushi => 'Sushi';

  @override
  String get accessoryRamen => 'Tô mì';

  @override
  String get accessoryTaco => 'Bánh taco';

  @override
  String get accessoryPizza => 'Bánh pizza';

  @override
  String get accessoryHotDog => 'Bánh mì xúc xích';

  @override
  String get accessoryFries => 'Khoai tây chiên';

  @override
  String get accessoryEgg => 'Quả trứng';

  @override
  String get accessoryBread => 'Ổ bánh mì';

  @override
  String get accessoryButter => 'Miếng bơ';

  @override
  String get accessoryPuzzle => 'Mảnh ghép';

  @override
  String get accessoryDice => 'Xúc xắc';

  @override
  String get accessoryChessPawn => 'Quân tốt';

  @override
  String get accessoryDart => 'Bia phi tiêu';

  @override
  String get accessoryBowling => 'Bowling';

  @override
  String get accessoryYoYo => 'Yo-yo';

  @override
  String get accessoryRollerSkate => 'Giày trượt patin';

  @override
  String get accessorySkateboard => 'Ván trượt';

  @override
  String get accessorySatellite => 'Vệ tinh';

  @override
  String get accessoryAlembic => 'Bình chưng cất';

  @override
  String get accessoryDna => 'Chuỗi DNA';

  @override
  String get accessoryTrophy => 'Cúp vô địch';

  @override
  String get accessoryLeopard => 'Báo hoa mai';

  @override
  String get accessoryElephant => 'Voi';

  @override
  String get accessoryPanda => 'Gấu trúc';

  @override
  String get accessoryGiraffe => 'Hươu cao cổ';

  @override
  String get accessoryTurtle => 'Rùa';

  @override
  String get accessoryKoala => 'Gấu koala';

  @override
  String get accessoryPenguin => 'Chim cánh cụt';

  @override
  String get accessorySauropod => 'Khủng long cổ dài';

  @override
  String get accessoryMermaid => 'Nàng tiên cá';

  @override
  String get accessoryEagle => 'Đại bàng';

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
  String get collectionTitle80 => 'Bậc thầy sưu tầm';

  @override
  String get collectionTitle100 => 'Đại gia sưu tầm';

  @override
  String get collectionTitle120 => 'Vua sưu tầm';

  @override
  String get collectionTitle140 => 'Hiền triết sưu tầm';

  @override
  String get collectionTitle160 => 'Thần sưu tầm';

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
  String get collectionSetsTitle => 'Bộ sưu tập';

  @override
  String get seasonTitle => 'Thẻ Mùa';

  @override
  String seasonEntrySub(int days, int tier) {
    return 'Còn $days ngày · bậc $tier/30';
  }

  @override
  String seasonTierLine(int max, int tier) {
    return 'Bậc $tier/$max';
  }

  @override
  String seasonDaysLeft(int days) {
    return 'Còn $days ngày';
  }

  @override
  String seasonHint(int cap) {
    return 'Kiếm XP từ nhiệm vụ, trò nhỏ, Phó bản, Đấu Trường (tối đa $cap XP/ngày). Sang mùa mới tiến độ được làm lại — nhớ nhận thưởng!';
  }

  @override
  String get seasonFreeTrack => 'Miễn phí';

  @override
  String get seasonPremiumTrack => 'Cao cấp';

  @override
  String seasonBuyPremium(int gems) {
    return 'Mở đường Cao cấp · $gems 💎';
  }

  @override
  String get seasonPremiumOwned => '✓ Đã mở đường Cao cấp';

  @override
  String get seasonPremiumBought => 'Đã mở đường Cao cấp!';

  @override
  String get seasonNotEnoughGems => 'Chưa đủ 💎';

  @override
  String get seasonLbTitle => 'BXH Thẻ Mùa';

  @override
  String get friendsTitle => 'Bạn bè';

  @override
  String get friendsTabList => 'Bạn bè';

  @override
  String get friendsTabRequests => 'Lời mời';

  @override
  String get friendsTabAdd => 'Thêm bạn';

  @override
  String get friendsTabRank => 'BXH';

  @override
  String get friendsEmpty =>
      'Chưa có bạn nào. Qua tab Thêm bạn để tìm theo biệt danh nhé.';

  @override
  String get friendsGiftSend => '🎁 Tặng quà';

  @override
  String get friendsGiftSentToday => 'Đã tặng hôm nay';

  @override
  String friendsGiftSentSnack(String xu) {
    return 'Đã tặng quà! Bạn nhận +$xu Xu';
  }

  @override
  String friendsGiftWaiting(int n) {
    return '$n quà từ bạn bè đang chờ';
  }

  @override
  String get friendsGiftClaim => 'Nhận';

  @override
  String friendsGiftClaimedSnack(int n, String xu) {
    return 'Nhận $n quà: +$xu Xu';
  }

  @override
  String get friendsRemove => 'Xoá bạn';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Xoá $name khỏi danh sách bạn?';
  }

  @override
  String get friendsRequestsEmpty => 'Không có lời mời nào.';

  @override
  String get friendsAccept => 'Chấp nhận';

  @override
  String get friendsDecline => 'Từ chối';

  @override
  String friendsAccepted(String name) {
    return 'Đã kết bạn với $name';
  }

  @override
  String get friendsSearchHint => 'Nhập biệt danh chính xác';

  @override
  String get friendsSearchButton => 'Tìm';

  @override
  String get friendsSearchEmpty =>
      'Không thấy ai tên này. Biệt danh phải khớp chính xác (không phân biệt hoa thường) và người đó cần đã liên kết email.';

  @override
  String get friendsAddButton => 'Kết bạn';

  @override
  String get friendsRequestSent => 'Đã gửi lời mời';

  @override
  String get friendsAlready => 'Hai bạn đã là bạn bè rồi';

  @override
  String friendsStage(int n) {
    return 'Giai đoạn $n';
  }

  @override
  String get friendsErrLimit =>
      'Danh sách bạn hoặc lời mời đã đầy (tối đa 50 bạn, 30 lời mời đang chờ).';

  @override
  String get friendsErrNotFound => 'Không tìm thấy người này.';

  @override
  String get friendsErrAlreadySent =>
      'Hôm nay bạn đã tặng quà cho người này rồi.';

  @override
  String get friendsErrNetwork => 'Không kết nối được, thử lại sau nhé.';

  @override
  String get friendsRetry => 'Thử lại';

  @override
  String get friendsRankIncome => 'Thu nhập';

  @override
  String get friendsRankSeason => 'Thẻ Mùa';

  @override
  String get friendsRankOrders => 'Pha theo đơn';

  @override
  String get friendsRankMe => '(bạn)';

  @override
  String get friendsRankEmpty => 'Kết bạn để so tài với nhau nhé.';

  @override
  String friendShopTitle(String name) {
    return 'Quán của $name';
  }

  @override
  String get friendShopDisplay => 'Đang trưng bày';

  @override
  String get friendShopDisplayEmpty => 'Chưa trưng bày món nào.';

  @override
  String get friendShopCollection => 'Bộ sưu tập';

  @override
  String get friendShopProfile => 'Hồ sơ';

  @override
  String get seasonLbEmpty =>
      'Chưa ai trên bảng mùa này. Kiếm XP Thẻ Mùa rồi mở lại để lên bảng (cần tài khoản liên kết email).';

  @override
  String get playerTitleChampion => 'Quán Quân Mùa';

  @override
  String get playerTitleChampionHint => 'Nhận thưởng top 3 BXH Thẻ Mùa';

  @override
  String get seasonRewardTitle => 'Thưởng mùa trước';

  @override
  String seasonRewardLine(int rank) {
    return 'Bạn đạt hạng #$rank BXH Thẻ Mùa mùa trước!';
  }

  @override
  String seasonRewardClaim(int gems) {
    return 'Nhận $gems 💎';
  }

  @override
  String seasonRewardGot(int gems) {
    return 'Đã nhận $gems 💎 thưởng mùa!';
  }

  @override
  String get seasonRewardFail => 'Không nhận được thưởng. Thử lại sau nhé.';

  @override
  String get seasonItemsTitle =>
      'Độc quyền Thẻ Mùa (bậc 20 miễn phí · bậc 30 Cao cấp)';

  @override
  String get accessorySeasonSakura => 'Hoa Anh Đào Mùa';

  @override
  String get accessorySeasonPaperLantern => 'Đèn Giấy Mùa';

  @override
  String get accessorySeasonSunflower => 'Hướng Dương Mùa';

  @override
  String get accessorySeasonIsland => 'Đảo Nhiệt Đới Mùa';

  @override
  String get accessorySeasonAutumnLeaf => 'Lá Thu Mùa';

  @override
  String get accessorySeasonMoonView => 'Ngắm Trăng Mùa';

  @override
  String get accessorySeasonSnowflake => 'Bông Tuyết Mùa';

  @override
  String get accessorySeasonMountain => 'Đỉnh Núi Mùa';

  @override
  String seasonGot(String text) {
    return 'Nhận $text';
  }

  @override
  String get dailyItemTitle => 'Món của ngày';

  @override
  String get dailyItemNew => 'Món còn thiếu trong bộ sưu tập';

  @override
  String get dailyItemOwned => 'Đã có — mua sẽ được bản dư';

  @override
  String collectionSetDone(int coins) {
    return 'Nhận $coins Xu Chợ cho bộ sưu tập!';
  }

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
  String get whatsNewSeason =>
      '🎫 Thẻ Mùa 28 ngày/30 bậc, Món của ngày và bảng xếp hạng mùa có thưởng cuối mùa';

  @override
  String get whatsNewGuild =>
      '🐉 Phó bản Hội 3 ải mỗi tuần, Boss hoạt hình; bộ trang bị và tinh luyện phụ kiện';

  @override
  String get whatsNewProfile =>
      '👤 Trang Hồ sơ của tôi: avatar ảnh, danh hiệu; mốc sưu tập theo bộ';

  @override
  String get whatsNewArena =>
      '⚔️ Đấu Trường: PK Công thức, trận bóng ma, giải đấu tuần; Nhiệm vụ & Quà gộp một màn';

  @override
  String get whatsNewMore =>
      '🤝 Gia hạn tin đăng ở Chợ bằng quảng cáo; tính năng online cần liên kết email';

  @override
  String get whatsNewLater => 'Để sau';

  @override
  String get whatsNewOpen => 'Chơi thử';

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
  String marketExpiresIn(String t) {
    return 'Hết hạn sau $t';
  }

  @override
  String marketListExpiryNote(int days) {
    return 'Tin đăng tồn tại tối đa $days ngày; hết hạn món sẽ tự về kho của bạn.';
  }

  @override
  String marketExpiredToast(int n) {
    return '$n món hết hạn đăng đã về kho của bạn.';
  }

  @override
  String get swapTab => 'Trao đổi';

  @override
  String get swapCreate => 'Tạo đề nghị';

  @override
  String get swapCreateOk => 'Đăng đề nghị';

  @override
  String swapIntro(int days) {
    return 'Đổi món lấy món với người khác — không tốn Xu Chợ. Món bạn đưa được giữ lại cho tới khi có người nhận (tối đa $days ngày, hết hạn sẽ tự về kho).';
  }

  @override
  String get swapEmpty =>
      'Chưa có đề nghị trao đổi nào. Hãy tạo đề nghị đầu tiên!';

  @override
  String get swapMine => 'Đề nghị trao đổi của tôi';

  @override
  String get swapMineEmpty => 'Bạn chưa đăng đề nghị nào.';

  @override
  String get swapGive => 'Đưa';

  @override
  String get swapWant => 'Cần';

  @override
  String get swapAccept => 'Đổi';

  @override
  String get swapNeedItem => 'Chưa có món cần';

  @override
  String get swapCancel => 'Huỷ';

  @override
  String get swapPickGive => 'Chọn món bạn đưa';

  @override
  String get swapPickWant => 'Chọn món bạn muốn';

  @override
  String get swapPickSearch => 'Tìm theo tên';

  @override
  String get swapPickNone => 'Không có món nào.';

  @override
  String swapMaxNote(int n) {
    return 'Tối đa $n đề nghị cùng lúc.';
  }

  @override
  String get swapConfirmTitle => 'Xác nhận đổi';

  @override
  String swapConfirmBody(String give, String want) {
    return 'Bạn nhận $give và đưa $want?';
  }

  @override
  String get swapCreatedToast => 'Đã đăng đề nghị trao đổi!';

  @override
  String swapDoneToast(String name) {
    return 'Đã đổi xong! Bạn nhận được $name.';
  }

  @override
  String get swapCancelledToast => 'Đã huỷ đề nghị, món đã về kho.';

  @override
  String swapCollectedToast(int n) {
    return '$n món từ trao đổi đã về kho của bạn.';
  }

  @override
  String get swapErrNotOwned =>
      'Bạn chưa có món này (thử mở lại Chợ để đối chiếu).';

  @override
  String get swapErrNotOwnedWant => 'Bạn chưa có món người ta cần.';

  @override
  String swapErrTooMany(int n) {
    return 'Bạn đang có quá nhiều đề nghị mở (tối đa $n).';
  }

  @override
  String get swapErrNotOpen =>
      'Đề nghị này vừa được nhận hoặc đã huỷ — danh sách đã cập nhật.';

  @override
  String get swapErrOwn => 'Không thể tự nhận đề nghị của chính mình.';

  @override
  String get swapErrInvalid => 'Đề nghị không hợp lệ.';

  @override
  String get swapErrNetwork => 'Không kết nối được, thử lại sau nhé.';

  @override
  String get marketCancelButton => 'Huỷ đăng';

  @override
  String get marketCancelledToast => 'Đã huỷ đăng.';

  @override
  String marketExtendButton(int days) {
    return 'Gia hạn thêm $days ngày (xem QC)';
  }

  @override
  String get marketExtendedToast => 'Đã gia hạn tin đăng.';

  @override
  String essenceEarned(int n) {
    return '+$n 🧪 Tinh chất';
  }

  @override
  String get masteryTitle => 'Bí quyết';

  @override
  String masteryEssence(int n) {
    return '🧪 $n Tinh chất';
  }

  @override
  String get masteryHint =>
      'Kiếm Tinh chất từ trò nhỏ, rồi nâng Bí quyết để tăng thu nhập của từng giai đoạn. Giữ nguyên khi Nhượng quyền.';

  @override
  String masteryBonus(String pct) {
    return '+$pct% thu nhập';
  }

  @override
  String masteryBuy(int cost) {
    return 'Nâng · $cost 🧪';
  }

  @override
  String get masteryMaxed => 'Tối đa';

  @override
  String get guildDungeonTitle => 'Phó bản Hội';

  @override
  String guildDungeonCardSub(int cleared) {
    return 'Đã qua $cleared/3 ải';
  }

  @override
  String guildDungeonStage(int n) {
    return 'Ải $n/3';
  }

  @override
  String get guildDungeonBarTap => 'Chạm ly';

  @override
  String get guildDungeonBarOff => 'Gác đêm';

  @override
  String get guildDungeonBarRec => 'Công thức';

  @override
  String get guildDungeonRoleTap => 'Thợ chạm';

  @override
  String get guildDungeonRoleOff => 'Người gác đêm';

  @override
  String get guildDungeonRoleRec => 'Đầu bếp';

  @override
  String get guildDungeonRoleHeader => 'Vai trò tuần này';

  @override
  String get guildDungeonRoleHint =>
      'Đóng góp đúng vai được ×1.5. Đổi vai được 1 lần trong tuần.';

  @override
  String get guildDungeonRoleLockedNote => 'Bạn đã dùng lượt đổi vai tuần này.';

  @override
  String get guildDungeonNoRole => 'Chưa chọn vai — chọn một vai để được ×1.5.';

  @override
  String get guildDungeonHint =>
      'Cả ba thanh phải đầy mới qua ải; thanh nào dư không bù cho thanh khác.';

  @override
  String guildDungeonHours(String n) {
    return '$n giờ';
  }

  @override
  String get guildDungeonCleared => 'Đã qua';

  @override
  String guildDungeonClaim(int coins) {
    return 'Nhận · $coins Xu Hội';
  }

  @override
  String guildDungeonClaimFinal(int coins, int gems) {
    return 'Nhận · $coins Xu Hội + $gems 💎 + rương';
  }

  @override
  String get guildDungeonClaimed => 'Đã nhận';

  @override
  String get guildDungeonNeedMin =>
      'Hãy đóng góp một ít (chạm, offline hoặc Công thức) để nhận thưởng.';

  @override
  String guildDungeonClaimedSnack(int coins, int gems) {
    return 'Thưởng ải: +$coins Xu Hội, +$gems 💎';
  }

  @override
  String guildDungeonClaimedSnackChest(int coins, int gems, String item) {
    return 'Thưởng ải: +$coins Xu Hội, +$gems 💎, $item';
  }

  @override
  String get guildDungeonBoard => 'Đóng góp của hội viên';

  @override
  String get guildDungeonErrLocked => 'Hội chưa qua ải này.';

  @override
  String get guildDungeonErrRoleLocked =>
      'Bạn đã đổi vai một lần trong tuần này rồi.';

  @override
  String get guildDungeonNudgeTooltip => 'Nhắc trong chat';

  @override
  String guildDungeonNudge(String bar) {
    return 'thanh $bar còn thiếu, giúp một tay nhé!';
  }

  @override
  String get refineTooltip => 'Tinh luyện';

  @override
  String get refineButton => 'Tinh luyện';

  @override
  String refineLevelLabel(int level, int max) {
    return 'Cấp $level/$max';
  }

  @override
  String refinePoints(String from, String to) {
    return 'Điểm trong bộ trang bị: $from → $to';
  }

  @override
  String refineCostSpares(int have, int need) {
    return 'Bản dư của món này: $have/$need';
  }

  @override
  String refineCostEssence(int have, int need) {
    return '🧪 Tinh chất: $have/$need';
  }

  @override
  String get refineMaxed => 'Đã đạt cấp tối đa';

  @override
  String refineDone(int level) {
    return 'Đã tinh luyện lên cấp $level';
  }

  @override
  String get refineNote =>
      'Mỗi cấp +25% điểm của món trong bộ trang bị, không nâng trần buff của họ. Cấp không chuyển theo khi bán hay đổi món.';

  @override
  String get refineErrSpares => 'Chưa đủ bản dư của món này.';

  @override
  String get refineErrEssence => 'Chưa đủ Tinh chất.';

  @override
  String get loadoutTitle => 'Bộ trang bị';

  @override
  String get loadoutHint =>
      'Mỗi họ cho một buff: 🔥 chạm · ✨ thu nhập · 🌿 offline · 💎 giá nâng cấp. Mang nhiều món cùng họ để có combo.';

  @override
  String get loadoutEmpty =>
      'Chưa có buff nào. Chạm một món trong bộ sưu tập để trang bị.';

  @override
  String loadoutBuffTap(String pct) {
    return '🔥 Chạm +$pct%';
  }

  @override
  String loadoutBuffIncome(String pct) {
    return '✨ Thu nhập +$pct%';
  }

  @override
  String loadoutBuffOffline(String pct) {
    return '🌿 Offline +$pct%';
  }

  @override
  String loadoutBuffDiscount(String pct) {
    return '💎 Giá nâng cấp −$pct%';
  }

  @override
  String loadoutComboSuffix(String mult) {
    return ' · combo ×$mult';
  }

  @override
  String loadoutLockNote(int minutes) {
    return '🔒 Đang khoá đổi: còn $minutes phút';
  }

  @override
  String get loadoutLockedTitle => 'Trang bị đang khoá';

  @override
  String loadoutLockedBody(int minutes) {
    return 'Bạn vừa đổi trang bị. Còn $minutes phút nữa mới tháo/thay tiếp được (lấp ô trống thì được ngay). Mở khoá ngay?';
  }

  @override
  String get loadoutUnlockAd => 'Xem QC để mở khoá';

  @override
  String get loadoutUnlockFree => 'Mở khoá';

  @override
  String get loadoutUnlockedToast => 'Đã mở khoá — đổi trang bị thoải mái!';

  @override
  String loadoutRemoveTitle(String name) {
    return 'Tháo $name?';
  }

  @override
  String loadoutRemoveBody(int minutes) {
    return 'Sau khi tháo, bạn không tháo/thay món khác được trong $minutes phút (lấp ô trống vẫn được).';
  }

  @override
  String get loadoutRemoveConfirm => 'Tháo';

  @override
  String get loadoutFamilyTap => 'Nhiệt huyết · tăng giá trị chạm';

  @override
  String get loadoutFamilyIncome => 'Lấp lánh · tăng thu nhập tự động';

  @override
  String get loadoutFamilyOffline => 'Yên bình · tăng thu nhập khi vắng mặt';

  @override
  String get loadoutFamilyDiscount => 'Tinh tế · giảm giá nâng cấp';

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
  String get chHeader => '🔥 Thử thách (khó — thưởng cao)';

  @override
  String chCat(int n) {
    return 'Bắt $n mèo Mưa vàng';
  }

  @override
  String chVip(int n) {
    return 'Phục vụ $n khách VIP';
  }

  @override
  String get chBonusLabel => 'Xong cả 2 thử thách';

  @override
  String get lbrTitle => 'Thưởng top tuần';

  @override
  String lbrIntro(int first, int second, int third) {
    return 'Mỗi tuần, top 3 của mỗi bảng tích lũy (Thu nhập, Trân Châu Rơi, Sưu tập, VIP, Thợ pha chế, Pha theo đơn) nhận $first / $second / $third 💎. Bảng được chốt vào đầu tuần (thứ Hai, giờ UTC); thưởng còn nhận được thêm một tuần.';
  }

  @override
  String get lbrEmpty =>
      'Chưa có thưởng — hãy leo lên top 3 các bảng xếp hạng!';

  @override
  String lbrRow(String board, String week) {
    return '$board · tuần $week';
  }

  @override
  String lbrClaim(int n) {
    return 'Nhận $n 💎';
  }

  @override
  String lbrGot(int n) {
    return 'Đã nhận $n 💎 thưởng top tuần!';
  }

  @override
  String get lbrErrGone => 'Phần thưởng đã hết hạn hoặc không còn.';

  @override
  String get lbrBoardIncome => 'Thu nhập';

  @override
  String get lbrBoardPearls => 'Trân Châu Rơi';

  @override
  String get lbrBoardCollection => 'Sưu tập';

  @override
  String get lbrBoardVip => 'VIP';

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
  String get weeklyQuestsTitle => 'Nhiệm vụ tuần';

  @override
  String get weeklyQuestsOpen => 'Nhiệm vụ tuần 🗓️';

  @override
  String wqPrestige(int n) {
    return 'Nhượng quyền $n lần';
  }

  @override
  String wqM3Win(int n) {
    return 'Thắng $n màn Trân Châu Rơi';
  }

  @override
  String wqTrade(int n) {
    return 'Giao dịch $n lần ở Chợ (đăng bán hoặc mua)';
  }

  @override
  String wqDailyDone(int n) {
    return 'Nhận thưởng $n nhiệm vụ ngày';
  }

  @override
  String wqSpin(int n) {
    return 'Quay vòng quay $n lần';
  }

  @override
  String wqBuy(int n) {
    return 'Mua nâng cấp $n lần';
  }

  @override
  String get weeklyChestLabel =>
      'Rương tuần: xong cả 3 → +1 phụ kiện Hiếm trở lên';

  @override
  String weeklyResetsIn(String time) {
    return 'Làm mới sau $time';
  }

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
  String get navMatch3 => 'Trò chơi';

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
  String get m3LeaveTitle => 'Thoát ván này?';

  @override
  String get m3LeaveBody => 'Ván đang chơi được giữ cho tới khi bạn tắt app.';

  @override
  String get m3LeaveStay => 'Chơi tiếp';

  @override
  String get m3LeaveConfirm => 'Thoát';

  @override
  String get accessoryHowToTitle => 'Hướng dẫn sưu tầm';

  @override
  String get accessoryHowToButton => 'Hướng dẫn';

  @override
  String get accessoryHtp1 =>
      '🎯 Mục tiêu: sưu tập đủ các món. Món đang mang quanh cốc cho buff nhỏ theo họ (🔥 chạm · ✨ thu nhập · 🌿 offline · 💎 giá nâng cấp); mang nhiều món cùng họ để có combo. Tháo/thay có thời gian chờ — xem quảng cáo để mở khoá ngay. Khoe với bạn bè và lên bảng xếp hạng Sưu tập.';

  @override
  String get accessoryHtp2 =>
      '🎁 Cách nhận: xong cả 3 nhiệm vụ ngày · qua màn mốc Trân Châu Rơi (10/30/60) · ô rương của vòng quay thường · mỗi lần Kỷ Nguyên hoá · mua Gói phụ kiện bằng 💎.';

  @override
  String get accessoryHtp3 =>
      '🎰 Vòng quay phụ kiện: mỗi lượt xem 1 quảng cáo hoặc dùng 💎. Lượt xem quảng cáo có giới hạn mỗi ngày.';

  @override
  String get accessoryHtp4 =>
      '✨ Độ hiếm: Thường → Hiếm → Sử thi → Huyền thoại. Cuối tuần và dịp lễ tăng tỉ lệ Sử thi/Huyền thoại; Gói Hiếm/Sử thi bảo đảm độ hiếm tối thiểu; dịp lễ có Gói Lễ Hội với món độc quyền.';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ Rớt trùng món đã có: nhận $gems 💎 và thêm 1 bản dư để đem bán ở Chợ.';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 Chợ: bán bản dư lấy Xu Chợ, mua món còn thiếu của người chơi khác (phí sàn 1%). Xu Chợ nạp bằng Xu hoặc 💎, không đổi ngược lại.';

  @override
  String get accessoryHtp7 =>
      '🏅 Mốc sưu tập (10/25/40/50/80/100/120/140/160 món) tặng Xu Chợ. Thêm món muốn có vào danh sách để theo dõi, xếp hạng tính theo số món khác nhau.';

  @override
  String get accessoryHtp8 =>
      '👆 Chạm một món đã có để trưng bày quanh cốc ở màn chính.';

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

  @override
  String eventBanner(String name) {
    return '🎉 Sự kiện $name';
  }

  @override
  String eventTitle(String name) {
    return 'Sự kiện $name';
  }

  @override
  String eventEndsIn(String time) {
    return 'Kết thúc sau $time';
  }

  @override
  String eventPoints(int n) {
    return 'Điểm sự kiện: $n';
  }

  @override
  String get eventRedeemHint =>
      'Làm nhiệm vụ để lấy điểm, đổi món độc quyền miễn phí. Điểm không đủ đổi cả bộ — hãy chọn món bạn thích!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost điểm';
  }

  @override
  String get eventLbTitle => 'BXH Sự kiện';

  @override
  String get eventLbEmpty =>
      'Chưa có ai lên bảng. Chạm vài cái là bạn đứng đầu!';

  @override
  String get eventLbNoScore =>
      'Bạn chưa có điểm — chạm ly, bắt mèo, phục vụ VIP để lên bảng.';

  @override
  String eventLbMyScore(int n) {
    return 'Điểm của bạn: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n điểm';
  }

  @override
  String eventBuff(String mult) {
    return 'Doanh thu ×$mult trong suốt sự kiện';
  }

  @override
  String get guildTitle => 'Hội';

  @override
  String get guildIntro =>
      'Lập hội hoặc vào hội để cùng hoàn thành mục tiêu tuần và nhận thưởng.';

  @override
  String get guildCreate => 'Tạo hội';

  @override
  String get guildJoin => 'Vào';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max thành viên';
  }

  @override
  String guildWeekTotal(int n) {
    return 'Tuần này: $n điểm';
  }

  @override
  String get guildNameLabel => 'Tên hội (3-20 ký tự)';

  @override
  String get guildTagLabel => 'Tag (2-4 chữ/số)';

  @override
  String get guildLeave => 'Rời hội';

  @override
  String get guildLeaveConfirm =>
      'Rời hội này? Điểm tuần của bạn sẽ không còn tính cho hội.';

  @override
  String get guildKick => 'Mời ra';

  @override
  String guildKickConfirm(String name) {
    return 'Mời $name ra khỏi hội?';
  }

  @override
  String get guildReport => 'Báo cáo hội';

  @override
  String get guildReportSent => 'Đã gửi báo cáo, cảm ơn bạn.';

  @override
  String get guildGoalTitle => 'Mục tiêu tuần';

  @override
  String get guildClaim => 'Nhận';

  @override
  String get guildHowToTitle => 'Cách kiếm điểm Hội';

  @override
  String guildHowTo(int n) {
    return '⭐ Điểm Hội = hoạt động của BẠN trong tuần: chạm ly +1, bắt mèo +50, phục vụ khách VIP +50.\n🎯 Điểm của cả hội cộng lại để mở các mốc thưởng; điểm tuần reset thứ Hai 00:00 UTC.\n🎁 Cần đóng góp ≥$n điểm cá nhân mới được nhận thưởng mốc.';
  }

  @override
  String guildNeedPoints(int n) {
    return 'Cần đóng góp ≥$n điểm để nhận';
  }

  @override
  String guildYourPoints(int n) {
    return 'Bạn đóng góp: $n điểm';
  }

  @override
  String get guildOwner => 'Chủ hội';

  @override
  String get guildEmpty => 'Chưa có hội công khai nào. Hãy tạo hội đầu tiên!';

  @override
  String get guildErrNameTaken => 'Tên hội đã có người dùng.';

  @override
  String get guildErrFull => 'Hội đã đủ thành viên.';

  @override
  String guildExpandButton(int cost, int max) {
    return 'Mở rộng lên $max chỗ · $cost 💎';
  }

  @override
  String guildExpandConfirm(int cost, int max) {
    return 'Mở rộng hội lên $max thành viên với $cost 💎?';
  }

  @override
  String get guildExpandAction => 'Mở rộng';

  @override
  String guildExpandDone(int max) {
    return 'Hội giờ chứa tối đa $max thành viên!';
  }

  @override
  String get guildExpandMaxed => 'Hội đã ở sức chứa tối đa.';

  @override
  String get guildErrAlready => 'Bạn đang ở trong một hội rồi.';

  @override
  String get guildErrInvalid => 'Tên hoặc tag không hợp lệ.';

  @override
  String get guildErrNotFound => 'Không tìm thấy hội (có thể hội đã đóng).';

  @override
  String get guildErrContribution =>
      'Bạn cần đóng góp thêm điểm trong tuần này.';

  @override
  String get guildErrNetwork => 'Không kết nối được, thử lại sau nhé.';

  @override
  String get guildLbTitle => 'BXH Hội';

  @override
  String get guildLbEmpty => 'Tuần này chưa hội nào có điểm.';

  @override
  String guildRewardGot(int gems) {
    return 'Nhận +$gems 💎';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return 'Nhận +$gems 💎 và $name';
  }

  @override
  String guildPoints(int n) {
    return '$n điểm';
  }

  @override
  String guildCreateCost(int n) {
    return 'Phí tạo hội: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return 'Cần $n 💎 để tạo hội.';
  }

  @override
  String get guildApprovalSwitch => 'Cần chủ hội duyệt khi xin vào';

  @override
  String get guildRequestJoin => 'Xin vào';

  @override
  String get guildRequestSent => 'Đã gửi yêu cầu, chờ chủ hội duyệt.';

  @override
  String get guildRequestPending => 'Chờ duyệt';

  @override
  String guildRequestsTitle(int n) {
    return 'Yêu cầu vào hội ($n)';
  }

  @override
  String get guildAccept => 'Duyệt';

  @override
  String get guildReject => 'Từ chối';

  @override
  String get guildErrApproval =>
      'Hội này cần chủ hội duyệt — hãy bấm \"Xin vào\".';

  @override
  String get guildErrNicknameTaken =>
      'Trong hội này đã có người dùng tên đó, hãy chọn tên khác.';

  @override
  String get guildErrRequestsFull => 'Hội đang có quá nhiều yêu cầu chờ duyệt.';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 Máy này: $local · Trên cloud: $cloud';
  }

  @override
  String get cloudRemindTitle => 'Bảo vệ tiến độ của bạn';

  @override
  String get cloudRemindBody =>
      'Bạn chưa liên kết email. Nếu đổi máy hoặc cài lại game, tiến độ (Xu, 💎, phụ kiện, Xu Chợ) sẽ MẤT. Liên kết email chỉ mất 1 phút và miễn phí.';

  @override
  String get cloudRemindLink => 'Liên kết ngay';

  @override
  String get cloudRemindLater => 'Để sau';

  @override
  String get ftueTap => 'Chạm vào ly để pha trà và kiếm Xu!';

  @override
  String get ftueBuy =>
      'Đủ Xu rồi! Mua nâng cấp đầu tiên để Xu tự chảy mỗi giây.';

  @override
  String get ftueExplain =>
      'Tuyệt! Giờ Xu tự tăng mỗi giây — kể cả khi bạn đóng app. Mua thêm nâng cấp để kiếm nhanh hơn, mở khoá giai đoạn mới và nhận quà nhiệm vụ.';

  @override
  String get ftueOk => 'Đã hiểu';

  @override
  String get ftueSkip => 'Bỏ qua';

  @override
  String get accessoryGuildFlag => 'Cờ hội';

  @override
  String get accessoryGuildCastle => 'Lâu đài hội';

  @override
  String get accessoryGuildWolf => 'Sói hội';

  @override
  String get accessoryGuildDragon => 'Rồng hội';

  @override
  String get accessoryGuildFox => 'Cáo hội';

  @override
  String get accessoryGuildTiger => 'Hổ hội';

  @override
  String get accessoryGuildShark => 'Cá mập hội';

  @override
  String get accessoryGuildTrex => 'Khủng long hội';

  @override
  String get accessoryGuildBoar => 'Heo rừng hội';

  @override
  String get accessoryGuildBear => 'Gấu hội';

  @override
  String get accessoryGuildScorpion => 'Bò cạp hội';

  @override
  String get accessoryGuildMoai => 'Tượng đá hội';

  @override
  String get guildChatTitle => 'Chat hội';

  @override
  String get guildChatEmpty =>
      'Chưa có tin nào. Hãy là người nói câu đầu tiên!';

  @override
  String get guildChatHint => 'Nhắn cho cả hội…';

  @override
  String get guildChatSend => 'Gửi';

  @override
  String get guildChatPinned => 'Thông báo';

  @override
  String get guildChatPin => 'Ghim';

  @override
  String get guildChatUnpin => 'Bỏ ghim';

  @override
  String get guildChatDelete => 'Xoá tin';

  @override
  String get guildChatReport => 'Báo cáo tin';

  @override
  String get guildChatReported =>
      'Đã báo cáo tin nhắn. Bạn sẽ không còn thấy tin này.';

  @override
  String get guildMembersHeader => 'Thành viên';

  @override
  String get guildMemberSearchHint => 'Tìm thành viên';

  @override
  String get guildMemberNoMatch => 'Không có thành viên nào khớp.';

  @override
  String get guildRoleOwner => 'Chủ hội';

  @override
  String get guildRoleOfficer => 'Phó hội';

  @override
  String get guildRoleMember => 'Thành viên';

  @override
  String get guildMemberMention => 'Nhắc trong chat';

  @override
  String get guildMemberProfile => 'Xem hồ sơ';

  @override
  String get guildQuestsSection => 'Nhiệm vụ Hội';

  @override
  String get guildQuestsSectionHint =>
      'Làm mới mỗi thứ Hai 00:00 UTC · thưởng Xu Hội';

  @override
  String get guildManage => 'Quản lý';

  @override
  String get guildPromote => 'Bổ nhiệm phó hội';

  @override
  String get guildDemote => 'Bãi nhiệm phó hội';

  @override
  String get guildTransfer => 'Nhường chức chủ hội';

  @override
  String get guildTeamTitle => 'Nhiệm vụ chung tuần này';

  @override
  String guildTeamProgress(int active, int need) {
    return '$active / $need người đã đạt';
  }

  @override
  String guildTeamHint(int n) {
    return 'Một nửa hội (ít nhất 2 người) cùng đạt $n điểm tuần thì ai đạt mức này đều nhận thưởng. Rủ nhau chơi nhé!';
  }

  @override
  String guildTeamClaim(int n) {
    return 'Nhận $n Xu Hội';
  }

  @override
  String guildTeamGot(int n) {
    return 'Đã nhận $n Xu Hội từ nhiệm vụ chung!';
  }

  @override
  String get guildErrTeamNotReached => 'Chưa đủ người trong hội đạt mức điểm.';

  @override
  String guildErrTeamLow(int n) {
    return 'Bạn cần đạt ít nhất $n điểm tuần để nhận thưởng.';
  }

  @override
  String get guildFundTitle => 'Quỹ hội tuần này';

  @override
  String guildFundMine(int n) {
    return 'Bạn đã góp $n 💎';
  }

  @override
  String guildFundClaim(int n) {
    return 'Nhận $n Xu Hội';
  }

  @override
  String guildFundHint(int min) {
    return 'Cả hội cùng nạp 💎 để đạt mục tiêu (tăng theo số thành viên). Mỗi người cần góp ít nhất $min 💎 mới nhận được thưởng.';
  }

  @override
  String guildFundGot(int n) {
    return 'Đã nhận $n Xu Hội từ quỹ hội!';
  }

  @override
  String get guildErrFundNotReached => 'Quỹ hội chưa đạt mục tiêu.';

  @override
  String guildErrFundLow(int n) {
    return 'Bạn cần góp ít nhất $n 💎 vào quỹ để nhận thưởng.';
  }

  @override
  String guildFundProgress(int progress, int target) {
    return '$progress / $target 💎';
  }

  @override
  String guildTransferConfirm(String name) {
    return 'Nhường chức chủ hội cho $name? Bạn sẽ trở thành thành viên thường.';
  }

  @override
  String get guildErrNotAllowed => 'Bạn không đủ quyền với người này.';

  @override
  String guildErrOfficersFull(int n) {
    return 'Hội đã đủ $n phó hội.';
  }

  @override
  String get guildActivityTitle => 'Nhật ký hội';

  @override
  String get guildActivityEmpty => 'Chưa có hoạt động nào.';

  @override
  String guildEvJoined(String name) {
    return '$name đã vào hội';
  }

  @override
  String guildEvLeft(String name) {
    return '$name đã rời hội';
  }

  @override
  String guildEvKicked(String actor, String target) {
    return '$actor đã mời $target ra khỏi hội';
  }

  @override
  String guildEvPromoted(String actor, String target) {
    return '$actor đã bổ nhiệm $target làm phó hội';
  }

  @override
  String guildEvDemoted(String actor, String target) {
    return '$actor đã bãi nhiệm phó hội $target';
  }

  @override
  String guildEvTransferred(String actor, String target) {
    return '$actor đã nhường chức chủ hội cho $target';
  }

  @override
  String get guildErrChatRate => 'Bạn gửi quá nhanh, chờ vài giây nhé.';

  @override
  String get guildErrTextBlocked => 'Tin nhắn chứa từ không được phép.';

  @override
  String guildErrDailyLimit(int n) {
    return 'Hôm nay bạn đã nạp tối đa $n 💎.';
  }

  @override
  String get guildErrCoins => 'Không đủ Xu Hội.';

  @override
  String get guildErrOwned => 'Bạn đã có vật phẩm này.';

  @override
  String get guildErrBuffMaxed =>
      'Buff của hội đã đạt mức tối đa, hãy chờ bớt.';

  @override
  String get guildErrClaimed => 'Bạn đã nhận phần thưởng này rồi.';

  @override
  String get guildErrInvalidInput => 'Thao tác không hợp lệ.';

  @override
  String get guildShopButton => 'Cửa hàng hội';

  @override
  String get guildShopTitle => 'Cửa hàng hội';

  @override
  String guildCoinsLabel(int n) {
    return 'Xu Hội: $n';
  }

  @override
  String get guildDonateTitle => 'Nạp 💎 lấy Xu Hội';

  @override
  String guildDonateHint(int used, int cap) {
    return 'Hôm nay: $used/$cap 💎 · 1 💎 = 1 Xu Hội';
  }

  @override
  String guildDonateGems(int n) {
    return '$n 💎';
  }

  @override
  String guildDonated(int n) {
    return 'Đã nạp, nhận +$n Xu Hội';
  }

  @override
  String get guildQuestsTitle => 'Nhiệm vụ hội tuần này';

  @override
  String guildQuestProgress(int have, int need) {
    return 'Đóng góp $need điểm trong tuần ($have/$need)';
  }

  @override
  String guildQuestReward(int n) {
    return '+$n Xu Hội';
  }

  @override
  String guildQuestGot(int n) {
    return 'Nhận +$n Xu Hội';
  }

  @override
  String get guildItemsTitle => 'Phụ kiện độc quyền của hội';

  @override
  String guildItemPrice(int n) {
    return '$n Xu';
  }

  @override
  String get guildItemOwned => 'Đã có';

  @override
  String get guildItemBought => 'Đã đổi! Phụ kiện nằm trong Kho.';

  @override
  String get guildBuffTitle => 'Buff thu nhập cả hội';

  @override
  String guildBuffDesc(int pct, int hours) {
    return '+$pct% Xu trong $hours giờ cho mọi thành viên (không áp khi offline)';
  }

  @override
  String guildBuffLeft(String time) {
    return 'Còn $time';
  }

  @override
  String get guildBuffBought => 'Đã kích hoạt buff cho cả hội!';

  @override
  String guildStreakLine(int n) {
    return '🔥 $n tuần liên tiếp đủ 3 mốc';
  }

  @override
  String guildBuffLine(int pct, String time) {
    return '⚡ Buff hội +$pct% · còn $time';
  }

  @override
  String get guildLbTabTotal => 'Tổng';

  @override
  String get guildLbTabAvg => 'Trung bình';

  @override
  String get guildLbTabStreak => 'Chuỗi';

  @override
  String guildLbAvgNote(int n) {
    return 'Chỉ tính hội từ $n thành viên trở lên';
  }

  @override
  String guildAvgPerMember(int n) {
    return '$n/người';
  }

  @override
  String guildStreakWeeks(int n) {
    return '$n tuần';
  }

  @override
  String get guildLbStreakNote => 'Số tuần liên tiếp cả hội đạt đủ 3 mốc';

  @override
  String get guildLbStreakEmpty => 'Chưa hội nào có chuỗi tuần.';

  @override
  String get guildLbAvgEmpty =>
      'Chưa hội nào đủ điều kiện xếp hạng trung bình.';

  @override
  String get recipeOrderOrders => 'Pha theo đơn';

  @override
  String recipeOrderAsk(String drink) {
    return 'Khách gọi: $drink';
  }

  @override
  String get recipeOrderGuideFull => 'Công thức mẫu';

  @override
  String get recipeOrderGuideNames => 'Nguyên liệu cần dùng (tự nhớ lượng)';

  @override
  String recipeOrderGuideCount(int n) {
    return 'Món này có $n nguyên liệu — tự nhớ nhé!';
  }

  @override
  String get recipeOrderGuideNone => 'Không gợi ý — pha theo trí nhớ!';

  @override
  String get recipeOrderTray =>
      'Khay nguyên liệu — kéo vào ly hoặc chạm để chọn';

  @override
  String get recipeOrderCupEmpty => 'Ly còn trống';

  @override
  String recipeOrderSetAmount(String name) {
    return 'Lượng $name';
  }

  @override
  String get recipeOrderPour => 'Cho vào ly';

  @override
  String get recipeOrderRemove => 'Bỏ ra';

  @override
  String get recipeOrderServe => 'Phục vụ';

  @override
  String get recipeOrderPerfect => 'Hoàn hảo! Đúng từng lượng';

  @override
  String get recipeOrderGood => 'Đạt — còn lệch chút lượng';

  @override
  String get recipeOrderFail => 'Chưa đúng món';

  @override
  String recipeOrderMissing(String amount, String name) {
    return 'Thiếu $name ($amount)';
  }

  @override
  String recipeOrderExtra(String name) {
    return 'Thừa $name — không có trong công thức';
  }

  @override
  String recipeOrderOff(String mine, String name, String right) {
    return '$name: bạn cho $mine, đúng là $right';
  }

  @override
  String get recipeOrderHint => 'Gợi ý: chạm nguyên liệu đã cho để sửa lượng';

  @override
  String get rlbTabQuiz => 'Trắc nghiệm';

  @override
  String get rlbOrderEmpty =>
      'Chưa có ai trên bảng. Hãy là người đầu tiên pha hoàn hảo một món không cần công thức mẫu!';

  @override
  String get rlbNoPerfect =>
      'Bạn chưa pha hoàn hảo món nào (không nhìn công thức mẫu) nên chưa có tên trên bảng.';

  @override
  String rlbPerfect(int n) {
    return 'Hoàn hảo $n món';
  }

  @override
  String get recipeOrderHold => 'Giữ để rót';

  @override
  String get recipeOrderPourAgain => 'Rót lại';

  @override
  String recipeOrderCombo(int n) {
    return '🔥 Combo ×$n';
  }

  @override
  String recipeOrderComboTip(String cash, int combo) {
    return 'Combo ×$combo: tip +$cash Xu!';
  }

  @override
  String get rlbTabDaily => 'Hôm nay';

  @override
  String get rlbDailyEmpty =>
      'Chưa ai nộp điểm hôm nay. Làm thử thách để lên bảng đầu tiên!';

  @override
  String get rlbNoDaily => 'Làm Thử thách hôm nay để có tên trên bảng.';

  @override
  String rlbDailyScore(Object n) {
    return '$n điểm';
  }

  @override
  String get recipeDailyTitle => 'Thử thách hôm nay';

  @override
  String get recipeDailyOpen => '3 đơn khó, không gợi ý — mỗi ngày một lần';

  @override
  String recipeDailyDone(Object score) {
    return 'Hôm nay bạn được $score/300 điểm';
  }

  @override
  String recipeDailyOrderScore(Object n) {
    return 'Điểm đơn này: $n/100';
  }

  @override
  String recipeDailyTotal(Object n) {
    return '$n/300 điểm';
  }

  @override
  String get recipeDailyAlready =>
      'Bạn đã làm thử thách hôm nay. Mai quay lại nhé — đề mới mỗi ngày!';

  @override
  String get recipeDailyBoard => 'Xem bảng hôm nay';

  @override
  String get recipeDailyIntro =>
      'Đề giống nhau cho mọi người, không gợi ý, lượng phải đúng từng mức. Chỉ làm được một lần mỗi ngày.';

  @override
  String get recipeOrderRush => 'Giờ cao điểm';

  @override
  String get recipeOrderRushSub =>
      'Khách chỉ chờ một lúc: giao kịp giờ và hoàn hảo thì có tip thêm. Hết giờ, ly pha dở bị chấm luôn.';

  @override
  String get recipeOrderTimeUp =>
      '⏰ Hết giờ! Khách bỏ đi, ly bị chấm như đang có.';

  @override
  String recipeOrderRushTip(String cash) {
    return '⏱ Giao kịp giờ! Tip +$cash Xu!';
  }

  @override
  String recipeOrderFestival(String name) {
    return 'Đơn lễ hội: $name';
  }

  @override
  String recipeOrderFestivalTip(String cash) {
    return '🎁 Đơn lễ hội hoàn hảo! Tip +$cash Xu!';
  }

  @override
  String get recipeOrderShare => 'Khoe ly này';

  @override
  String get cupShareTitle => 'Ly hoàn hảo';

  @override
  String get cupSharePerfect => 'Pha hoàn hảo!';

  @override
  String cupShareText(String name) {
    return 'Mình vừa pha hoàn hảo $name trong Boba Empire! 🧋';
  }

  @override
  String recipeCounterNext(int count) {
    return 'Thạo $count món để mở thêm 1 chỗ trưng bày';
  }

  @override
  String get lbrBoardOrders => 'Pha theo đơn';

  @override
  String get storySpeedrunTabExt3 => 'Hồi 4';

  @override
  String get storySpeedrunExt3NotCompletedYet =>
      'Bạn chưa hoàn thành Hồi 4 — hoàn thành Chương 46 để được xếp hạng.';

  @override
  String storyCondRecipes(int n, String game) {
    return 'Thạo $n món ở $game';
  }

  @override
  String storyCondOrders(int n, String game) {
    return 'Pha hoàn hảo $n món ở $game';
  }

  @override
  String storyCondDaily(int n, String game) {
    return 'Làm $game trong $n ngày';
  }

  @override
  String get lbrBoardDaily => 'Thử thách ngày';

  @override
  String get lbrBoardArena => 'Giải đấu Đấu Trường';

  @override
  String lbrDailyNote(int rest) {
    return 'Thử thách ngày: top 10 theo TỔNG điểm cả tuần trước cũng có thưởng — hạng 1-3 như trên, hạng 4-10 nhận $rest 💎.';
  }

  @override
  String get rlbDailyWeeklyHint =>
      'Mỗi tuần, top 10 theo tổng điểm Thử thách ngày của cả tuần nhận 💎 (chốt vào đầu tuần sau, giờ UTC).';

  @override
  String get howToTooltip => 'Cách chơi';

  @override
  String get howToRecipesTitle => 'Cách chơi: Công thức pha chế';

  @override
  String get howToRecipes1 =>
      'Học công thức bằng cách ÔN CÁCH QUÃNG: mỗi ngày game gọi những món đến hạn ôn, bạn trả lời vài câu hỏi.';

  @override
  String howToRecipes2(int a, int b, int c) {
    return 'Mỗi món có 4 bậc: Mới → Quen → Thuộc → Thạo. Đúng thì lên bậc và hẹn ôn lại sau $a / $b / $c ngày; sai thì hạ một bậc và ôn lại ngay.';
  }

  @override
  String get howToRecipes3 =>
      'Câu hỏi khó dần theo bậc: bậc Mới điền nguyên liệu còn thiếu, bậc Quen đoán lượng, bậc Thuộc/Thạo chọn công thức đầy đủ đúng.';

  @override
  String get howToRecipes4 =>
      'Ôn món chưa tới hạn chỉ để luyện tập: không tính bậc và không có thưởng. Có thể xem quảng cáo để nhận gợi ý (câu đó không tính bậc).';

  @override
  String get howToRecipes5 =>
      'Lần đầu đạt mỗi bậc nhận Xu; lần đầu đạt Thạo nhận thêm 💎. Đạt các mốc số món Thạo (5, 10, 20…) nhận rương phụ kiện.';

  @override
  String howToRecipes6(int n) {
    return 'Ôn mỗi ngày để giữ 🔥 chuỗi ôn và nhận 💎 ở các mốc 3 / 7 / 14 / 30 ngày; lỡ đứt chuỗi có thể cứu bằng 💎. Thuộc $n món của một nhóm thì mở nhóm công thức kế tiếp.';
  }

  @override
  String get howToOrdersTitle => 'Cách chơi: Pha theo đơn';

  @override
  String get howToOrders1 =>
      'Khách gọi một món: kéo (hoặc chạm) nguyên liệu từ khay vào ly rồi chọn lượng.';

  @override
  String get howToOrders2 =>
      'Ở bảng chọn lượng, chạm lên thước hoặc GIỮ nút rót để lượng tăng dần; bậc thấp có vạch chia gợi ý.';

  @override
  String get howToOrders3 =>
      'Bấm Phục vụ: ly được đậy nắp, lắc rồi chấm từng nguyên liệu — đúng lượng, lệch 1 mức, sai lượng, thiếu hoặc thừa.';

  @override
  String get howToOrders4 =>
      'Món càng thuộc càng ít gợi ý: bậc Mới có công thức mẫu và vạch xanh, Quen chỉ hiện tên nguyên liệu, Thuộc chỉ cho biết số lượng, Thạo không gợi ý. Bậc Mới/Quen cho lệch 1 mức, Thuộc/Thạo phải đúng từng mức.';

  @override
  String get howToOrders5 =>
      'Kết quả ghi vào bậc thuộc của món như câu trắc nghiệm. Xem quảng cáo để hiện công thức mẫu (đơn đó không tính bậc).';

  @override
  String get howToOrders6 =>
      'Pha hoàn hảo nhiều đơn liên tiếp mà không dùng gợi ý để có 🔥 combo và tip Xu (chỉ với món đến hạn ôn).';

  @override
  String get howToOrders7 =>
      'Bật ⏱ Giờ cao điểm ở đơn đầu: khách chỉ kiên nhẫn một lúc. Giao kịp giờ và hoàn hảo thì có thêm tip; hết giờ, ly bị chấm như đang có.';

  @override
  String get howToOrders8 =>
      'Trong dịp lễ, cuối buổi có thêm đơn lễ hội (tip lớn hơn). Pha hoàn hảo thì bấm “Khoe ly này” để chia sẻ ảnh ly. Số món pha hoàn hảo không xem công thức mẫu được xếp hạng.';

  @override
  String get howToDailyTitle => 'Cách chơi: Thử thách hằng ngày';

  @override
  String get howToDaily1 =>
      'Mỗi ngày có 3 đơn khó, GIỐNG NHAU cho mọi người chơi trên thế giới.';

  @override
  String get howToDaily2 =>
      'Không có gợi ý, có nhiều nguyên liệu gây nhiễu và phải đúng từng mức. Không ghi bậc thuộc của món.';

  @override
  String howToDaily3(int max) {
    return 'Mỗi đơn tối đa 100 điểm (đúng 1, lệch 1 mức một nửa, thiếu 0, thừa bị trừ). Tổng tối đa $max điểm.';
  }

  @override
  String howToDaily4(int gems) {
    return 'Mỗi ngày chỉ làm MỘT lần: xong nhận $gems 💎 và Xu theo điểm; điểm đã nộp không sửa được.';
  }

  @override
  String get howToDaily5 =>
      'Tab “Hôm nay” ở bảng xếp hạng xếp theo điểm hôm nay. Mỗi tuần, top 10 theo TỔNG điểm cả tuần nhận 💎 (cần liên kết email).';
}
