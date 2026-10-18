// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Boba Empire';

  @override
  String get tapBrew => 'แตะเพื่อชงชา';

  @override
  String get coinsSuffix => ' เหรียญ';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / วินาที';
  }

  @override
  String get instantCashButton => 'เงินทันที';

  @override
  String instantCashSnack(String amount) {
    return 'เงินทันที! +$amount เหรียญ';
  }

  @override
  String get adNotReadySnack => 'โฆษณายังไม่พร้อม ลองใหม่อีกสักครู่นะ';

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'ปลดล็อก $cost เหรียญ';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount เหรียญ/วินาที ต่อระดับ';
  }

  @override
  String buyButton(String cost) {
    return '$cost เหรียญ';
  }

  @override
  String get buyModeMax => 'MAX';

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · $seconds วิ';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'ลูกค้า VIP! +$cash เหรียญ, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'ได้รับ +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'ลบโฆษณาแล้ว ขอบคุณ!';

  @override
  String iapStarterSnack(String amount) {
    return 'แพ็กเริ่มต้น: +$amount 💎';
  }

  @override
  String get genTraDen => 'ชาดำ';

  @override
  String get genTranChau => 'ไข่มุก';

  @override
  String get genThach => 'เฉาก๊วย';

  @override
  String get genPudding => 'พุดดิ้ง';

  @override
  String get genKemNuong => 'ชานมครีมบรูเล่';

  @override
  String get genMatcha => 'มัทฉะถัง';

  @override
  String get stage1 => 'รถเข็นริมทาง';

  @override
  String get stage2 => 'คีออสก์เล็ก';

  @override
  String get stage3 => 'เครือคาเฟ่หรู';

  @override
  String gemShopTitle(String gems) {
    return 'ร้านค้า 💎 (มี $gems)';
  }

  @override
  String get gemBoostName => 'เพิ่มรายได้';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% รายได้ถาวรต่อระดับ';
  }

  @override
  String get offlineCapName => 'ตู้เย็นออฟไลน์';

  @override
  String offlineCapDesc(int hours) {
    return '+$hours ชม. เพดานออฟไลน์ต่อระดับ';
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
  String get gemInstantStageName => 'ปลดล็อกด่านทันที';

  @override
  String gemInstantStageDesc(String stage) {
    return 'ปลดล็อก $stage เลย ข้ามค่า Coin';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return 'ปลดล็อก $stage แล้ว!';
  }

  @override
  String get gemTimeSkipName => 'เร่งเวลา';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'รับผลผลิต $hours ชม. ทันที';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return 'เหลือ $remaining/$max ครั้งวันนี้';
  }

  @override
  String get iapSectionTitle => 'ซื้อด้วยเงินจริง';

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get close => 'ปิด';

  @override
  String get iapGemsDesc => 'เติมเพชรเพื่อซื้อไอเทมในร้านค้า';

  @override
  String get iapRemoveAdsTitle => 'ลบโฆษณา';

  @override
  String get iapRemoveAdsDesc =>
      'ข้ามโฆษณาทั้งหมด — ยังได้รับรางวัลครบโดยไม่ต้องดู';

  @override
  String get iapStarterTitle => 'แพ็กเริ่มต้น';

  @override
  String get iapStarterDesc => 'ครั้งเดียว: รับถุงเพชรใบใหญ่ทันที';

  @override
  String get prestigeTitle => 'แฟรนไชส์ 🏪';

  @override
  String prestigeIntro(String percent) {
    return '⭐ ดาวแต่ละดวงให้ +$percent% รายได้ถาวร';
  }

  @override
  String get prestigeStarsNow => 'ดาวปัจจุบัน';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'แฟรนไชส์เลย';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'โบนัสรวมหลังจากนั้น';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ รีเซ็ต Coin เลเวลอัปเกรด และด่าน (เพิร์ก Star เก็บบางส่วนได้)';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String prestigeConfirm(String stars) {
    return 'แฟรนไชส์ (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'ไม่พอ';

  @override
  String get prestigeAdConfirm => 'ดูโฆษณา: รับเหรียญเริ่มต้นเพิ่ม';

  @override
  String prestigeSuccess(String stars) {
    return 'แฟรนไชส์สำเร็จ! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'ยินดีต้อนรับกลับ! 🧋';

  @override
  String offlineBody(String amount) {
    return 'ร้านยังขายต่อขณะที่คุณไม่อยู่\nคุณได้รับ $amount เหรียญ';
  }

  @override
  String get offlineClaim => 'รับ';

  @override
  String get offlineDoubleButton => 'ดูโฆษณา ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'เพิ่มเป็นสองเท่า! +$amount เหรียญ';
  }

  @override
  String get howToPlayTitle => 'วิธีเล่น';

  @override
  String get htpTap => 'แตะแก้วเพื่อชงชาและรับเหรียญ';

  @override
  String get htpBuy => 'ซื้ออัปเกรดเพื่อรับรายได้อัตโนมัติทุกวินาที';

  @override
  String get htpStage =>
      'สะสมเหรียญเพื่อปลดล็อกด่านใหม่ที่มีเครื่องดื่มหรูขึ้น';

  @override
  String get htpCat => 'แตะแมวนำโชคเพื่อรับโกลเด้นรัช ×3 ชั่วครู่';

  @override
  String get htpVip => 'บริการลูกค้า VIP เพื่อรับเพชร 💎';

  @override
  String get htpGems => 'ใช้เพชรในร้านค้าเพื่อซื้ออัปเกรดถาวร';

  @override
  String get htpPrestige => 'แฟรนไชส์เพื่อเริ่มใหม่และรับดาว — โบนัสรายได้ถาวร';

  @override
  String get htpOffline =>
      'ร้านยังขายต่อขณะที่คุณไม่อยู่ — กลับมารับเงินออฟไลน์';

  @override
  String get htpNumberFormat =>
      'ตัวเลขใหญ่ใช้ตัวย่อ: K=พัน, M=ล้าน, B=พันล้าน, T=ล้านล้าน จากนั้นเป็น aa, bb, cc... — แต่ละขั้นมากกว่าขั้นก่อนหน้า 1,000 เท่า';

  @override
  String get language => 'ภาษา';

  @override
  String get languageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String get dailyTitle => 'เช็คอินรายวัน';

  @override
  String get dailyPrompt => 'รับของขวัญเข้าสู่ระบบวันนี้!';

  @override
  String get adNotReady => 'โฆษณายังไม่พร้อม ลองอีกครั้งในอีกไม่กี่วินาที';

  @override
  String get accessoryBat => 'ค้างคาวราตรี';

  @override
  String get accessoryJackOLantern => 'ฟักทองฮาโลวีน';

  @override
  String get accessoryGhost => 'ผีน้อยใจดี';

  @override
  String get accessoryWitch => 'แม่มดน้อย';

  @override
  String get accessorySnowman => 'มนุษย์หิมะ';

  @override
  String get accessoryChristmasTree => 'ต้นคริสต์มาส';

  @override
  String get accessoryReindeer => 'กวางเรนเดียร์';

  @override
  String get accessorySanta => 'ซานตาคลอส';

  @override
  String get accessoryFirecracker => 'ประทัด';

  @override
  String get accessoryRedEnvelope => 'อั่งเปา';

  @override
  String get accessoryApricotBlossom => 'ดอกเหมย';

  @override
  String get accessoryGoldenGoat => 'แพะทอง';

  @override
  String get festivalHalloween => 'ฮาโลวีน';

  @override
  String get festivalChristmas => 'คริสต์มาส';

  @override
  String get festivalTet => 'ตรุษจีน';

  @override
  String get festivalSection => 'เครื่องประดับเทศกาล (เฉพาะกิจ)';

  @override
  String festivalPackTitle(String name) {
    return 'แพ็ก$name';
  }

  @override
  String festivalPackDesc(int gems) {
    return 'แต่ละแพ็กได้ไอเทมเฉพาะกิจที่ยังไม่มี 1 ชิ้น ขายเฉพาะช่วงเทศกาล หากมีครบแล้วจะได้ $gems 💎 แทน ไม่สามารถซื้อขายได้';
  }

  @override
  String get accessoryChampagne => 'แชมเปญฉลอง';

  @override
  String get accessoryPartyPopper => 'ปืนปาร์ตี้';

  @override
  String get accessoryFireworks => 'ดอกไม้ไฟ';

  @override
  String get accessoryGoldenSparkler => 'ดอกไม้ไฟทอง';

  @override
  String get accessoryLoveLetter => 'จดหมายรัก';

  @override
  String get accessoryRose => 'กุหลาบแดง';

  @override
  String get accessoryChocolate => 'ช็อกโกแลต';

  @override
  String get accessoryCupidArrow => 'ลูกศรคิวปิด';

  @override
  String get accessoryTulip => 'ทิวลิป';

  @override
  String get accessoryBouquet => 'ช่อดอกไม้';

  @override
  String get accessoryLipstick => 'ลิปสติก';

  @override
  String get accessoryPrincess => 'เจ้าหญิง';

  @override
  String get accessoryMooncake => 'ขนมไหว้พระจันทร์';

  @override
  String get accessoryRabbit => 'กระต่ายบนดวงจันทร์';

  @override
  String get accessoryFullMoon => 'พระจันทร์เต็มดวง';

  @override
  String get accessoryLionDance => 'ระบำสิงโต';

  @override
  String get festivalNewYear => 'ปีใหม่';

  @override
  String get festivalValentine => 'วันวาเลนไทน์';

  @override
  String get festivalWomensDay => 'วันสตรีสากล';

  @override
  String get festivalMidAutumn => 'เทศกาลไหว้พระจันทร์';

  @override
  String get dailyClaim => 'รับ';

  @override
  String get accessoryWheelTitle => 'วงล้อเครื่องประดับ';

  @override
  String accessoryWheelAd(int n) {
    return 'หมุน: ดูโฆษณา (เหลือ $n)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return 'หมุน $gems 💎';
  }

  @override
  String get accessoryPackButton => 'แพ็กเครื่องประดับ';

  @override
  String get accessoryPackTitle => 'แพ็กเครื่องประดับ';

  @override
  String get accessoryPackBasic => 'แพ็กธรรมดา';

  @override
  String get accessoryPackRare => 'แพ็กหายาก (หายากขึ้นไป)';

  @override
  String get accessoryPackEpic => 'แพ็กมหากาพย์ (มหากาพย์ขึ้นไป)';

  @override
  String get accessoryPackSeason =>
      'อีเวนต์ตามฤดูกาล: ลด 25% และโอกาสมหากาพย์/ตำนาน ×2!';

  @override
  String get accessoryAdDropButton => 'ดูโฆษณา: รับเครื่องประดับ +1';

  @override
  String dailyStreakAtRisk(int days) {
    return 'คุณพลาดไป 1 วัน — สตรีค $days วันกำลังจะหาย!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return 'กู้สตรีค ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => 'ดูโฆษณาเพื่อกู้สตรีค';

  @override
  String get dailySkipRestore => 'ข้ามและเริ่มใหม่';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return 'สตรีค $days วัน 🔥';
  }

  @override
  String dailyMilestoneBonus(String gems) {
    return 'โบนัสเหรียญสตรีค: +$gems 💎';
  }

  @override
  String dailyVipBonus(int percent) {
    return 'โบนัส VIP: +$percent% 💎';
  }

  @override
  String get achievementsTitle => 'ความสำเร็จ';

  @override
  String achEarn(String amount) {
    return 'หาเงินรวม $amount เหรียญ';
  }

  @override
  String achStage(int n) {
    return 'ไปถึงระยะ $n';
  }

  @override
  String achLevels(int n) {
    return 'มีเลเวลอัปเกรดรวม $n';
  }

  @override
  String achPrestige(int n) {
    return 'แฟรนไชส์ ($n★ ขึ้นไป)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 ปลดล็อกความสำเร็จ! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'ร้านดาว ⭐';

  @override
  String prestigeShopSpendable(String stars) {
    return 'เหลือ $stars ⭐ ให้ใช้';
  }

  @override
  String get prestigeIncomeName => 'รายได้สุดยอด';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% รายได้ถาวรต่อเลเวล';
  }

  @override
  String get prestigeTapName => 'แตะสุดยอด';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% ค่าการแตะต่อเลเวล';
  }

  @override
  String get prestigeOfflineName => 'ซุปเปอร์ออฟไลน์';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% รายได้ตอนไม่อยู่ ต่อเลเวล';
  }

  @override
  String get prestigeStartCashName => 'เงินทุนตั้งต้น';

  @override
  String get prestigeStartCashDesc =>
      'รับ Coin ทันทีหลังแฟรนไชส์ (เพิ่มต่อเลเวล)';

  @override
  String get prestigeKeepStageName => 'เก็บด่าน';

  @override
  String get prestigeKeepStageDesc =>
      'เก็บด่านเพิ่ม 1 ด่านหลังแฟรนไชส์ ต่อเลเวล';

  @override
  String get prestigeDiscountName => 'ซื้อยกล็อต';

  @override
  String prestigeDiscountDesc(int percent) {
    return '-$percent% ค่าอัปเกรด ต่อเลเวล';
  }

  @override
  String get prestigeAutoBuyName => 'ซื้ออัตโนมัติ';

  @override
  String get prestigeAutoBuyDesc =>
      'ปลดล็อกสวิตช์ซื้อแหล่งที่คุ้มที่สุดอัตโนมัติ';

  @override
  String get autoBuyLabel => 'อัตโนมัติ';

  @override
  String prestigeStarCost(String cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'แตะชงชา $n ครั้ง';
  }

  @override
  String questBuy(int n) {
    return 'ซื้ออัปเกรด $n รายการ';
  }

  @override
  String questRepeatEarn(String amount) {
    return 'หาเงินเพิ่มอีก $amount Coin';
  }

  @override
  String get questClaim => 'รับ';

  @override
  String get iapDoubleTitle => 'x2 รายได้ (ถาวร)';

  @override
  String get iapDoubleDesc => 'เพิ่มรายได้อัตโนมัติเป็นสองเท่า ตลอดไป';

  @override
  String get iapDoubleSnack => 'เปิด x2 รายได้ถาวรแล้ว!';

  @override
  String get iapColdStorageTitle => 'ห้องเย็นถาวร';

  @override
  String iapColdStorageDesc(Object hours) {
    return 'เพิ่มเพดานรายได้ออฟไลน์อีก $hours ชั่วโมง ตลอดไป';
  }

  @override
  String iapColdStorageSnack(Object hours) {
    return 'เพิ่มเพดานออฟไลน์อีก $hours ชั่วโมงแล้ว!';
  }

  @override
  String get iapComboTitle => 'คอมโบ: ไม่มีโฆษณา + รายได้ x2';

  @override
  String get iapComboDesc =>
      'ลบโฆษณาทั้งหมดและเพิ่มรายได้อัตโนมัติ x2 ตลอดไป ถูกกว่าซื้อแยก';

  @override
  String get iapComboSnack => 'ลบโฆษณาและเปิดรายได้ x2 ถาวรแล้ว!';

  @override
  String get topupTitle => 'รางวัลเติมเงิน & VIP';

  @override
  String get topupOpen => '👑 เติมเงิน & VIP';

  @override
  String topupSummary(Object points) {
    return 'VIP EXP $points';
  }

  @override
  String topupBuff(Object now, Object percent) {
    return 'VIP แต่ละเลเวล: รายได้ +$percent% (ตอนนี้ +$now%)';
  }

  @override
  String get topupNote =>
      'ซื้อในร้าน: ประมาณ 100 EXP ต่อ 1 ดอลลาร์ (แพ็กใหญ่ได้มากกว่า) การซื้อ EXP ด้วย 💎 แพงกว่ามากและมีเพดาน รับรางวัลแต่ละขั้นได้ครั้งเดียว';

  @override
  String topupTier(Object points) {
    return '$points EXP';
  }

  @override
  String get topupAccessory => '+ เครื่องประดับ';

  @override
  String vipTierPerks(int buff, String daily, String monthly, String weekly) {
    return 'รายวัน +$daily 💎 · รายสัปดาห์ +$weekly 💎 · รายเดือน +$monthly 💎 (พร้อมเครื่องประดับ) · รายได้ +$buff%';
  }

  @override
  String get topupClaim => 'รับ';

  @override
  String get topupClaimed => 'รับแล้ว';

  @override
  String topupClaimSnack(Object gems) {
    return 'รับ +$gems 💎 แล้ว';
  }

  @override
  String get vipName1 => 'ขาประจำ';

  @override
  String get vipName2 => 'คนรักชา';

  @override
  String get vipName3 => 'เซียนชา';

  @override
  String get vipName4 => 'แขกผู้มีเกียรติ';

  @override
  String get vipName5 => 'เจ้าของร้าน';

  @override
  String get vipName6 => 'เศรษฐีบ็อบา';

  @override
  String get vipName7 => 'เจ้าพ่อธุรกิจ';

  @override
  String get vipName8 => 'ราชวงศ์';

  @override
  String get vipName9 => 'ตำนาน';

  @override
  String get vipName10 => 'จักรพรรดิบ็อบา';

  @override
  String vipBuyExp(Object exp, Object gems) {
    return 'ซื้อ $exp EXP · $gems 💎';
  }

  @override
  String vipBuyExpSnack(Object exp) {
    return '+$exp VIP EXP';
  }

  @override
  String vipBuyExpCapped(Object cap) {
    return 'EXP ที่ซื้อด้วย 💎 ถึงเพดานแล้ว ($cap) เลเวลที่สูงกว่านี้ต้องเติมเงินจริง';
  }

  @override
  String get vipBenefitsTitle => 'สิทธิพิเศษ VIP';

  @override
  String get vipBenefitsLocked =>
      'ถึง VIP 1 เพื่อปลดล็อกของขวัญรายวัน/รายสัปดาห์/รายเดือน';

  @override
  String get vipDaily => 'รายวัน';

  @override
  String get vipWeekly => 'รายสัปดาห์';

  @override
  String get vipMonthly => 'รายเดือน';

  @override
  String get vipHowToTitle => 'คู่มือ VIP';

  @override
  String get vipHtp1 =>
      '👑 VIP มี 10 เลเวล แต่ละเลเวลมีฉายา เลเวลของคุณแสดงเป็นป้าย \"VIP n\" ข้างชื่อบนกระดานอันดับและในกิลด์ ตั้งแต่ VIP 5 ชื่อของคุณจะมีบรรทัดฉายาในทุกกระดานอันดับ มีจุดเขียวเมื่อออนไลน์ และทุกคนที่ออนไลน์เห็นแบนเนอร์เมื่อคุณเข้าเกม';

  @override
  String vipHtp2(Object cap, Object exp, Object gems) {
    return '⭐ EXP VIP: ซื้อด้วยเงินจริงในร้าน (ประมาณ 100 EXP ต่อ 1 ดอลลาร์ แพ็ก 💎 ใหญ่ได้เพิ่ม) หรือซื้อด้วย 💎 ($gems 💎 → $exp EXP สูงสุด $cap EXP — ดังนั้น VIP 7–10 ต้องเติมเงินจริง)';
  }

  @override
  String vipHtp3(Object percent) {
    return '📈 สิทธิพิเศษ: รายได้อัตโนมัติ +$percent% ต่อเลเวล (ถาวร) และรางวัลครั้งเดียวทุกเลเวล (💎 และเครื่องประดับในบางเลเวล)';
  }

  @override
  String get vipHtp4 =>
      '🎁 ของขวัญรายวัน / รายสัปดาห์ / รายเดือน: 💎 เพิ่มตามเลเวล รายสัปดาห์และรายเดือนมีเครื่องประดับด้วย รีเซ็ตเวลา 00:00 UTC (สัปดาห์เริ่มวันจันทร์ เดือนตามปฏิทิน)';

  @override
  String get vipHtp5 =>
      '♻️ ไม่ใช่ VIP Pass 30 วัน: VIP Pass (ไม่มีโฆษณา รายได้ x2…) มีอายุจำกัด เลเวล VIP นี้ไม่หมดอายุ และรวมกันได้';

  @override
  String get vipHtp6 => '📍 เปิดที่ร้านค้า 💎 → ปุ่ม 👑';

  @override
  String get vipLbTitle => 'กระดานอันดับ VIP';

  @override
  String get vipLbEmpty => 'ยังไม่มีใครในกระดานอันดับ VIP';

  @override
  String get vipLbNoVip => 'ถึง VIP 1 เพื่อมีชื่อบนกระดานอันดับ VIP';

  @override
  String vipLbExp(Object exp) {
    return '$exp EXP';
  }

  @override
  String vipOnlineBanner(Object nickname, Object title) {
    return '👑 $title $nickname เพิ่งออนไลน์!';
  }

  @override
  String get emailGateTitle => 'ผูกอีเมลก่อนเติมเงิน';

  @override
  String get emailGateBody =>
      'การซื้อจะผูกกับบัญชีของคุณ เพื่อกู้คืนได้หากเปลี่ยนเครื่องหรือเกิดปัญหา กรุณาผูกอีเมลก่อน (ฟรี ใช้เวลาประมาณหนึ่งนาที)';

  @override
  String get emailGateOnlineTitle => 'ผูกอีเมลเพื่อเล่นออนไลน์';

  @override
  String get emailGateOnlineBody =>
      'กิลด์ ตลาด สนามประลอง และกระดานอันดับต้องใช้บัญชีที่ผูกอีเมล เพื่อให้ข้อมูลของคุณปลอดภัยและกู้คืนได้เมื่อเปลี่ยนเครื่องหรือติดตั้งใหม่ ฟรีและใช้เวลาประมาณหนึ่งนาที';

  @override
  String get emailGateLink => 'ผูกอีเมล';

  @override
  String iapGemsFirstSnack(Object amount) {
    return 'ได้รับ +$amount 💎 — โบนัสซื้อครั้งแรกคูณสอง!';
  }

  @override
  String get iapFirstBuyNote => '🎉 ซื้อครั้งแรก: รับ 💎 สองเท่า!';

  @override
  String get guildGiftTooltip => 'ส่ง 💎 เป็นของขวัญ';

  @override
  String guildGiftTitle(Object nickname) {
    return 'ส่ง 💎 ให้ $nickname';
  }

  @override
  String guildGiftHint(Object cap, Object days) {
    return 'สูงสุด $cap 💎 ต่อวัน ผู้รับมี $days วันในการรับของขวัญ';
  }

  @override
  String guildGiftSent(Object amount, Object nickname) {
    return 'ส่ง $amount 💎 ให้ $nickname แล้ว';
  }

  @override
  String guildGiftInboxTitle(Object count) {
    return '🎁 ของขวัญจากสมาชิกกิลด์ ($count)';
  }

  @override
  String guildGiftFrom(Object amount, Object nickname) {
    return '$nickname · +$amount 💎';
  }

  @override
  String guildGiftClaimed(Object amount) {
    return 'รับ +$amount 💎 แล้ว';
  }

  @override
  String guildErrGiftLimit(Object receive, Object send) {
    return 'วันนี้ถึงขีดจำกัดการส่งของขวัญแล้ว (ส่งได้สูงสุด $send 💎/วัน ผู้รับหนึ่งคนรับได้สูงสุด $receive 💎/วัน)';
  }

  @override
  String get vipTitlePick => 'ฉายาที่แสดงใต้ชื่อ';

  @override
  String get vipTitleAuto => 'อัตโนมัติ (สูงสุด)';

  @override
  String get vipTitleHide => 'ซ่อน';

  @override
  String get marketFilterWish => 'อยากได้';

  @override
  String get guildErrGemsSpend => '💎 ไม่พอ';

  @override
  String guildCreateVipDiscount(Object percent) {
    return 'สิทธิ์ VIP: ลด $percent% ค่าสร้างกิลด์';
  }

  @override
  String get guildLbTabVip => 'VIP';

  @override
  String get guildLbVipEmpty => 'ยังไม่มีกิลด์ที่มีสมาชิก VIP บนกระดาน';

  @override
  String get guildLbVipNote =>
      'VIP EXP รวมของสมาชิก (นับเฉพาะคนที่ตั้งชื่อเล่นแล้ว)';

  @override
  String guildVipExpTotal(Object exp) {
    return '$exp EXP';
  }

  @override
  String guildVipBonusLine(Object members, Object pct) {
    return 'โบนัส VIP: สมาชิก VIP $members คน → รายได้ทั้งกิลด์ +$pct%';
  }

  @override
  String guildVipBonusHint(Object cap, Object level, Object per) {
    return 'สมาชิกระดับ VIP $level+ แต่ละคนเพิ่มรายได้ทั้งกิลด์ +$per% (สูงสุด +$cap%)';
  }

  @override
  String get reminderVipTitle => '👑 ของขวัญ VIP กำลังรอคุณ';

  @override
  String get reminderVipDailyBody =>
      'ของขวัญ VIP รายวัน เช็กอิน และภารกิจพร้อมแล้ว มารับเลย!';

  @override
  String get reminderVipWeeklyBody =>
      'ของขวัญ VIP รายสัปดาห์ (พร้อมเครื่องประดับ) พร้อมแล้ว!';

  @override
  String get reminderVipMonthlyBody =>
      'ของขวัญ VIP รายเดือนมาแล้ว ชิ้นใหญ่กำลังรออยู่!';

  @override
  String get reminderVipUnclaimedBody =>
      'วันนี้คุณยังมีของขวัญ VIP ที่ยังไม่ได้รับ';

  @override
  String get dealTitle => 'ดีลวันนี้';

  @override
  String dealResets(Object time) {
    return 'เปลี่ยนเวลา 00:00 UTC · เหลือ $time';
  }

  @override
  String get dealClaimed => 'ซื้อแล้ววันนี้ พรุ่งนี้มาใหม่นะ';

  @override
  String dealGotAccessory(Object name) {
    return 'ได้รับ $name!';
  }

  @override
  String get dealUnavailable => 'ตอนนี้ยังซื้อดีลนี้ไม่ได้';

  @override
  String get guildBossTitle => 'บอสประจำสัปดาห์ของกิลด์';

  @override
  String guildBossTier(Object tier) {
    return 'ระดับ $tier';
  }

  @override
  String guildBossProgress(Object damage, Object hp) {
    return '$damage / $hp ความเสียหาย';
  }

  @override
  String guildBossClaim(Object coins, Object gems) {
    return 'รับหีบ: +$gems 💎 +$coins เหรียญกิลด์';
  }

  @override
  String get guildBossClaimedLabel => 'รับหีบแล้ว';

  @override
  String guildBossClaimedSnack(Object coins, Object gems) {
    return 'หีบบอส: +$gems 💎 +$coins เหรียญกิลด์';
  }

  @override
  String get guildBossErrAlive => 'บอสยังไม่ถูกโค่น';

  @override
  String get guildBossName1 => 'มังกรไข่มุก';

  @override
  String get guildBossName2 => 'ไททันน้ำแข็งใส';

  @override
  String get guildBossName3 => 'คราเคนชาดำ';

  @override
  String get guildBossName4 => 'หมีพุดดิ้ง';

  @override
  String get guildBossName5 => 'เสือมัทฉะ';

  @override
  String get guildBossName6 => 'ฟีนิกซ์ชีสโฟม';

  @override
  String get accessoryVipWatch => 'นาฬิกาหรู';

  @override
  String get accessoryVipLuggage => 'กระเป๋าเดินทางหรู';

  @override
  String get accessoryVipBriefcase => 'กระเป๋าเอกสารผู้บริหาร';

  @override
  String get accessoryVipTophat => 'หมวกทรงสูง';

  @override
  String get accessoryVipRacecar => 'ซูเปอร์คาร์';

  @override
  String get accessoryVipHeli => 'เฮลิคอปเตอร์';

  @override
  String get accessoryVipYacht => 'เรือยอชต์';

  @override
  String get accessoryVipJet => 'เครื่องบินส่วนตัว';

  @override
  String get vipShopOpen => '🛍️ ร้านค้า VIP';

  @override
  String get vipShopTitle => 'ร้านค้า VIP';

  @override
  String vipCoinsLabel(Object n) {
    return 'เหรียญ VIP: $n';
  }

  @override
  String vipShopLocked(Object level) {
    return 'ต้องการ VIP $level';
  }

  @override
  String get vipShopOwned => 'มีแล้ว';

  @override
  String get vipShopNeedCoins => 'เหรียญ VIP ไม่พอ';

  @override
  String vipShopBoughtSnack(Object name) {
    return 'ได้รับ $name!';
  }

  @override
  String get vipShopHint =>
      'รับเหรียญ VIP จากการรับของขวัญ VIP รายวัน รายสัปดาห์ และรายเดือน';

  @override
  String vipBenefitSnack(Object coins, Object gems) {
    return 'รับ +$gems 💎 +$coins เหรียญ VIP แล้ว';
  }

  @override
  String get vipItemsTitle => 'ของพิเศษ VIP';

  @override
  String vipShopPrice(Object n) {
    return '$n เหรียญ VIP';
  }

  @override
  String get vipEntryHint =>
      'เติมเงินเพื่อปลดล็อกของขวัญ VIP รายวัน รายสัปดาห์ และรายเดือน';

  @override
  String get settingsWebsite => 'เว็บไซต์';

  @override
  String get settingsWebGuide => 'คู่มือการเล่น (เว็บ)';

  @override
  String get guideOnWeb => 'ดูคู่มือฉบับเต็มบนเว็บไซต์';

  @override
  String get webOpenFailed =>
      'เปิดเว็บไซต์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';

  @override
  String get webBoardOpenTip => 'ดูกระดานอันดับนี้บนเว็บ';

  @override
  String get webBoardShareTip => 'แชร์ลิงก์กระดานอันดับ';

  @override
  String webBoardShareText(Object url) {
    return 'ดูกระดานอันดับของ Boba Empire: $url';
  }

  @override
  String get settingsShareProfile => 'แชร์โปรไฟล์อันดับของฉัน';

  @override
  String profileShareText(String name, String url) {
    return 'ดูอันดับของ $name ใน Boba Empire: $url';
  }

  @override
  String profileTitle(String name) {
    return 'โปรไฟล์: $name';
  }

  @override
  String get profileBoardIncome => 'รายได้';

  @override
  String get profileBoardPearls => 'ไข่มุก';

  @override
  String get profileBoardCollection => 'สะสม';

  @override
  String get profileBoardSpeed => 'สปีดรันเนื้อเรื่อง';

  @override
  String get profileBoardVip => 'VIP';

  @override
  String get profileNoRanks => 'ยังไม่อยู่ในอันดับใด ๆ';

  @override
  String get myProfileTitle => 'โปรไฟล์ของฉัน';

  @override
  String get myProfileChangeAvatar => 'เปลี่ยนรูปประจำตัว';

  @override
  String get myProfileRemoveAvatar => 'ลบรูป';

  @override
  String get myProfileAvatarFail =>
      'อัปโหลดรูปไม่สำเร็จ ต้องมีอินเทอร์เน็ตและบัญชีที่ผูกอีเมล';

  @override
  String get myProfileAvatarTooBig => 'รูปใหญ่เกินไป เลือกรูปอื่น';

  @override
  String get myProfileNoNickname =>
      'ยังไม่มีชื่อเล่น เปิดอันดับใดก็ได้เพื่อตั้งชื่อ';

  @override
  String get myProfileStatStage => 'ช่วง';

  @override
  String get myProfileStatEarned => 'รายได้รวม';

  @override
  String get myProfileStatStars => 'ดาว';

  @override
  String get myProfileStatAscend => 'เลื่อนขั้น';

  @override
  String get myProfileStatVip => 'VIP';

  @override
  String get myProfileStatCollection => 'สะสม';

  @override
  String get myProfileStatAchievements => 'ความสำเร็จ';

  @override
  String get myProfileRanks => 'ดูอันดับของฉัน';

  @override
  String get myProfileShare => 'แชร์โปรไฟล์';

  @override
  String get avatarReport => 'รายงานรูป';

  @override
  String get avatarReportConfirm => 'รายงานรูปประจำตัวนี้ว่าไม่เหมาะสมหรือไม่?';

  @override
  String get avatarReportSent => 'ส่งรายงานแล้ว ขอบคุณ!';

  @override
  String get avatarReportFail =>
      'ส่งรายงานไม่สำเร็จ ต้องมีอินเทอร์เน็ตและบัญชีที่ผูกอีเมล';

  @override
  String get titlePickerTitle => 'ฉายา';

  @override
  String get titlePickerNone => 'ไม่ใช้ฉายา';

  @override
  String get titlePickerHint =>
      'ปลดล็อกด้วยความคืบหน้า ฉายาที่เลือกจะแสดงในโปรไฟล์สาธารณะ (ต้องมีบัญชีที่ผูกอีเมล)';

  @override
  String get playerTitleTycoon => 'เจ้าของเชน';

  @override
  String get playerTitleTycoonHint => 'ถึงช่วง 5';

  @override
  String get playerTitleMogul => 'เศรษฐี';

  @override
  String get playerTitleMogulHint => 'ถึงช่วง 10';

  @override
  String get playerTitleLegend => 'ตำนาน';

  @override
  String get playerTitleLegendHint => 'ถึงช่วง 18';

  @override
  String get playerTitleTimewalker => 'นักเดินทางข้ามเวลา';

  @override
  String get playerTitleTimewalkerHint => 'เลื่อนขั้นอย่างน้อย 1 ครั้ง';

  @override
  String get playerTitleStargazer => 'นักเก็บดาว';

  @override
  String get playerTitleStargazerHint => 'มี 50 ดาว';

  @override
  String get playerTitleCollector => 'นักสะสม';

  @override
  String get playerTitleCollectorHint => 'มีอุปกรณ์ 100 ชิ้น';

  @override
  String get playerTitleVip => 'ขุนนาง VIP';

  @override
  String get playerTitleVipHint => 'ถึง VIP 5';

  @override
  String get profileViewButton => 'โปรไฟล์';

  @override
  String get profileOpenWeb => 'ดูบนเว็บ';

  @override
  String get refEntry => '👥 ชวนเพื่อน';

  @override
  String refEntryNote(Object gems) {
    return 'รับ $gems 💎 ต่อเพื่อนที่เข้าร่วมทุกคน';
  }

  @override
  String get refTitle => 'ชวนเพื่อน';

  @override
  String get refYourCode => 'รหัสเชิญของคุณ';

  @override
  String get refCopy => 'คัดลอกรหัส';

  @override
  String get refCopied => 'คัดลอกรหัสแล้ว';

  @override
  String get refShare => 'แชร์';

  @override
  String refShareText(Object code) {
    return 'มาเล่น Boba Empire กับฉัน! ใช้รหัสเชิญ $code รับ 💎 โบนัส: https://bobaempiregame.com';
  }

  @override
  String refStats(Object invited, Object max, Object reached) {
    return 'เชิญแล้ว: $invited/$max · ถึงเป้าหมาย: $reached';
  }

  @override
  String refRule(Object gems, Object stage) {
    return 'คุณได้รับ $gems 💎 ต่อเพื่อนที่ถึงด่าน $stage เพื่อนของคุณก็ได้ 💎 เมื่อกรอกรหัสของคุณ';
  }

  @override
  String refClaim(Object gems) {
    return 'รับ +$gems 💎';
  }

  @override
  String refClaimedSnack(Object gems) {
    return 'รับ +$gems 💎 แล้ว';
  }

  @override
  String get refEnterTitle => 'มีรหัสของเพื่อนไหม?';

  @override
  String get refEnterHint => 'รหัสเชิญ';

  @override
  String get refRedeem => 'ใช้รหัส';

  @override
  String refRedeemedSnack(Object gems) {
    return 'รหัสถูกต้อง: +$gems 💎';
  }

  @override
  String get refErrEmail => 'กรุณาผูกอีเมลก่อน';

  @override
  String get refErrNotFound => 'ไม่พบรหัสนี้';

  @override
  String get refErrInvalid => 'คุณใช้รหัสนี้ไม่ได้';

  @override
  String get refErrAlready => 'คุณใช้รหัสเชิญไปแล้ว';

  @override
  String get refErrFull => 'รหัสนี้เชิญครบจำนวนแล้ว';

  @override
  String get refErrNothing => 'ยังไม่มีอะไรให้รับ';

  @override
  String get refErrNetwork => 'เครือข่ายมีปัญหา ลองใหม่อีกครั้ง';

  @override
  String get vipLbOpen => 'กระดานอันดับ VIP';

  @override
  String get rewardsTitle => 'หาเพิ่ม 🎁';

  @override
  String get dailyHubTitle => 'ภารกิจและของรางวัล';

  @override
  String get dailyHubTabDaily => 'รายวัน';

  @override
  String get dailyHubTabWeekly => 'รายสัปดาห์';

  @override
  String get dailyHubTabRewards => 'รางวัล 🎁';

  @override
  String get rewardsChip => 'หาเพิ่ม';

  @override
  String rewardAutoTapName(int m) {
    return 'แตะอัตโนมัติ $m นาที';
  }

  @override
  String rewardAutoTapActive(String t) {
    return 'กำลังทำงาน · เหลือ $t';
  }

  @override
  String rewardAutoTapVip(int n) {
    return 'VIP $n+ ได้แตะอัตโนมัติถาวร';
  }

  @override
  String rewardAutoTapHint(int n) {
    return 'ดูโฆษณาเพื่อแตะแก้วอัตโนมัติ (VIP $n+ ปลดล็อกถาวร)';
  }

  @override
  String get rewardAutoTapSnack =>
      'เปิดแตะอัตโนมัติแล้ว! ได้แค่เหรียญ ไม่นับแต้มกิลด์หรือภารกิจ';

  @override
  String get rewardX2Name => 'x2 รายได้ 24 ชม.';

  @override
  String rewardX2Active(int hours) {
    return 'กำลังใช้ · เหลือ $hours ชม.';
  }

  @override
  String get rewardX2Snack => 'เปิด x2 รายได้ 24 ชม. แล้ว!';

  @override
  String rewardGemsName(int gems) {
    return 'รับ $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'เร่งเวลา $hours ชม.';
  }

  @override
  String get watchAd => 'ดูโฆษณา';

  @override
  String get piggyName => 'กระปุกออมสิน';

  @override
  String get piggyBreak => 'ทุบ';

  @override
  String piggySnack(String gems) {
    return 'กระปุก: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'VIP Pass (30 วัน) 👑';

  @override
  String get iapVipDesc => 'ไม่มีโฆษณา + x2 รายได้ + 50💎/วัน + เพดานออฟไลน์+';

  @override
  String get iapVipSnack => 'เปิด VIP 30 วันแล้ว! 👑';

  @override
  String get genDuongDen => 'นมสดน้ำตาลดำ';

  @override
  String get genBrulee => 'ชานมบรูเล่';

  @override
  String get genCheeseFoam => 'ชีสโฟม';

  @override
  String get genTraTraiCay => 'ชาผลไม้';

  @override
  String get genBobaVang => 'โบบาทองคำ';

  @override
  String get genGalaxy => 'ชานมกาแล็กซี';

  @override
  String get genQuantumTea => 'ชานมควอนตัม';

  @override
  String get genAiTea => 'ชานมเอไอ';

  @override
  String get genParallelTea => 'ชานมจักรวาลคู่ขนาน';

  @override
  String get genNftTea => 'ชานมเอ็นเอฟที';

  @override
  String get genTimeTea => 'ชานมข้ามเวลา';

  @override
  String get genMultidimTea => 'ชานมหลายมิติ';

  @override
  String get genBlackholeTea => 'ชานมหลุมดำ';

  @override
  String get genLightTea => 'ชานมความเร็วแสง';

  @override
  String get genRobotTea => 'ชานมหุ่นยนต์';

  @override
  String get genHologramTea => 'ชานมโฮโลแกรม';

  @override
  String get genLegendTea => 'ชานมตำนาน';

  @override
  String get genEternalTea => 'ชานมนิรันดร์';

  @override
  String get stage4 => 'โรงงานบรูเล่';

  @override
  String get stage5 => 'โรงงานชีสโฟม';

  @override
  String get stage6 => 'อาณาจักรระดับโลก';

  @override
  String get stage7 => 'เข้าตลาดหลักทรัพย์';

  @override
  String get stage8 => 'กลุ่มบริษัทข้ามธุรกิจ';

  @override
  String get stage9 => 'กองทุนการลงทุนระดับโลก';

  @override
  String get stage10 => 'ห่วงโซ่อุปทานฟาร์ม';

  @override
  String get stage11 => 'อาณาจักรเทคโนโลยีเอไอ';

  @override
  String get stage12 => 'ตำนานชานม';

  @override
  String get stage13 => 'สถาบันชานม';

  @override
  String get stage14 => 'เมืองชานม';

  @override
  String get stage15 => 'ชาติชานม';

  @override
  String get stage16 => 'พันธมิตรโลก';

  @override
  String get stage17 => 'ดาวชานม';

  @override
  String get stage18 => 'สัจธรรมชานม';

  @override
  String get genAcademyTea => 'ชานมสถาบัน';

  @override
  String get genScholarTea => 'ชานมนักปราชญ์';

  @override
  String get genCityTea => 'ชานมเมือง';

  @override
  String get genMetroTea => 'ชานมมหานคร';

  @override
  String get genNationTea => 'ชานมแห่งชาติ';

  @override
  String get genTreatyTea => 'ชานมสนธิสัญญา';

  @override
  String get genUnionTea => 'ชานมพันธมิตร';

  @override
  String get genWorldTea => 'ชานมสันติภาพโลก';

  @override
  String get genPlanetTea => 'ชานมดาวเคราะห์';

  @override
  String get genTerraformTea => 'ชานมปรับสภาพดาว';

  @override
  String get genTruthTea => 'ชานมสัจธรรม';

  @override
  String get genUltimateTea => 'ชานมสูงสุด';

  @override
  String get settingsTitle => 'ตั้งค่า';

  @override
  String get settingsSound => 'เสียง';

  @override
  String recipeGroupLocked(String name, int need, int learned) {
    return '🔒 $name — ปลดล็อกเมื่อจำสูตรของกลุ่มก่อนหน้าได้ $need สูตร ($learned/$need)';
  }

  @override
  String recipeGroupLockedFar(String name) {
    return '🔒 $name';
  }

  @override
  String recipeGroupOpened(String name) {
    return '🔓 ปลดล็อกกลุ่มใหม่แล้ว: $name!';
  }

  @override
  String recipeStreak(int n) {
    return '🔥 ทบทวนต่อเนื่อง: $n วัน';
  }

  @override
  String get recipeStreakToday => 'ทบทวนวันนี้แล้ว ✓';

  @override
  String get recipeStreakPending =>
      'วันนี้ยังไม่ได้ทบทวน — ฝึกสักรอบเพื่อรักษาสถิติ';

  @override
  String recipeRescueTitle(int n) {
    return 'คุณพลาดไปหนึ่งวัน — สถิติ $n วันกำลังจะหาย!';
  }

  @override
  String recipeRescueGems(int n) {
    return 'ช่วยไว้ด้วย $n 💎';
  }

  @override
  String get recipeRescueAd => 'ดูโฆษณาเพื่อช่วยไว้';

  @override
  String get recipeRescued => 'ช่วยสถิติไว้แล้ว!';

  @override
  String get recipeRescueNoGems => '💎 ไม่พอสำหรับช่วยสถิติ';

  @override
  String recipeStreakGems(int n, int gems) {
    return '🔥 ต่อเนื่อง $n วัน! +$gems 💎';
  }

  @override
  String recipeStreakFeedback(int n) {
    return '🔥 ทบทวนต่อเนื่อง: $n วัน';
  }

  @override
  String get recipeNotifyTitle => 'สูตรเครื่องดื่ม';

  @override
  String recipeNotifyStreak(int n) {
    return 'สถิติทบทวน $n วันกำลังจะขาด! ฝึกสักรอบเพื่อรักษาไว้';
  }

  @override
  String recipeNotifyDue(int n) {
    return 'มี $n สูตรต้องทบทวนวันนี้';
  }

  @override
  String get rlbTitle => 'ผู้เชี่ยวชาญสูตร';

  @override
  String get lbrBoardRecipes => 'ผู้เชี่ยวชาญสูตร';

  @override
  String get rlbEmpty =>
      'ยังไม่มีใครบนกระดาน มาเป็นคนแรกที่เชี่ยวชาญสูตรกันเถอะ!';

  @override
  String get rlbNoMastered =>
      'คุณยังไม่มีสูตรที่เชี่ยวชาญ จึงยังไม่อยู่บนกระดาน';

  @override
  String rlbMastered(int n) {
    return 'เชี่ยวชาญ $n สูตร';
  }

  @override
  String get rlbError => 'โหลดกระดานอันดับไม่ได้ ลองใหม่ภายหลัง';

  @override
  String recipeMilestone(int n) {
    return 'เชี่ยวชาญ $n สูตร — คุณได้รับของตกแต่ง!';
  }

  @override
  String get dqRecipe => 'ฝึกสูตรให้จบ 1 รอบ';

  @override
  String wqRecipeSessions(int n) {
    return 'ฝึกสูตรให้จบ $n รอบ';
  }

  @override
  String wqRecipeLevels(int n) {
    return 'เลื่อนระดับสูตร $n สูตร';
  }

  @override
  String get recipeHint => 'คำใบ้ (ดูโฆษณา)';

  @override
  String get recipeHintNoCount => 'คุณใช้คำใบ้ ข้อนี้จึงไม่นับระดับ';

  @override
  String get recipeDouble => 'ดูโฆษณาเพื่อรับเหรียญ 2 เท่า';

  @override
  String get recipeDoubled => 'รางวัลเหรียญเป็น 2 เท่าแล้ว!';

  @override
  String get recipeTitle => 'สูตรเครื่องดื่ม';

  @override
  String get recipeEntryNote => 'จำสูตรให้แม่น รับรางวัล';

  @override
  String get recipeEntryButton => 'เล่น';

  @override
  String recipeMastered(int n, int total) {
    return 'เชี่ยวชาญ $n/$total';
  }

  @override
  String recipeDueToday(int n) {
    return 'มี $n สูตรต้องทบทวนวันนี้';
  }

  @override
  String get recipeAllDone =>
      'วันนี้ทบทวนครบแล้ว! ยังฝึกเพิ่มได้ (ไม่นับระดับ)';

  @override
  String get recipePractice => 'ฝึก';

  @override
  String get recipeBox0 => 'ใหม่';

  @override
  String get recipeBox1 => 'เริ่มคุ้น';

  @override
  String get recipeBox2 => 'จำได้';

  @override
  String get recipeBox3 => 'เชี่ยวชาญ';

  @override
  String get recipeReviewToday => 'ทบทวน: วันนี้';

  @override
  String recipeReviewIn(int n) {
    return 'ทบทวนในอีก $n วัน';
  }

  @override
  String recipeQMissing(String name) {
    return '$name ขาดวัตถุดิบอะไร?';
  }

  @override
  String recipeQQuantity(String drink, String ingredient) {
    return '$drink: ต้องใช้ $ingredient เท่าไร?';
  }

  @override
  String recipeQFull(String name) {
    return 'สูตรที่ถูกต้องของ $name คือข้อใด?';
  }

  @override
  String get recipeCorrect => 'ถูกต้อง!';

  @override
  String get recipeWrongShort => 'ยังไม่ถูก — คำตอบที่ถูกต้องถูกไฮไลต์ไว้';

  @override
  String recipeLevelUp(String box, String name) {
    return '$name ขึ้นเป็น$boxแล้ว!';
  }

  @override
  String get recipePracticeOnly =>
      'ยังไม่ถึงเวลาทบทวน — ฝึกได้อย่างเดียว ระดับไม่เปลี่ยน';

  @override
  String get recipeNext => 'ต่อไป';

  @override
  String get recipeSeeResult => 'ดูผลลัพธ์';

  @override
  String get recipeResultTitle => 'ผลลัพธ์';

  @override
  String recipeScore(int correct, int total) {
    return 'ถูก $correct/$total ข้อ';
  }

  @override
  String recipeLevelUps(int n) {
    return '$n สูตรขึ้นระดับ';
  }

  @override
  String recipeRewardCash(String cash) {
    return 'รางวัล: +$cash เหรียญ';
  }

  @override
  String recipeRewardBoth(String cash, int gems) {
    return 'รางวัล: +$cash เหรียญ, +$gems 💎';
  }

  @override
  String get recipeAgain => 'ฝึกอีกครั้ง';

  @override
  String get recipeDone => 'เสร็จสิ้น';

  @override
  String get recipeDisclaimer =>
      'สูตรเป็นข้อมูลอ้างอิงสำหรับเกมเท่านั้น ไม่ใช่สูตรทางการของแบรนด์ใด';

  @override
  String get recipeIngredients => 'วัตถุดิบ';

  @override
  String walkerTipSnack(String amount) {
    return 'ลูกค้าให้ทิป +$amount เหรียญ 🧋';
  }

  @override
  String get settingsEffects => 'เอฟเฟกต์ภาพ';

  @override
  String get settingsEffectsAuto => 'อัตโนมัติ (ตามเครื่อง)';

  @override
  String get settingsEffectsHigh => 'สูง';

  @override
  String get settingsEffectsMedium => 'ปานกลาง';

  @override
  String get settingsEffectsLow => 'ต่ำ (ประหยัดแบตเตอรี่)';

  @override
  String get settingsEffectsOff => 'ปิด';

  @override
  String get settingsReset => 'เริ่มใหม่';

  @override
  String get settingsResetConfirm => 'ลบความคืบหน้าทั้งหมดและเริ่มใหม่?';

  @override
  String get navHome => 'หน้าหลัก';

  @override
  String get navShop => 'ร้านค้า';

  @override
  String get navPrestige => 'เพรสทีจ';

  @override
  String get navAchievements => 'รางวัล';

  @override
  String get wheelName => 'วงล้อนำโชค 🎡';

  @override
  String get spinFree => 'หมุนฟรี';

  @override
  String get spinAd => 'ดูโฆษณาเพื่อหมุน';

  @override
  String storyChapterLabel(int n) {
    return 'บทที่ $n';
  }

  @override
  String get storyContinue => 'ต่อไป';

  @override
  String get storyChoosePrompt => 'เลือกเส้นทางของคุณ — เปลี่ยนใจไม่ได้:';

  @override
  String get storyLogTitle => 'เนื้อเรื่อง';

  @override
  String get storyLogLocked => 'ยังไม่ปลดล็อก';

  @override
  String storyUnlockWhen(String cond) {
    return 'ปลดล็อกเมื่อ: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return 'ปลดล็อกหลัง $chapter';
  }

  @override
  String storyCondFirst(String name) {
    return '$name ครั้งแรก';
  }

  @override
  String get storyCondRival => 'เอาชนะคู่แข่ง';

  @override
  String storyCondAscension(int n, String name) {
    return '$name ครั้งที่ $n';
  }

  @override
  String storyCondM3(int n, String game) {
    return 'ผ่านด่าน $n ของ $game';
  }

  @override
  String get rivalEventTitle => 'คู่แข่งลงมือแล้ว!';

  @override
  String get rivalEventIgnore => 'เพิกเฉย';

  @override
  String get rivalMeterAhead => 'นำอยู่';

  @override
  String get rivalMeterEven => 'สูสี';

  @override
  String get rivalMeterBehind => 'กำลังเสียเปรียบ';

  @override
  String get rivalResolvedSnack => 'จัดการแล้ว คู่แข่งถอย';

  @override
  String get rivalIgnoredSnack => 'คุณปล่อยผ่าน — คู่แข่งได้ใจ';

  @override
  String get navArena => 'สนามประลอง';

  @override
  String get navCompete => 'แข่งขัน';

  @override
  String get arenaTitle => 'สนามประลอง';

  @override
  String get arenaIntro => 'ดวล 1v1 60 วินาที ใครได้เหรียญเยอะกว่าชนะ!';

  @override
  String get arenaStartButton => 'หาคู่แข่ง';

  @override
  String get arenaModeTap => 'แข่งแตะ';

  @override
  String get arenaModeMatch3 => 'ไข่มุกร่วง';

  @override
  String get arenaMatch3Intro =>
      'จับคู่ 3 ชิ้นที่เหมือนกันใน 60 วินาที — ได้คะแนนมากกว่าคู่ต่อสู้เป็นผู้ชนะ!';

  @override
  String get arenaMatch3Stuck => 'ไม่มีตาเดินแล้ว!';

  @override
  String get arenaQueueWaiting => 'กำลังหาคู่แข่ง…';

  @override
  String get arenaCancelButton => 'ยกเลิก';

  @override
  String get arenaTapButton => 'แตะแก้ว';

  @override
  String get arenaResolving => 'กำลังสรุปผล…';

  @override
  String arenaTierButton(String cost) {
    return 'อัปเกรด ×2 ($cost เหรียญ)';
  }

  @override
  String get arenaModeRecipe => 'ดวลสูตรเครื่องดื่ม';

  @override
  String get arenaRecipeIntro =>
      'ชงออเดอร์ชุดเดียวกัน 5 ออเดอร์ — คะแนนรวมสูงกว่าเป็นผู้ชนะ ถ้าทั้งสองคนเสร็จก่อนเวลา การดวลจะจบทันที!';

  @override
  String get arenaRecipeStart => 'เริ่มชง';

  @override
  String arenaRecipeProgress(int done, int theirs) {
    return 'คุณ: $done/5 ออเดอร์ · คู่ต่อสู้: $theirs/5';
  }

  @override
  String get arenaRecipeWaiting => 'เสร็จแล้ว! กำลังรอคู่ต่อสู้…';

  @override
  String arenaTimeLeft(int seconds) {
    return 'เหลือ $seconds วิ';
  }

  @override
  String arenaOnlineCount(int count) {
    return 'ออนไลน์ $count คน';
  }

  @override
  String get arenaYourScore => 'คะแนนคุณ';

  @override
  String get arenaOpponentScore => 'คู่แข่ง';

  @override
  String get arenaGhostBadge =>
      '👻 แมตช์ผี: คุณกำลังแข่งกับบันทึกของผู้เล่นคนอื่น รางวัลลดลงและไม่นับในอันดับ';

  @override
  String get arenaResultWin => 'คุณชนะ! 🎉';

  @override
  String get arenaResultLose => 'คุณแพ้';

  @override
  String get arenaResultDraw => 'เสมอ';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'ปิด';

  @override
  String get redeemTitle => 'แลกโค้ดของขวัญ';

  @override
  String get redeemHint => 'กรอกโค้ด';

  @override
  String get redeemButton => 'แลกรับ';

  @override
  String redeemSuccess(int gems) {
    return 'แลกสำเร็จ +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => 'คุณแลกโค้ดนี้ไปแล้ว';

  @override
  String get redeemInvalid => 'โค้ดไม่ถูกต้อง';

  @override
  String get cloudSaveMenuTitle => 'สำรองความคืบหน้า';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'เชื่อมต่อแล้ว: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'ยังไม่เชื่อมต่อ — อาจเสียความคืบหน้าถ้าถอนการติดตั้ง';

  @override
  String get cloudSaveTitle => 'สำรองความคืบหน้า';

  @override
  String get cloudSaveIntro =>
      'เชื่อมอีเมลเพื่อกู้คืนความคืบหน้าได้ถ้าถอนแอปหรือเปลี่ยนเครื่อง';

  @override
  String get cloudSaveEmailHint => 'อีเมลของคุณ';

  @override
  String get cloudSaveSendCode => 'ส่งรหัส';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'ส่งรหัสยืนยันไปที่ $email แล้ว';
  }

  @override
  String get cloudSaveCheckSpam =>
      'ไม่เจออีเมล? ลองดูในโฟลเดอร์สแปม / จดหมายขยะด้วย';

  @override
  String get cloudSaveCodeHint => 'รหัสยืนยัน';

  @override
  String get cloudSaveVerify => 'ยืนยัน';

  @override
  String get cloudSaveChangeEmail => 'ใช้อีเมลอื่น';

  @override
  String get cloudSaveResend => 'ส่งรหัสอีกครั้ง';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'ส่งรหัสอีกครั้ง ($seconds วิ)';
  }

  @override
  String get cloudSaveConflictTitle => 'พบข้อมูลบันทึกอื่นบนคลาวด์';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'เครื่องนี้: $amount เหรียญสะสมทั้งหมด';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'บนคลาวด์: $amount เหรียญสะสมทั้งหมด';
  }

  @override
  String get cloudSaveRestoreButton => 'กู้คืนจากคลาวด์';

  @override
  String get cloudSaveKeepLocalButton => 'ใช้เครื่องนี้ต่อ';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'เชื่อมต่อแล้ว: $email';
  }

  @override
  String get cloudSaveDisconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get cloudSaveRetry => 'ลองอีกครั้ง';

  @override
  String get leaderboardMenuTitle => 'อันดับ';

  @override
  String get leaderboardTitle => 'อันดับ';

  @override
  String get leaderboardNicknameIntro =>
      'ตั้งชื่อที่จะแสดงบนกระดานอันดับ (เปลี่ยนทีหลังได้):';

  @override
  String get leaderboardNicknameHint => 'ชื่อของคุณ';

  @override
  String get leaderboardSubmit => 'ยืนยัน';

  @override
  String leaderboardYourRank(int rank) {
    return 'อันดับของคุณ: #$rank';
  }

  @override
  String leaderboardStars(String stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => 'ยังไม่มีใครในกระดานอันดับ — คือคุณเลย!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 คุณอยู่ในอันดับต้น ๆ! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'อันดับ 1: $top1💎 · อันดับ 2-3: $top23💎 · อันดับ 4-10: $top410💎 — ทุก 24 ชม. ถ้ายังติดอันดับ';
  }

  @override
  String get leaderboardChangeName => 'เปลี่ยนชื่อ';

  @override
  String get leaderboardRetry => 'ลองอีกครั้ง';

  @override
  String get storySpeedrunMenuTitle => 'สปีดรัน';

  @override
  String get storySpeedrunTitle => 'อันดับสปีดรัน';

  @override
  String get storySpeedrunNotCompletedYet =>
      'คุณยังไม่จบเนื้อเรื่อง — จบตอนที่ 18 เพื่อขึ้นอันดับ';

  @override
  String get storySpeedrunTabMain => 'ภาค 1';

  @override
  String get storySpeedrunTabExt => 'ภาค 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'คุณยังไม่จบภาค 2 — จบตอนที่ 28 เพื่อติดอันดับ';

  @override
  String get storySpeedrunTabExt2 => 'ภาค 3';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      'คุณยังไม่จบภาค 3 — จบตอนที่ 36 เพื่อติดอันดับ';

  @override
  String get accessoryMenuTitle => 'คอลเลกชัน';

  @override
  String get collectionChip => 'คอลเลกชัน';

  @override
  String get accessoryInventoryTitle => 'คลังของสะสม';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return 'สะสมแล้ว $owned/$total';
  }

  @override
  String get accessoryRarityCommon => 'ทั่วไป';

  @override
  String get accessoryRarityRare => 'หายาก';

  @override
  String get accessoryRarityEpic => 'เอพิก';

  @override
  String get accessoryRarityLegendary => 'ตำนาน';

  @override
  String get accessoryLbTitle => 'อันดับนักสะสม';

  @override
  String accessoryLbCount(int n) {
    return '$n ชิ้น';
  }

  @override
  String get accessoryLbTopTitle => 'นักสะสม';

  @override
  String get accessoryLbTitleKing => 'ราชาแอคเซสซอรี';

  @override
  String get accessoryLbTitleMaster => 'ปรมาจารย์นักสะสม';

  @override
  String get accessoryLbEmpty =>
      'ยังไม่มีใครติดอันดับ เก็บของสะสมสักชิ้นแล้วคุณจะได้อันดับ 1!';

  @override
  String get accessoryLbNoOwned =>
      'คุณยังไม่มีของสะสมเลย — ทำภารกิจประจำวันให้ครบ 3 อย่างเพื่อมีโอกาสได้รับ';

  @override
  String get accessoryLbError => 'โหลดอันดับไม่ได้ ลองใหม่ภายหลังนะ';

  @override
  String get accessoryMintLeaf => 'ใบมินต์';

  @override
  String get accessoryCupcake => 'คัพเค้ก';

  @override
  String get accessoryCookie => 'คุกกี้';

  @override
  String get accessoryPottedPlant => 'ต้นไม้กระถางเล็ก';

  @override
  String get accessoryCandle => 'เทียนหอม';

  @override
  String get accessoryScarf => 'ผ้าพันคอ';

  @override
  String get accessoryKite => 'ว่าวกระดาษ';

  @override
  String get accessoryCap => 'หมวกแก๊ป';

  @override
  String get accessorySeashell => 'เปลือกหอย';

  @override
  String get accessoryMask => 'หน้ากาก';

  @override
  String get accessoryDrum => 'กลองเล็ก';

  @override
  String get accessoryPalette => 'จานสี';

  @override
  String get accessoryCrystalBall => 'ลูกแก้ว';

  @override
  String get accessoryLantern => 'โคมไฟโบราณ';

  @override
  String get accessoryUnicorn => 'ยูนิคอร์นตัวน้อย';

  @override
  String get accessoryDragon => 'มังกรตัวน้อย';

  @override
  String get accessoryBalloon => 'ลูกโป่ง';

  @override
  String get accessoryBowtie => 'โบว์';

  @override
  String get accessorySunglasses => 'แว่นกันแดด';

  @override
  String get accessoryUmbrella => 'ร่มเล็ก';

  @override
  String get accessoryTeapot => 'กาน้ำชาเล็ก';

  @override
  String get accessoryBell => 'กระดิ่งเล็ก';

  @override
  String get accessoryRibbon => 'ริบบิ้น';

  @override
  String get accessoryBookmark => 'ที่คั่นหนังสือน่ารัก';

  @override
  String get accessoryWindChime => 'กระดิ่งลม';

  @override
  String get accessoryClover => 'โคลเวอร์สี่ใบ';

  @override
  String get accessoryBubble => 'ฟองสบู่';

  @override
  String get accessorySticker => 'สติกเกอร์';

  @override
  String get accessoryYarn => 'ไหมพรมม้วน';

  @override
  String get accessoryFan => 'พัดกระดาษ';

  @override
  String get accessoryBasket => 'ตะกร้าหวาย';

  @override
  String get accessoryBead => 'กำไลลูกปัด';

  @override
  String get accessoryLadybug => 'เต่าทองตัวน้อย';

  @override
  String get accessoryKey => 'กุญแจโบราณ';

  @override
  String get accessoryDiamondStone => 'หินเพชร';

  @override
  String get accessoryMusicNote => 'โน้ตดนตรี';

  @override
  String get accessoryTelescope => 'กล้องโทรทรรศน์';

  @override
  String get accessoryAnchor => 'สมอเรือ';

  @override
  String get accessoryFeather => 'ขนนก';

  @override
  String get accessoryHourglass => 'นาฬิกาทราย';

  @override
  String get accessoryMap => 'แผนที่โบราณ';

  @override
  String get accessoryRing => 'แหวนวงเล็ก';

  @override
  String get accessoryMagicWand => 'ไม้กายสิทธิ์';

  @override
  String get accessoryTrident => 'ตรีศูล';

  @override
  String get accessoryPeacock => 'นกยูงตัวน้อย';

  @override
  String get accessoryComet => 'ดาวหาง';

  @override
  String get accessoryButterfly => 'ผีเสื้อคริสตัล';

  @override
  String get accessoryAngelWing => 'ปีกนางฟ้า';

  @override
  String get accessoryPhoenix => 'ฟีนิกซ์';

  @override
  String get accessoryGalaxy => 'กาแล็กซี';

  @override
  String get accessoryDonut => 'โดนัท';

  @override
  String get accessoryLollipop => 'อมยิ้ม';

  @override
  String get accessoryPretzel => 'เพรทเซล';

  @override
  String get accessoryIceCream => 'ไอศกรีมโคน';

  @override
  String get accessoryStrawberry => 'สตรอว์เบอร์รี';

  @override
  String get accessoryCherry => 'เชอร์รี';

  @override
  String get accessoryLemon => 'เลมอน';

  @override
  String get accessoryPeach => 'พีช';

  @override
  String get accessoryPopcorn => 'ป๊อปคอร์น';

  @override
  String get accessoryHoneyPot => 'โหลน้ำผึ้ง';

  @override
  String get accessoryMilkGlass => 'แก้วนม';

  @override
  String get accessoryTangerine => 'ส้ม';

  @override
  String get accessoryChestnut => 'เกาลัด';

  @override
  String get accessoryMapleLeaf => 'ใบเมเปิล';

  @override
  String get accessoryCompass => 'เข็มทิศ';

  @override
  String get accessoryRocket => 'จรวด';

  @override
  String get accessoryViolin => 'ไวโอลิน';

  @override
  String get accessoryScroll => 'ม้วนคัมภีร์โบราณ';

  @override
  String get accessoryMicrophone => 'ไมโครโฟน';

  @override
  String get accessoryLotus => 'ดอกบัว';

  @override
  String get accessoryJellyfish => 'แมงกะพรุน';

  @override
  String get accessoryCamera => 'กล้องถ่ายรูป';

  @override
  String get accessoryShield => 'โล่';

  @override
  String get accessoryAmphora => 'แจกันโบราณ';

  @override
  String get accessoryRainbow => 'รุ้งกินน้ำ';

  @override
  String get accessoryFairy => 'นางฟ้า';

  @override
  String get accessoryDiscoBall => 'ลูกบอลดิสโก้';

  @override
  String get accessoryShiningStar => 'ดาวส่องแสง';

  @override
  String get accessoryKraken => 'คราเคน';

  @override
  String get accessoryThunderbolt => 'สายฟ้าเทพ';

  @override
  String get accessoryIceCube => 'ก้อนน้ำแข็ง';

  @override
  String get accessoryCroissant => 'ครัวซองต์';

  @override
  String get accessoryPancakes => 'แพนเค้ก';

  @override
  String get accessoryWaffle => 'วาฟเฟิล';

  @override
  String get accessoryBagel => 'เบเกิล';

  @override
  String get accessoryCakeSlice => 'เค้กหนึ่งชิ้น';

  @override
  String get accessoryPie => 'พาย';

  @override
  String get accessoryCandy => 'ลูกอม';

  @override
  String get accessoryGrapes => 'องุ่น';

  @override
  String get accessoryWatermelon => 'แตงโม';

  @override
  String get accessoryPineapple => 'สับปะรด';

  @override
  String get accessoryMango => 'มะม่วง';

  @override
  String get accessoryKiwi => 'กีวี';

  @override
  String get accessoryBanana => 'กล้วย';

  @override
  String get accessoryApple => 'แอปเปิล';

  @override
  String get accessoryTeddy => 'ตุ๊กตาหมี';

  @override
  String get accessoryCrayon => 'สีเทียน';

  @override
  String get accessoryBucket => 'ถัง';

  @override
  String get accessoryGuitar => 'กีตาร์';

  @override
  String get accessoryTrumpet => 'ทรัมเป็ต';

  @override
  String get accessoryPiano => 'เปียโน';

  @override
  String get accessorySaxophone => 'แซกโซโฟน';

  @override
  String get accessoryBanjo => 'แบนโจ';

  @override
  String get accessoryMicroscope => 'กล้องจุลทรรศน์';

  @override
  String get accessoryRingedPlanet => 'ดาวเคราะห์มีวงแหวน';

  @override
  String get accessoryCrescentMoon => 'จันทร์เสี้ยว';

  @override
  String get accessoryBowArrow => 'ธนูและลูกศร';

  @override
  String get accessoryMirror => 'กระจกเงา';

  @override
  String get accessoryFerrisWheel => 'ชิงช้าสวรรค์';

  @override
  String get accessoryCarousel => 'ม้าหมุน';

  @override
  String get accessorySwan => 'หงส์';

  @override
  String get accessoryFlamingo => 'นกฟลามิงโก';

  @override
  String get accessoryOwl => 'นกฮูก';

  @override
  String get accessoryWhale => 'ปลาวาฬ';

  @override
  String get accessoryCrown => 'มงกุฎ';

  @override
  String get accessoryCircusTent => 'เต็นท์ละครสัตว์';

  @override
  String get accessoryPinata => 'พินยาต้า';

  @override
  String get accessoryCastle => 'ปราสาท';

  @override
  String get accessoryGenie => 'จินนี่';

  @override
  String get accessoryVolcano => 'ภูเขาไฟ';

  @override
  String get accessoryCarrot => 'แครอท';

  @override
  String get accessoryCorn => 'ข้าวโพด';

  @override
  String get accessoryTomato => 'มะเขือเทศ';

  @override
  String get accessoryAvocado => 'อะโวคาโด';

  @override
  String get accessoryCoconut => 'มะพร้าว';

  @override
  String get accessoryBlueberries => 'บลูเบอร์รี';

  @override
  String get accessoryPear => 'ลูกแพร์';

  @override
  String get accessoryRiceBall => 'ข้าวปั้น';

  @override
  String get accessoryDumpling => 'เกี๊ยว';

  @override
  String get accessorySushi => 'ซูชิ';

  @override
  String get accessoryRamen => 'ราเมน';

  @override
  String get accessoryTaco => 'ทาโก้';

  @override
  String get accessoryPizza => 'พิซซ่า';

  @override
  String get accessoryHotDog => 'ฮอทดอก';

  @override
  String get accessoryFries => 'เฟรนช์ฟรายส์';

  @override
  String get accessoryEgg => 'ไข่';

  @override
  String get accessoryBread => 'ขนมปัง';

  @override
  String get accessoryButter => 'เนย';

  @override
  String get accessoryPuzzle => 'ชิ้นจิ๊กซอว์';

  @override
  String get accessoryDice => 'ลูกเต๋า';

  @override
  String get accessoryChessPawn => 'หมากรุก';

  @override
  String get accessoryDart => 'เป้าปาลูกดอก';

  @override
  String get accessoryBowling => 'โบว์ลิ่ง';

  @override
  String get accessoryYoYo => 'โยโย่';

  @override
  String get accessoryRollerSkate => 'โรลเลอร์เบลด';

  @override
  String get accessorySkateboard => 'สเก็ตบอร์ด';

  @override
  String get accessorySatellite => 'ดาวเทียม';

  @override
  String get accessoryAlembic => 'เครื่องกลั่น';

  @override
  String get accessoryDna => 'ดีเอ็นเอ';

  @override
  String get accessoryTrophy => 'ถ้วยรางวัล';

  @override
  String get accessoryLeopard => 'เสือดาว';

  @override
  String get accessoryElephant => 'ช้าง';

  @override
  String get accessoryPanda => 'แพนด้า';

  @override
  String get accessoryGiraffe => 'ยีราฟ';

  @override
  String get accessoryTurtle => 'เต่า';

  @override
  String get accessoryKoala => 'โคอาล่า';

  @override
  String get accessoryPenguin => 'เพนกวิน';

  @override
  String get accessorySauropod => 'ไดโนเสาร์คอยาว';

  @override
  String get accessoryMermaid => 'นางเงือก';

  @override
  String get accessoryEagle => 'นกอินทรี';

  @override
  String get marketTitle => 'ตลาดของสะสม';

  @override
  String get marketTabBrowse => 'ตลาด';

  @override
  String get marketTabMine => 'ของฉัน';

  @override
  String get marketRecentSalesHeader => 'เพิ่งขายไป';

  @override
  String get marketMerchantTitle => 'พ่อค้าประจำสัปดาห์';

  @override
  String get marketFilterAll => 'ทั้งหมด';

  @override
  String get marketFilterMissing => 'ยังไม่มี';

  @override
  String get marketSortPriceAsc => 'ราคาต่ำสุด';

  @override
  String get marketBadgeNew => 'ใหม่';

  @override
  String marketNeedMore(int n) {
    return 'ขาดอีก $n เหรียญตลาด';
  }

  @override
  String get marketNoFilterResults => 'ไม่มีของที่ตรงกับตัวกรอง';

  @override
  String accessoryRevealNew(String name) {
    return 'ได้รับแอคเซสซอรีใหม่: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return '$name ซ้ำ: +$gems 💎 และสำเนาสำรอง 1 ชิ้นสำหรับขายในตลาด';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return 'จัดแสดง $n/$max — แตะของที่มีเพื่อวางรอบแก้ว';
  }

  @override
  String accessoryEquipFull(int max) {
    return 'จัดแสดงเต็มแล้ว ($max) — ยกเลิกหนึ่งชิ้นก่อน';
  }

  @override
  String get accessoryFlairHint => 'กดค้างไอเทมเพื่อใช้เป็นเหรียญตราบนอันดับ';

  @override
  String accessoryFlairSet(String name) {
    return 'ตั้ง $name เป็นเหรียญตราบนอันดับแล้ว';
  }

  @override
  String get accessoryFlairCleared => 'ถอดเหรียญตราบนอันดับแล้ว';

  @override
  String get accessoryFlairFailed =>
      'ตั้งเหรียญตราไม่ได้ — ไอเทมยังไม่ซิงก์หรือออฟไลน์';

  @override
  String get marketStarterTitle => 'ชุดเริ่มต้นตลาด';

  @override
  String get marketStarterBody =>
      'รับเครื่องประดับธรรมดา 1 ชิ้น + ของซ้ำ 1 ชิ้นไว้ขาย + 10 เหรียญตลาด รับได้ครั้งเดียว';

  @override
  String get marketStarterClaim => 'รับ';

  @override
  String get marketStarterDone => 'รับชุดเริ่มต้นแล้ว! ดูในคอลเลกชัน';

  @override
  String get marketStarterErrCap =>
      'ของขวัญวันนี้หมดทั้งเซิร์ฟเวอร์ — พรุ่งนี้มาใหม่นะ';

  @override
  String get marketStarterErrNet =>
      'รับไม่ได้ — ตรวจสอบเครือข่ายแล้วลองอีกครั้ง';

  @override
  String get marketIntroTitle => 'ยินดีต้อนรับสู่ตลาด!';

  @override
  String get marketIntroStep1 =>
      '1. แปลง 💎 หรือเหรียญเป็นเหรียญตลาด (ปุ่มแปลง) — ใช้ได้เฉพาะในตลาดและแปลงกลับไม่ได้';

  @override
  String get marketIntroStep2 =>
      '2. ซื้อเครื่องประดับที่ผู้เล่นอื่นลงขายเพื่อเก็บให้ครบชุด';

  @override
  String get marketIntroStep3 =>
      '3. ขายของซ้ำที่แท็บของฉัน ค่าธรรมเนียมเพียง 1%';

  @override
  String get marketIntroOk => 'เข้าใจแล้ว';

  @override
  String get collectionTitle10 => 'นักสะสม';

  @override
  String get collectionTitle25 => 'นักสะสมตัวยง';

  @override
  String get collectionTitle40 => 'ผู้เชี่ยวชาญการสะสม';

  @override
  String get collectionTitle50 => 'ตำนานนักสะสม';

  @override
  String get collectionTitle80 => 'ปรมาจารย์นักสะสม';

  @override
  String get collectionTitle100 => 'นักสะสมผู้ยิ่งใหญ่';

  @override
  String get collectionTitle120 => 'ราชาแห่งการสะสม';

  @override
  String get collectionTitle140 => 'ปราชญ์นักสะสม';

  @override
  String get collectionTitle160 => 'เทพแห่งการสะสม';

  @override
  String collectionTitleLabel(String title) {
    return 'ฉายา: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return 'รับ +$coins';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count ชิ้น · $coins เหรียญตลาด';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return 'ได้รับ $coins เหรียญตลาดและฉายาใหม่!';
  }

  @override
  String get collectionMilestoneErrNet =>
      'รับไม่ได้ — ตรวจสอบเครือข่ายแล้วลองอีกครั้ง';

  @override
  String get collectionSetsTitle => 'ชุดสะสม';

  @override
  String get seasonTitle => 'บัตรซีซัน';

  @override
  String seasonEntrySub(int days, int tier) {
    return 'เหลือ $days วัน · ขั้น $tier/30';
  }

  @override
  String seasonTierLine(int max, int tier) {
    return 'ขั้น $tier/$max';
  }

  @override
  String seasonDaysLeft(int days) {
    return 'เหลือ $days วัน';
  }

  @override
  String seasonHint(int cap) {
    return 'รับ XP จากภารกิจ มินิเกม ดันเจี้ยนกิลด์ และอารีนา (สูงสุด $cap XP/วัน) ความคืบหน้าจะรีเซ็ตทุกซีซัน — อย่าลืมรับรางวัล!';
  }

  @override
  String get seasonFreeTrack => 'ฟรี';

  @override
  String get seasonPremiumTrack => 'พรีเมียม';

  @override
  String seasonBuyPremium(int gems) {
    return 'ปลดล็อกพรีเมียม · $gems 💎';
  }

  @override
  String get seasonPremiumOwned => '✓ ปลดล็อกพรีเมียมแล้ว';

  @override
  String get seasonPremiumBought => 'ปลดล็อกพรีเมียมแล้ว!';

  @override
  String get seasonNotEnoughGems => '💎 ไม่พอ';

  @override
  String get seasonLbTitle => 'อันดับบัตรซีซัน';

  @override
  String get seasonLbEmpty =>
      'ยังไม่มีใครในอันดับซีซันนี้ รับ XP บัตรซีซันแล้วเปิดใหม่เพื่อขึ้นอันดับ (ต้องมีบัญชีที่ผูกอีเมล)';

  @override
  String get playerTitleChampion => 'แชมป์ซีซัน';

  @override
  String get playerTitleChampionHint => 'รับรางวัลท็อป 3 ของบัตรซีซัน';

  @override
  String get seasonRewardTitle => 'รางวัลซีซันที่แล้ว';

  @override
  String seasonRewardLine(int rank) {
    return 'คุณได้อันดับ #$rank ของบัตรซีซันครั้งก่อน!';
  }

  @override
  String seasonRewardClaim(int gems) {
    return 'รับ $gems 💎';
  }

  @override
  String seasonRewardGot(int gems) {
    return 'ได้รับ $gems 💎 รางวัลซีซัน!';
  }

  @override
  String get seasonRewardFail => 'รับรางวัลไม่สำเร็จ ลองใหม่ภายหลัง';

  @override
  String get seasonItemsTitle =>
      'ไอเทมเฉพาะบัตรซีซัน (ขั้น 20 ฟรี · ขั้น 30 พรีเมียม)';

  @override
  String get accessorySeasonSakura => 'ซากุระซีซัน';

  @override
  String get accessorySeasonPaperLantern => 'โคมกระดาษซีซัน';

  @override
  String get accessorySeasonSunflower => 'ทานตะวันซีซัน';

  @override
  String get accessorySeasonIsland => 'เกาะเขตร้อนซีซัน';

  @override
  String get accessorySeasonAutumnLeaf => 'ใบไม้ร่วงซีซัน';

  @override
  String get accessorySeasonMoonView => 'ชมจันทร์ซีซัน';

  @override
  String get accessorySeasonSnowflake => 'เกล็ดหิมะซีซัน';

  @override
  String get accessorySeasonMountain => 'ยอดเขาซีซัน';

  @override
  String seasonGot(String text) {
    return 'ได้รับ $text';
  }

  @override
  String get dailyItemTitle => 'ไอเทมประจำวัน';

  @override
  String get dailyItemNew => 'ชิ้นใหม่สำหรับคอลเลกชัน';

  @override
  String get dailyItemOwned => 'มีแล้ว — จะได้ชิ้นสำรอง';

  @override
  String collectionSetDone(int coins) {
    return 'ได้รับ $coins เหรียญตลาดจากชุดสะสม!';
  }

  @override
  String marketPriceLast(int n) {
    return 'ขายล่าสุด: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return 'ถูกสุดที่ลงขาย: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return 'เฉลี่ย 7 วัน: $n';
  }

  @override
  String get marketWishAdd => 'เพิ่มในรายการที่อยากได้';

  @override
  String get marketWishRemove => 'เอาออกจากรายการที่อยากได้';

  @override
  String marketWishFull(int max) {
    return 'รายการที่อยากได้เต็มแล้ว ($max ชิ้น)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return 'ฟรีช่วงสุดสัปดาห์: คุณได้รับเต็ม $proceeds เหรียญตลาด';
  }

  @override
  String get marketWeekendBanner =>
      '🎉 สุดสัปดาห์: ค่าธรรมเนียม 0% & โอกาสได้เครื่องประดับหายากสูงขึ้น!';

  @override
  String collectionPeekTitle(String name) {
    return 'คอลเลกชันของ $name';
  }

  @override
  String get collectionPeekError => 'โหลดคอลเลกชันไม่ได้ — ลองใหม่ภายหลัง';

  @override
  String get collectionShareTooltip => 'อวดคอลเลกชัน';

  @override
  String collectionShareText(int owned, int total, String items) {
    return 'ฉันสะสมเครื่องประดับได้ $owned/$total ชิ้นใน Boba Empire! $items';
  }

  @override
  String get collectionShareCopied => 'คัดลอกแล้ว — วางในแชทเพื่ออวดได้เลย!';

  @override
  String get collectionCardTitle => 'การ์ดคอลเลกชัน';

  @override
  String get collectionShareImage => 'แชร์รูปภาพ';

  @override
  String get collectionShareCopy => 'คัดลอกข้อความ';

  @override
  String get collectionShareFailed => 'แชร์ไม่ได้ — ลองคัดลอกข้อความแทน';

  @override
  String whatsNewTitle(String version) {
    return 'มีอะไรใหม่ใน $version';
  }

  @override
  String get whatsNewOrders =>
      '🧋 ชงตามออเดอร์: ลากวัตถุดิบลงแก้ว ลูกค้าชิบิน่ารัก คอมโบ ชั่วโมงเร่งด่วน และออเดอร์เทศกาล';

  @override
  String get whatsNewRecipes =>
      '📖 เกมสูตร: ทบทวนแบบเว้นระยะ 100 เครื่องดื่มและสตรีครายวัน ทุกมินิเกมมีวิธีเล่น';

  @override
  String get whatsNewDaily =>
      '📅 ภารกิจประจำวัน: ออเดอร์เดียวกันสำหรับทุกคน อันดับวันนี้ และรางวัลท็อปรายสัปดาห์';

  @override
  String get whatsNewAct4 =>
      '📜 ภาค 4 \"เทศกาลฝีมือยิ่งใหญ่\": 10 บท แต่ละบทปลดล็อกด้วยเป้าหมายของมินิเกม';

  @override
  String get whatsNewMore =>
      '🤝 แตะอัตโนมัติ แลกของตกแต่งในตลาด ภารกิจกิลด์ ฟีเจอร์ออนไลน์ (อันดับ ตลาด กิลด์) ต้องเชื่อมอีเมล';

  @override
  String get whatsNewLater => 'ไว้ทีหลัง';

  @override
  String get whatsNewOpen => 'ลองเล่น';

  @override
  String marketWallet(int n) {
    return '$n เหรียญตลาด';
  }

  @override
  String get marketError => 'โหลดตลาดไม่ได้ ลองใหม่ภายหลังนะ';

  @override
  String get marketEmptyBrowse => 'ยังไม่มีใครลงขายอะไรเลย';

  @override
  String get marketBuyButton => 'ซื้อ';

  @override
  String get marketBoughtToast => 'ซื้อสำเร็จ!';

  @override
  String marketConfirmBuy(int price) {
    return 'ซื้อในราคา $price เหรียญตลาดใช่ไหม?';
  }

  @override
  String marketPriceTag(int price) {
    return '$price เหรียญตลาด';
  }

  @override
  String get marketMyListingsHeader => 'รายการที่คุณลงขาย';

  @override
  String get marketEmptyMine => 'คุณยังไม่ได้ลงขายอะไรเลย';

  @override
  String marketExpiresIn(String t) {
    return 'หมดอายุใน $t';
  }

  @override
  String marketListExpiryNote(int days) {
    return 'ประกาศอยู่ได้สูงสุด $days วัน เมื่อหมดอายุไอเท็มจะกลับเข้าคลังของคุณ';
  }

  @override
  String marketExpiredToast(int n) {
    return 'ประกาศที่หมดอายุ $n รายการกลับเข้าคลังแล้ว';
  }

  @override
  String get swapTab => 'แลกเปลี่ยน';

  @override
  String get swapCreate => 'สร้างข้อเสนอ';

  @override
  String get swapCreateOk => 'โพสต์ข้อเสนอ';

  @override
  String swapIntro(int days) {
    return 'แลกไอเท็มกับผู้เล่นอื่นโดยไม่ต้องใช้เหรียญตลาด ไอเท็มของคุณจะถูกเก็บไว้จนกว่าจะมีคนรับ (สูงสุด $days วัน หมดอายุจะกลับเข้าคลัง)';
  }

  @override
  String get swapEmpty => 'ยังไม่มีข้อเสนอแลกเปลี่ยน สร้างอันแรกเลย!';

  @override
  String get swapMine => 'ข้อเสนอแลกเปลี่ยนของฉัน';

  @override
  String get swapMineEmpty => 'คุณยังไม่ได้โพสต์ข้อเสนอ';

  @override
  String get swapGive => 'ให้';

  @override
  String get swapWant => 'ต้องการ';

  @override
  String get swapAccept => 'แลก';

  @override
  String get swapNeedItem => 'ยังไม่มีไอเท็มที่ต้องการ';

  @override
  String get swapCancel => 'ยกเลิก';

  @override
  String get swapPickGive => 'เลือกไอเท็มที่จะให้';

  @override
  String get swapPickWant => 'เลือกไอเท็มที่ต้องการ';

  @override
  String get swapPickSearch => 'ค้นหาตามชื่อ';

  @override
  String get swapPickNone => 'ไม่มีไอเท็ม';

  @override
  String swapMaxNote(int n) {
    return 'โพสต์ได้พร้อมกันสูงสุด $n ข้อเสนอ';
  }

  @override
  String get swapConfirmTitle => 'ยืนยันการแลก';

  @override
  String swapConfirmBody(String give, String want) {
    return 'คุณจะได้ $give และให้ $want ใช่ไหม?';
  }

  @override
  String get swapCreatedToast => 'โพสต์ข้อเสนอแลกเปลี่ยนแล้ว!';

  @override
  String swapDoneToast(String name) {
    return 'แลกสำเร็จ! คุณได้รับ $name';
  }

  @override
  String get swapCancelledToast => 'ยกเลิกข้อเสนอแล้ว ไอเท็มกลับเข้าคลัง';

  @override
  String swapCollectedToast(int n) {
    return 'ไอเท็มจากการแลก $n ชิ้นกลับเข้าคลังแล้ว';
  }

  @override
  String get swapErrNotOwned => 'คุณยังไม่มีไอเท็มนี้ (เปิดตลาดใหม่เพื่อซิงก์)';

  @override
  String get swapErrNotOwnedWant => 'คุณไม่มีไอเท็มที่เขาต้องการ';

  @override
  String swapErrTooMany(int n) {
    return 'คุณมีข้อเสนอที่เปิดอยู่มากเกินไป (สูงสุด $n)';
  }

  @override
  String get swapErrNotOpen =>
      'ข้อเสนอนี้เพิ่งถูกรับหรือถูกยกเลิก — อัปเดตรายการแล้ว';

  @override
  String get swapErrOwn => 'รับข้อเสนอของตัวเองไม่ได้';

  @override
  String get swapErrInvalid => 'ข้อเสนอไม่ถูกต้อง';

  @override
  String get swapErrNetwork => 'เชื่อมต่อไม่ได้ ลองใหม่ภายหลัง';

  @override
  String get marketCancelButton => 'ยกเลิกการขาย';

  @override
  String get marketCancelledToast => 'ยกเลิกการขายแล้ว';

  @override
  String marketExtendButton(int days) {
    return 'ต่ออายุอีก $days วัน (ดูโฆษณา)';
  }

  @override
  String get marketExtendedToast => 'ต่ออายุการขายแล้ว';

  @override
  String essenceEarned(int n) {
    return '+$n 🧪 แก่นแท้';
  }

  @override
  String get masteryTitle => 'ความเชี่ยวชาญ';

  @override
  String masteryEssence(int n) {
    return '🧪 แก่นแท้ $n';
  }

  @override
  String get masteryHint =>
      'สะสมแก่นแท้จากมินิเกม แล้วอัปเกรดความเชี่ยวชาญเพื่อเพิ่มรายได้ของแต่ละด่าน คงอยู่หลังแฟรนไชส์';

  @override
  String masteryBonus(String pct) {
    return 'รายได้ +$pct%';
  }

  @override
  String masteryBuy(int cost) {
    return 'อัปเกรด · $cost 🧪';
  }

  @override
  String get masteryMaxed => 'สูงสุด';

  @override
  String get guildDungeonTitle => 'ดันเจี้ยนกิลด์';

  @override
  String guildDungeonCardSub(int cleared) {
    return 'ผ่านแล้ว $cleared/3 ด่าน';
  }

  @override
  String guildDungeonStage(int n) {
    return 'ด่าน $n/3';
  }

  @override
  String get guildDungeonBarTap => 'แตะ';

  @override
  String get guildDungeonBarOff => 'เฝ้ายามกลางคืน';

  @override
  String get guildDungeonBarRec => 'สูตร';

  @override
  String get guildDungeonRoleTap => 'สายแตะ';

  @override
  String get guildDungeonRoleOff => 'ผู้เฝ้ายาม';

  @override
  String get guildDungeonRoleRec => 'เชฟ';

  @override
  String get guildDungeonRoleHeader => 'บทบาทสัปดาห์นี้';

  @override
  String get guildDungeonRoleHint =>
      'การช่วยตามบทบาทของตัวเองนับ ×1.5 เปลี่ยนบทบาทได้สัปดาห์ละ 1 ครั้ง';

  @override
  String get guildDungeonRoleLockedNote =>
      'คุณใช้สิทธิ์เปลี่ยนบทบาทของสัปดาห์นี้แล้ว';

  @override
  String get guildDungeonNoRole =>
      'ยังไม่มีบทบาท — เลือกหนึ่งอย่างเพื่อรับ ×1.5';

  @override
  String get guildDungeonHint =>
      'ต้องเต็มทั้งสามแถบจึงจะผ่านด่าน แถบที่เกินไม่ช่วยแถบอื่น';

  @override
  String guildDungeonHours(String n) {
    return '$n ชม.';
  }

  @override
  String get guildDungeonCleared => 'ผ่านแล้ว';

  @override
  String guildDungeonClaim(int coins) {
    return 'รับ · เหรียญกิลด์ $coins';
  }

  @override
  String guildDungeonClaimFinal(int coins, int gems) {
    return 'รับ · เหรียญกิลด์ $coins + 💎 $gems + หีบ';
  }

  @override
  String get guildDungeonClaimed => 'รับแล้ว';

  @override
  String get guildDungeonNeedMin =>
      'ช่วยสักเล็กน้อย (แตะ ออฟไลน์ หรือสูตร) เพื่อรับรางวัล';

  @override
  String guildDungeonClaimedSnack(int coins, int gems) {
    return 'รางวัลด่าน: เหรียญกิลด์ +$coins, 💎 +$gems';
  }

  @override
  String guildDungeonClaimedSnackChest(int coins, int gems, String item) {
    return 'รางวัลด่าน: เหรียญกิลด์ +$coins, 💎 +$gems, $item';
  }

  @override
  String get guildDungeonBoard => 'ผลงานของสมาชิก';

  @override
  String get guildDungeonErrLocked => 'กิลด์ยังไม่ผ่านด่านนี้';

  @override
  String get guildDungeonErrRoleLocked =>
      'สัปดาห์นี้คุณเปลี่ยนบทบาทไปแล้วหนึ่งครั้ง';

  @override
  String get guildDungeonNudgeTooltip => 'เตือนในแชต';

  @override
  String guildDungeonNudge(String bar) {
    return 'แถบ$barยังขาดอยู่ ช่วยหน่อยนะ!';
  }

  @override
  String get refineTooltip => 'ตีบวก';

  @override
  String get refineButton => 'ตีบวก';

  @override
  String refineLevelLabel(int level, int max) {
    return 'เลเวล $level/$max';
  }

  @override
  String refinePoints(String from, String to) {
    return 'แต้มชุดสวมใส่: $from → $to';
  }

  @override
  String refineCostSpares(int have, int need) {
    return 'ไอเทมซ้ำของชิ้นนี้: $have/$need';
  }

  @override
  String refineCostEssence(int have, int need) {
    return '🧪 แก่นแท้: $have/$need';
  }

  @override
  String get refineMaxed => 'ถึงเลเวลสูงสุดแล้ว';

  @override
  String refineDone(int level) {
    return 'ตีบวกเป็นเลเวล $level แล้ว';
  }

  @override
  String get refineNote =>
      'แต่ละเลเวลเพิ่มแต้มของชิ้นนี้ 25% แต่ไม่เพิ่มเพดานของสาย เลเวลไม่ติดไปเมื่อขายหรือแลกเปลี่ยน';

  @override
  String get refineErrSpares => 'ไอเทมซ้ำของชิ้นนี้ไม่พอ';

  @override
  String get refineErrEssence => 'แก่นแท้ไม่พอ';

  @override
  String get loadoutTitle => 'ชุดสวมใส่';

  @override
  String get loadoutHint =>
      'แต่ละตระกูลให้บัฟหนึ่งอย่าง: 🔥 แตะ · ✨ รายได้ · 🌿 ออฟไลน์ · 💎 ค่าอัปเกรด ใส่หลายชิ้นจากตระกูลเดียวกันเพื่อรับคอมโบ';

  @override
  String get loadoutEmpty => 'ยังไม่มีบัฟ แตะไอเทมในคอลเลกชันเพื่อสวมใส่';

  @override
  String loadoutBuffTap(String pct) {
    return '🔥 แตะ +$pct%';
  }

  @override
  String loadoutBuffIncome(String pct) {
    return '✨ รายได้ +$pct%';
  }

  @override
  String loadoutBuffOffline(String pct) {
    return '🌿 ออฟไลน์ +$pct%';
  }

  @override
  String loadoutBuffDiscount(String pct) {
    return '💎 ค่าอัปเกรด −$pct%';
  }

  @override
  String loadoutComboSuffix(String mult) {
    return ' · คอมโบ ×$mult';
  }

  @override
  String loadoutLockNote(int minutes) {
    return '🔒 ล็อกการเปลี่ยน: เหลือ $minutes นาที';
  }

  @override
  String get loadoutLockedTitle => 'ชุดสวมใส่ถูกล็อก';

  @override
  String loadoutLockedBody(int minutes) {
    return 'คุณเพิ่งเปลี่ยนชุดสวมใส่ อีก $minutes นาทีจึงจะถอดหรือเปลี่ยนได้อีก (เติมช่องว่างได้เสมอ) ปลดล็อกเลยไหม?';
  }

  @override
  String get loadoutUnlockAd => 'ดูโฆษณาเพื่อปลดล็อก';

  @override
  String get loadoutUnlockFree => 'ปลดล็อก';

  @override
  String get loadoutUnlockedToast => 'ปลดล็อกแล้ว เปลี่ยนได้เต็มที่!';

  @override
  String loadoutRemoveTitle(String name) {
    return 'ถอด $name ไหม?';
  }

  @override
  String loadoutRemoveBody(int minutes) {
    return 'หลังถอดแล้ว จะถอดหรือเปลี่ยนไอเทมอื่นไม่ได้เป็นเวลา $minutes นาที (เติมช่องว่างได้)';
  }

  @override
  String get loadoutRemoveConfirm => 'ถอด';

  @override
  String get loadoutFamilyTap => 'ความร้อนแรง · เพิ่มค่าการแตะ';

  @override
  String get loadoutFamilyIncome => 'ประกาย · เพิ่มรายได้อัตโนมัติ';

  @override
  String get loadoutFamilyOffline => 'สงบ · เพิ่มรายได้ตอนออฟไลน์';

  @override
  String get loadoutFamilyDiscount => 'ความประณีต · อัปเกรดถูกลง';

  @override
  String get marketSellableHeader => 'ของสะสมที่ขายได้';

  @override
  String get marketEmptySellable => 'คุณยังไม่มีของสะสมให้ขาย';

  @override
  String get marketListedToast => 'ลงขายสำเร็จ!';

  @override
  String get marketListButton => 'ลงขาย';

  @override
  String get marketPriceLabel => 'ราคา (เหรียญตลาด)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return 'คุณจะได้รับ $proceeds เหรียญตลาดหลังหักค่าธรรมเนียม 1% (−$fee)';
  }

  @override
  String get marketConvertButton => 'แลกเปลี่ยน';

  @override
  String get marketConvertTitle => 'แลกเป็นเหรียญตลาด';

  @override
  String get marketConvertAmountLabel => 'จำนวนเหรียญตลาดที่ต้องการ';

  @override
  String marketConvertCostGems(String cost) {
    return 'ค่าใช้จ่าย: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return 'ค่าใช้จ่าย: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => 'แลกเปลี่ยนสำเร็จ!';

  @override
  String get marketConvertFailToast =>
      'แลกเปลี่ยนไม่สำเร็จ ยอดคงเหลือไม่พอหรือเครือข่ายขัดข้อง';

  @override
  String get storySpeedrunEmpty => 'ยังไม่มีใครจบเนื้อเรื่อง — เป็นคนแรกสิ!';

  @override
  String get arenaLeaderboardMenuTitle => 'อันดับ PK';

  @override
  String get arenaLeaderboardTitle => 'อันดับ PK';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'คุณยังไม่เคยแข่งขันในสนามประลอง — ชนะสักครั้งเพื่อปรากฏที่นี่';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '$winsชนะ - $lossesแพ้';
  }

  @override
  String get ascensionTitle => 'ยุคใหม่';

  @override
  String get ascensionOpen => 'ยุคใหม่ ⏳';

  @override
  String get ascensionIntro =>
      'แลกดาวและเพิร์กร้านดาวทั้งหมดเป็น ⏳ แต้มยุคใหม่ — เพิร์กถาวรที่แรงขึ้น คุณจะเริ่มเล่นใหม่';

  @override
  String ascensionProgress(int percent) {
    return 'ความคืบหน้าปลดล็อก: $percent%';
  }

  @override
  String get ascensionPointsNow => 'แต้มที่มี';

  @override
  String get ascensionPointsGain => 'ที่จะได้รับ';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ รีเซ็ตดาว เพิร์กร้านดาวทั้งหมด เหรียญ เลเวลอัปเกรด และด่าน เก็บ 💎 ความสำเร็จ และเนื้อเรื่องไว้ ดาวบนกระดานอันดับจะเป็น 0 (อันดับตามรายได้รวมไม่เปลี่ยน)';

  @override
  String ascensionConfirm(int points) {
    return 'เริ่มยุคใหม่ (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'ยังไม่พร้อม';

  @override
  String ascensionSuccess(int points) {
    return 'ยุคใหม่เริ่มต้น! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'เพิร์กยุคใหม่ ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return 'เหลือ $points ⏳ ให้ใช้';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => 'สูงสุด';

  @override
  String get ascensionIncomeName => 'แหล่งพลังงาน';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% รายได้ต่อเลเวล';
  }

  @override
  String get ascensionStarBonusName => 'ดาวเจิดจรัส';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% พลังต่อดาว ต่อเลเวล';
  }

  @override
  String get ascensionStarGainName => 'ดาวอุดม';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% อัตราได้ดาว ต่อเลเวล';
  }

  @override
  String get achAscend => 'เริ่มยุคใหม่ครั้งแรก';

  @override
  String get dailyQuestsTitle => 'ภารกิจรายวัน';

  @override
  String get dailyQuestsChip => 'ภารกิจ';

  @override
  String get chHeader => '🔥 ภารกิจท้าทาย (ยาก — รางวัลสูง)';

  @override
  String chCat(int n) {
    return 'จับแมวฝนทอง $n ตัว';
  }

  @override
  String chVip(int n) {
    return 'เสิร์ฟลูกค้า VIP $n คน';
  }

  @override
  String get chBonusLabel => 'ทำภารกิจท้าทายครบทั้ง 2';

  @override
  String get lbrTitle => 'รางวัลท็อปประจำสัปดาห์';

  @override
  String lbrIntro(int first, int second, int third) {
    return 'ทุกสัปดาห์ท็อป 3 ของทุกกระดานสะสม (รายได้ ไข่มุกร่วง สะสม VIP ผู้เชี่ยวชาญสูตร ชงตามออเดอร์) รับ $first / $second / $third 💎 กระดานจะถูกล็อกต้นสัปดาห์ (วันจันทร์ UTC) และรับรางวัลได้อีกหนึ่งสัปดาห์';
  }

  @override
  String get lbrEmpty => 'ยังไม่มีรางวัล — ไต่ขึ้นท็อป 3 ของกระดานอันดับ!';

  @override
  String lbrRow(String board, String week) {
    return '$board · สัปดาห์ $week';
  }

  @override
  String lbrClaim(int n) {
    return 'รับ $n 💎';
  }

  @override
  String lbrGot(int n) {
    return 'รับ $n 💎 รางวัลท็อปประจำสัปดาห์แล้ว!';
  }

  @override
  String get lbrErrGone => 'รางวัลนี้หมดอายุหรือไม่มีแล้ว';

  @override
  String get lbrBoardIncome => 'รายได้';

  @override
  String get lbrBoardPearls => 'ไข่มุกร่วง';

  @override
  String get lbrBoardCollection => 'สะสม';

  @override
  String get lbrBoardVip => 'VIP';

  @override
  String get dailyQuestsBonusLabel => 'ทำครบ 3 ภารกิจ';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'ภารกิจใหม่ใน $time';
  }

  @override
  String get dailyQuestClaimed => 'รับแล้ว';

  @override
  String dqTap(int n) {
    return 'แตะแก้ว $n ครั้ง';
  }

  @override
  String dqBuy(int n) {
    return 'ซื้ออัปเกรด $n ครั้ง';
  }

  @override
  String dqEarn(Object amount) {
    return 'หาเงิน $amount เหรียญ';
  }

  @override
  String get dqCat => 'จับแมวทอง';

  @override
  String get dqVip => 'บริการลูกค้า VIP';

  @override
  String get dqSpin => 'หมุนวงล้อนำโชค';

  @override
  String get weeklyQuestsTitle => 'ภารกิจประจำสัปดาห์';

  @override
  String get weeklyQuestsOpen => 'ภารกิจสัปดาห์ 🗓️';

  @override
  String wqPrestige(int n) {
    return 'เพรสทีจ $n ครั้ง';
  }

  @override
  String wqM3Win(int n) {
    return 'ชนะ $n ด่านไข่มุกร่วง';
  }

  @override
  String wqTrade(int n) {
    return 'ซื้อขายในตลาด $n ครั้ง (ลงขายหรือซื้อ)';
  }

  @override
  String wqDailyDone(int n) {
    return 'รับรางวัลภารกิจประจำวัน $n ครั้ง';
  }

  @override
  String wqSpin(int n) {
    return 'หมุนวงล้อ $n ครั้ง';
  }

  @override
  String wqBuy(int n) {
    return 'ซื้ออัปเกรด $n ครั้ง';
  }

  @override
  String get weeklyChestLabel =>
      'หีบประจำสัปดาห์: ทำครบ 3 → ได้ของตกแต่งระดับหายากขึ้นไป 1 ชิ้น';

  @override
  String weeklyResetsIn(String time) {
    return 'รีเซ็ตใน $time';
  }

  @override
  String get notifyOfflineFullTitle => 'คลังเหรียญเต็มแล้ว! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'ร้านหยุดสะสมเหรียญแล้ว — กลับมาเก็บแล้วเปิดกะใหม่กันเถอะ';

  @override
  String get notifyDailyTitle => 'วันใหม่ ภารกิจใหม่ 📋';

  @override
  String get notifyDailyBody =>
      'รางวัลรายวัน หมุนวงล้อฟรี 1 ครั้ง และภารกิจ 3 อย่างรออยู่';

  @override
  String get notifyD3Title => 'ร้านคิดถึงคุณอยู่ 3 วันแล้ว 🧋';

  @override
  String get notifyD3Body => 'คลังเหรียญเต็มมานานแล้ว กลับมาเก็บกันเถอะ';

  @override
  String get notifyD7Title => 'ผ่านไปหนึ่งสัปดาห์แล้ว! 🧋';

  @override
  String get notifyD7Body => 'ยุคใหม่ ไข่มุกร่วง และของใหม่อีกมากมายรอคุณอยู่';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 อีเวนต์: รายได้ ×$mult! เหลือ $timeLeft';
  }

  @override
  String get navMatch3 => 'เกม';

  @override
  String get m3Title => 'ไข่มุกร่วง';

  @override
  String m3Level(int n) {
    return 'ด่าน $n';
  }

  @override
  String get m3Locked => 'ยังไม่ปลดล็อก';

  @override
  String m3MovesLeft(int n) {
    return 'เหลือ $n ตา';
  }

  @override
  String get m3Score => 'คะแนน';

  @override
  String get m3Win => 'ผ่านด่าน!';

  @override
  String get m3Lose => 'ยังไม่ถึงเป้าหมาย';

  @override
  String get m3Retry => 'เล่นใหม่';

  @override
  String get m3Next => 'ด่านถัดไป';

  @override
  String get m3Back => 'รายการด่าน';

  @override
  String get m3Reward => 'รางวัล';

  @override
  String get m3NoReward => 'รับรางวัลด่านนี้ไปแล้ว';

  @override
  String get m3LeaveTitle => 'ออกจากเกมนี้?';

  @override
  String get m3LeaveBody => 'เกมที่เล่นค้างไว้จะถูกเก็บไว้จนกว่าคุณจะปิดแอป';

  @override
  String get m3LeaveStay => 'เล่นต่อ';

  @override
  String get m3LeaveConfirm => 'ออก';

  @override
  String get accessoryHowToTitle => 'คู่มือการสะสม';

  @override
  String get accessoryHowToButton => 'คู่มือ';

  @override
  String get accessoryHtp1 =>
      '🎯 เป้าหมาย: สะสมให้ครบทุกชิ้น ไอเทมที่สวมรอบแก้วให้บัฟเล็กน้อยตามตระกูล (🔥 แตะ · ✨ รายได้ · 🌿 ออฟไลน์ · 💎 ค่าอัปเกรด) ใส่หลายชิ้นจากตระกูลเดียวกันเพื่อรับคอมโบ การถอด/เปลี่ยนมีเวลารอ ดูโฆษณาเพื่อปลดล็อกทันที อวดเพื่อนและไต่อันดับสะสม';

  @override
  String get accessoryHtp2 =>
      '🎁 วิธีได้รับ: ทำเควสต์รายวันครบ 3 ข้อ · ผ่านด่านหมุดหมายไข่มุกร่วง (10/30/60) · ช่องหีบของวงล้อหลัก · ทุกครั้งที่เลื่อนขั้น · ซื้อแพ็กของแต่งด้วย 💎';

  @override
  String get accessoryHtp3 =>
      '🎰 วงล้อของแต่ง: หมุนแต่ละครั้งต้องดูโฆษณา 1 ครั้งหรือใช้ 💎 การหมุนด้วยโฆษณามีจำกัดต่อวัน';

  @override
  String get accessoryHtp4 =>
      '✨ ความหายาก: ธรรมดา → หายาก → มหากาพย์ → ตำนาน วันหยุดสุดสัปดาห์และเทศกาลเพิ่มโอกาสมหากาพย์/ตำนาน แพ็กหายาก/มหากาพย์รับประกันความหายากขั้นต่ำ และเทศกาลมีแพ็กเทศกาลที่มีของเฉพาะ';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ ได้ของซ้ำ: รับ $gems 💎 และสำเนาสำรอง 1 ชิ้นไว้ขายที่ตลาด';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 ตลาด: ขายสำเนาสำรองเพื่อรับเหรียญตลาด ซื้อชิ้นที่ขาดจากผู้เล่นอื่น (ค่าธรรมเนียม 1%) เหรียญตลาดซื้อได้ด้วยเหรียญหรือ 💎 และแลกกลับไม่ได้';

  @override
  String get accessoryHtp7 =>
      '🏅 หมุดหมายการสะสม (10/25/40/50/80/100/120/140/160 ชิ้น) ให้เหรียญตลาด เพิ่มชิ้นที่อยากได้ลงรายการที่อยากได้ อันดับนับจากจำนวนชิ้นที่ไม่ซ้ำกัน';

  @override
  String get accessoryHtp8 =>
      '👆 แตะชิ้นที่มีอยู่เพื่อตั้งโชว์รอบแก้วบนหน้าหลัก';

  @override
  String m3AdMoves(int n) {
    return 'ดูโฆษณา: +$n ตา';
  }

  @override
  String get m3KeepPlaying => 'เล่นต่อ';

  @override
  String get m3Pause => 'พักก่อน';

  @override
  String get m3GoalReached => 'ถึงเป้าหมายแล้ว!';

  @override
  String m3NeedScore(String n, int star) {
    return 'อีก $n คะแนนได้ $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return 'อีก $n $icon ได้ $star★';
  }

  @override
  String get m3HowToTitle => 'วิธีเล่นไข่มุกร่วง';

  @override
  String get m3HtpSwap =>
      '🔄 สลับช่องที่ติดกันสองช่อง (แตะช่องหนึ่งแล้วแตะอีกช่อง หรือปัด) ให้เรียงชนิดเดียวกัน 3 ช่องขึ้นไป ถ้าสลับแล้วไม่เกิดแถวจะไม่นับ';

  @override
  String get m3HtpGoal =>
      '🎯 แต่ละด่านมีเป้าหมายเดียว: ทำคะแนนให้ถึง หรือเก็บช่องชนิดที่กำหนดให้ครบ ดูเป้าหมายได้ที่แถบด้านบน';

  @override
  String get m3HtpMoves =>
      '👣 จำนวนตาจำกัด หมดตาคือจบด่าน จึงควรเลือกตาที่เคลียร์ได้มากที่สุด';

  @override
  String get m3HtpChain =>
      '⛓️ ช่องที่หายไปทำให้ช่องด้านบนร่วงลงมา ถ้าเกิดแถวใหม่จะต่อเนื่องเป็นลูกโซ่ และขั้นถัดไปได้คะแนนมากขึ้นมาก';

  @override
  String get m3HtpSpecial =>
      '💥 เรียง 4 ช่องได้ระเบิดกากบาท (เคลียร์ทั้งแถวและคอลัมน์) เรียง 5 ช่องขึ้นไปได้ระเบิดสี 🌈 (เคลียร์ทุกช่องชนิดนั้น) จับคู่เหมือนช่องปกติเพื่อจุดระเบิด';

  @override
  String get m3HtpStars =>
      '⭐ ดาวสามดวงบนแถบคือสามระดับ ถึงดวงแรกคือผ่านด่าน กด \"เล่นต่อ\" เพื่อใช้ตาที่เหลือไล่เก็บดาวเพิ่ม';

  @override
  String get m3HtpReward =>
      '🎁 รางวัลจ่ายเฉพาะครั้งแรกที่ถึงดาวแต่ละดวง เล่นซ้ำด่านเดิมจะไม่ได้เพิ่ม';

  @override
  String get m3LbTitle => 'อันดับไข่มุกร่วง';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty =>
      'ยังไม่มีใครบนกระดาน ผ่านสักสองสามด่านแล้วคุณจะเป็นที่หนึ่ง!';

  @override
  String get m3LbNoStars => 'คุณยังไม่มีดาว — ผ่านหนึ่งด่านเพื่อขึ้นกระดาน';

  @override
  String m3LbLevels(int n) {
    return '$n ด่าน';
  }

  @override
  String get m3LbError => 'โหลดอันดับไม่ได้ ลองใหม่ภายหลัง';

  @override
  String eventBanner(String name) {
    return '🎉 อีเวนต์ $name';
  }

  @override
  String eventTitle(String name) {
    return 'อีเวนต์ $name';
  }

  @override
  String eventEndsIn(String time) {
    return 'สิ้นสุดใน $time';
  }

  @override
  String eventPoints(int n) {
    return 'แต้มอีเวนต์: $n';
  }

  @override
  String get eventRedeemHint =>
      'ทำภารกิจเพื่อรับแต้ม แล้วแลกไอเทมพิเศษฟรี แต้มไม่พอแลกครบชุด — เลือกชิ้นที่ชอบ!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost แต้ม';
  }

  @override
  String get eventLbTitle => 'อันดับอีเวนต์';

  @override
  String get eventLbEmpty => 'ยังไม่มีใครติดอันดับ แตะไม่กี่ครั้งก็ที่ 1!';

  @override
  String get eventLbNoScore =>
      'คุณยังไม่มีคะแนน — แตะแก้ว จับแมว บริการ VIP เพื่อขึ้นอันดับ';

  @override
  String eventLbMyScore(int n) {
    return 'คะแนนของคุณ: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n คะแนน';
  }

  @override
  String eventBuff(String mult) {
    return 'รายได้ ×$mult ตลอดอีเวนต์';
  }

  @override
  String get guildTitle => 'กิลด์';

  @override
  String get guildIntro =>
      'สร้างหรือเข้าร่วมกิลด์เพื่อทำเป้าหมายรายสัปดาห์ร่วมกันและรับรางวัล';

  @override
  String get guildCreate => 'สร้างกิลด์';

  @override
  String get guildJoin => 'เข้าร่วม';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max สมาชิก';
  }

  @override
  String guildWeekTotal(int n) {
    return 'สัปดาห์นี้: $n แต้ม';
  }

  @override
  String get guildNameLabel => 'ชื่อกิลด์ (3-20 ตัวอักษร)';

  @override
  String get guildTagLabel => 'แท็ก (ตัวอักษร/ตัวเลข 2-4 ตัว)';

  @override
  String get guildLeave => 'ออกจากกิลด์';

  @override
  String get guildLeaveConfirm =>
      'ออกจากกิลด์นี้? แต้มรายสัปดาห์ของคุณจะไม่นับให้กิลด์อีก';

  @override
  String get guildKick => 'เชิญออก';

  @override
  String guildKickConfirm(String name) {
    return 'เชิญ $name ออกจากกิลด์?';
  }

  @override
  String get guildReport => 'รายงานกิลด์';

  @override
  String get guildReportSent => 'ส่งรายงานแล้ว ขอบคุณ';

  @override
  String get guildGoalTitle => 'เป้าหมายสัปดาห์';

  @override
  String get guildClaim => 'รับ';

  @override
  String get guildHowToTitle => 'วิธีหาแต้มกิลด์';

  @override
  String guildHowTo(int n) {
    return '⭐ แต้มกิลด์มาจากกิจกรรมของคุณในสัปดาห์นี้: แตะแก้ว +1 จับแมว +50 เสิร์ฟลูกค้า VIP +50\n🎯 แต้มของทุกคนรวมกันเพื่อปลดล็อกรางวัลเป้าหมาย รีเซ็ตทุกวันจันทร์ 00:00 UTC\n🎁 ต้องสะสมแต้มส่วนตัว ≥$n จึงจะรับรางวัลเป้าหมายได้';
  }

  @override
  String guildNeedPoints(int n) {
    return 'ต้องสะสม ≥$n แต้มเพื่อรับ';
  }

  @override
  String guildYourPoints(int n) {
    return 'คุณสะสม: $n แต้ม';
  }

  @override
  String get guildOwner => 'หัวหน้า';

  @override
  String get guildEmpty => 'ยังไม่มีกิลด์สาธารณะ สร้างกิลด์แรกเลย!';

  @override
  String get guildErrNameTaken => 'ชื่อกิลด์นี้ถูกใช้แล้ว';

  @override
  String get guildErrFull => 'กิลด์เต็มแล้ว';

  @override
  String guildExpandButton(int cost, int max) {
    return 'ขยายเป็น $max ที่ · $cost 💎';
  }

  @override
  String guildExpandConfirm(int cost, int max) {
    return 'ขยายกิลด์เป็น $max คนด้วย $cost 💎 ไหม?';
  }

  @override
  String get guildExpandAction => 'ขยาย';

  @override
  String guildExpandDone(int max) {
    return 'กิลด์รองรับได้สูงสุด $max คนแล้ว!';
  }

  @override
  String get guildExpandMaxed => 'กิลด์มีความจุสูงสุดแล้ว';

  @override
  String get guildErrAlready => 'คุณอยู่ในกิลด์แล้ว';

  @override
  String get guildErrInvalid => 'ชื่อหรือแท็กไม่ถูกต้อง';

  @override
  String get guildErrNotFound => 'ไม่พบกิลด์ (อาจปิดไปแล้ว)';

  @override
  String get guildErrContribution => 'คุณต้องสะสมแต้มเพิ่มในสัปดาห์นี้';

  @override
  String get guildErrNetwork => 'เชื่อมต่อไม่ได้ ลองใหม่อีกครั้ง';

  @override
  String get guildLbTitle => 'อันดับกิลด์';

  @override
  String get guildLbEmpty => 'สัปดาห์นี้ยังไม่มีกิลด์ที่มีแต้ม';

  @override
  String guildRewardGot(int gems) {
    return 'ได้รับ +$gems 💎';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return 'ได้รับ +$gems 💎 และ $name';
  }

  @override
  String guildPoints(int n) {
    return '$n แต้ม';
  }

  @override
  String guildCreateCost(int n) {
    return 'ค่าสร้างกิลด์: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return 'ต้องมี $n 💎 เพื่อสร้างกิลด์';
  }

  @override
  String get guildApprovalSwitch => 'หัวหน้าต้องอนุมัติคำขอเข้าร่วม';

  @override
  String get guildRequestJoin => 'ขอเข้าร่วม';

  @override
  String get guildRequestSent => 'ส่งคำขอแล้ว รอหัวหน้าอนุมัติ';

  @override
  String get guildRequestPending => 'รออนุมัติ';

  @override
  String guildRequestsTitle(int n) {
    return 'คำขอเข้าร่วม ($n)';
  }

  @override
  String get guildAccept => 'อนุมัติ';

  @override
  String get guildReject => 'ปฏิเสธ';

  @override
  String get guildErrApproval =>
      'กิลด์นี้ต้องให้หัวหน้าอนุมัติ — กด \"ขอเข้าร่วม\"';

  @override
  String get guildErrNicknameTaken =>
      'มีคนในกิลด์นี้ใช้ชื่อนี้แล้ว โปรดเลือกชื่ออื่น';

  @override
  String get guildErrRequestsFull => 'กิลด์นี้มีคำขอรออนุมัติมากเกินไป';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 เครื่องนี้: $local · บนคลาวด์: $cloud';
  }

  @override
  String get cloudRemindTitle => 'ปกป้องความคืบหน้าของคุณ';

  @override
  String get cloudRemindBody =>
      'คุณยังไม่ได้ผูกอีเมล หากเปลี่ยนเครื่องหรือติดตั้งใหม่ ความคืบหน้า (เหรียญ, 💎, ของตกแต่ง, เหรียญตลาด) จะหายทั้งหมด การผูกใช้เวลาแค่ 1 นาทีและฟรี';

  @override
  String get cloudRemindLink => 'ผูกเลย';

  @override
  String get cloudRemindLater => 'ไว้ทีหลัง';

  @override
  String get ftueTap => 'แตะที่แก้วเพื่อชงชาและหาเหรียญ!';

  @override
  String get ftueBuy =>
      'เหรียญพอแล้ว! ซื้ออัปเกรดแรกเพื่อให้เหรียญไหลเข้ามาทุกวินาที';

  @override
  String get ftueExplain =>
      'เยี่ยม! ตอนนี้เหรียญเพิ่มขึ้นทุกวินาที แม้ปิดแอป อัปเกรดต่อเพื่อหาเงินเร็วขึ้น ปลดล็อกด่านใหม่ และรับรางวัลภารกิจ';

  @override
  String get ftueOk => 'เข้าใจแล้ว';

  @override
  String get ftueSkip => 'ข้าม';

  @override
  String get accessoryGuildFlag => 'ธงกิลด์';

  @override
  String get accessoryGuildCastle => 'ปราสาทกิลด์';

  @override
  String get accessoryGuildWolf => 'หมาป่ากิลด์';

  @override
  String get accessoryGuildDragon => 'มังกรกิลด์';

  @override
  String get accessoryGuildFox => 'จิ้งจอกกิลด์';

  @override
  String get accessoryGuildTiger => 'เสือกิลด์';

  @override
  String get accessoryGuildShark => 'ฉลามกิลด์';

  @override
  String get accessoryGuildTrex => 'ไทแรนโนซอรัสกิลด์';

  @override
  String get accessoryGuildBoar => 'หมูป่ากิลด์';

  @override
  String get accessoryGuildBear => 'หมีกิลด์';

  @override
  String get accessoryGuildScorpion => 'แมงป่องกิลด์';

  @override
  String get accessoryGuildMoai => 'โมอายกิลด์';

  @override
  String get guildChatTitle => 'แชทกิลด์';

  @override
  String get guildChatEmpty => 'ยังไม่มีข้อความ เป็นคนแรกที่พูดเลย!';

  @override
  String get guildChatHint => 'ส่งข้อความถึงกิลด์…';

  @override
  String get guildChatSend => 'ส่ง';

  @override
  String get guildChatPinned => 'ประกาศ';

  @override
  String get guildChatPin => 'ปักหมุด';

  @override
  String get guildChatUnpin => 'เลิกปักหมุด';

  @override
  String get guildChatDelete => 'ลบข้อความ';

  @override
  String get guildChatReport => 'รายงานข้อความ';

  @override
  String get guildChatReported => 'รายงานข้อความแล้ว คุณจะไม่เห็นข้อความนี้อีก';

  @override
  String get guildMembersHeader => 'สมาชิก';

  @override
  String get guildMemberSearchHint => 'ค้นหาสมาชิก';

  @override
  String get guildMemberNoMatch => 'ไม่พบสมาชิกที่ตรงกัน';

  @override
  String get guildRoleOwner => 'หัวหน้ากิลด์';

  @override
  String get guildRoleOfficer => 'รองหัวหน้า';

  @override
  String get guildRoleMember => 'สมาชิก';

  @override
  String get guildMemberMention => 'แท็กในแชต';

  @override
  String get guildMemberProfile => 'ดูโปรไฟล์';

  @override
  String get guildQuestsSection => 'ภารกิจกิลด์';

  @override
  String get guildQuestsSectionHint =>
      'รีเซ็ตทุกวันจันทร์ 00:00 UTC · รับเหรียญกิลด์';

  @override
  String get guildManage => 'จัดการ';

  @override
  String get guildPromote => 'แต่งตั้งรองหัวหน้า';

  @override
  String get guildDemote => 'ปลดรองหัวหน้า';

  @override
  String get guildTransfer => 'โอนตำแหน่งหัวหน้า';

  @override
  String get guildTeamTitle => 'ภารกิจทีมสัปดาห์นี้';

  @override
  String guildTeamProgress(int active, int need) {
    return '$active / $need คนทำสำเร็จ';
  }

  @override
  String guildTeamHint(int n) {
    return 'ถ้าครึ่งหนึ่งของกิลด์ (อย่างน้อย 2 คน) ได้ $n แต้มรายสัปดาห์ ทุกคนที่ทำถึงจะได้รางวัล เล่นด้วยกันนะ!';
  }

  @override
  String guildTeamClaim(int n) {
    return 'รับ $n เหรียญกิลด์';
  }

  @override
  String guildTeamGot(int n) {
    return 'ได้รับ $n เหรียญกิลด์จากภารกิจทีม!';
  }

  @override
  String get guildErrTeamNotReached => 'ยังมีสมาชิกทำแต้มถึงไม่พอ';

  @override
  String guildErrTeamLow(int n) {
    return 'ต้องมีอย่างน้อย $n แต้มรายสัปดาห์จึงจะรับได้';
  }

  @override
  String get guildFundTitle => 'กองทุนกิลด์สัปดาห์นี้';

  @override
  String guildFundMine(int n) {
    return 'คุณบริจาคแล้ว $n 💎';
  }

  @override
  String guildFundClaim(int n) {
    return 'รับ $n เหรียญกิลด์';
  }

  @override
  String guildFundHint(int min) {
    return 'ทุกคนช่วยกันบริจาค 💎 ให้ถึงเป้าหมาย (เพิ่มตามจำนวนสมาชิก) สมาชิกแต่ละคนต้องบริจาคอย่างน้อย $min 💎 จึงจะรับรางวัลได้';
  }

  @override
  String guildFundGot(int n) {
    return 'รับ $n เหรียญกิลด์จากกองทุนแล้ว!';
  }

  @override
  String get guildErrFundNotReached => 'กองทุนกิลด์ยังไม่ถึงเป้าหมาย';

  @override
  String guildErrFundLow(int n) {
    return 'คุณต้องบริจาคให้กองทุนอย่างน้อย $n 💎 จึงจะรับรางวัลได้';
  }

  @override
  String guildFundProgress(int progress, int target) {
    return '$progress / $target 💎';
  }

  @override
  String guildTransferConfirm(String name) {
    return 'โอนตำแหน่งหัวหน้าให้ $name? คุณจะกลายเป็นสมาชิกทั่วไป';
  }

  @override
  String get guildErrNotAllowed => 'คุณไม่มีสิทธิ์จัดการสมาชิกคนนี้';

  @override
  String guildErrOfficersFull(int n) {
    return 'กิลด์มีรองหัวหน้าครบ $n คนแล้ว';
  }

  @override
  String get guildActivityTitle => 'บันทึกกิลด์';

  @override
  String get guildActivityEmpty => 'ยังไม่มีกิจกรรม';

  @override
  String guildEvJoined(String name) {
    return '$name เข้าร่วมกิลด์';
  }

  @override
  String guildEvLeft(String name) {
    return '$name ออกจากกิลด์';
  }

  @override
  String guildEvKicked(String actor, String target) {
    return '$actor เชิญ $target ออกจากกิลด์';
  }

  @override
  String guildEvPromoted(String actor, String target) {
    return '$actor แต่งตั้ง $target เป็นรองหัวหน้า';
  }

  @override
  String guildEvDemoted(String actor, String target) {
    return '$actor ปลด $target จากรองหัวหน้า';
  }

  @override
  String guildEvTransferred(String actor, String target) {
    return '$actor โอนตำแหน่งหัวหน้าให้ $target';
  }

  @override
  String get guildErrChatRate => 'คุณส่งเร็วเกินไป รอสักครู่';

  @override
  String get guildErrTextBlocked => 'ข้อความมีคำที่ไม่อนุญาต';

  @override
  String guildErrDailyLimit(int n) {
    return 'วันนี้คุณบริจาคครบสูงสุด $n 💎 แล้ว';
  }

  @override
  String get guildErrCoins => 'เหรียญกิลด์ไม่พอ';

  @override
  String get guildErrOwned => 'คุณมีไอเทมนี้แล้ว';

  @override
  String get guildErrBuffMaxed => 'บัฟกิลด์เต็มสูงสุดแล้ว รอสักครู่';

  @override
  String get guildErrClaimed => 'คุณรับรางวัลนี้ไปแล้ว';

  @override
  String get guildErrInvalidInput => 'การกระทำไม่ถูกต้อง';

  @override
  String get guildShopButton => 'ร้านค้ากิลด์';

  @override
  String get guildShopTitle => 'ร้านค้ากิลด์';

  @override
  String guildCoinsLabel(int n) {
    return 'เหรียญกิลด์: $n';
  }

  @override
  String get guildDonateTitle => 'บริจาค 💎 รับเหรียญกิลด์';

  @override
  String guildDonateHint(int used, int cap) {
    return 'วันนี้: $used/$cap 💎 · 1 💎 = 1 เหรียญกิลด์';
  }

  @override
  String guildDonateGems(int n) {
    return '$n 💎';
  }

  @override
  String guildDonated(int n) {
    return 'บริจาคแล้ว ได้รับ +$n เหรียญกิลด์';
  }

  @override
  String get guildQuestsTitle => 'ภารกิจกิลด์ประจำสัปดาห์';

  @override
  String guildQuestProgress(int have, int need) {
    return 'สะสม $need แต้มในสัปดาห์นี้ ($have/$need)';
  }

  @override
  String guildQuestReward(int n) {
    return '+$n เหรียญกิลด์';
  }

  @override
  String guildQuestGot(int n) {
    return 'ได้รับ +$n เหรียญกิลด์';
  }

  @override
  String get guildItemsTitle => 'ของตกแต่งพิเศษของกิลด์';

  @override
  String guildItemPrice(int n) {
    return '$n เหรียญ';
  }

  @override
  String get guildItemOwned => 'มีแล้ว';

  @override
  String get guildItemBought => 'แลกแล้ว! ของตกแต่งอยู่ในคลังของคุณ';

  @override
  String get guildBuffTitle => 'บัฟรายได้กิลด์';

  @override
  String guildBuffDesc(int pct, int hours) {
    return '+$pct% เหรียญนาน $hours ชั่วโมงสำหรับสมาชิกทุกคน (ไม่ใช้ตอนออฟไลน์)';
  }

  @override
  String guildBuffLeft(String time) {
    return 'เหลือ $time';
  }

  @override
  String get guildBuffBought => 'เปิดใช้บัฟกิลด์แล้ว!';

  @override
  String guildStreakLine(int n) {
    return '🔥 ทำครบ 3 เป้าหมาย $n สัปดาห์ติดต่อกัน';
  }

  @override
  String guildBuffLine(int pct, String time) {
    return '⚡ บัฟกิลด์ +$pct% · เหลือ $time';
  }

  @override
  String get guildLbTabTotal => 'รวม';

  @override
  String get guildLbTabAvg => 'เฉลี่ย';

  @override
  String get guildLbTabStreak => 'ต่อเนื่อง';

  @override
  String guildLbAvgNote(int n) {
    return 'เฉพาะกิลด์ที่มี $n สมาชิกขึ้นไปเท่านั้นที่ติดอันดับ';
  }

  @override
  String guildAvgPerMember(int n) {
    return '$n/คน';
  }

  @override
  String guildStreakWeeks(int n) {
    return '$n สัปดาห์';
  }

  @override
  String get guildLbStreakNote =>
      'จำนวนสัปดาห์ติดต่อกันที่กิลด์ทำครบ 3 เป้าหมาย';

  @override
  String get guildLbStreakEmpty => 'ยังไม่มีกิลด์ที่มีสถิติต่อเนื่อง';

  @override
  String get guildLbAvgEmpty => 'ยังไม่มีกิลด์ที่เข้าเงื่อนไขอันดับเฉลี่ย';

  @override
  String get recipeOrderOrders => 'ชงตามออเดอร์';

  @override
  String recipeOrderAsk(String drink) {
    return 'ลูกค้าสั่ง: $drink';
  }

  @override
  String get recipeOrderGuideFull => 'สูตรตัวอย่าง';

  @override
  String get recipeOrderGuideNames => 'วัตถุดิบที่ต้องใช้ (จำปริมาณให้ได้)';

  @override
  String recipeOrderGuideCount(int n) {
    return 'เมนูนี้มีวัตถุดิบ $n อย่าง — ลองจำดูนะ!';
  }

  @override
  String get recipeOrderGuideNone => 'ไม่มีคำใบ้ — ชงจากความจำ!';

  @override
  String get recipeOrderTray => 'ถาดวัตถุดิบ — ลากใส่แก้วหรือแตะเพื่อเลือก';

  @override
  String get recipeOrderCupEmpty => 'แก้วยังว่างอยู่';

  @override
  String recipeOrderSetAmount(String name) {
    return 'ปริมาณ $name';
  }

  @override
  String get recipeOrderPour => 'ใส่แก้ว';

  @override
  String get recipeOrderRemove => 'เอาออก';

  @override
  String get recipeOrderServe => 'เสิร์ฟ';

  @override
  String get recipeOrderPerfect => 'เยี่ยม! ปริมาณถูกทุกอย่าง';

  @override
  String get recipeOrderGood => 'ผ่าน — ปริมาณคลาดเล็กน้อย';

  @override
  String get recipeOrderFail => 'ยังไม่ใช่เมนูที่สั่ง';

  @override
  String recipeOrderMissing(String amount, String name) {
    return 'ขาด $name ($amount)';
  }

  @override
  String recipeOrderExtra(String name) {
    return 'เกิน $name — ไม่มีในสูตร';
  }

  @override
  String recipeOrderOff(String mine, String name, String right) {
    return '$name: คุณใส่ $mine ที่ถูกคือ $right';
  }

  @override
  String get recipeOrderHint => 'เคล็ดลับ: แตะวัตถุดิบที่ใส่แล้วเพื่อแก้ปริมาณ';

  @override
  String get rlbTabQuiz => 'ควิซ';

  @override
  String get rlbOrderEmpty =>
      'ยังไม่มีใครในอันดับ มาเป็นคนแรกที่ชงเมนูได้สมบูรณ์แบบโดยไม่ดูสูตรตัวอย่าง!';

  @override
  String get rlbNoPerfect =>
      'คุณยังไม่เคยชงเมนูได้สมบูรณ์แบบ (โดยไม่ดูสูตรตัวอย่าง) จึงยังไม่มีชื่อในอันดับ';

  @override
  String rlbPerfect(int n) {
    return 'สมบูรณ์แบบ $n เมนู';
  }

  @override
  String get recipeOrderHold => 'กดค้างเพื่อเท';

  @override
  String get recipeOrderPourAgain => 'เทใหม่';

  @override
  String recipeOrderCombo(int n) {
    return '🔥 คอมโบ ×$n';
  }

  @override
  String recipeOrderComboTip(String cash, int combo) {
    return 'คอมโบ ×$combo: ทิป +$cash เหรียญ!';
  }

  @override
  String get rlbTabDaily => 'วันนี้';

  @override
  String get rlbDailyEmpty =>
      'วันนี้ยังไม่มีใครส่งคะแนน ลองทำภารกิจเพื่อเป็นคนแรกบนอันดับ!';

  @override
  String get rlbNoDaily => 'ทำภารกิจวันนี้เพื่อให้มีชื่อบนอันดับ';

  @override
  String rlbDailyScore(Object n) {
    return '$n คะแนน';
  }

  @override
  String get recipeDailyTitle => 'ภารกิจวันนี้';

  @override
  String get recipeDailyOpen => 'ออเดอร์ยาก 3 อย่าง ไม่มีคำใบ้ — วันละครั้ง';

  @override
  String recipeDailyDone(Object score) {
    return 'วันนี้คุณได้ $score/300';
  }

  @override
  String recipeDailyOrderScore(Object n) {
    return 'ออเดอร์นี้: $n/100';
  }

  @override
  String recipeDailyTotal(Object n) {
    return '$n/300 คะแนน';
  }

  @override
  String get recipeDailyAlready =>
      'คุณทำภารกิจวันนี้แล้ว พรุ่งนี้มาใหม่ มีออเดอร์ใหม่ทุกวัน!';

  @override
  String get recipeDailyBoard => 'ดูอันดับวันนี้';

  @override
  String get recipeDailyIntro =>
      'ออเดอร์เหมือนกันสำหรับทุกคน ไม่มีคำใบ้ ปริมาณต้องตรงทุกระดับ ทำได้วันละครั้ง';

  @override
  String get recipeOrderRush => 'ชั่วโมงเร่งด่วน';

  @override
  String get recipeOrderRushSub =>
      'ลูกค้ารอไม่นาน เสิร์ฟเครื่องดื่มสมบูรณ์แบบให้ทันเวลาเพื่อรับทิปเพิ่ม ถ้าหมดเวลา แก้วจะถูกตัดสินตามที่เป็นอยู่';

  @override
  String get recipeOrderTimeUp =>
      '⏰ หมดเวลา! ลูกค้าจากไปแล้ว แก้วถูกตัดสินตามที่เป็นอยู่';

  @override
  String recipeOrderRushTip(String cash) {
    return '⏱ เสิร์ฟทันเวลา! ทิป +$cash เหรียญ!';
  }

  @override
  String recipeOrderFestival(String name) {
    return 'ออเดอร์เทศกาล: $name';
  }

  @override
  String recipeOrderFestivalTip(String cash) {
    return '🎁 ออเดอร์เทศกาลสมบูรณ์แบบ! ทิป +$cash เหรียญ!';
  }

  @override
  String get recipeOrderShare => 'อวดแก้วนี้';

  @override
  String get cupShareTitle => 'แก้วสมบูรณ์แบบ';

  @override
  String get cupSharePerfect => 'ชงสมบูรณ์แบบ!';

  @override
  String cupShareText(String name) {
    return 'ฉันเพิ่งชง $name ได้สมบูรณ์แบบใน Boba Empire! 🧋';
  }

  @override
  String recipeCounterNext(int count) {
    return 'เชี่ยวชาญ $count สูตรเพื่อเปิดช่องโชว์เพิ่ม 1 ช่อง';
  }

  @override
  String get lbrBoardOrders => 'ชงตามออเดอร์';

  @override
  String get storySpeedrunTabExt3 => 'ภาค 4';

  @override
  String get storySpeedrunExt3NotCompletedYet =>
      'คุณยังไม่จบภาค 4 — จบตอนที่ 46 เพื่อติดอันดับ';

  @override
  String storyCondRecipes(int n, String game) {
    return 'เชี่ยวชาญ $n สูตรใน $game';
  }

  @override
  String storyCondOrders(int n, String game) {
    return 'ทำเครื่องดื่มสมบูรณ์แบบ $n แก้วใน $game';
  }

  @override
  String storyCondDaily(int n, String game) {
    return 'ทำ $game ให้ครบ $n วัน';
  }

  @override
  String get lbrBoardDaily => 'ภารกิจประจำวัน';

  @override
  String get lbrBoardArena => 'ทัวร์นาเมนต์อารีนา';

  @override
  String lbrDailyNote(int rest) {
    return 'ภารกิจประจำวัน: ท็อป 10 ตามคะแนนรวมของสัปดาห์ที่แล้วก็ได้รางวัล อันดับ 1-3 เหมือนด้านบน อันดับ 4-10 รับ $rest 💎';
  }

  @override
  String get rlbDailyWeeklyHint =>
      'ทุกสัปดาห์ท็อป 10 ตามคะแนนรวมภารกิจประจำวันทั้งสัปดาห์รับ 💎 (ล็อกต้นสัปดาห์ถัดไป UTC)';

  @override
  String get howToTooltip => 'วิธีเล่น';

  @override
  String get howToRecipesTitle => 'วิธีเล่น: สูตรเครื่องดื่ม';

  @override
  String get howToRecipes1 =>
      'เรียนสูตรด้วยการทบทวนแบบเว้นระยะ: ทุกวันเกมจะเลือกเครื่องดื่มที่ถึงเวลาทบทวน แล้วเจ้าตอบคำถามไม่กี่ข้อ';

  @override
  String howToRecipes2(int a, int b, int c) {
    return 'เครื่องดื่มแต่ละอย่างมี 4 ระดับ: ใหม่ → คุ้นเคย → ท่องได้ → เชี่ยวชาญ ตอบถูกจะขึ้นระดับและนัดทบทวนอีก $a / $b / $c วัน ตอบผิดจะลดหนึ่งระดับและกลับมาทันที';
  }

  @override
  String get howToRecipes3 =>
      'คำถามยากขึ้นตามระดับ: ใหม่เติมวัตถุดิบที่ขาด คุ้นเคยเดาปริมาณ ท่องได้/เชี่ยวชาญเลือกสูตรเต็มที่ถูกต้อง';

  @override
  String get howToRecipes4 =>
      'ทบทวนเครื่องดื่มที่ยังไม่ถึงเวลาเป็นแค่การฝึก ไม่เปลี่ยนระดับและไม่มีรางวัล ดูโฆษณาเพื่อรับคำใบ้ได้ (ข้อนั้นไม่นับระดับ)';

  @override
  String get howToRecipes5 =>
      'ถึงแต่ละระดับครั้งแรกได้เหรียญ ถึงเชี่ยวชาญครั้งแรกได้ 💎 ด้วย ครบเป้าจำนวนเครื่องดื่มที่เชี่ยวชาญ (5, 10, 20…) รับหีบของตกแต่ง';

  @override
  String howToRecipes6(int n) {
    return 'ทบทวนทุกวันเพื่อรักษา 🔥 สตรีคและรับ 💎 ที่ 3 / 7 / 14 / 30 วัน สตรีคขาดกู้คืนได้ด้วย 💎 เรียนรู้ $n เครื่องดื่มของกลุ่มหนึ่งเพื่อปลดล็อกกลุ่มถัดไป';
  }

  @override
  String get howToOrdersTitle => 'วิธีเล่น: ชงตามออเดอร์';

  @override
  String get howToOrders1 =>
      'ลูกค้าสั่งเครื่องดื่ม: ลาก (หรือแตะ) วัตถุดิบจากถาดลงแก้ว แล้วเลือกปริมาณ';

  @override
  String get howToOrders2 =>
      'ในหน้าเลือกปริมาณ แตะที่ไม้บรรทัดหรือกดค้างปุ่มเทเพื่อเพิ่มปริมาณ ระดับต่ำมีขีดบอกให้';

  @override
  String get howToOrders3 =>
      'แตะเสิร์ฟ: แก้วจะถูกปิดฝาและเขย่า แล้วตรวจทีละวัตถุดิบ ตรงเป๊ะ คลาดหนึ่งขั้น ปริมาณผิด ขาด หรือเกิน';

  @override
  String get howToOrders4 =>
      'ยิ่งรู้จักเครื่องดื่มมาก คำใบ้ยิ่งน้อย: ใหม่มีสูตรตัวอย่างและขีดเขียว คุ้นเคยเห็นแต่ชื่อวัตถุดิบ ท่องได้รู้แค่จำนวน เชี่ยวชาญไม่มีคำใบ้ ระดับใหม่/คุ้นเคยคลาดได้หนึ่งขั้น ท่องได้/เชี่ยวชาญต้องตรงเป๊ะ';

  @override
  String get howToOrders5 =>
      'ผลลัพธ์นับเป็นระดับของเครื่องดื่มเหมือนตอบแบบทดสอบ ดูโฆษณาเพื่อเปิดสูตรตัวอย่าง (ออเดอร์นั้นไม่นับระดับ)';

  @override
  String get howToOrders6 =>
      'ชงออเดอร์สมบูรณ์แบบติดกันโดยไม่ใช้คำใบ้ เพื่อรับคอมโบ 🔥 และทิปเหรียญ (เฉพาะเครื่องดื่มที่ถึงเวลาทบทวน)';

  @override
  String get howToOrders7 =>
      'เปิด ⏱ ชั่วโมงเร่งด่วนที่ออเดอร์แรก: ลูกค้ารอไม่นาน เสิร์ฟสมบูรณ์แบบให้ทันเวลาเพื่อรับทิปเพิ่ม ถ้าหมดเวลา แก้วจะถูกตัดสินตามที่เป็นอยู่';

  @override
  String get howToOrders8 =>
      'ช่วงเทศกาลจะมีออเดอร์เทศกาลเพิ่มตอนท้าย (ทิปมากกว่า) ชงสมบูรณ์แบบแล้วแตะ “อวดแก้วนี้” เพื่อแชร์รูปแก้ว จำนวนเครื่องดื่มที่ชงสมบูรณ์แบบโดยไม่ใช้สูตรตัวอย่างจะนับในอันดับ';

  @override
  String get howToDailyTitle => 'วิธีเล่น: ภารกิจประจำวัน';

  @override
  String get howToDaily1 =>
      'ทุกวันมีออเดอร์ยากสามรายการ เหมือนกันสำหรับผู้เล่นทุกคนในโลก';

  @override
  String get howToDaily2 =>
      'ไม่มีคำใบ้ มีวัตถุดิบตัวหลอกเยอะ และทุกปริมาณต้องตรงเป๊ะ ไม่เปลี่ยนระดับของเครื่องดื่มใด ๆ';

  @override
  String howToDaily3(int max) {
    return 'แต่ละออเดอร์ได้สูงสุด 100 คะแนน (ตรงเป๊ะ 1 คลาดหนึ่งขั้นครึ่งหนึ่ง ขาด 0 เกินถูกหัก) รวมสูงสุด $max คะแนน';
  }

  @override
  String howToDaily4(int gems) {
    return 'ทำได้วันละ หนึ่ง ครั้งเท่านั้น: เสร็จแล้วรับ $gems 💎 และเหรียญตามคะแนน คะแนนที่ส่งแล้วแก้ไม่ได้';
  }

  @override
  String get howToDaily5 =>
      'แท็บ “วันนี้” ในอันดับเรียงตามคะแนนวันนี้ ทุกสัปดาห์ท็อป 10 ตามคะแนนรวมทั้งสัปดาห์รับ 💎 (ต้องเชื่อมอีเมล)';
}
