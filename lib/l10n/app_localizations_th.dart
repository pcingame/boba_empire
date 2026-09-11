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
  String get gemTimeSkipName => 'เร่งเวลา 💎';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'รับผลผลิต $hours ชม. ทันที';
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
      '⚠️ รีเซ็ต Coin เลเวลอัปเกรด และด่าน (เพิร์ก Star เก็บบางส่วนได้)';

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
  String get arenaTitle => 'สนามประลอง';

  @override
  String get arenaIntro => 'ดวล 1v1 60 วินาที ใครได้เหรียญเยอะกว่าชนะ!';

  @override
  String get arenaStartButton => 'หาคู่แข่ง';

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
  String get cloudSaveCodeHint => 'รหัสยืนยัน';

  @override
  String get cloudSaveVerify => 'ยืนยัน';

  @override
  String get cloudSaveChangeEmail => 'ใช้อีเมลอื่น';

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
  String leaderboardStars(int stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => 'ยังไม่มีใครในกระดานอันดับ — คือคุณเลย!';

  @override
  String get leaderboardChangeName => 'เปลี่ยนชื่อ';

  @override
  String get leaderboardRetry => 'ลองอีกครั้ง';
}
