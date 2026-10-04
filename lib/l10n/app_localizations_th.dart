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
  String get htpTap => '🧋 แตะแก้วเพื่อชงชาและรับเหรียญ';

  @override
  String get htpBuy => '🛒 ซื้ออัปเกรดเพื่อรับรายได้อัตโนมัติทุกวินาที';

  @override
  String get htpStage =>
      '🏪 สะสมเหรียญเพื่อปลดล็อกด่านใหม่ที่มีเครื่องดื่มหรูขึ้น';

  @override
  String get htpCat => '🐱 แตะแมวนำโชคเพื่อรับโกลเด้นรัช ×3 ชั่วครู่';

  @override
  String get htpVip => '🚗 บริการลูกค้า VIP เพื่อรับเพชร 💎';

  @override
  String get htpGems => '💎 ใช้เพชรในร้านค้าเพื่อซื้ออัปเกรดถาวร';

  @override
  String get htpPrestige =>
      '⭐ แฟรนไชส์เพื่อเริ่มใหม่และรับดาว — โบนัสรายได้ถาวร';

  @override
  String get htpOffline =>
      '😴 ร้านยังขายต่อขณะที่คุณไม่อยู่ — กลับมารับเงินออฟไลน์';

  @override
  String get htpNumberFormat =>
      '🔢 ตัวเลขใหญ่ใช้ตัวย่อ: K=พัน, M=ล้าน, B=พันล้าน, T=ล้านล้าน จากนั้นเป็น aa, bb, cc... — แต่ละขั้นมากกว่าขั้นก่อนหน้า 1,000 เท่า';

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
  String get rewardsTitle => 'หาเพิ่ม 🎁';

  @override
  String get rewardsChip => 'หาเพิ่ม';

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
  String get whatsNewCollection =>
      '🎀 คอลเลกชัน: เครื่องประดับ 50 ชิ้น จัดโชว์รอบแก้ว ตราบนกระดานจัดอันดับ รางวัลตามเป้าหมาย';

  @override
  String get whatsNewMarket =>
      '🛒 ตลาดเครื่องประดับ: ซื้อขายด้วยเหรียญตลาด ราคาอ้างอิง รายการที่อยากได้ แจ้งเตือนเมื่อขายได้';

  @override
  String get whatsNewWheel =>
      '🎡 วงล้อมีหีบเครื่องประดับ สุดสัปดาห์: ค่าธรรมเนียม 0% และมีโอกาสได้ของหายากมากขึ้น';

  @override
  String get whatsNewStory => '📖 เนื้อเรื่องภาค 3: เพิ่ม 8 ตอน';

  @override
  String get whatsNewLook => '🎨 ธีมพาสเทล ลื่นขึ้น แชร์คอลเลกชันเป็นรูปภาพ';

  @override
  String get whatsNewLater => 'ไว้ทีหลัง';

  @override
  String get whatsNewOpen => 'ดูคอลเลกชัน';

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
  String get marketCancelButton => 'ยกเลิกการขาย';

  @override
  String get marketCancelledToast => 'ยกเลิกการขายแล้ว';

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
  String get navMatch3 => 'ไข่มุก';

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
}
