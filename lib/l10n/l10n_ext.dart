/// Ánh xạ các id ở tầng dữ liệu (generator/stage) và enum IAP sang chuỗi đã
/// dịch. Gom một chỗ để tầng core/Balance khỏi giữ tên hiển thị.
library;

import '../iap/iap_products.dart';
import 'app_localizations.dart';

String generatorName(AppLocalizations l10n, String id) => switch (id) {
      'tra_den' => l10n.genTraDen,
      'tran_chau' => l10n.genTranChau,
      'thach' => l10n.genThach,
      'pudding' => l10n.genPudding,
      'kem_nuong' => l10n.genKemNuong,
      'matcha' => l10n.genMatcha,
      _ => id,
    };

String stageName(AppLocalizations l10n, int stage) => switch (stage) {
      1 => l10n.stage1,
      2 => l10n.stage2,
      3 => l10n.stage3,
      _ => '',
    };

String iapTitle(AppLocalizations l10n, IapProduct p) => switch (p) {
      IapProduct.gems => l10n.iapGemsTitle,
      IapProduct.removeAds => l10n.iapRemoveAdsTitle,
      IapProduct.starterPack => l10n.iapStarterTitle,
    };

String iapDescription(AppLocalizations l10n, IapProduct p) => switch (p) {
      IapProduct.gems => l10n.iapGemsDesc,
      IapProduct.removeAds => l10n.iapRemoveAdsDesc,
      IapProduct.starterPack => l10n.iapStarterDesc,
    };
