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
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'ปลดล็อก $cost เหรียญ';
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
  String prestigeIntro(int percent) {
    return '⭐ ดาวแต่ละดวงให้ +$percent% รายได้ถาวร';
  }

  @override
  String get prestigeStarsNow => 'ดาวปัจจุบัน';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'แฟรนไชส์เลย';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'โบนัสรวมหลังจากนั้น';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ จะรีเซ็ตเหรียญและระดับอัปเกรดปัจจุบันทั้งหมด';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String prestigeConfirm(int stars) {
    return 'แฟรนไชส์ (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'ไม่พอ';

  @override
  String prestigeSuccess(int stars) {
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
  String get language => 'ภาษา';

  @override
  String get languageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String get dailyTitle => 'เช็คอินรายวัน';

  @override
  String get dailyPrompt => 'รับของขวัญเข้าสู่ระบบวันนี้!';

  @override
  String get dailyClaim => 'รับ';

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
  String prestigeShopSpendable(int stars) {
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
  String prestigeStarCost(int cost) {
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
  String get stage4 => 'โรงงานบรูเล่';

  @override
  String get stage5 => 'โรงงานชีสโฟม';

  @override
  String get stage6 => 'อาณาจักรระดับโลก';
}
