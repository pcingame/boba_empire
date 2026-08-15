// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Boba Empire';

  @override
  String get tapBrew => 'Tap to brew';

  @override
  String get coinsSuffix => ' Coins';

  @override
  String incomePerSecond(String amount) {
    return '+$amount / sec';
  }

  @override
  String get instantCashButton => 'Instant cash';

  @override
  String instantCashSnack(String amount) {
    return 'Instant cash! +$amount Coins';
  }

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Unlock $cost Coins';
  }

  @override
  String generatorSubtitle(String amount) {
    return '+$amount Coins/sec per level';
  }

  @override
  String buyButton(String cost) {
    return '$cost Coins';
  }

  @override
  String boostChip(int seconds) {
    return '🔥 x3 · ${seconds}s';
  }

  @override
  String vipSnack(String cash, int gems) {
    return 'VIP customer! +$cash Coins, +$gems 💎';
  }

  @override
  String iapGemsSnack(String amount) {
    return 'Received +$amount 💎';
  }

  @override
  String get iapRemoveAdsSnack => 'Ads removed. Thank you!';

  @override
  String iapStarterSnack(String amount) {
    return 'Starter pack: +$amount 💎';
  }

  @override
  String get genTraDen => 'Black Tea';

  @override
  String get genTranChau => 'Boba Pearls';

  @override
  String get genThach => 'Grass Jelly';

  @override
  String get genPudding => 'Pudding';

  @override
  String get genKemNuong => 'Crème Brûlée Milk Tea';

  @override
  String get genMatcha => 'Bucket Matcha';

  @override
  String get stage1 => 'Street Cart';

  @override
  String get stage2 => 'Small Kiosk';

  @override
  String get stage3 => 'Luxury Cafe Chain';

  @override
  String gemShopTitle(String gems) {
    return 'Shop 💎 (you have $gems)';
  }

  @override
  String get gemBoostName => 'Income boost';

  @override
  String gemBoostDesc(int percent) {
    return '+$percent% permanent income per level';
  }

  @override
  String get offlineCapName => 'Offline cooler';

  @override
  String offlineCapDesc(int hours) {
    return '+${hours}h offline cap per level';
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
  String get iapSectionTitle => 'Buy with real money';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get close => 'Close';

  @override
  String get iapGemsDesc => 'Top up Gems to buy items in the Shop.';

  @override
  String get iapRemoveAdsTitle => 'Remove ads';

  @override
  String get iapRemoveAdsDesc =>
      'Skip all ads — you still get every reward, no watching needed.';

  @override
  String get iapStarterTitle => 'Starter pack';

  @override
  String get iapStarterDesc => 'One-time: get a big pouch of Gems right away.';

  @override
  String get prestigeTitle => 'Franchise 🏪';

  @override
  String prestigeIntro(int percent) {
    return 'Each ⭐ Star gives +$percent% permanent income.';
  }

  @override
  String get prestigeStarsNow => 'Current stars';

  @override
  String prestigeStarsValue(int stars, int percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franchise now';

  @override
  String prestigeGain(int stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Total bonus after';

  @override
  String prestigeTotalValue(int percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ This resets all your Coins and current upgrade levels.';

  @override
  String get cancel => 'Cancel';

  @override
  String prestigeConfirm(int stars) {
    return 'Franchise (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Not enough';

  @override
  String prestigeSuccess(int stars) {
    return 'Franchise successful! +$stars ⭐';
  }

  @override
  String get offlineTitle => 'Welcome back! 🧋';

  @override
  String offlineBody(String amount) {
    return 'The shop kept selling while you were away.\nYou earned $amount Coins.';
  }

  @override
  String get offlineClaim => 'Claim';

  @override
  String get offlineDoubleButton => 'Watch ad ×2';

  @override
  String offlineDoubleSnack(String amount) {
    return 'Doubled! +$amount Coins';
  }

  @override
  String get howToPlayTitle => 'How to play';

  @override
  String get htpTap => '🧋 Tap the cup to brew tea and earn Coins.';

  @override
  String get htpBuy => '🛒 Buy upgrades for automatic income every second.';

  @override
  String get htpStage =>
      '🏪 Save up Coins to unlock new stages with fancier drinks.';

  @override
  String get htpCat => '🐱 Tap the lucky cat for a short ×3 Golden Rush.';

  @override
  String get htpVip => '🚗 Serve the VIP customer to earn Gems 💎.';

  @override
  String get htpGems => '💎 Spend Gems in the Shop on permanent upgrades.';

  @override
  String get htpPrestige =>
      '⭐ Franchise to restart and earn Stars — a permanent income bonus.';

  @override
  String get htpOffline =>
      '😴 The shop keeps selling while you\'re away — come back for offline cash.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get dailyTitle => 'Daily check-in';

  @override
  String get dailyPrompt => 'Claim today\'s login gift!';

  @override
  String get dailyClaim => 'Claim';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return '$days-day streak 🔥';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achEarn(String amount) {
    return 'Earn $amount Coins total';
  }

  @override
  String achStage(int n) {
    return 'Reach stage $n';
  }

  @override
  String achLevels(int n) {
    return 'Own $n upgrade levels total';
  }

  @override
  String achPrestige(int n) {
    return 'Franchise ($n★ or more)';
  }

  @override
  String achUnlocked(String gems) {
    return '🏆 Achievement unlocked! +$gems 💎';
  }

  @override
  String get prestigeShopTitle => 'Star Shop ⭐';

  @override
  String prestigeShopSpendable(int stars) {
    return '$stars ⭐ to spend';
  }

  @override
  String get prestigeIncomeName => 'Mega income';

  @override
  String prestigeIncomeDesc(int percent) {
    return '+$percent% permanent income per level';
  }

  @override
  String get prestigeTapName => 'Mega tap';

  @override
  String prestigeTapDesc(int percent) {
    return '+$percent% tap value per level';
  }

  @override
  String prestigeStarCost(int cost) {
    return '$cost ⭐';
  }

  @override
  String questTap(int n) {
    return 'Tap to brew $n times';
  }

  @override
  String questBuy(int n) {
    return 'Buy $n upgrades';
  }

  @override
  String get questClaim => 'Claim';

  @override
  String get iapDoubleTitle => 'x2 Income (permanent)';

  @override
  String get iapDoubleDesc => 'Double all passive income, forever';

  @override
  String get iapDoubleSnack => 'x2 permanent income enabled!';

  @override
  String get rewardsTitle => 'Earn more 🎁';

  @override
  String get rewardX2Name => 'x2 income for 24h';

  @override
  String rewardX2Active(int hours) {
    return 'Active · ${hours}h left';
  }

  @override
  String get rewardX2Snack => 'x2 income for 24h enabled!';

  @override
  String rewardGemsName(int gems) {
    return 'Get $gems 💎';
  }

  @override
  String rewardTimeSkip(int hours) {
    return 'Fast-forward ${hours}h';
  }

  @override
  String get watchAd => 'Watch ad';
}
