/// Ánh xạ các id ở tầng dữ liệu (generator/stage) và enum IAP sang chuỗi đã
/// dịch. Gom một chỗ để tầng core/Balance khỏi giữ tên hiển thị.
library;

import '../core/accessories.dart';
import '../core/achievements.dart';
import '../core/format.dart';
import '../core/quests.dart';
import '../iap/iap_products.dart';
import 'app_localizations.dart';

String generatorName(AppLocalizations l10n, String id) => switch (id) {
      'tra_den' => l10n.genTraDen,
      'tran_chau' => l10n.genTranChau,
      'thach' => l10n.genThach,
      'pudding' => l10n.genPudding,
      'kem_nuong' => l10n.genKemNuong,
      'matcha' => l10n.genMatcha,
      'duong_den' => l10n.genDuongDen,
      'brulee' => l10n.genBrulee,
      'cheese_foam' => l10n.genCheeseFoam,
      'tra_trai_cay' => l10n.genTraTraiCay,
      'boba_vang' => l10n.genBobaVang,
      'galaxy' => l10n.genGalaxy,
      'quantum_tea' => l10n.genQuantumTea,
      'ai_tea' => l10n.genAiTea,
      'parallel_tea' => l10n.genParallelTea,
      'nft_tea' => l10n.genNftTea,
      'time_tea' => l10n.genTimeTea,
      'multidim_tea' => l10n.genMultidimTea,
      'blackhole_tea' => l10n.genBlackholeTea,
      'light_tea' => l10n.genLightTea,
      'robot_tea' => l10n.genRobotTea,
      'hologram_tea' => l10n.genHologramTea,
      'legend_tea' => l10n.genLegendTea,
      'eternal_tea' => l10n.genEternalTea,
      'academy_tea' => l10n.genAcademyTea,
      'scholar_tea' => l10n.genScholarTea,
      'city_tea' => l10n.genCityTea,
      'metro_tea' => l10n.genMetroTea,
      'nation_tea' => l10n.genNationTea,
      'treaty_tea' => l10n.genTreatyTea,
      'union_tea' => l10n.genUnionTea,
      'world_tea' => l10n.genWorldTea,
      'planet_tea' => l10n.genPlanetTea,
      'terraform_tea' => l10n.genTerraformTea,
      'truth_tea' => l10n.genTruthTea,
      'ultimate_tea' => l10n.genUltimateTea,
      _ => id,
    };

String stageName(AppLocalizations l10n, int stage) => switch (stage) {
      1 => l10n.stage1,
      2 => l10n.stage2,
      3 => l10n.stage3,
      4 => l10n.stage4,
      5 => l10n.stage5,
      6 => l10n.stage6,
      7 => l10n.stage7,
      8 => l10n.stage8,
      9 => l10n.stage9,
      10 => l10n.stage10,
      11 => l10n.stage11,
      12 => l10n.stage12,
      13 => l10n.stage13,
      14 => l10n.stage14,
      15 => l10n.stage15,
      16 => l10n.stage16,
      17 => l10n.stage17,
      18 => l10n.stage18,
      _ => '',
    };

String iapTitle(AppLocalizations l10n, IapProduct p) => switch (p) {
      IapProduct.removeAds => l10n.iapRemoveAdsTitle,
      IapProduct.starterPack => l10n.iapStarterTitle,
      IapProduct.doubleIncome => l10n.iapDoubleTitle,
      IapProduct.vip30 => l10n.iapVipTitle,
      _ => '${formatNumber(p.gems)} 💎', // gói gems: hiện luôn số lượng
    };

String iapDescription(AppLocalizations l10n, IapProduct p) => switch (p) {
      IapProduct.removeAds => l10n.iapRemoveAdsDesc,
      IapProduct.starterPack => l10n.iapStarterDesc,
      IapProduct.doubleIncome => l10n.iapDoubleDesc,
      IapProduct.vip30 => l10n.iapVipDesc,
      _ => l10n.iapGemsDesc,
    };

/// Mô tả hiển thị của một nhiệm vụ (tái dùng template thành tựu cho các mốc chung).
String questDesc(AppLocalizations l10n, Quest q) {
  if (q.repeatable) {
    return l10n.questRepeatEarn(formatNumber(q.threshold.toDouble()));
  }
  return switch (q.metric) {
    QuestMetric.tap => l10n.questTap(q.threshold.toInt()),
    QuestMetric.buy => l10n.questBuy(q.threshold.toInt()),
    QuestMetric.earn => l10n.achEarn(formatNumber(q.threshold.toDouble())),
    QuestMetric.levels => l10n.achLevels(q.threshold.toInt()),
    QuestMetric.stage => l10n.achStage(q.threshold.toInt()),
    QuestMetric.prestige => l10n.achPrestige(q.threshold.toInt()),
  };
}

/// Mô tả hiển thị của một thành tựu (dựng từ template + ngưỡng).
String achievementDesc(AppLocalizations l10n, Achievement a) =>
    switch (a.metric) {
      AchievementMetric.earn =>
        l10n.achEarn(formatNumber(a.threshold.toDouble())),
      AchievementMetric.stage => l10n.achStage(a.threshold.toInt()),
      AchievementMetric.levels => l10n.achLevels(a.threshold.toInt()),
      AchievementMetric.prestige => l10n.achPrestige(a.threshold.toInt()),
      AchievementMetric.ascension => l10n.achAscend,
    };

/// Tên hiển thị của một phụ kiện sưu tập (xem core/accessories.dart).
String accessoryName(AppLocalizations l10n, String id) => switch (id) {
      'mint_leaf' => l10n.accessoryMintLeaf,
      'cupcake' => l10n.accessoryCupcake,
      'cookie' => l10n.accessoryCookie,
      'potted_plant' => l10n.accessoryPottedPlant,
      'candle' => l10n.accessoryCandle,
      'scarf' => l10n.accessoryScarf,
      'kite' => l10n.accessoryKite,
      'cap' => l10n.accessoryCap,
      'seashell' => l10n.accessorySeashell,
      'mask' => l10n.accessoryMask,
      'drum' => l10n.accessoryDrum,
      'palette' => l10n.accessoryPalette,
      'crystal_ball' => l10n.accessoryCrystalBall,
      'lantern' => l10n.accessoryLantern,
      'unicorn' => l10n.accessoryUnicorn,
      'dragon' => l10n.accessoryDragon,
      'balloon' => l10n.accessoryBalloon,
      'bowtie' => l10n.accessoryBowtie,
      'sunglasses' => l10n.accessorySunglasses,
      'umbrella' => l10n.accessoryUmbrella,
      'teapot' => l10n.accessoryTeapot,
      'bell' => l10n.accessoryBell,
      'ribbon' => l10n.accessoryRibbon,
      'bookmark' => l10n.accessoryBookmark,
      'wind_chime' => l10n.accessoryWindChime,
      'clover' => l10n.accessoryClover,
      'bubble' => l10n.accessoryBubble,
      'sticker' => l10n.accessorySticker,
      'yarn' => l10n.accessoryYarn,
      'fan' => l10n.accessoryFan,
      'basket' => l10n.accessoryBasket,
      'bead' => l10n.accessoryBead,
      'ladybug' => l10n.accessoryLadybug,
      'key' => l10n.accessoryKey,
      'diamond_stone' => l10n.accessoryDiamondStone,
      'music_note' => l10n.accessoryMusicNote,
      'telescope' => l10n.accessoryTelescope,
      'anchor' => l10n.accessoryAnchor,
      'feather' => l10n.accessoryFeather,
      'hourglass' => l10n.accessoryHourglass,
      'map' => l10n.accessoryMap,
      'ring' => l10n.accessoryRing,
      'magic_wand' => l10n.accessoryMagicWand,
      'trident' => l10n.accessoryTrident,
      'peacock' => l10n.accessoryPeacock,
      'comet' => l10n.accessoryComet,
      'butterfly' => l10n.accessoryButterfly,
      'angel_wing' => l10n.accessoryAngelWing,
      'phoenix' => l10n.accessoryPhoenix,
      'galaxy' => l10n.accessoryGalaxy,
      _ => id,
    };

String accessoryRarityLabel(AppLocalizations l10n, AccessoryRarity r) =>
    switch (r) {
      AccessoryRarity.common => l10n.accessoryRarityCommon,
      AccessoryRarity.rare => l10n.accessoryRarityRare,
      AccessoryRarity.epic => l10n.accessoryRarityEpic,
      AccessoryRarity.legendary => l10n.accessoryRarityLegendary,
    };
