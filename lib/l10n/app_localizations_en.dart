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
  String get prestigeAdConfirm => 'Watch ad: bonus starting Coins';

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
  String get htpTap => 'Tap the cup to brew tea and earn Coins.';

  @override
  String get htpBuy => 'Buy upgrades for automatic income every second.';

  @override
  String get htpStage =>
      'Save up Coins to unlock new stages with fancier drinks.';

  @override
  String get htpCat => 'Tap the lucky cat for a short ×3 Golden Rush.';

  @override
  String get htpVip => 'Serve the VIP customer to earn Gems 💎.';

  @override
  String get htpGems => 'Spend Gems in the Shop on permanent upgrades.';

  @override
  String get htpPrestige =>
      'Franchise to restart and earn Stars — a permanent income bonus.';

  @override
  String get htpOffline =>
      'The shop keeps selling while you\'re away — come back for offline cash.';

  @override
  String get htpNumberFormat =>
      'Big numbers use suffixes: K=thousand, M=million, B=billion, T=trillion, then aa, bb, cc... — each step is 1,000× the one before.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get dailyTitle => 'Daily check-in';

  @override
  String get dailyPrompt => 'Claim today\'s login gift!';

  @override
  String get adNotReady => 'Ad isn\'t ready yet, try again in a few seconds.';

  @override
  String get accessoryBat => 'Night Bat';

  @override
  String get accessoryJackOLantern => 'Jack-o\'-Lantern';

  @override
  String get accessoryGhost => 'Friendly Ghost';

  @override
  String get accessoryWitch => 'Little Witch';

  @override
  String get accessorySnowman => 'Snowman';

  @override
  String get accessoryChristmasTree => 'Christmas Tree';

  @override
  String get accessoryReindeer => 'Reindeer';

  @override
  String get accessorySanta => 'Santa Claus';

  @override
  String get accessoryFirecracker => 'Firecracker';

  @override
  String get accessoryRedEnvelope => 'Red Envelope';

  @override
  String get accessoryApricotBlossom => 'Apricot Blossom';

  @override
  String get accessoryGoldenGoat => 'Golden Goat';

  @override
  String get festivalHalloween => 'Halloween';

  @override
  String get festivalChristmas => 'Christmas';

  @override
  String get festivalTet => 'Lunar New Year';

  @override
  String get festivalSection => 'Festival accessories (exclusive)';

  @override
  String festivalPackTitle(String name) {
    return '$name Pack';
  }

  @override
  String festivalPackDesc(int gems) {
    return 'Each pack gives 1 exclusive item you don\'t own yet, sold only during the festival. If you own them all, you get $gems 💎 instead. Not tradable.';
  }

  @override
  String get accessoryChampagne => 'Champagne Toast';

  @override
  String get accessoryPartyPopper => 'Party Popper';

  @override
  String get accessoryFireworks => 'Fireworks';

  @override
  String get accessoryGoldenSparkler => 'Golden Sparkler';

  @override
  String get accessoryLoveLetter => 'Love Letter';

  @override
  String get accessoryRose => 'Red Rose';

  @override
  String get accessoryChocolate => 'Chocolate';

  @override
  String get accessoryCupidArrow => 'Cupid\'s Arrow';

  @override
  String get accessoryTulip => 'Tulip';

  @override
  String get accessoryBouquet => 'Bouquet';

  @override
  String get accessoryLipstick => 'Lipstick';

  @override
  String get accessoryPrincess => 'Princess';

  @override
  String get accessoryMooncake => 'Mooncake';

  @override
  String get accessoryRabbit => 'Moon Rabbit';

  @override
  String get accessoryFullMoon => 'Full Moon';

  @override
  String get accessoryLionDance => 'Lion Dance';

  @override
  String get festivalNewYear => 'New Year';

  @override
  String get festivalValentine => 'Valentine\'s Day';

  @override
  String get festivalWomensDay => 'Women\'s Day';

  @override
  String get festivalMidAutumn => 'Mid-Autumn Festival';

  @override
  String get dailyClaim => 'Claim';

  @override
  String get accessoryWheelTitle => 'Accessory wheel';

  @override
  String accessoryWheelAd(int n) {
    return 'Spin: watch ad ($n left)';
  }

  @override
  String accessoryWheelGems(int gems) {
    return 'Spin $gems 💎';
  }

  @override
  String get accessoryPackButton => 'Accessory packs';

  @override
  String get accessoryPackTitle => 'Accessory packs';

  @override
  String get accessoryPackBasic => 'Basic Pack';

  @override
  String get accessoryPackRare => 'Rare Pack (Rare or better)';

  @override
  String get accessoryPackEpic => 'Epic Pack (Epic or better)';

  @override
  String get accessoryPackSeason =>
      'Seasonal event: 25% off packs, Epic/Legendary odds ×2!';

  @override
  String get accessoryAdDropButton => 'Watch ad: +1 accessory';

  @override
  String dailyStreakAtRisk(int days) {
    return 'You missed a day — your $days-day streak is about to be lost!';
  }

  @override
  String dailyRestoreGems(int gems) {
    return 'Save streak ($gems 💎)';
  }

  @override
  String get dailyRestoreAd => 'Watch an ad to save streak';

  @override
  String get dailySkipRestore => 'Skip, start over';

  @override
  String dailyReward(String gems) {
    return '+$gems 💎';
  }

  @override
  String dailyStreak(int days) {
    return '$days-day streak 🔥';
  }

  @override
  String dailyMilestoneBonus(String gems) {
    return 'Streak milestone bonus: +$gems 💎';
  }

  @override
  String dailyVipBonus(int percent) {
    return 'VIP bonus: +$percent% 💎';
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
  String get iapColdStorageTitle => 'Cold Storage (permanent)';

  @override
  String iapColdStorageDesc(Object hours) {
    return 'Adds $hours hours to your offline earnings cap, forever';
  }

  @override
  String iapColdStorageSnack(Object hours) {
    return 'Offline cap increased by $hours hours!';
  }

  @override
  String get iapComboTitle => 'Combo: No Ads + x2 Income';

  @override
  String get iapComboDesc =>
      'Remove all ads and double passive income forever — cheaper than buying separately';

  @override
  String get iapComboSnack => 'Ads removed and x2 permanent income enabled!';

  @override
  String get topupTitle => 'Top-up rewards & VIP';

  @override
  String get topupOpen => '👑 Top-up rewards & VIP';

  @override
  String topupSummary(Object points) {
    return '$points VIP EXP';
  }

  @override
  String topupBuff(Object now, Object percent) {
    return 'Each VIP level: +$percent% income (now +$now%)';
  }

  @override
  String get topupNote =>
      'Store purchases: ~100 EXP per USD (big packs give more). Buying EXP with 💎 costs far more and is capped. Each reward is claimed once.';

  @override
  String topupTier(Object points) {
    return '$points EXP';
  }

  @override
  String get topupAccessory => '+ accessory';

  @override
  String vipTierPerks(int buff, String daily, String monthly, String weekly) {
    return 'Daily +$daily 💎 · weekly +$weekly 💎 · monthly +$monthly 💎 (with accessory) · +$buff% income';
  }

  @override
  String get topupClaim => 'Claim';

  @override
  String get topupClaimed => 'Claimed';

  @override
  String topupClaimSnack(Object gems) {
    return 'Claimed +$gems 💎';
  }

  @override
  String get vipName1 => 'Regular';

  @override
  String get vipName2 => 'Tea Lover';

  @override
  String get vipName3 => 'Tea Connoisseur';

  @override
  String get vipName4 => 'Honored Guest';

  @override
  String get vipName5 => 'Shop Owner';

  @override
  String get vipName6 => 'Boba Billionaire';

  @override
  String get vipName7 => 'Tycoon';

  @override
  String get vipName8 => 'Royalty';

  @override
  String get vipName9 => 'Legend';

  @override
  String get vipName10 => 'Boba Emperor';

  @override
  String vipBuyExp(Object exp, Object gems) {
    return 'Buy $exp EXP · $gems 💎';
  }

  @override
  String vipBuyExpSnack(Object exp) {
    return '+$exp VIP EXP';
  }

  @override
  String vipBuyExpCapped(Object cap) {
    return 'EXP bought with 💎 reached the limit ($cap). Higher levels need real top-ups.';
  }

  @override
  String get vipBenefitsTitle => 'VIP benefits';

  @override
  String get vipBenefitsLocked =>
      'Reach VIP 1 to unlock daily/weekly/monthly gifts.';

  @override
  String get vipDaily => 'Daily';

  @override
  String get vipWeekly => 'Weekly';

  @override
  String get vipMonthly => 'Monthly';

  @override
  String get vipHowToTitle => 'VIP guide';

  @override
  String get vipHtp1 =>
      '👑 VIP has 10 levels, each with a title. Your level shows as a \"VIP n\" tag next to your name on leaderboards and in your Guild. From VIP 5, your name gets a title line on every leaderboard, a green dot while you\'re online, and everyone online sees a banner when you join.';

  @override
  String vipHtp2(Object cap, Object exp, Object gems) {
    return '⭐ VIP EXP: real-money purchases in the store (~100 EXP per USD, big 💎 packs give extra) or buy it with 💎 ($gems 💎 → $exp EXP, up to $cap EXP — so VIP 7–10 need real top-ups).';
  }

  @override
  String vipHtp3(Object percent) {
    return '📈 Perks: +$percent% passive income per level (permanent) and a one-time milestone reward for every level (💎, plus an accessory on some).';
  }

  @override
  String get vipHtp4 =>
      '🎁 Daily / weekly / monthly gifts: 💎 grow with your level; weekly and monthly add an accessory. Periods reset at 00:00 UTC (weeks start Monday, months by calendar).';

  @override
  String get vipHtp5 =>
      '♻️ Not the 30-day VIP Pass: the VIP Pass (no ads, x2 income…) is a timed ticket; this VIP level never expires and the two stack.';

  @override
  String get vipHtp6 => '📍 Open it from the 💎 Shop → 👑 button.';

  @override
  String get vipLbTitle => 'VIP leaderboard';

  @override
  String get vipLbEmpty => 'Nobody is on the VIP leaderboard yet.';

  @override
  String get vipLbNoVip => 'Reach VIP 1 to get on the VIP leaderboard.';

  @override
  String vipLbExp(Object exp) {
    return '$exp EXP';
  }

  @override
  String vipOnlineBanner(Object nickname, Object title) {
    return '👑 $title $nickname just came online!';
  }

  @override
  String get emailGateTitle => 'Link your email to top up';

  @override
  String get emailGateBody =>
      'Purchases are tied to your account so they can be recovered if you change phones or something goes wrong. Link an email first (free, takes about a minute).';

  @override
  String get emailGateOnlineTitle => 'Link your email to play online';

  @override
  String get emailGateOnlineBody =>
      'Guilds, the Market, the Arena and leaderboards need an email-linked account, so your data stays safe and can be restored if you change phones or reinstall. It\'s free and takes about a minute.';

  @override
  String get emailGateLink => 'Link email';

  @override
  String iapGemsFirstSnack(Object amount) {
    return 'Received +$amount 💎 — first-purchase double bonus!';
  }

  @override
  String get iapFirstBuyNote => '🎉 First purchase: get double 💎!';

  @override
  String get guildGiftTooltip => 'Gift 💎';

  @override
  String guildGiftTitle(Object nickname) {
    return 'Gift 💎 to $nickname';
  }

  @override
  String guildGiftHint(Object cap, Object days) {
    return 'Up to $cap 💎 a day. The receiver has $days days to claim it.';
  }

  @override
  String guildGiftSent(Object amount, Object nickname) {
    return 'Sent $amount 💎 to $nickname';
  }

  @override
  String guildGiftInboxTitle(Object count) {
    return '🎁 Gifts from guildmates ($count)';
  }

  @override
  String guildGiftFrom(Object amount, Object nickname) {
    return '$nickname · +$amount 💎';
  }

  @override
  String guildGiftClaimed(Object amount) {
    return 'Claimed +$amount 💎';
  }

  @override
  String guildErrGiftLimit(Object receive, Object send) {
    return 'Gift limit reached today (you can send up to $send 💎/day; one person can receive up to $receive 💎/day).';
  }

  @override
  String get vipTitlePick => 'Title shown under your name';

  @override
  String get vipTitleAuto => 'Auto (highest)';

  @override
  String get vipTitleHide => 'Hide';

  @override
  String get marketFilterWish => 'Wishlist';

  @override
  String get guildErrGemsSpend => 'Not enough 💎.';

  @override
  String guildCreateVipDiscount(Object percent) {
    return 'VIP perk: $percent% off the guild creation fee';
  }

  @override
  String get guildLbTabVip => 'VIP';

  @override
  String get guildLbVipEmpty => 'No guild has VIP members on the board yet.';

  @override
  String get guildLbVipNote =>
      'Total VIP EXP of members (only members who set a nickname count).';

  @override
  String guildVipExpTotal(Object exp) {
    return '$exp EXP';
  }

  @override
  String guildVipBonusLine(Object members, Object pct) {
    return 'VIP bonus: $members VIP members → +$pct% income for the whole guild';
  }

  @override
  String guildVipBonusHint(Object cap, Object level, Object per) {
    return 'Each member at VIP $level+ adds +$per% income for the whole guild (max +$cap%)';
  }

  @override
  String get reminderVipTitle => '👑 Your VIP gift is waiting';

  @override
  String get reminderVipDailyBody =>
      'Your daily VIP gift, check-in and quests are ready — come claim them!';

  @override
  String get reminderVipWeeklyBody =>
      'Your weekly VIP gift (with an accessory) is ready!';

  @override
  String get reminderVipMonthlyBody =>
      'Your monthly VIP gift is here — a big one is waiting!';

  @override
  String get reminderVipUnclaimedBody =>
      'You still have unclaimed VIP gifts today.';

  @override
  String get dealTitle => 'Today\'s deal';

  @override
  String dealResets(Object time) {
    return 'Changes at 00:00 UTC · $time left';
  }

  @override
  String get dealClaimed => 'Bought today — come back tomorrow';

  @override
  String dealGotAccessory(Object name) {
    return 'Got $name!';
  }

  @override
  String get dealUnavailable => 'This deal can\'t be bought right now.';

  @override
  String get guildBossTitle => 'Guild weekly boss';

  @override
  String guildBossTier(Object tier) {
    return 'Tier $tier';
  }

  @override
  String guildBossProgress(Object damage, Object hp) {
    return '$damage / $hp damage';
  }

  @override
  String guildBossClaim(Object coins, Object gems) {
    return 'Claim chest: +$gems 💎 +$coins Guild Coins';
  }

  @override
  String get guildBossClaimedLabel => 'Chest claimed';

  @override
  String guildBossClaimedSnack(Object coins, Object gems) {
    return 'Boss chest: +$gems 💎 +$coins Guild Coins';
  }

  @override
  String get guildBossErrAlive => 'The boss is still alive.';

  @override
  String get guildBossName1 => 'Pearl Dragon';

  @override
  String get guildBossName2 => 'Shaved-Ice Titan';

  @override
  String get guildBossName3 => 'Black-Tea Kraken';

  @override
  String get guildBossName4 => 'Pudding Bear';

  @override
  String get guildBossName5 => 'Matcha Tiger';

  @override
  String get guildBossName6 => 'Cheese-Foam Phoenix';

  @override
  String get accessoryVipWatch => 'Luxury Watch';

  @override
  String get accessoryVipLuggage => 'Luxury Luggage';

  @override
  String get accessoryVipBriefcase => 'Executive Briefcase';

  @override
  String get accessoryVipTophat => 'Gentleman\'s Top Hat';

  @override
  String get accessoryVipRacecar => 'Supercar';

  @override
  String get accessoryVipHeli => 'Helicopter';

  @override
  String get accessoryVipYacht => 'Yacht';

  @override
  String get accessoryVipJet => 'Private Jet';

  @override
  String get vipShopOpen => '🛍️ VIP shop';

  @override
  String get vipShopTitle => 'VIP shop';

  @override
  String vipCoinsLabel(Object n) {
    return 'VIP Coins: $n';
  }

  @override
  String vipShopLocked(Object level) {
    return 'Needs VIP $level';
  }

  @override
  String get vipShopOwned => 'Owned';

  @override
  String get vipShopNeedCoins => 'Not enough VIP Coins';

  @override
  String vipShopBoughtSnack(Object name) {
    return 'Got $name!';
  }

  @override
  String get vipShopHint =>
      'Earn VIP Coins by claiming your daily, weekly and monthly VIP gifts.';

  @override
  String vipBenefitSnack(Object coins, Object gems) {
    return 'Claimed +$gems 💎 +$coins VIP Coins';
  }

  @override
  String get vipItemsTitle => 'VIP exclusives';

  @override
  String vipShopPrice(Object n) {
    return '$n VIP Coins';
  }

  @override
  String get vipEntryHint =>
      'Top up to unlock daily, weekly and monthly VIP gifts';

  @override
  String get settingsWebsite => 'Website';

  @override
  String get settingsWebGuide => 'How-to guide (web)';

  @override
  String get guideOnWeb => 'Full guide on the website';

  @override
  String get webOpenFailed =>
      'Couldn\'t open the website. Check your connection and try again.';

  @override
  String get webBoardOpenTip => 'View this leaderboard on the web';

  @override
  String get webBoardShareTip => 'Share leaderboard link';

  @override
  String webBoardShareText(Object url) {
    return 'Check out the Boba Empire leaderboard: $url';
  }

  @override
  String get settingsShareProfile => 'Share my ranking profile';

  @override
  String profileShareText(String name, String url) {
    return 'See $name’s ranks in Boba Empire: $url';
  }

  @override
  String profileTitle(String name) {
    return 'Profile: $name';
  }

  @override
  String get profileBoardIncome => 'Income';

  @override
  String get profileBoardPearls => 'Pearls';

  @override
  String get profileBoardCollection => 'Collection';

  @override
  String get profileBoardSpeed => 'Story speedrun';

  @override
  String get profileBoardVip => 'VIP';

  @override
  String get profileNoRanks => 'Not on any leaderboard yet.';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get myProfileChangeAvatar => 'Change avatar';

  @override
  String get myProfileRemoveAvatar => 'Remove photo';

  @override
  String get myProfileAvatarFail =>
      'Couldn\'t upload the photo. You need a connection and an email-linked account.';

  @override
  String get myProfileAvatarTooBig => 'That photo is too large, pick another.';

  @override
  String get myProfileNoNickname =>
      'No nickname yet. Open any leaderboard to set one.';

  @override
  String get myProfileStatStage => 'Stage';

  @override
  String get myProfileStatEarned => 'Total earned';

  @override
  String get myProfileStatStars => 'Stars';

  @override
  String get myProfileStatAscend => 'Ascensions';

  @override
  String get myProfileStatVip => 'VIP';

  @override
  String get myProfileStatCollection => 'Collection';

  @override
  String get myProfileStatAchievements => 'Achievements';

  @override
  String get myProfileRanks => 'See my ranks';

  @override
  String get myProfileShare => 'Share profile';

  @override
  String get avatarReport => 'Report photo';

  @override
  String get avatarReportConfirm => 'Report this avatar as inappropriate?';

  @override
  String get avatarReportSent => 'Report sent. Thank you!';

  @override
  String get avatarReportFail =>
      'Couldn\'t send the report. You need a connection and an email-linked account.';

  @override
  String get titlePickerTitle => 'Title';

  @override
  String get titlePickerNone => 'No title';

  @override
  String get titlePickerHint =>
      'Unlock them through progress. The chosen title shows on your public profile (needs an email-linked account).';

  @override
  String get playerTitleTycoon => 'Chain Tycoon';

  @override
  String get playerTitleTycoonHint => 'Reach stage 5';

  @override
  String get playerTitleMogul => 'Mogul';

  @override
  String get playerTitleMogulHint => 'Reach stage 10';

  @override
  String get playerTitleLegend => 'Legend';

  @override
  String get playerTitleLegendHint => 'Reach stage 18';

  @override
  String get playerTitleTimewalker => 'Time Walker';

  @override
  String get playerTitleTimewalkerHint => 'Ascend at least once';

  @override
  String get playerTitleStargazer => 'Stargazer';

  @override
  String get playerTitleStargazerHint => 'Hold 50 stars';

  @override
  String get playerTitleCollector => 'Collector';

  @override
  String get playerTitleCollectorHint => 'Own 100 accessories';

  @override
  String get playerTitleVip => 'VIP Noble';

  @override
  String get playerTitleVipHint => 'Reach VIP 5';

  @override
  String get profileViewButton => 'Profile';

  @override
  String get profileOpenWeb => 'View on web';

  @override
  String get refEntry => '👥 Invite friends';

  @override
  String refEntryNote(Object gems) {
    return 'Earn $gems 💎 for every friend who joins';
  }

  @override
  String get refTitle => 'Invite friends';

  @override
  String get refYourCode => 'Your invite code';

  @override
  String get refCopy => 'Copy code';

  @override
  String get refCopied => 'Code copied';

  @override
  String get refShare => 'Share';

  @override
  String refShareText(Object code) {
    return 'Join me in Boba Empire! Use my invite code $code for bonus 💎: https://bobaempiregame.com';
  }

  @override
  String refStats(Object invited, Object max, Object reached) {
    return 'Invited: $invited/$max · reached the goal: $reached';
  }

  @override
  String refRule(Object gems, Object stage) {
    return 'You get $gems 💎 for each friend who reaches stage $stage. Your friend gets 💎 too when they enter your code.';
  }

  @override
  String refClaim(Object gems) {
    return 'Claim +$gems 💎';
  }

  @override
  String refClaimedSnack(Object gems) {
    return 'Claimed +$gems 💎';
  }

  @override
  String get refEnterTitle => 'Got a friend\'s code?';

  @override
  String get refEnterHint => 'Invite code';

  @override
  String get refRedeem => 'Redeem';

  @override
  String refRedeemedSnack(Object gems) {
    return 'Code accepted: +$gems 💎';
  }

  @override
  String get refErrEmail => 'Link your email first.';

  @override
  String get refErrNotFound => 'Code not found.';

  @override
  String get refErrInvalid => 'You can\'t use this code.';

  @override
  String get refErrAlready => 'You\'ve already used an invite code.';

  @override
  String get refErrFull => 'This code has reached its invite limit.';

  @override
  String get refErrNothing => 'Nothing to claim yet.';

  @override
  String get refErrNetwork => 'Network problem, try again.';

  @override
  String get vipLbOpen => 'VIP leaderboard';

  @override
  String get rewardsTitle => 'Earn more 🎁';

  @override
  String get dailyHubTitle => 'Quests & Rewards';

  @override
  String get dailyHubTabDaily => 'Daily';

  @override
  String get dailyHubTabWeekly => 'Weekly';

  @override
  String get dailyHubTabRewards => 'Rewards 🎁';

  @override
  String get rewardsChip => 'Earn more';

  @override
  String rewardAutoTapName(int m) {
    return 'Auto-tap for $m min';
  }

  @override
  String rewardAutoTapActive(String t) {
    return 'Active · $t left';
  }

  @override
  String rewardAutoTapVip(int n) {
    return 'VIP $n+ gets auto-tap permanently';
  }

  @override
  String rewardAutoTapHint(int n) {
    return 'Watch an ad to auto-tap the cup (VIP $n+ unlocks it for good)';
  }

  @override
  String get rewardAutoTapSnack =>
      'Auto-tap on! It only earns coins — no Guild points or quest progress.';

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
  String recipeGroupLocked(String name, int need, int learned) {
    return '🔒 $name — unlocks when you\'ve learned $need recipes of the previous group ($learned/$need)';
  }

  @override
  String recipeGroupLockedFar(String name) {
    return '🔒 $name';
  }

  @override
  String recipeGroupOpened(String name) {
    return '🔓 New group unlocked: $name!';
  }

  @override
  String recipeStreak(int n) {
    return '🔥 Review streak: $n days';
  }

  @override
  String get recipeStreakToday => 'Reviewed today ✓';

  @override
  String get recipeStreakPending =>
      'Not reviewed today — do a session to keep your streak';

  @override
  String recipeRescueTitle(int n) {
    return 'You missed a day — your $n-day streak is about to be lost!';
  }

  @override
  String recipeRescueGems(int n) {
    return 'Save for $n 💎';
  }

  @override
  String get recipeRescueAd => 'Watch an ad to save';

  @override
  String get recipeRescued => 'Streak saved!';

  @override
  String get recipeRescueNoGems => 'Not enough 💎 to save the streak.';

  @override
  String recipeStreakGems(int n, int gems) {
    return '🔥 $n-day streak! +$gems 💎';
  }

  @override
  String recipeStreakFeedback(int n) {
    return '🔥 Review streak: $n days';
  }

  @override
  String get recipeNotifyTitle => 'Drink recipes';

  @override
  String recipeNotifyStreak(int n) {
    return 'Your $n-day review streak is about to end! Do one session to keep it';
  }

  @override
  String recipeNotifyDue(int n) {
    return '$n recipes are due for review today';
  }

  @override
  String get rlbTitle => 'Recipe Masters';

  @override
  String get lbrBoardRecipes => 'Recipe Masters';

  @override
  String get rlbEmpty =>
      'Nobody is on the board yet. Be the first to master a recipe!';

  @override
  String get rlbNoMastered =>
      'You haven\'t mastered any recipe yet, so you\'re not on the board.';

  @override
  String rlbMastered(int n) {
    return '$n mastered';
  }

  @override
  String get rlbError => 'Couldn\'t load the leaderboard, try again later.';

  @override
  String recipeMilestone(int n) {
    return '$n recipes mastered — you got an accessory!';
  }

  @override
  String get dqRecipe => 'Finish 1 recipe practice session';

  @override
  String wqRecipeSessions(int n) {
    return 'Finish $n recipe practice sessions';
  }

  @override
  String wqRecipeLevels(int n) {
    return 'Level up $n recipes';
  }

  @override
  String get recipeHint => 'Hint (watch an ad)';

  @override
  String get recipeHintNoCount =>
      'You used a hint, so this question doesn\'t count toward levels.';

  @override
  String get recipeDouble => 'Watch an ad to double the coins';

  @override
  String get recipeDoubled => 'Coin reward doubled!';

  @override
  String get recipeTitle => 'Drink recipes';

  @override
  String get recipeEntryNote => 'Memorize recipes, earn rewards';

  @override
  String get recipeEntryButton => 'Play';

  @override
  String recipeMastered(int n, int total) {
    return 'Mastered $n/$total';
  }

  @override
  String recipeDueToday(int n) {
    return '$n recipes to review today';
  }

  @override
  String get recipeAllDone =>
      'All reviewed for today! You can still practice (won\'t count toward levels).';

  @override
  String get recipePractice => 'Practice';

  @override
  String get recipeBox0 => 'New';

  @override
  String get recipeBox1 => 'Familiar';

  @override
  String get recipeBox2 => 'Learned';

  @override
  String get recipeBox3 => 'Mastered';

  @override
  String get recipeReviewToday => 'Review: today';

  @override
  String recipeReviewIn(int n) {
    return 'Review in $n days';
  }

  @override
  String recipeQMissing(String name) {
    return 'Which ingredient is missing from $name?';
  }

  @override
  String recipeQQuantity(String drink, String ingredient) {
    return '$drink: how much $ingredient?';
  }

  @override
  String recipeQFull(String name) {
    return 'Which is the correct recipe for $name?';
  }

  @override
  String get recipeCorrect => 'Correct!';

  @override
  String get recipeWrongShort => 'Not quite — the right answer is highlighted.';

  @override
  String recipeLevelUp(String box, String name) {
    return '$name reached $box!';
  }

  @override
  String get recipePracticeOnly =>
      'Not due for review yet — practice only, no level change.';

  @override
  String get recipeNext => 'Next';

  @override
  String get recipeSeeResult => 'See results';

  @override
  String get recipeResultTitle => 'Results';

  @override
  String recipeScore(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String recipeLevelUps(int n) {
    return '$n recipes leveled up';
  }

  @override
  String recipeRewardCash(String cash) {
    return 'Reward: +$cash coins';
  }

  @override
  String recipeRewardBoth(String cash, int gems) {
    return 'Reward: +$cash coins, +$gems 💎';
  }

  @override
  String get recipeAgain => 'Practice again';

  @override
  String get recipeDone => 'Done';

  @override
  String get recipeDisclaimer =>
      'Recipes are for gameplay reference only, not any brand\'s official recipe.';

  @override
  String get recipeIngredients => 'Ingredients';

  @override
  String walkerTipSnack(String amount) {
    return 'A customer tipped +$amount coins 🧋';
  }

  @override
  String get settingsEffects => 'Visual effects';

  @override
  String get settingsEffectsAuto => 'Auto (match device)';

  @override
  String get settingsEffectsHigh => 'High';

  @override
  String get settingsEffectsMedium => 'Medium';

  @override
  String get settingsEffectsLow => 'Low (saves battery)';

  @override
  String get settingsEffectsOff => 'Off';

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
  String get arenaModeRecipe => 'Recipe Duel';

  @override
  String get arenaRecipeIntro =>
      'Make the same 5 orders — the higher total score wins. If both finish early, the match ends right away!';

  @override
  String get arenaRecipeStart => 'Start brewing';

  @override
  String arenaRecipeProgress(int done, int theirs) {
    return 'You: $done/5 orders · Opponent: $theirs/5';
  }

  @override
  String get arenaRecipeWaiting => 'All done! Waiting for your opponent…';

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
  String get arenaGhostBadge =>
      '👻 Ghost match: you\'re racing a recording of another player. Reduced reward, doesn\'t count for the ranking.';

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
  String get accessoryDonut => 'Donut';

  @override
  String get accessoryLollipop => 'Lollipop';

  @override
  String get accessoryPretzel => 'Pretzel';

  @override
  String get accessoryIceCream => 'Ice Cream Cone';

  @override
  String get accessoryStrawberry => 'Strawberry';

  @override
  String get accessoryCherry => 'Cherries';

  @override
  String get accessoryLemon => 'Lemon';

  @override
  String get accessoryPeach => 'Peach';

  @override
  String get accessoryPopcorn => 'Popcorn';

  @override
  String get accessoryHoneyPot => 'Honey Pot';

  @override
  String get accessoryMilkGlass => 'Glass of Milk';

  @override
  String get accessoryTangerine => 'Tangerine';

  @override
  String get accessoryChestnut => 'Chestnut';

  @override
  String get accessoryMapleLeaf => 'Maple Leaf';

  @override
  String get accessoryCompass => 'Compass';

  @override
  String get accessoryRocket => 'Rocket';

  @override
  String get accessoryViolin => 'Violin';

  @override
  String get accessoryScroll => 'Ancient Scroll';

  @override
  String get accessoryMicrophone => 'Microphone';

  @override
  String get accessoryLotus => 'Lotus';

  @override
  String get accessoryJellyfish => 'Jellyfish';

  @override
  String get accessoryCamera => 'Camera';

  @override
  String get accessoryShield => 'Shield';

  @override
  String get accessoryAmphora => 'Ancient Vase';

  @override
  String get accessoryRainbow => 'Rainbow';

  @override
  String get accessoryFairy => 'Fairy';

  @override
  String get accessoryDiscoBall => 'Disco Ball';

  @override
  String get accessoryShiningStar => 'Shining Star';

  @override
  String get accessoryKraken => 'Kraken';

  @override
  String get accessoryThunderbolt => 'Divine Thunderbolt';

  @override
  String get accessoryIceCube => 'Ice Cube';

  @override
  String get accessoryCroissant => 'Croissant';

  @override
  String get accessoryPancakes => 'Pancakes';

  @override
  String get accessoryWaffle => 'Waffle';

  @override
  String get accessoryBagel => 'Bagel';

  @override
  String get accessoryCakeSlice => 'Cake Slice';

  @override
  String get accessoryPie => 'Pie';

  @override
  String get accessoryCandy => 'Candy';

  @override
  String get accessoryGrapes => 'Grapes';

  @override
  String get accessoryWatermelon => 'Watermelon';

  @override
  String get accessoryPineapple => 'Pineapple';

  @override
  String get accessoryMango => 'Mango';

  @override
  String get accessoryKiwi => 'Kiwi';

  @override
  String get accessoryBanana => 'Banana';

  @override
  String get accessoryApple => 'Apple';

  @override
  String get accessoryTeddy => 'Teddy Bear';

  @override
  String get accessoryCrayon => 'Crayon';

  @override
  String get accessoryBucket => 'Bucket';

  @override
  String get accessoryGuitar => 'Guitar';

  @override
  String get accessoryTrumpet => 'Trumpet';

  @override
  String get accessoryPiano => 'Piano';

  @override
  String get accessorySaxophone => 'Saxophone';

  @override
  String get accessoryBanjo => 'Banjo';

  @override
  String get accessoryMicroscope => 'Microscope';

  @override
  String get accessoryRingedPlanet => 'Ringed Planet';

  @override
  String get accessoryCrescentMoon => 'Crescent Moon';

  @override
  String get accessoryBowArrow => 'Bow and Arrow';

  @override
  String get accessoryMirror => 'Mirror';

  @override
  String get accessoryFerrisWheel => 'Ferris Wheel';

  @override
  String get accessoryCarousel => 'Carousel';

  @override
  String get accessorySwan => 'Swan';

  @override
  String get accessoryFlamingo => 'Flamingo';

  @override
  String get accessoryOwl => 'Owl';

  @override
  String get accessoryWhale => 'Whale';

  @override
  String get accessoryCrown => 'Crown';

  @override
  String get accessoryCircusTent => 'Circus Tent';

  @override
  String get accessoryPinata => 'Piñata';

  @override
  String get accessoryCastle => 'Castle';

  @override
  String get accessoryGenie => 'Genie';

  @override
  String get accessoryVolcano => 'Volcano';

  @override
  String get accessoryCarrot => 'Carrot';

  @override
  String get accessoryCorn => 'Corn';

  @override
  String get accessoryTomato => 'Tomato';

  @override
  String get accessoryAvocado => 'Avocado';

  @override
  String get accessoryCoconut => 'Coconut';

  @override
  String get accessoryBlueberries => 'Blueberries';

  @override
  String get accessoryPear => 'Pear';

  @override
  String get accessoryRiceBall => 'Rice Ball';

  @override
  String get accessoryDumpling => 'Dumpling';

  @override
  String get accessorySushi => 'Sushi';

  @override
  String get accessoryRamen => 'Ramen';

  @override
  String get accessoryTaco => 'Taco';

  @override
  String get accessoryPizza => 'Pizza';

  @override
  String get accessoryHotDog => 'Hot Dog';

  @override
  String get accessoryFries => 'French Fries';

  @override
  String get accessoryEgg => 'Egg';

  @override
  String get accessoryBread => 'Bread';

  @override
  String get accessoryButter => 'Butter';

  @override
  String get accessoryPuzzle => 'Puzzle Piece';

  @override
  String get accessoryDice => 'Dice';

  @override
  String get accessoryChessPawn => 'Chess Pawn';

  @override
  String get accessoryDart => 'Dartboard';

  @override
  String get accessoryBowling => 'Bowling';

  @override
  String get accessoryYoYo => 'Yo-Yo';

  @override
  String get accessoryRollerSkate => 'Roller Skate';

  @override
  String get accessorySkateboard => 'Skateboard';

  @override
  String get accessorySatellite => 'Satellite';

  @override
  String get accessoryAlembic => 'Alembic';

  @override
  String get accessoryDna => 'DNA';

  @override
  String get accessoryTrophy => 'Trophy';

  @override
  String get accessoryLeopard => 'Leopard';

  @override
  String get accessoryElephant => 'Elephant';

  @override
  String get accessoryPanda => 'Panda';

  @override
  String get accessoryGiraffe => 'Giraffe';

  @override
  String get accessoryTurtle => 'Turtle';

  @override
  String get accessoryKoala => 'Koala';

  @override
  String get accessoryPenguin => 'Penguin';

  @override
  String get accessorySauropod => 'Sauropod';

  @override
  String get accessoryMermaid => 'Mermaid';

  @override
  String get accessoryEagle => 'Eagle';

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
  String get collectionTitle80 => 'Master Collector';

  @override
  String get collectionTitle100 => 'Grand Collector';

  @override
  String get collectionTitle120 => 'Collection King';

  @override
  String get collectionTitle140 => 'Collection Sage';

  @override
  String get collectionTitle160 => 'Collecting Deity';

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
  String get collectionSetsTitle => 'Collection sets';

  @override
  String get seasonTitle => 'Season Pass';

  @override
  String seasonEntrySub(int days, int tier) {
    return '$days days left · tier $tier/30';
  }

  @override
  String seasonTierLine(int max, int tier) {
    return 'Tier $tier/$max';
  }

  @override
  String seasonDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String seasonHint(int cap) {
    return 'Earn XP from quests, minigames, the Guild Dungeon and the Arena (up to $cap XP/day). Progress resets each season — claim your rewards!';
  }

  @override
  String get seasonFreeTrack => 'Free';

  @override
  String get seasonPremiumTrack => 'Premium';

  @override
  String seasonBuyPremium(int gems) {
    return 'Unlock Premium · $gems 💎';
  }

  @override
  String get seasonPremiumOwned => '✓ Premium unlocked';

  @override
  String get seasonPremiumBought => 'Premium unlocked!';

  @override
  String get seasonNotEnoughGems => 'Not enough 💎';

  @override
  String get seasonLbTitle => 'Season Pass Ranking';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsTabList => 'Friends';

  @override
  String get friendsTabRequests => 'Requests';

  @override
  String get friendsTabAdd => 'Add friend';

  @override
  String get friendsTabRank => 'Ranking';

  @override
  String get friendsEmpty =>
      'No friends yet. Use the Add friend tab to search by nickname.';

  @override
  String get friendsGiftSend => '🎁 Send gift';

  @override
  String get friendsGiftSentToday => 'Sent today';

  @override
  String friendsGiftSentSnack(String xu) {
    return 'Gift sent! You got +$xu Coins';
  }

  @override
  String friendsGiftWaiting(int n) {
    return '$n gifts from friends are waiting';
  }

  @override
  String get friendsGiftClaim => 'Claim';

  @override
  String friendsGiftClaimedSnack(int n, String xu) {
    return 'Claimed $n gifts: +$xu Coins';
  }

  @override
  String get friendsRemove => 'Remove friend';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Remove $name from your friends?';
  }

  @override
  String get friendsRequestsEmpty => 'No requests.';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsDecline => 'Decline';

  @override
  String friendsAccepted(String name) {
    return 'You are now friends with $name';
  }

  @override
  String get friendsSearchHint => 'Enter the exact nickname';

  @override
  String get friendsSearchButton => 'Search';

  @override
  String get friendsSearchEmpty =>
      'Nobody found with that name. The nickname must match exactly (not case-sensitive) and the player must have linked an email.';

  @override
  String get friendsAddButton => 'Add friend';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsAlready => 'You are already friends';

  @override
  String friendsStage(int n) {
    return 'Stage $n';
  }

  @override
  String get friendsErrLimit =>
      'Your friend list or requests are full (max 50 friends, 30 pending requests).';

  @override
  String get friendsErrNotFound => 'Player not found.';

  @override
  String get friendsErrAlreadySent =>
      'You already sent this friend a gift today.';

  @override
  String get friendsErrNetwork => 'Couldn\'t connect, try again later.';

  @override
  String get friendsRetry => 'Retry';

  @override
  String get friendsRankIncome => 'Earnings';

  @override
  String get friendsRankSeason => 'Season Pass';

  @override
  String get friendsRankOrders => 'Brew by Order';

  @override
  String get friendsRankMe => '(you)';

  @override
  String get friendsRankEmpty => 'Add friends to compete with them.';

  @override
  String get seasonLbEmpty =>
      'Nobody is on this season\'s board yet. Earn Season Pass XP and reopen to appear (needs an email-linked account).';

  @override
  String get playerTitleChampion => 'Season Champion';

  @override
  String get playerTitleChampionHint => 'Claim a top-3 Season Pass reward';

  @override
  String get seasonRewardTitle => 'Last season\'s reward';

  @override
  String seasonRewardLine(int rank) {
    return 'You finished #$rank on last season\'s Season Pass ranking!';
  }

  @override
  String seasonRewardClaim(int gems) {
    return 'Claim $gems 💎';
  }

  @override
  String seasonRewardGot(int gems) {
    return 'Got $gems 💎 season reward!';
  }

  @override
  String get seasonRewardFail => 'Couldn\'t claim the reward. Try again later.';

  @override
  String get seasonItemsTitle =>
      'Season Pass exclusives (tier 20 free · tier 30 Premium)';

  @override
  String get accessorySeasonSakura => 'Season Sakura';

  @override
  String get accessorySeasonPaperLantern => 'Season Paper Lantern';

  @override
  String get accessorySeasonSunflower => 'Season Sunflower';

  @override
  String get accessorySeasonIsland => 'Season Tropical Island';

  @override
  String get accessorySeasonAutumnLeaf => 'Season Autumn Leaf';

  @override
  String get accessorySeasonMoonView => 'Season Moon Viewing';

  @override
  String get accessorySeasonSnowflake => 'Season Snowflake';

  @override
  String get accessorySeasonMountain => 'Season Summit';

  @override
  String seasonGot(String text) {
    return 'Got $text';
  }

  @override
  String get dailyItemTitle => 'Item of the day';

  @override
  String get dailyItemNew => 'A new one for your collection';

  @override
  String get dailyItemOwned => 'Owned — you\'d get a spare';

  @override
  String collectionSetDone(int coins) {
    return 'Got $coins Market Coins for the set!';
  }

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
  String get whatsNewSeason =>
      '🎫 28-day Season Pass (30 tiers), Daily Item and a season leaderboard with end-of-season rewards';

  @override
  String get whatsNewGuild =>
      '🐉 Guild Dungeon (3 stages a week), animated Boss; loadouts and accessory refining';

  @override
  String get whatsNewProfile =>
      '👤 My Profile page: photo avatar and titles; collection set rewards';

  @override
  String get whatsNewArena =>
      '⚔️ Arena: Recipe PK, ghost matches, weekly tournament; Quests & Gifts merged into one screen';

  @override
  String get whatsNewMore =>
      '🤝 Extend Market listings with an ad; online features need a linked email';

  @override
  String get whatsNewLater => 'Later';

  @override
  String get whatsNewOpen => 'Try it';

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
  String marketExpiresIn(String t) {
    return 'Expires in $t';
  }

  @override
  String marketListExpiryNote(int days) {
    return 'Listings last at most $days days; when one expires the item returns to your inventory.';
  }

  @override
  String marketExpiredToast(int n) {
    return '$n expired listing(s) returned to your inventory.';
  }

  @override
  String get swapTab => 'Swaps';

  @override
  String get swapCreate => 'Create offer';

  @override
  String get swapCreateOk => 'Post offer';

  @override
  String swapIntro(int days) {
    return 'Swap an item for another with other players — no Market Coins needed. Your item is held until someone accepts (up to $days days; it returns to your inventory if it expires).';
  }

  @override
  String get swapEmpty => 'No swap offers yet. Create the first one!';

  @override
  String get swapMine => 'My swap offers';

  @override
  String get swapMineEmpty => 'You have no offers posted.';

  @override
  String get swapGive => 'Give';

  @override
  String get swapWant => 'Want';

  @override
  String get swapAccept => 'Swap';

  @override
  String get swapNeedItem => 'Item needed';

  @override
  String get swapCancel => 'Cancel';

  @override
  String get swapPickGive => 'Pick the item you give';

  @override
  String get swapPickWant => 'Pick the item you want';

  @override
  String get swapPickSearch => 'Search by name';

  @override
  String get swapPickNone => 'No items.';

  @override
  String swapMaxNote(int n) {
    return 'Up to $n offers at once.';
  }

  @override
  String get swapConfirmTitle => 'Confirm swap';

  @override
  String swapConfirmBody(String give, String want) {
    return 'You get $give and give $want?';
  }

  @override
  String get swapCreatedToast => 'Swap offer posted!';

  @override
  String swapDoneToast(String name) {
    return 'Swapped! You received $name.';
  }

  @override
  String get swapCancelledToast =>
      'Offer cancelled, the item is back in your inventory.';

  @override
  String swapCollectedToast(int n) {
    return '$n item(s) from swaps returned to your inventory.';
  }

  @override
  String get swapErrNotOwned =>
      'You don\'t have this item (reopen the Market to re-sync).';

  @override
  String get swapErrNotOwnedWant => 'You don\'t have the item they want.';

  @override
  String swapErrTooMany(int n) {
    return 'You have too many open offers (max $n).';
  }

  @override
  String get swapErrNotOpen =>
      'This offer was just taken or cancelled — the list has been updated.';

  @override
  String get swapErrOwn => 'You can\'t accept your own offer.';

  @override
  String get swapErrInvalid => 'Invalid offer.';

  @override
  String get swapErrNetwork => 'Couldn\'t connect, try again later.';

  @override
  String get marketCancelButton => 'Cancel listing';

  @override
  String get marketCancelledToast => 'Listing cancelled.';

  @override
  String marketExtendButton(int days) {
    return 'Extend $days more days (watch ad)';
  }

  @override
  String get marketExtendedToast => 'Listing extended.';

  @override
  String essenceEarned(int n) {
    return '+$n 🧪 Essence';
  }

  @override
  String get masteryTitle => 'Mastery';

  @override
  String masteryEssence(int n) {
    return '🧪 $n Essence';
  }

  @override
  String get masteryHint =>
      'Earn Essence in the mini-games, then upgrade Mastery to boost each stage\'s income. Kept through Franchise.';

  @override
  String masteryBonus(String pct) {
    return '+$pct% income';
  }

  @override
  String masteryBuy(int cost) {
    return 'Upgrade · $cost 🧪';
  }

  @override
  String get masteryMaxed => 'Max';

  @override
  String get guildDungeonTitle => 'Guild Dungeon';

  @override
  String guildDungeonCardSub(int cleared) {
    return '$cleared/3 stages cleared';
  }

  @override
  String guildDungeonStage(int n) {
    return 'Stage $n/3';
  }

  @override
  String get guildDungeonBarTap => 'Taps';

  @override
  String get guildDungeonBarOff => 'Night watch';

  @override
  String get guildDungeonBarRec => 'Recipes';

  @override
  String get guildDungeonRoleTap => 'Tapper';

  @override
  String get guildDungeonRoleOff => 'Night Watcher';

  @override
  String get guildDungeonRoleRec => 'Chef';

  @override
  String get guildDungeonRoleHeader => 'Your role this week';

  @override
  String get guildDungeonRoleHint =>
      'Contributions in your own role count ×1.5. You can switch roles once a week.';

  @override
  String get guildDungeonRoleLockedNote =>
      'You\'ve used your role switch this week.';

  @override
  String get guildDungeonNoRole => 'No role yet — pick one for ×1.5.';

  @override
  String get guildDungeonHint =>
      'All three bars must be full to clear a stage; a surplus in one doesn\'t cover another.';

  @override
  String guildDungeonHours(String n) {
    return '$n h';
  }

  @override
  String get guildDungeonCleared => 'Cleared';

  @override
  String guildDungeonClaim(int coins) {
    return 'Claim · $coins Guild Coins';
  }

  @override
  String guildDungeonClaimFinal(int coins, int gems) {
    return 'Claim · $coins Guild Coins + $gems 💎 + chest';
  }

  @override
  String get guildDungeonClaimed => 'Claimed';

  @override
  String get guildDungeonNeedMin =>
      'Contribute a little (taps, offline time or recipes) to claim the reward.';

  @override
  String guildDungeonClaimedSnack(int coins, int gems) {
    return 'Stage reward: +$coins Guild Coins, +$gems 💎';
  }

  @override
  String guildDungeonClaimedSnackChest(int coins, int gems, String item) {
    return 'Stage reward: +$coins Guild Coins, +$gems 💎, $item';
  }

  @override
  String get guildDungeonBoard => 'Member contributions';

  @override
  String get guildDungeonErrLocked =>
      'Your guild hasn\'t cleared this stage yet.';

  @override
  String get guildDungeonErrRoleLocked =>
      'You\'ve already switched roles once this week.';

  @override
  String get guildDungeonNudgeTooltip => 'Nudge in chat';

  @override
  String guildDungeonNudge(String bar) {
    return 'the $bar bar is short, could you help out?';
  }

  @override
  String get refineTooltip => 'Refine';

  @override
  String get refineButton => 'Refine';

  @override
  String refineLevelLabel(int level, int max) {
    return 'Level $level/$max';
  }

  @override
  String refinePoints(String from, String to) {
    return 'Loadout points: $from → $to';
  }

  @override
  String refineCostSpares(int have, int need) {
    return 'Spares of this item: $have/$need';
  }

  @override
  String refineCostEssence(int have, int need) {
    return '🧪 Essence: $have/$need';
  }

  @override
  String get refineMaxed => 'Max level reached';

  @override
  String refineDone(int level) {
    return 'Refined to level $level';
  }

  @override
  String get refineNote =>
      'Each level adds 25% to the item\'s loadout points; it doesn\'t raise the family cap. The level doesn\'t transfer when you sell or swap the item.';

  @override
  String get refineErrSpares => 'Not enough spares of this item.';

  @override
  String get refineErrEssence => 'Not enough Essence.';

  @override
  String get loadoutTitle => 'Loadout';

  @override
  String get loadoutHint =>
      'Each family gives one buff: 🔥 tap · ✨ income · 🌿 offline · 💎 upgrade cost. Wear several of one family for a combo.';

  @override
  String get loadoutEmpty =>
      'No buffs yet. Tap an item in your collection to wear it.';

  @override
  String loadoutBuffTap(String pct) {
    return '🔥 Tap +$pct%';
  }

  @override
  String loadoutBuffIncome(String pct) {
    return '✨ Income +$pct%';
  }

  @override
  String loadoutBuffOffline(String pct) {
    return '🌿 Offline +$pct%';
  }

  @override
  String loadoutBuffDiscount(String pct) {
    return '💎 Upgrade cost −$pct%';
  }

  @override
  String loadoutComboSuffix(String mult) {
    return ' · combo ×$mult';
  }

  @override
  String loadoutLockNote(int minutes) {
    return '🔒 Swap locked: $minutes min left';
  }

  @override
  String get loadoutLockedTitle => 'Loadout is locked';

  @override
  String loadoutLockedBody(int minutes) {
    return 'You just changed your loadout. $minutes more minutes before you can remove or swap again (filling an empty slot is always OK). Unlock now?';
  }

  @override
  String get loadoutUnlockAd => 'Watch ad to unlock';

  @override
  String get loadoutUnlockFree => 'Unlock';

  @override
  String get loadoutUnlockedToast => 'Unlocked — swap away!';

  @override
  String loadoutRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String loadoutRemoveBody(int minutes) {
    return 'After removing, you can\'t remove or swap another item for $minutes minutes (filling an empty slot is still OK).';
  }

  @override
  String get loadoutRemoveConfirm => 'Remove';

  @override
  String get loadoutFamilyTap => 'Fervor · boosts tap value';

  @override
  String get loadoutFamilyIncome => 'Sparkle · boosts auto income';

  @override
  String get loadoutFamilyOffline => 'Serenity · boosts offline income';

  @override
  String get loadoutFamilyDiscount => 'Finesse · cheaper upgrades';

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
  String get chHeader => '🔥 Challenges (hard — big rewards)';

  @override
  String chCat(int n) {
    return 'Catch $n Golden Rush cats';
  }

  @override
  String chVip(int n) {
    return 'Serve $n VIP customers';
  }

  @override
  String get chBonusLabel => 'Finish both challenges';

  @override
  String get lbrTitle => 'Weekly top rewards';

  @override
  String lbrIntro(int first, int second, int third) {
    return 'Each week the top 3 of every cumulative board (Income, Pearl Drop, Collection, VIP, Recipe Masters, Drink Orders) get $first / $second / $third 💎. Boards are locked at the start of the week (Monday, UTC); rewards can be claimed for one more week.';
  }

  @override
  String get lbrEmpty =>
      'No rewards yet — climb into the top 3 of the leaderboards!';

  @override
  String lbrRow(String board, String week) {
    return '$board · week $week';
  }

  @override
  String lbrClaim(int n) {
    return 'Claim $n 💎';
  }

  @override
  String lbrGot(int n) {
    return 'Claimed $n 💎 weekly top reward!';
  }

  @override
  String get lbrErrGone => 'This reward has expired or is no longer available.';

  @override
  String get lbrBoardIncome => 'Income';

  @override
  String get lbrBoardPearls => 'Pearl Drop';

  @override
  String get lbrBoardCollection => 'Collection';

  @override
  String get lbrBoardVip => 'VIP';

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
  String get weeklyQuestsTitle => 'Weekly quests';

  @override
  String get weeklyQuestsOpen => 'Weekly quests 🗓️';

  @override
  String wqPrestige(int n) {
    return 'Prestige $n times';
  }

  @override
  String wqM3Win(int n) {
    return 'Win $n Falling Pearls levels';
  }

  @override
  String wqTrade(int n) {
    return 'Make $n Market trades (list or buy)';
  }

  @override
  String wqDailyDone(int n) {
    return 'Claim $n daily quest rewards';
  }

  @override
  String wqSpin(int n) {
    return 'Spin the wheel $n times';
  }

  @override
  String wqBuy(int n) {
    return 'Buy $n upgrades';
  }

  @override
  String get weeklyChestLabel =>
      'Weekly chest: finish all 3 → +1 Rare+ accessory';

  @override
  String weeklyResetsIn(String time) {
    return 'Resets in $time';
  }

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
  String get navMatch3 => 'Games';

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
  String get m3LeaveTitle => 'Leave this game?';

  @override
  String get m3LeaveBody => 'Your game is kept until you close the app.';

  @override
  String get m3LeaveStay => 'Keep playing';

  @override
  String get m3LeaveConfirm => 'Leave';

  @override
  String get accessoryHowToTitle => 'Collecting guide';

  @override
  String get accessoryHowToButton => 'Guide';

  @override
  String get accessoryHtp1 =>
      '🎯 Goal: collect every item. Items worn around your cup give small buffs by family (🔥 tap · ✨ income · 🌿 offline · 💎 upgrade cost); wear several of one family for a combo. Removing or swapping has a cooldown — watch an ad to unlock it right away. Show them off and climb the Collection leaderboard.';

  @override
  String get accessoryHtp2 =>
      '🎁 How to get them: finish all 3 daily quests · clear the Falling Pearls milestone levels (10/30/60) · the chest slot on the main wheel · every Ascension · buy Accessory Packs with 💎.';

  @override
  String get accessoryHtp3 =>
      '🎰 Accessory Wheel: each spin costs one ad view or 💎. Ad spins are limited per day.';

  @override
  String get accessoryHtp4 =>
      '✨ Rarity: Common → Rare → Epic → Legendary. Weekends and festivals raise Epic/Legendary odds; Rare/Epic Packs guarantee a minimum rarity; festivals bring a Festival Pack with exclusive items.';

  @override
  String accessoryHtp5(int gems) {
    return '♻️ Duplicate drop: you get $gems 💎 and 1 spare copy to sell on the Market.';
  }

  @override
  String get accessoryHtp6 =>
      '🏬 Market: sell spares for Market Coins, buy missing items from other players (1% fee). Market Coins are bought with Coins or 💎 and can\'t be converted back.';

  @override
  String get accessoryHtp7 =>
      '🏅 Collection milestones (10/25/40/50/80/100/120/140/160 items) reward Market Coins. Add wanted items to your wishlist; ranking counts distinct items.';

  @override
  String get accessoryHtp8 =>
      '👆 Tap an owned item to display it around your cup on the main screen.';

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

  @override
  String eventBanner(String name) {
    return '🎉 $name event';
  }

  @override
  String eventTitle(String name) {
    return '$name event';
  }

  @override
  String eventEndsIn(String time) {
    return 'Ends in $time';
  }

  @override
  String eventPoints(int n) {
    return 'Event points: $n';
  }

  @override
  String get eventRedeemHint =>
      'Finish quests to earn points and redeem exclusive items for free. Points won\'t cover the whole set — pick what you like!';

  @override
  String eventRedeemCost(int cost) {
    return '$cost pts';
  }

  @override
  String get eventLbTitle => 'Event Leaderboard';

  @override
  String get eventLbEmpty =>
      'Nobody is on the board yet. A few taps and you\'re first!';

  @override
  String get eventLbNoScore =>
      'You have no points yet — tap the cup, catch cats, serve VIPs to get on the board.';

  @override
  String eventLbMyScore(int n) {
    return 'Your score: $n';
  }

  @override
  String eventLbScore(int n) {
    return '$n pts';
  }

  @override
  String eventBuff(String mult) {
    return 'Revenue ×$mult during the event';
  }

  @override
  String get guildTitle => 'Guild';

  @override
  String get guildIntro =>
      'Create or join a guild to hit weekly goals together and earn rewards.';

  @override
  String get guildCreate => 'Create guild';

  @override
  String get guildJoin => 'Join';

  @override
  String guildMembersCount(int n, int max) {
    return '$n/$max members';
  }

  @override
  String guildWeekTotal(int n) {
    return 'This week: $n pts';
  }

  @override
  String get guildNameLabel => 'Guild name (3-20 chars)';

  @override
  String get guildTagLabel => 'Tag (2-4 letters/digits)';

  @override
  String get guildLeave => 'Leave guild';

  @override
  String get guildLeaveConfirm =>
      'Leave this guild? Your weekly points will no longer count for it.';

  @override
  String get guildKick => 'Remove';

  @override
  String guildKickConfirm(String name) {
    return 'Remove $name from the guild?';
  }

  @override
  String get guildReport => 'Report guild';

  @override
  String get guildReportSent => 'Report sent, thank you.';

  @override
  String get guildGoalTitle => 'Weekly goal';

  @override
  String get guildClaim => 'Claim';

  @override
  String get guildHowToTitle => 'How to earn Guild points';

  @override
  String guildHowTo(int n) {
    return '⭐ Guild points come from YOUR activity this week: tap a cup +1, catch a cat +50, serve a VIP customer +50.\n🎯 Everyone\'s points add up to unlock milestone rewards; the week resets Monday 00:00 UTC.\n🎁 You must contribute ≥$n personal points to claim a milestone reward.';
  }

  @override
  String guildNeedPoints(int n) {
    return 'Contribute ≥$n pts to claim';
  }

  @override
  String guildYourPoints(int n) {
    return 'Your contribution: $n pts';
  }

  @override
  String get guildOwner => 'Owner';

  @override
  String get guildEmpty => 'No public guilds yet. Create the first one!';

  @override
  String get guildErrNameTaken => 'That guild name is taken.';

  @override
  String get guildErrFull => 'This guild is full.';

  @override
  String guildExpandButton(int cost, int max) {
    return 'Expand to $max slots · $cost 💎';
  }

  @override
  String guildExpandConfirm(int cost, int max) {
    return 'Expand the guild to $max members for $cost 💎?';
  }

  @override
  String get guildExpandAction => 'Expand';

  @override
  String guildExpandDone(int max) {
    return 'The guild now holds up to $max members!';
  }

  @override
  String get guildExpandMaxed => 'The guild is already at max capacity.';

  @override
  String get guildErrAlready => 'You\'re already in a guild.';

  @override
  String get guildErrInvalid => 'Invalid name or tag.';

  @override
  String get guildErrNotFound => 'Guild not found (it may have closed).';

  @override
  String get guildErrContribution =>
      'You need to contribute more points this week.';

  @override
  String get guildErrNetwork => 'Can\'t connect, please try again.';

  @override
  String get guildLbTitle => 'Guild Leaderboard';

  @override
  String get guildLbEmpty => 'No guild has points this week yet.';

  @override
  String guildRewardGot(int gems) {
    return 'Got +$gems 💎';
  }

  @override
  String guildRewardGotAccessory(int gems, String name) {
    return 'Got +$gems 💎 and $name';
  }

  @override
  String guildPoints(int n) {
    return '$n pts';
  }

  @override
  String guildCreateCost(int n) {
    return 'Guild creation fee: $n 💎';
  }

  @override
  String guildErrGems(int n) {
    return 'You need $n 💎 to create a guild.';
  }

  @override
  String get guildApprovalSwitch => 'Owner must approve join requests';

  @override
  String get guildRequestJoin => 'Request';

  @override
  String get guildRequestSent =>
      'Request sent, waiting for the owner to approve.';

  @override
  String get guildRequestPending => 'Pending';

  @override
  String guildRequestsTitle(int n) {
    return 'Join requests ($n)';
  }

  @override
  String get guildAccept => 'Approve';

  @override
  String get guildReject => 'Reject';

  @override
  String get guildErrApproval =>
      'This guild needs the owner\'s approval — tap \"Request\".';

  @override
  String get guildErrNicknameTaken =>
      'Someone in this guild already uses that name — pick another one.';

  @override
  String get guildErrRequestsFull =>
      'This guild has too many pending requests.';

  @override
  String cloudSaveConflictGems(String local, String cloud) {
    return '💎 This device: $local · On the cloud: $cloud';
  }

  @override
  String get cloudRemindTitle => 'Protect your progress';

  @override
  String get cloudRemindBody =>
      'You haven\'t linked an email. If you switch phones or reinstall, your progress (Coins, 💎, accessories, Market Coins) will be LOST. Linking takes a minute and is free.';

  @override
  String get cloudRemindLink => 'Link now';

  @override
  String get cloudRemindLater => 'Later';

  @override
  String get ftueTap => 'Tap the cup to brew tea and earn Coins!';

  @override
  String get ftueBuy =>
      'Enough Coins! Buy your first upgrade so Coins flow in every second.';

  @override
  String get ftueExplain =>
      'Nice! Your Coins now grow every second — even when the app is closed. Keep upgrading to earn faster, unlock new stages and claim quest rewards.';

  @override
  String get ftueOk => 'Got it';

  @override
  String get ftueSkip => 'Skip';

  @override
  String get accessoryGuildFlag => 'Guild Flag';

  @override
  String get accessoryGuildCastle => 'Guild Castle';

  @override
  String get accessoryGuildWolf => 'Guild Wolf';

  @override
  String get accessoryGuildDragon => 'Guild Dragon';

  @override
  String get accessoryGuildFox => 'Guild Fox';

  @override
  String get accessoryGuildTiger => 'Guild Tiger';

  @override
  String get accessoryGuildShark => 'Guild Shark';

  @override
  String get accessoryGuildTrex => 'Guild T-Rex';

  @override
  String get accessoryGuildBoar => 'Guild Boar';

  @override
  String get accessoryGuildBear => 'Guild Bear';

  @override
  String get accessoryGuildScorpion => 'Guild Scorpion';

  @override
  String get accessoryGuildMoai => 'Guild Moai';

  @override
  String get guildChatTitle => 'Guild chat';

  @override
  String get guildChatEmpty =>
      'No messages yet. Be the first to say something!';

  @override
  String get guildChatHint => 'Message your guild…';

  @override
  String get guildChatSend => 'Send';

  @override
  String get guildChatPinned => 'Announcement';

  @override
  String get guildChatPin => 'Pin';

  @override
  String get guildChatUnpin => 'Unpin';

  @override
  String get guildChatDelete => 'Delete message';

  @override
  String get guildChatReport => 'Report message';

  @override
  String get guildChatReported =>
      'Message reported. You won\'t see it anymore.';

  @override
  String get guildMembersHeader => 'Members';

  @override
  String get guildMemberSearchHint => 'Search members';

  @override
  String get guildMemberNoMatch => 'No matching members.';

  @override
  String get guildRoleOwner => 'Owner';

  @override
  String get guildRoleOfficer => 'Officer';

  @override
  String get guildRoleMember => 'Member';

  @override
  String get guildMemberMention => 'Mention in chat';

  @override
  String get guildMemberProfile => 'View profile';

  @override
  String get guildQuestsSection => 'Guild quests';

  @override
  String get guildQuestsSectionHint =>
      'Reset every Monday 00:00 UTC · rewards Guild Coins';

  @override
  String get guildManage => 'Manage';

  @override
  String get guildPromote => 'Appoint officer';

  @override
  String get guildDemote => 'Remove officer';

  @override
  String get guildTransfer => 'Transfer ownership';

  @override
  String get guildTeamTitle => 'This week\'s team quest';

  @override
  String guildTeamProgress(int active, int need) {
    return '$active / $need members done';
  }

  @override
  String guildTeamHint(int n) {
    return 'Half the guild (at least 2 members) reaching $n weekly points unlocks the reward for everyone who got there. Play together!';
  }

  @override
  String guildTeamClaim(int n) {
    return 'Claim $n Guild Coins';
  }

  @override
  String guildTeamGot(int n) {
    return 'Got $n Guild Coins from the team quest!';
  }

  @override
  String get guildErrTeamNotReached =>
      'Not enough members have reached the points yet.';

  @override
  String guildErrTeamLow(int n) {
    return 'You need at least $n weekly points to claim.';
  }

  @override
  String get guildFundTitle => 'This week\'s guild fund';

  @override
  String guildFundMine(int n) {
    return 'You contributed $n 💎';
  }

  @override
  String guildFundClaim(int n) {
    return 'Claim $n Guild Coins';
  }

  @override
  String guildFundHint(int min) {
    return 'Everyone donates 💎 together to hit the goal (it grows with member count). Each member must give at least $min 💎 to claim the reward.';
  }

  @override
  String guildFundGot(int n) {
    return 'Claimed $n Guild Coins from the fund!';
  }

  @override
  String get guildErrFundNotReached =>
      'The guild fund hasn\'t reached its goal yet.';

  @override
  String guildErrFundLow(int n) {
    return 'You need to give at least $n 💎 to the fund to claim the reward.';
  }

  @override
  String guildFundProgress(int progress, int target) {
    return '$progress / $target 💎';
  }

  @override
  String guildTransferConfirm(String name) {
    return 'Transfer ownership to $name? You\'ll become a regular member.';
  }

  @override
  String get guildErrNotAllowed =>
      'You don\'t have permission over this member.';

  @override
  String guildErrOfficersFull(int n) {
    return 'The guild already has $n officers.';
  }

  @override
  String get guildActivityTitle => 'Guild log';

  @override
  String get guildActivityEmpty => 'No activity yet.';

  @override
  String guildEvJoined(String name) {
    return '$name joined the guild';
  }

  @override
  String guildEvLeft(String name) {
    return '$name left the guild';
  }

  @override
  String guildEvKicked(String actor, String target) {
    return '$actor removed $target from the guild';
  }

  @override
  String guildEvPromoted(String actor, String target) {
    return '$actor appointed $target as officer';
  }

  @override
  String guildEvDemoted(String actor, String target) {
    return '$actor removed $target as officer';
  }

  @override
  String guildEvTransferred(String actor, String target) {
    return '$actor transferred ownership to $target';
  }

  @override
  String get guildErrChatRate =>
      'You\'re sending too fast, wait a few seconds.';

  @override
  String get guildErrTextBlocked => 'Your message contains a blocked word.';

  @override
  String guildErrDailyLimit(int n) {
    return 'You\'ve already donated the daily max of $n 💎.';
  }

  @override
  String get guildErrCoins => 'Not enough Guild Coins.';

  @override
  String get guildErrOwned => 'You already own this item.';

  @override
  String get guildErrBuffMaxed =>
      'The guild buff is at its maximum, wait a bit.';

  @override
  String get guildErrClaimed => 'You already claimed this reward.';

  @override
  String get guildErrInvalidInput => 'Invalid action.';

  @override
  String get guildShopButton => 'Guild shop';

  @override
  String get guildShopTitle => 'Guild shop';

  @override
  String guildCoinsLabel(int n) {
    return 'Guild Coins: $n';
  }

  @override
  String get guildDonateTitle => 'Donate 💎 for Guild Coins';

  @override
  String guildDonateHint(int used, int cap) {
    return 'Today: $used/$cap 💎 · 1 💎 = 1 Guild Coin';
  }

  @override
  String guildDonateGems(int n) {
    return '$n 💎';
  }

  @override
  String guildDonated(int n) {
    return 'Donated, got +$n Guild Coins';
  }

  @override
  String get guildQuestsTitle => 'Weekly guild quests';

  @override
  String guildQuestProgress(int have, int need) {
    return 'Contribute $need points this week ($have/$need)';
  }

  @override
  String guildQuestReward(int n) {
    return '+$n Guild Coins';
  }

  @override
  String guildQuestGot(int n) {
    return 'Got +$n Guild Coins';
  }

  @override
  String get guildItemsTitle => 'Exclusive guild accessories';

  @override
  String guildItemPrice(int n) {
    return '$n Coins';
  }

  @override
  String get guildItemOwned => 'Owned';

  @override
  String get guildItemBought =>
      'Exchanged! The accessory is in your Collection.';

  @override
  String get guildBuffTitle => 'Guild income buff';

  @override
  String guildBuffDesc(int pct, int hours) {
    return '+$pct% Coins for $hours hours for every member (not applied offline)';
  }

  @override
  String guildBuffLeft(String time) {
    return '$time left';
  }

  @override
  String get guildBuffBought => 'Guild buff activated!';

  @override
  String guildStreakLine(int n) {
    return '🔥 $n weeks in a row hitting all 3 milestones';
  }

  @override
  String guildBuffLine(int pct, String time) {
    return '⚡ Guild buff +$pct% · $time left';
  }

  @override
  String get guildLbTabTotal => 'Total';

  @override
  String get guildLbTabAvg => 'Average';

  @override
  String get guildLbTabStreak => 'Streak';

  @override
  String guildLbAvgNote(int n) {
    return 'Only guilds with $n+ members are ranked';
  }

  @override
  String guildAvgPerMember(int n) {
    return '$n/member';
  }

  @override
  String guildStreakWeeks(int n) {
    return '$n weeks';
  }

  @override
  String get guildLbStreakNote =>
      'Consecutive weeks the guild hit all 3 milestones';

  @override
  String get guildLbStreakEmpty => 'No guild has a streak yet.';

  @override
  String get guildLbAvgEmpty =>
      'No guild qualifies for the average ranking yet.';

  @override
  String get recipeOrderOrders => 'Brew by order';

  @override
  String recipeOrderAsk(String drink) {
    return 'Customer orders: $drink';
  }

  @override
  String get recipeOrderGuideFull => 'Sample recipe';

  @override
  String get recipeOrderGuideNames => 'Ingredients to use (recall the amounts)';

  @override
  String recipeOrderGuideCount(int n) {
    return 'This drink has $n ingredients — recall them!';
  }

  @override
  String get recipeOrderGuideNone => 'No hints — brew from memory!';

  @override
  String get recipeOrderTray =>
      'Ingredient tray — drag into the cup or tap to pick';

  @override
  String get recipeOrderCupEmpty => 'The cup is empty';

  @override
  String recipeOrderSetAmount(String name) {
    return 'Amount of $name';
  }

  @override
  String get recipeOrderPour => 'Add to cup';

  @override
  String get recipeOrderRemove => 'Remove';

  @override
  String get recipeOrderServe => 'Serve';

  @override
  String get recipeOrderPerfect => 'Perfect! Every amount is right';

  @override
  String get recipeOrderGood => 'Passed — amounts slightly off';

  @override
  String get recipeOrderFail => 'Not the right drink';

  @override
  String recipeOrderMissing(String amount, String name) {
    return 'Missing $name ($amount)';
  }

  @override
  String recipeOrderExtra(String name) {
    return 'Extra $name — not in the recipe';
  }

  @override
  String recipeOrderOff(String mine, String name, String right) {
    return '$name: you added $mine, correct is $right';
  }

  @override
  String get recipeOrderHint =>
      'Tip: tap an added ingredient to change its amount';

  @override
  String get rlbTabQuiz => 'Quiz';

  @override
  String get rlbOrderEmpty =>
      'Nobody is on the board yet. Be the first to brew a drink perfectly without the sample recipe!';

  @override
  String get rlbNoPerfect =>
      'You haven\'t brewed any drink perfectly (without the sample recipe) yet, so you\'re not on the board.';

  @override
  String rlbPerfect(int n) {
    return '$n perfect drinks';
  }

  @override
  String get recipeOrderHold => 'Hold to pour';

  @override
  String get recipeOrderPourAgain => 'Start over';

  @override
  String recipeOrderCombo(int n) {
    return '🔥 Combo ×$n';
  }

  @override
  String recipeOrderComboTip(String cash, int combo) {
    return 'Combo ×$combo: tip +$cash coins!';
  }

  @override
  String get rlbTabDaily => 'Today';

  @override
  String get rlbDailyEmpty =>
      'Nobody has posted a score today. Do the challenge to be first on the board!';

  @override
  String get rlbNoDaily =>
      'Do today\'s challenge to get your name on the board.';

  @override
  String rlbDailyScore(Object n) {
    return '$n pts';
  }

  @override
  String get recipeDailyTitle => 'Today\'s challenge';

  @override
  String get recipeDailyOpen => '3 hard orders, no hints — once a day';

  @override
  String recipeDailyDone(Object score) {
    return 'Today you scored $score/300';
  }

  @override
  String recipeDailyOrderScore(Object n) {
    return 'This order: $n/100';
  }

  @override
  String recipeDailyTotal(Object n) {
    return '$n/300 pts';
  }

  @override
  String get recipeDailyAlready =>
      'You\'ve done today\'s challenge. Come back tomorrow — new orders every day!';

  @override
  String get recipeDailyBoard => 'See today\'s board';

  @override
  String get recipeDailyIntro =>
      'Same orders for everyone, no hints, every amount must be exact. One try per day.';

  @override
  String get recipeOrderRush => 'Rush hour';

  @override
  String get recipeOrderRushSub =>
      'Customers won\'t wait long: serve a perfect drink in time for an extra tip. When time runs out, the cup is graded as it is.';

  @override
  String get recipeOrderTimeUp =>
      '⏰ Time\'s up! The customer left, your cup is graded as it stands.';

  @override
  String recipeOrderRushTip(String cash) {
    return '⏱ Served in time! Tip +$cash coins!';
  }

  @override
  String recipeOrderFestival(String name) {
    return 'Festival order: $name';
  }

  @override
  String recipeOrderFestivalTip(String cash) {
    return '🎁 Perfect festival order! Tip +$cash coins!';
  }

  @override
  String get recipeOrderShare => 'Show off this cup';

  @override
  String get cupShareTitle => 'Perfect cup';

  @override
  String get cupSharePerfect => 'Perfect pour!';

  @override
  String cupShareText(String name) {
    return 'I just made a perfect $name in Boba Empire! 🧋';
  }

  @override
  String recipeCounterNext(int count) {
    return 'Master $count recipes to unlock 1 more display slot';
  }

  @override
  String get lbrBoardOrders => 'Brew by order';

  @override
  String get storySpeedrunTabExt3 => 'Act 4';

  @override
  String get storySpeedrunExt3NotCompletedYet =>
      'You haven\'t finished Act 4 yet — complete Chapter 46 to be ranked.';

  @override
  String storyCondRecipes(int n, String game) {
    return 'Master $n recipes in $game';
  }

  @override
  String storyCondOrders(int n, String game) {
    return 'Make $n perfect drinks in $game';
  }

  @override
  String storyCondDaily(int n, String game) {
    return 'Complete $game on $n days';
  }

  @override
  String get lbrBoardDaily => 'Daily Challenge';

  @override
  String get lbrBoardArena => 'Arena Tournament';

  @override
  String lbrDailyNote(int rest) {
    return 'Daily Challenge: the top 10 by TOTAL score over last week also get rewards — ranks 1-3 as above, ranks 4-10 get $rest 💎.';
  }

  @override
  String get rlbDailyWeeklyHint =>
      'Each week the top 10 by total Daily Challenge score for the whole week get 💎 (locked at the start of next week, UTC).';

  @override
  String get howToTooltip => 'How to play';

  @override
  String get howToRecipesTitle => 'How to play: Recipes';

  @override
  String get howToRecipes1 =>
      'Learn recipes with SPACED REVIEW: each day the game picks the drinks that are due and you answer a few questions.';

  @override
  String howToRecipes2(int a, int b, int c) {
    return 'Each drink has 4 levels: New → Familiar → Learned → Mastered. A correct answer levels it up and schedules the next review in $a / $b / $c days; a wrong one drops it one level and brings it back right away.';
  }

  @override
  String get howToRecipes3 =>
      'Questions get harder with the level: New fills in the missing ingredient, Familiar guesses the amount, Learned/Mastered picks the correct full recipe.';

  @override
  String get howToRecipes4 =>
      'Reviewing a drink that isn\'t due is practice only: no level change and no reward. You can watch an ad for a hint (that question doesn\'t count).';

  @override
  String get howToRecipes5 =>
      'Reaching each level for the first time earns coins; the first Mastered also earns 💎. Milestones of Mastered drinks (5, 10, 20…) give accessory chests.';

  @override
  String howToRecipes6(int n) {
    return 'Review every day to keep your 🔥 streak and earn 💎 at 3 / 7 / 14 / 30 days; a broken streak can be rescued with 💎. Learn $n drinks of a group to unlock the next group.';
  }

  @override
  String get howToOrdersTitle => 'How to play: Brew by order';

  @override
  String get howToOrders1 =>
      'A customer orders a drink: drag (or tap) ingredients from the tray into the cup, then set the amount.';

  @override
  String get howToOrders2 =>
      'In the amount sheet, tap the ruler or HOLD the pour button to raise the amount; lower levels show guide marks.';

  @override
  String get howToOrders3 =>
      'Tap Serve: the cup is sealed and shaken, then each ingredient is graded — exact, one step off, wrong amount, missing or extra.';

  @override
  String get howToOrders4 =>
      'The better you know a drink, the fewer hints: New shows the sample recipe and a green mark, Familiar only the ingredient names, Learned only how many, Mastered nothing. New/Familiar allow one step off; Learned/Mastered must be exact.';

  @override
  String get howToOrders5 =>
      'The result counts toward the drink\'s level like a quiz answer. Watch an ad to reveal the sample recipe (that order doesn\'t count).';

  @override
  String get howToOrders6 =>
      'Brew several perfect orders in a row without hints for a 🔥 combo and coin tips (only for drinks that are due).';

  @override
  String get howToOrders7 =>
      'Turn on ⏱ Rush hour at the first order: customers only wait so long. Serve a perfect drink in time for an extra tip; when time runs out, the cup is graded as it is.';

  @override
  String get howToOrders8 =>
      'During a festival an extra festival order appears at the end (bigger tip). After a perfect drink, tap “Show off this cup” to share its picture. Drinks made perfectly without the sample recipe count toward the leaderboard.';

  @override
  String get howToDailyTitle => 'How to play: Daily Challenge';

  @override
  String get howToDaily1 =>
      'Every day has 3 hard orders, the SAME for every player in the world.';

  @override
  String get howToDaily2 =>
      'No hints, many distractor ingredients and every amount must be exact. It doesn\'t change any drink\'s level.';

  @override
  String howToDaily3(int max) {
    return 'Each order is worth up to 100 points (exact 1, one step off half, missing 0, extra deducts). Maximum total: $max points.';
  }

  @override
  String howToDaily4(int gems) {
    return 'Only ONE attempt per day: finish for $gems 💎 and coins based on your score; a submitted score can\'t be changed.';
  }

  @override
  String get howToDaily5 =>
      'The “Today” tab of the leaderboard ranks today\'s scores. Every week the top 10 by TOTAL score for the week get 💎 (email link required).';
}
