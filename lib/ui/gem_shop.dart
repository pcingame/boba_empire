import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/format.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

/// Mở Cửa hàng Kim Cương — chỗ tiêu gems kiếm từ VIP, và nạp bằng tiền thật.
Future<void> showGemShop(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _GemShop(),
  );
}

class _GemShop extends ConsumerStatefulWidget {
  const _GemShop();

  @override
  ConsumerState<_GemShop> createState() => _GemShopState();
}

class _GemShopState extends ConsumerState<_GemShop> {
  // Tải giá một lần khi mở dialog (stub trả rỗng → mục IAP tự ẩn nút mua).
  late final Future<Map<IapProduct, String>> _prices =
      ref.read(iapServiceProvider).loadPrices();

  @override
  Widget build(BuildContext context) {
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final boostLevel =
        ref.watch(gameControllerProvider.select((s) => s.gemBoostLevel));
    final capLevel =
        ref.watch(gameControllerProvider.select((s) => s.offlineCapLevel));
    final controller = ref.read(gameControllerProvider.notifier);

    final adsRemoved =
        ref.watch(gameControllerProvider.select((s) => s.adsRemoved));
    final starterOwned =
        ref.watch(gameControllerProvider.select((s) => s.starterPackOwned));
    final doubleOwned =
        ref.watch(gameControllerProvider.select((s) => s.doubleIncomeOwned));

    final l10n = AppLocalizations.of(context)!;
    final boostPercent = (Balance.gemBoostPerLevel * 100).round();
    final capHours = Balance.offlineCapPerLevelSeconds ~/ 3600;

    return AlertDialog(
      title: Text(l10n.gemShopTitle(formatNumber(gems))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GemItem(
              name: l10n.gemBoostName,
              level: boostLevel,
              description: l10n.gemBoostDesc(boostPercent),
              cost: gemBoostCost(boostLevel),
              gems: gems,
              onBuy: controller.buyGemBoostUpgrade,
            ),
            _GemItem(
              name: l10n.offlineCapName,
              level: capLevel,
              description: l10n.offlineCapDesc(capHours),
              cost: offlineCapCost(capLevel),
              gems: gems,
              onBuy: controller.buyOfflineCapUpgrade,
            ),
            FutureBuilder<Map<IapProduct, String>>(
              future: _prices,
              builder: (context, snap) => _iapSectionBuilder(
                snap.data ?? const {},
                adsRemoved: adsRemoved,
                starterOwned: starterOwned,
                doubleOwned: doubleOwned,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  /// Phần "nạp bằng tiền thật" — chỉ hiện khi store trả về giá (mobile thật).
  Widget _iapSectionBuilder(
    Map<IapProduct, String> prices, {
    required bool adsRemoved,
    required bool starterOwned,
    required bool doubleOwned,
  }) {
    final iap = ref.read(iapServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    final products = [
      for (final p in IapProduct.values)
        // Heo đất có UI riêng ở dialog "Kiếm thêm" → không liệt kê ở đây.
        if (p != IapProduct.piggyBreak &&
            !(p == IapProduct.removeAds && adsRemoved) &&
            !(p == IapProduct.starterPack && starterOwned) &&
            !(p == IapProduct.doubleIncome && doubleOwned))
          p,
    ];
    if (prices.isEmpty || products.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.iapSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final p in products)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(iapTitle(l10n, p)),
            subtitle: Text(iapDescription(l10n, p)),
            trailing: FilledButton.tonal(
              key: Key('iap-buy-${p.id}'),
              onPressed: () => iap.buy(p),
              child: Text(prices[p] ?? '—'),
            ),
          ),
        TextButton(
          onPressed: () => iap.restore(),
          child: Text(l10n.restorePurchases),
        ),
      ],
    );
  }
}

class _GemItem extends StatelessWidget {
  const _GemItem({
    required this.name,
    required this.level,
    required this.description,
    required this.cost,
    required this.gems,
    required this.onBuy,
  });

  final String name;
  final int level;
  final String description;
  final int cost;
  final double gems;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final canAfford = gems >= cost;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.gemItemLevel(name, level),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            key: Key('gem-buy-$name'),
            onPressed: canAfford ? onBuy : null,
            child: Text(l10n.gemCost(cost)),
          ),
        ],
      ),
    );
  }
}
