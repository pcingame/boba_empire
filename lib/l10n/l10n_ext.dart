/// Ánh xạ các id ở tầng dữ liệu (generator/stage) và enum IAP sang chuỗi đã
/// dịch. Gom một chỗ để tầng core/Balance khỏi giữ tên hiển thị.
library;

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
      _ => id,
    };

String stageName(AppLocalizations l10n, int stage) => switch (stage) {
      1 => l10n.stage1,
      2 => l10n.stage2,
      3 => l10n.stage3,
      4 => l10n.stage4,
      5 => l10n.stage5,
      6 => l10n.stage6,
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
String questDesc(AppLocalizations l10n, Quest q) => switch (q.metric) {
      QuestMetric.tap => l10n.questTap(q.threshold.toInt()),
      QuestMetric.buy => l10n.questBuy(q.threshold.toInt()),
      QuestMetric.earn => l10n.achEarn(formatNumber(q.threshold.toDouble())),
      QuestMetric.levels => l10n.achLevels(q.threshold.toInt()),
      QuestMetric.stage => l10n.achStage(q.threshold.toInt()),
      QuestMetric.prestige => l10n.achPrestige(q.threshold.toInt()),
    };

/// Mô tả hiển thị của một thành tựu (dựng từ template + ngưỡng).
String achievementDesc(AppLocalizations l10n, Achievement a) =>
    switch (a.metric) {
      AchievementMetric.earn =>
        l10n.achEarn(formatNumber(a.threshold.toDouble())),
      AchievementMetric.stage => l10n.achStage(a.threshold.toInt()),
      AchievementMetric.levels => l10n.achLevels(a.threshold.toInt()),
      AchievementMetric.prestige => l10n.achPrestige(a.threshold.toInt()),
    };
