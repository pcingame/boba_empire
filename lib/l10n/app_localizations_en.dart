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
  String get adNotReadySnack => 'Ad not ready yet, try again shortly';

  @override
  String stageHeader(String name) {
    return '🏪 $name';
  }

  @override
  String unlockStageButton(String cost) {
    return 'Unlock $cost Coins';
  }

  @override
  String globalBonusChip(int percent) {
    return '🌐 +$percent%';
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
  String get buyModeMax => 'MAX';

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
  String get gemInstantStageName => 'Instant stage unlock';

  @override
  String gemInstantStageDesc(String stage) {
    return 'Unlock $stage now, skip the Coin cost';
  }

  @override
  String gemStageUnlockedSnack(String stage) {
    return '$stage unlocked!';
  }

  @override
  String get gemTimeSkipName => 'Fast-forward 💎';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Get ${hours}h of production instantly';
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
      '⚠️ Resets Coins, upgrade levels and stage (Star shop perks can keep some).';

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
  String get prestigeOfflineName => 'Super offline';

  @override
  String prestigeOfflineDesc(int percent) {
    return '+$percent% away-earnings per level';
  }

  @override
  String get prestigeStartCashName => 'Seed capital';

  @override
  String get prestigeStartCashDesc =>
      'Get Coins right after Franchise (more per level)';

  @override
  String get prestigeKeepStageName => 'Keep stage';

  @override
  String get prestigeKeepStageDesc =>
      'Keep 1 more stage after Franchise per level';

  @override
  String get prestigeDiscountName => 'Bulk buy';

  @override
  String prestigeDiscountDesc(int percent) {
    return '-$percent% upgrade cost per level';
  }

  @override
  String get prestigeAutoBuyName => 'Auto-buy';

  @override
  String get prestigeAutoBuyDesc =>
      'Unlock a switch that auto-buys the best-value source';

  @override
  String get autoBuyLabel => 'Auto-buy';

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
  String questRepeatEarn(String amount) {
    return 'Earn $amount more Coins';
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

  @override
  String get piggyName => 'Piggy Bank';

  @override
  String get piggyBreak => 'Break';

  @override
  String piggySnack(String gems) {
    return 'Piggy: +$gems 💎';
  }

  @override
  String get iapVipTitle => 'VIP Pass (30 days) 👑';

  @override
  String get iapVipDesc => 'No ads + x2 income + 50💎/day + offline cap+';

  @override
  String get iapVipSnack => 'VIP activated for 30 days! 👑';

  @override
  String get genDuongDen => 'Brown Sugar Milk';

  @override
  String get genBrulee => 'Brûlée Milk Tea';

  @override
  String get genCheeseFoam => 'Cheese Foam';

  @override
  String get genTraTraiCay => 'Fruit Tea';

  @override
  String get genBobaVang => 'Golden Boba';

  @override
  String get genGalaxy => 'Galaxy Milk Tea';

  @override
  String get genQuantumTea => 'Quantum Milk Tea';

  @override
  String get genAiTea => 'AI Milk Tea';

  @override
  String get genParallelTea => 'Parallel-Universe Milk Tea';

  @override
  String get genNftTea => 'NFT Milk Tea';

  @override
  String get genTimeTea => 'Time-Travel Milk Tea';

  @override
  String get genMultidimTea => 'Multidimensional Milk Tea';

  @override
  String get genBlackholeTea => 'Black-Hole Milk Tea';

  @override
  String get genLightTea => 'Light-Speed Milk Tea';

  @override
  String get genRobotTea => 'Robot Milk Tea';

  @override
  String get genHologramTea => 'Hologram Milk Tea';

  @override
  String get genLegendTea => 'Legendary Milk Tea';

  @override
  String get genEternalTea => 'Eternal Milk Tea';

  @override
  String get stage4 => 'Brûlée Workshop';

  @override
  String get stage5 => 'Cheese Foam Factory';

  @override
  String get stage6 => 'Global Empire';

  @override
  String get stage7 => 'Stock Market IPO';

  @override
  String get stage8 => 'Conglomerate';

  @override
  String get stage9 => 'Global Investment Fund';

  @override
  String get stage10 => 'Farm Supply Chain';

  @override
  String get stage11 => 'AI Tech Empire';

  @override
  String get stage12 => 'Milk Tea Legend';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsReset => 'Reset game';

  @override
  String get settingsResetConfirm => 'Erase all progress and start over?';

  @override
  String get navHome => 'Home';

  @override
  String get navShop => 'Shop';

  @override
  String get navPrestige => 'Prestige';

  @override
  String get navAchievements => 'Awards';

  @override
  String get wheelName => 'Lucky Wheel 🎡';

  @override
  String get spinFree => 'Free spin';

  @override
  String get spinAd => 'Watch ad to spin';

  @override
  String storyChapterLabel(int n) {
    return 'Chapter $n';
  }

  @override
  String get storyContinue => 'Continue';

  @override
  String get storyChoosePrompt => 'Choose your path — this can\'t be undone:';

  @override
  String get storyLogTitle => 'Story';

  @override
  String get storyLogLocked => 'Not unlocked yet';

  @override
  String get rivalEventTitle => 'The rival strikes!';

  @override
  String get rivalEventIgnore => 'Ignore';

  @override
  String get rivalMeterAhead => 'Ahead';

  @override
  String get rivalMeterEven => 'Neck and neck';

  @override
  String get rivalMeterBehind => 'Losing ground';

  @override
  String get rivalResolvedSnack => 'Handled. The rival backs off.';

  @override
  String get rivalIgnoredSnack => 'You let it slide — the rival gains ground.';

  @override
  String get navArena => 'Arena';

  @override
  String get navCompete => 'Compete';

  @override
  String get arenaTitle => 'Arena';

  @override
  String get arenaIntro =>
      '1v1 duel, 60 seconds — whoever earns more Coins wins!';

  @override
  String get arenaStartButton => 'Find opponent';

  @override
  String get arenaQueueWaiting => 'Finding an opponent…';

  @override
  String get arenaCancelButton => 'Cancel';

  @override
  String get arenaTapButton => 'Tap the cup';

  @override
  String get arenaResolving => 'Wrapping up the match…';

  @override
  String arenaTierButton(String cost) {
    return 'Upgrade ×2 ($cost Coins)';
  }

  @override
  String arenaTimeLeft(int seconds) {
    return '${seconds}s left';
  }

  @override
  String get arenaYourScore => 'Your score';

  @override
  String get arenaOpponentScore => 'Opponent';

  @override
  String get arenaResultWin => 'You win! 🎉';

  @override
  String get arenaResultLose => 'You lost';

  @override
  String get arenaResultDraw => 'Draw';

  @override
  String arenaResultReward(int gems) {
    return '+$gems 💎';
  }

  @override
  String get arenaCloseButton => 'Close';

  @override
  String get cloudSaveMenuTitle => 'Backup progress';

  @override
  String cloudSaveMenuLinked(String email) {
    return 'Linked: $email';
  }

  @override
  String get cloudSaveMenuUnlinked =>
      'Not linked — you may lose progress if you uninstall';

  @override
  String get cloudSaveTitle => 'Backup progress';

  @override
  String get cloudSaveIntro =>
      'Link an email to recover your progress if you uninstall or switch devices.';

  @override
  String get cloudSaveEmailHint => 'Your email';

  @override
  String get cloudSaveSendCode => 'Send code';

  @override
  String cloudSaveCodeSentTo(String email) {
    return 'Sent a confirmation code to $email';
  }

  @override
  String get cloudSaveCodeHint => 'Confirmation code';

  @override
  String get cloudSaveVerify => 'Verify';

  @override
  String get cloudSaveChangeEmail => 'Use a different email';

  @override
  String get cloudSaveConflictTitle => 'Found a different save on the cloud';

  @override
  String cloudSaveConflictLocal(String amount) {
    return 'This device: $amount Coins lifetime';
  }

  @override
  String cloudSaveConflictCloud(String amount) {
    return 'On the cloud: $amount Coins lifetime';
  }

  @override
  String get cloudSaveRestoreButton => 'Restore from cloud';

  @override
  String get cloudSaveKeepLocalButton => 'Keep this device';

  @override
  String cloudSaveLinkedStatus(String email) {
    return 'Linked: $email';
  }

  @override
  String get cloudSaveDisconnect => 'Disconnect';

  @override
  String get cloudSaveRetry => 'Retry';

  @override
  String get leaderboardMenuTitle => 'Leaderboard';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardNicknameIntro =>
      'Pick a display name for the leaderboard (you can change it later):';

  @override
  String get leaderboardNicknameHint => 'Your name';

  @override
  String get leaderboardSubmit => 'Confirm';

  @override
  String leaderboardYourRank(int rank) {
    return 'Your rank: #$rank';
  }

  @override
  String leaderboardStars(int stars) {
    return '$stars ⭐';
  }

  @override
  String get leaderboardEmpty => 'No one on the leaderboard yet — that\'s you!';

  @override
  String leaderboardRewardSnack(int gems) {
    return '🎉 You\'re holding a top rank! +$gems 💎';
  }

  @override
  String leaderboardRewardInfo(int top1, int top23, int top410) {
    return 'Top 1: $top1💎 · Top 2-3: $top23💎 · Top 4-10: $top410💎 — every 24h while ranked';
  }

  @override
  String get leaderboardChangeName => 'Change name';

  @override
  String get leaderboardRetry => 'Retry';

  @override
  String get storySpeedrunMenuTitle => 'Speedrun';

  @override
  String get storySpeedrunTitle => 'Speedrun Leaderboard';

  @override
  String get storySpeedrunNotCompletedYet =>
      'You haven\'t finished the story yet — complete Chapter 18 to get ranked.';

  @override
  String get storySpeedrunEmpty =>
      'No one has finished the story yet — be the first!';
}
