import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/economy.dart';
import '../core/format.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../state/game_providers.dart';

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

    final boostPercent = (Balance.gemBoostPerLevel * 100).round();
    final capHours = Balance.offlineCapPerLevelSeconds ~/ 3600;

    return AlertDialog(
      title: Text('Cửa Hàng 💎 (có ${formatNumber(gems)})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GemItem(
              name: 'Tăng thu nhập',
              level: boostLevel,
              description: '+$boostPercent% thu nhập vĩnh viễn mỗi cấp',
              cost: gemBoostCost(boostLevel),
              gems: gems,
              onBuy: controller.buyGemBoostUpgrade,
            ),
            const Divider(),
            _GemItem(
              name: 'Kho lạnh offline',
              level: capLevel,
              description: '+$capHours giờ trần tiền offline mỗi cấp',
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
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  /// Phần "nạp bằng tiền thật" — chỉ hiện khi store trả về giá (mobile thật).
  Widget _iapSectionBuilder(
    Map<IapProduct, String> prices, {
    required bool adsRemoved,
    required bool starterOwned,
  }) {
    final iap = ref.read(iapServiceProvider);

    final products = [
      for (final p in IapProduct.values)
        if (!(p == IapProduct.removeAds && adsRemoved) &&
            !(p == IapProduct.starterPack && starterOwned))
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
            'Nạp bằng tiền thật',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final p in products)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.title),
            subtitle: Text(p.description),
            trailing: FilledButton.tonal(
              key: Key('iap-buy-${p.id}'),
              onPressed: () => iap.buy(p),
              child: Text(prices[p] ?? '—'),
            ),
          ),
        TextButton(
          onPressed: () => iap.restore(),
          child: const Text('Khôi phục giao dịch'),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$name  Lv.$level'),
      subtitle: Text(description),
      trailing: FilledButton(
        key: Key('gem-buy-$name'),
        onPressed: canAfford ? onBuy : null,
        child: Text('$cost 💎'),
      ),
    );
  }
}
