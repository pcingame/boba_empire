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
  String get gemTimeSkipName => 'Fast-forward';

  @override
  String gemTimeSkipDesc(int hours) {
    return 'Get ${hours}h of production instantly';
  }

  @override
  String gemTimeSkipRemaining(int remaining, int max) {
    return '$remaining/$max left today';
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
  String prestigeIntro(String percent) {
    return 'Each ⭐ Star gives +$percent% permanent income.';
  }

  @override
  String get prestigeStarsNow => 'Current stars';

  @override
  String prestigeStarsValue(String stars, String percent) {
    return '$stars ⭐  (+$percent%)';
  }

  @override
  String get prestigeNow => 'Franchise now';

  @override
  String prestigeGain(String stars) {
    return '+$stars ⭐';
  }

  @override
  String get prestigeTotalBonus => 'Total bonus after';

  @override
  String prestigeTotalValue(String percent) {
    return '+$percent%';
  }

  @override
  String get prestigeWarning =>
      '⚠️ Resets Coins, upgrade levels and stage (Star shop perks can keep some).';

  @override
  String get cancel => 'Cancel';

  @override
  String prestigeConfirm(String stars) {
    return 'Franchise (+$stars ⭐)';
  }

  @override
  String get prestigeNotEnough => 'Not enough';

  @override
  String prestigeSuccess(String stars) {
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
  String get htpNumberFormat =>
      '🔢 Big numbers use suffixes: K=thousand, M=million, B=billion, T=trillion, then aa, bb, cc... — each step is 1,000× the one before.';

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
  String prestigeShopSpendable(String stars) {
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
  String prestigeStarCost(String cost) {
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
  String get rewardsChip => 'Earn more';

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
  String get stage13 => 'Milk Tea Academy';

  @override
  String get stage14 => 'Milk Tea City';

  @override
  String get stage15 => 'Milk Tea Nation';

  @override
  String get stage16 => 'World Alliance';

  @override
  String get stage17 => 'Milk Tea Planet';

  @override
  String get stage18 => 'Truth of Milk Tea';

  @override
  String get genAcademyTea => 'Academy Milk Tea';

  @override
  String get genScholarTea => 'Scholar Milk Tea';

  @override
  String get genCityTea => 'City Milk Tea';

  @override
  String get genMetroTea => 'Metropolis Milk Tea';

  @override
  String get genNationTea => 'National Milk Tea';

  @override
  String get genTreatyTea => 'Treaty Milk Tea';

  @override
  String get genUnionTea => 'Alliance Milk Tea';

  @override
  String get genWorldTea => 'World Peace Milk Tea';

  @override
  String get genPlanetTea => 'Planetary Milk Tea';

  @override
  String get genTerraformTea => 'Terraformed Milk Tea';

  @override
  String get genTruthTea => 'Truth Milk Tea';

  @override
  String get genUltimateTea => 'Ultimate Milk Tea';

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
  String storyUnlockWhen(String cond) {
    return 'Unlocks when: $cond';
  }

  @override
  String storyUnlockAfter(String chapter) {
    return 'Unlocks after $chapter';
  }

  @override
  String storyCondFirst(String name) {
    return 'First $name';
  }

  @override
  String get storyCondRival => 'Defeat the rival';

  @override
  String storyCondAscension(int n, String name) {
    return '$name #$n';
  }

  @override
  String storyCondM3(int n, String game) {
    return 'Clear level $n of $game';
  }

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
  String get arenaModeTap => 'Tap race';

  @override
  String get arenaModeMatch3 => 'Falling Pearls';

  @override
  String get arenaMatch3Intro =>
      'Match 3 in a row for 60 seconds — score more than your opponent to win!';

  @override
  String get arenaMatch3Stuck => 'No moves left!';

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
  String arenaOnlineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players online',
      one: '1 player online',
    );
    return '$_temp0';
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
  String get redeemTitle => 'Redeem gift code';

  @override
  String get redeemHint => 'Enter code';

  @override
  String get redeemButton => 'Redeem';

  @override
  String redeemSuccess(int gems) {
    return 'Redeemed +$gems 💎!';
  }

  @override
  String get redeemAlreadyClaimed => 'You already redeemed this code';

  @override
  String get redeemInvalid => 'Invalid code';

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
  String get cloudSaveCheckSpam =>
      'Can\'t find the email? Check your Spam / Junk folder too.';

  @override
  String get cloudSaveCodeHint => 'Confirmation code';

  @override
  String get cloudSaveVerify => 'Verify';

  @override
  String get cloudSaveChangeEmail => 'Use a different email';

  @override
  String get cloudSaveResend => 'Resend code';

  @override
  String cloudSaveResendIn(int seconds) {
    return 'Resend code (${seconds}s)';
  }

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
  String leaderboardStars(String stars) {
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
  String get storySpeedrunTabMain => 'Act 1';

  @override
  String get storySpeedrunTabExt => 'Act 2';

  @override
  String get storySpeedrunExtNotCompletedYet =>
      'You haven\'t finished Act 2 yet — complete Chapter 28 to be ranked.';

  @override
  String get storySpeedrunTabExt2 => 'Act 3';

  @override
  String get storySpeedrunExt2NotCompletedYet =>
      'You haven\'t finished Act 3 yet — complete Chapter 36 to be ranked.';

  @override
  String get accessoryMenuTitle => 'Collection';

  @override
  String get collectionChip => 'Collection';

  @override
  String get accessoryInventoryTitle => 'Accessory Collection';

  @override
  String accessoryInventoryOwned(int owned, int total) {
    return '$owned/$total collected';
  }

  @override
  String get accessoryRarityCommon => 'Common';

  @override
  String get accessoryRarityRare => 'Rare';

  @override
  String get accessoryRarityEpic => 'Epic';

  @override
  String get accessoryRarityLegendary => 'Legendary';

  @override
  String get accessoryLbTitle => 'Collection ranking';

  @override
  String accessoryLbCount(int n) {
    return '$n accessories';
  }

  @override
  String get accessoryLbTopTitle => 'Collector';

  @override
  String get accessoryLbTitleKing => 'Accessory King';

  @override
  String get accessoryLbTitleMaster => 'Collection Master';

  @override
  String get accessoryLbEmpty =>
      'Nobody on the board yet. Collect an accessory and the top spot is yours!';

  @override
  String get accessoryLbNoOwned =>
      'You haven\'t collected anything yet — finish all 3 daily quests for a chance at one.';

  @override
  String get accessoryLbError =>
      'Couldn\'t load the ranking. Please try again later.';

  @override
  String get accessoryMintLeaf => 'Mint Leaf';

  @override
  String get accessoryCupcake => 'Cupcake';

  @override
  String get accessoryCookie => 'Cookie';

  @override
  String get accessoryPottedPlant => 'Potted Plant';

  @override
  String get accessoryCandle => 'Scented Candle';

  @override
  String get accessoryScarf => 'Scarf';

  @override
  String get accessoryKite => 'Paper Kite';

  @override
  String get accessoryCap => 'Cap';

  @override
  String get accessorySeashell => 'Seashell';

  @override
  String get accessoryMask => 'Mask';

  @override
  String get accessoryDrum => 'Little Drum';

  @override
  String get accessoryPalette => 'Color Palette';

  @override
  String get accessoryCrystalBall => 'Crystal Ball';

  @override
  String get accessoryLantern => 'Antique Lantern';

  @override
  String get accessoryUnicorn => 'Little Unicorn';

  @override
  String get accessoryDragon => 'Little Dragon';

  @override
  String get accessoryBalloon => 'Balloon';

  @override
  String get accessoryBowtie => 'Bow';

  @override
  String get accessorySunglasses => 'Sunglasses';

  @override
  String get accessoryUmbrella => 'Little Umbrella';

  @override
  String get accessoryTeapot => 'Little Teapot';

  @override
  String get accessoryBell => 'Little Bell';

  @override
  String get accessoryRibbon => 'Ribbon';

  @override
  String get accessoryBookmark => 'Cute Bookmark';

  @override
  String get accessoryWindChime => 'Wind Chime';

  @override
  String get accessoryClover => 'Four-Leaf Clover';

  @override
  String get accessoryBubble => 'Soap Bubble';

  @override
  String get accessorySticker => 'Sticker';

  @override
  String get accessoryYarn => 'Yarn Ball';

  @override
  String get accessoryFan => 'Paper Fan';

  @override
  String get accessoryBasket => 'Wicker Basket';

  @override
  String get accessoryBead => 'Beaded Bracelet';

  @override
  String get accessoryLadybug => 'Little Ladybug';

  @override
  String get accessoryKey => 'Antique Key';

  @override
  String get accessoryDiamondStone => 'Diamond Stone';

  @override
  String get accessoryMusicNote => 'Musical Note';

  @override
  String get accessoryTelescope => 'Telescope';

  @override
  String get accessoryAnchor => 'Anchor';

  @override
  String get accessoryFeather => 'Feather';

  @override
  String get accessoryHourglass => 'Hourglass';

  @override
  String get accessoryMap => 'Old Map';

  @override
  String get accessoryRing => 'Little Ring';

  @override
  String get accessoryMagicWand => 'Magic Wand';

  @override
  String get accessoryTrident => 'Trident';

  @override
  String get accessoryPeacock => 'Little Peacock';

  @override
  String get accessoryComet => 'Comet';

  @override
  String get accessoryButterfly => 'Crystal Butterfly';

  @override
  String get accessoryAngelWing => 'Angel Wing';

  @override
  String get accessoryPhoenix => 'Phoenix';

  @override
  String get accessoryGalaxy => 'Galaxy';

  @override
  String get marketTitle => 'Accessory Market';

  @override
  String get marketTabBrowse => 'Market';

  @override
  String get marketTabMine => 'Mine';

  @override
  String get marketRecentSalesHeader => 'Recently sold';

  @override
  String get marketMerchantTitle => 'Weekly Merchant';

  @override
  String get marketFilterAll => 'All';

  @override
  String get marketFilterMissing => 'Missing';

  @override
  String get marketSortPriceAsc => 'Lowest price';

  @override
  String get marketBadgeNew => 'NEW';

  @override
  String marketNeedMore(int n) {
    return 'Need $n more Market Coins';
  }

  @override
  String get marketNoFilterResults => 'No items match the filter.';

  @override
  String accessoryRevealNew(String name) {
    return 'New accessory: $name!';
  }

  @override
  String accessoryRevealDuplicate(String name, int gems) {
    return 'Duplicate $name: +$gems 💎 and a spare to sell in the Market';
  }

  @override
  String accessoryEquipHint(int n, int max) {
    return 'Displayed $n/$max — tap an item you own to show it around the cup';
  }

  @override
  String accessoryEquipFull(int max) {
    return 'Display is full ($max) — remove one first';
  }

  @override
  String get accessoryFlairHint =>
      'Long-press an item to use it as your leaderboard badge';

  @override
  String accessoryFlairSet(String name) {
    return '$name is now your leaderboard badge';
  }

  @override
  String get accessoryFlairCleared => 'Leaderboard badge removed';

  @override
  String get accessoryFlairFailed =>
      'Couldn\'t set the badge — item not synced yet or you\'re offline';

  @override
  String get marketStarterTitle => 'Market Starter Pack';

  @override
  String get marketStarterBody =>
      'Get 1 Common accessory + 1 spare to sell + 10 Market Coins. One time only.';

  @override
  String get marketStarterClaim => 'Claim';

  @override
  String get marketStarterDone =>
      'Starter Pack claimed! Check your Collection.';

  @override
  String get marketStarterErrCap =>
      'Today\'s gifts ran out server-wide — come back tomorrow.';

  @override
  String get marketStarterErrNet =>
      'Couldn\'t claim — check your connection and try again.';

  @override
  String get marketIntroTitle => 'Welcome to the Market!';

  @override
  String get marketIntroStep1 =>
      '1. Convert 💎 or coins into Market Coins (Convert button) — they only work in the Market and can\'t be converted back.';

  @override
  String get marketIntroStep2 =>
      '2. Buy accessories other players list to complete your collection.';

  @override
  String get marketIntroStep3 =>
      '3. Sell spares in the My items tab. The fee is only 1%.';

  @override
  String get marketIntroOk => 'Got it';

  @override
  String get collectionTitle10 => 'Collector';

  @override
  String get collectionTitle25 => 'Connoisseur';

  @override
  String get collectionTitle40 => 'Expert Collector';

  @override
  String get collectionTitle50 => 'Collecting Legend';

  @override
  String collectionTitleLabel(String title) {
    return 'Title: $title';
  }

  @override
  String collectionMilestoneClaim(int coins) {
    return 'Claim +$coins';
  }

  @override
  String collectionMilestoneLocked(int count, int coins) {
    return '$count items · $coins Market Coins';
  }

  @override
  String collectionMilestoneDone(int coins) {
    return 'Got $coins Market Coins and a new title!';
  }

  @override
  String get collectionMilestoneErrNet =>
      'Couldn\'t claim — check your connection and try again.';

  @override
  String marketPriceLast(int n) {
    return 'Last sold: $n';
  }

  @override
  String marketPriceLowest(int n) {
    return 'Cheapest listed: $n';
  }

  @override
  String marketPriceAvg(int n) {
    return '7-day avg: $n';
  }

  @override
  String get marketWishAdd => 'Add to wishlist';

  @override
  String get marketWishRemove => 'Remove from wishlist';

  @override
  String marketWishFull(int max) {
    return 'Wishlist is full ($max items)';
  }

  @override
  String marketFeeFreeNote(int proceeds) {
    return 'Free on weekends: you receive the full $proceeds Market Coins';
  }

  @override
  String get marketWeekendBanner =>
      '🎉 Weekend: 0% Market fee & boosted rare accessory drops!';

  @override
  String collectionPeekTitle(String name) {
    return '$name\'s collection';
  }

  @override
  String get collectionPeekError =>
      'Couldn\'t load the collection — try again later.';

  @override
  String get collectionShareTooltip => 'Show off collection';

  @override
  String collectionShareText(int owned, int total, String items) {
    return 'I\'ve collected $owned/$total accessories in Boba Empire! $items';
  }

  @override
  String get collectionShareCopied =>
      'Copied — paste it in a chat to show off!';

  @override
  String get collectionCardTitle => 'Collection card';

  @override
  String get collectionShareImage => 'Share image';

  @override
  String get collectionShareCopy => 'Copy text';

  @override
  String get collectionShareFailed => 'Couldn\'t share — try copying the text.';

  @override
  String whatsNewTitle(String version) {
    return 'What\'s new in $version';
  }

  @override
  String get whatsNewCollection =>
      '🎀 Collection: 50 accessories, show them around your cup, leaderboard badges, milestone rewards';

  @override
  String get whatsNewMarket =>
      '🛒 Accessory Market: trade with Market Coins, price hints, wishlist, sale alerts';

  @override
  String get whatsNewWheel =>
      '🎡 The wheel has an accessory chest. Weekends: 0% Market fee and better rare drops';

  @override
  String get whatsNewStory => '📖 Story Act 3: 8 new chapters';

  @override
  String get whatsNewLook =>
      '🎨 Pastel look, smoother play, share your collection as an image';

  @override
  String get whatsNewLater => 'Later';

  @override
  String get whatsNewOpen => 'View collection';

  @override
  String marketWallet(int n) {
    return '$n Market Coins';
  }

  @override
  String get marketError => 'Couldn\'t load the market, try again later.';

  @override
  String get marketEmptyBrowse => 'Nobody has listed anything yet.';

  @override
  String get marketBuyButton => 'Buy';

  @override
  String get marketBoughtToast => 'Bought!';

  @override
  String marketConfirmBuy(int price) {
    return 'Buy for $price Market Coins?';
  }

  @override
  String marketPriceTag(int price) {
    return '$price Market Coins';
  }

  @override
  String get marketMyListingsHeader => 'Your listings';

  @override
  String get marketEmptyMine => 'You haven\'t listed anything yet.';

  @override
  String get marketCancelButton => 'Cancel listing';

  @override
  String get marketCancelledToast => 'Listing cancelled.';

  @override
  String get marketSellableHeader => 'Accessories you can sell';

  @override
  String get marketEmptySellable =>
      'You don\'t have any accessories to sell yet.';

  @override
  String get marketListedToast => 'Listed!';

  @override
  String get marketListButton => 'List for sale';

  @override
  String get marketPriceLabel => 'Price (Market Coins)';

  @override
  String marketListFeeNote(int proceeds, int fee) {
    return 'You\'ll receive $proceeds Market Coins after the 1% fee (−$fee)';
  }

  @override
  String get marketConvertButton => 'Convert';

  @override
  String get marketConvertTitle => 'Convert to Market Coins';

  @override
  String get marketConvertAmountLabel => 'Market Coins wanted';

  @override
  String marketConvertCostGems(String cost) {
    return 'Cost: $cost 💎';
  }

  @override
  String marketConvertCostMoney(String cost) {
    return 'Cost: $cost 💰';
  }

  @override
  String get marketConvertSuccessToast => 'Converted!';

  @override
  String get marketConvertFailToast =>
      'Conversion failed — insufficient balance or network error.';

  @override
  String get storySpeedrunEmpty =>
      'No one has finished the story yet — be the first!';

  @override
  String get arenaLeaderboardMenuTitle => 'PK Leaderboard';

  @override
  String get arenaLeaderboardTitle => 'PK Leaderboard';

  @override
  String get arenaLeaderboardNotPlayedYet =>
      'You haven\'t fought any Arena matches yet — win one to appear here.';

  @override
  String arenaLeaderboardRecord(int wins, int losses) {
    return '${wins}W - ${losses}L';
  }

  @override
  String get ascensionTitle => 'Ascension';

  @override
  String get ascensionOpen => 'Ascension ⏳';

  @override
  String get ascensionIntro =>
      'Trade all your Stars and Star Shop perks for ⏳ Ascension Points — stronger permanent perks. You start over.';

  @override
  String ascensionProgress(int percent) {
    return 'Progress to unlock: $percent%';
  }

  @override
  String get ascensionPointsNow => 'Points owned';

  @override
  String get ascensionPointsGain => 'Gain if you ascend';

  @override
  String ascensionPointsValue(int points) {
    return '$points ⏳';
  }

  @override
  String get ascensionWarning =>
      '⚠️ Resets Stars, all Star Shop perks, Coins, upgrade levels and stage. Keeps 💎, achievements and story. Your leaderboard Stars drop to 0 (rank by lifetime earnings is unchanged).';

  @override
  String ascensionConfirm(int points) {
    return 'Ascend (+$points ⏳)';
  }

  @override
  String get ascensionNotEnough => 'Not yet available';

  @override
  String ascensionSuccess(int points) {
    return 'A new era begins! +$points ⏳';
  }

  @override
  String get ascensionShopTitle => 'Ascension perks ⏳';

  @override
  String ascensionShopSpendable(int points) {
    return '$points ⏳ to spend';
  }

  @override
  String ascensionCost(int cost) {
    return '$cost ⏳';
  }

  @override
  String get ascensionMaxed => 'Max';

  @override
  String get ascensionIncomeName => 'Power source';

  @override
  String ascensionIncomeDesc(int percent) {
    return '+$percent% income per level';
  }

  @override
  String get ascensionStarBonusName => 'Radiant stars';

  @override
  String ascensionStarBonusDesc(int percent) {
    return '+$percent% power per Star, per level';
  }

  @override
  String get ascensionStarGainName => 'Abundant stars';

  @override
  String ascensionStarGainDesc(int percent) {
    return '+$percent% Star gain rate, per level';
  }

  @override
  String get achAscend => 'Ascend for the first time';

  @override
  String get dailyQuestsTitle => 'Daily quests';

  @override
  String get dailyQuestsChip => 'Quests';

  @override
  String get dailyQuestsBonusLabel => 'Finish all 3 quests';

  @override
  String dailyQuestsResetsIn(Object time) {
    return 'New quests in $time';
  }

  @override
  String get dailyQuestClaimed => 'Claimed';

  @override
  String dqTap(int n) {
    return 'Tap the cup $n times';
  }

  @override
  String dqBuy(int n) {
    return 'Buy $n upgrades';
  }

  @override
  String dqEarn(Object amount) {
    return 'Earn $amount Coins';
  }

  @override
  String get dqCat => 'Catch the Golden Cat';

  @override
  String get dqVip => 'Serve a VIP customer';

  @override
  String get dqSpin => 'Spin the Lucky Wheel';

  @override
  String get notifyOfflineFullTitle => 'Your coin stash is full! 🧋';

  @override
  String get notifyOfflineFullBody =>
      'The shop stopped piling up Coins — come collect and start a new shift.';

  @override
  String get notifyDailyTitle => 'New day, new quests 📋';

  @override
  String get notifyDailyBody =>
      'Your daily check-in, free spin and 3 quests are waiting.';

  @override
  String get notifyD3Title => 'Your shop misses you 🧋';

  @override
  String get notifyD3Body =>
      'It\'s been 3 days — the coin stash filled up ages ago, come collect it.';

  @override
  String get notifyD7Title => 'It\'s been a week! 🧋';

  @override
  String get notifyD7Body =>
      'Ascension, Falling Pearls and lots of new stuff are waiting for you.';

  @override
  String eventBannerLabel(String mult, String timeLeft) {
    return '🎉 Event: ×$mult income! $timeLeft left';
  }

  @override
  String get navMatch3 => 'Pearls';

  @override
  String get m3Title => 'Falling Pearls';

  @override
  String m3Level(int n) {
    return 'Level $n';
  }

  @override
  String get m3Locked => 'Locked';

  @override
  String m3MovesLeft(int n) {
    return '$n moves left';
  }

  @override
  String get m3Score => 'Score';

  @override
  String get m3Win => 'Level clear!';

  @override
  String get m3Lose => 'Goal not reached';

  @override
  String get m3Retry => 'Retry';

  @override
  String get m3Next => 'Next level';

  @override
  String get m3Back => 'Level list';

  @override
  String get m3Reward => 'Reward';

  @override
  String get m3NoReward => 'You already claimed this level\'s reward';

  @override
  String m3AdMoves(int n) {
    return 'Watch ad: +$n moves';
  }

  @override
  String get m3KeepPlaying => 'Keep playing';

  @override
  String get m3Pause => 'Take a break';

  @override
  String get m3GoalReached => 'Goal reached!';

  @override
  String m3NeedScore(String n, int star) {
    return '$n more points for $star★';
  }

  @override
  String m3NeedCollect(int n, String icon, int star) {
    return '$n more $icon for $star★';
  }

  @override
  String get m3HowToTitle => 'How to play Falling Pearls';

  @override
  String get m3HtpSwap =>
      '🔄 Swap two ADJACENT tiles (tap one then the other, or swipe) to line up 3 or more of a kind. Swaps that make no line do not count.';

  @override
  String get m3HtpGoal =>
      '🎯 Each level has one goal: reach a score, or collect enough tiles of one kind. The goal is shown in the bar at the top.';

  @override
  String get m3HtpMoves =>
      '👣 Moves are limited. When they run out the level ends, so favour swaps that clear more tiles.';

  @override
  String get m3HtpChain =>
      '⛓️ Cleared tiles make the ones above fall; if those form a new line it chains — later steps score far more.';

  @override
  String get m3HtpSpecial =>
      '💥 Line up 4 to create a CROSS BOMB (clears its whole row and column). Line up 5 or more for a COLOUR BOMB 🌈 (clears every tile of that kind). Match them like normal tiles to set them off.';

  @override
  String get m3HtpStars =>
      '⭐ The three stars on the bar are three tiers. Reaching the first clears the level; tap \"Keep playing\" to spend your remaining moves chasing more stars.';

  @override
  String get m3HtpReward =>
      '🎁 Rewards are paid only the FIRST time you reach each star tier. Replaying a level for practice pays nothing extra.';

  @override
  String get m3LbTitle => 'Falling Pearls ranking';

  @override
  String m3LbStars(int n) {
    return '$n ⭐';
  }

  @override
  String get m3LbEmpty =>
      'Nobody on the board yet. Clear a few levels and the top spot is yours!';

  @override
  String get m3LbNoStars =>
      'You have no stars yet — clear one level to get on the board.';

  @override
  String m3LbLevels(int n) {
    return '$n levels';
  }

  @override
  String get m3LbError => 'Couldn\'t load the ranking. Please try again later.';
}
