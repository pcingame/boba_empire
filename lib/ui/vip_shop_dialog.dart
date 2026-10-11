/// Cửa hàng VIP: đổi Xu VIP (kiếm từ quà VIP theo kỳ) lấy phụ kiện độc quyền; mỗi món đòi một cấp
/// VIP tối thiểu. Mở từ màn Mốc nạp & VIP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../core/vip_shop.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';

Future<void> showVipShop(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _VipShopDialog(),
    );

class _VipShopDialog extends ConsumerWidget {
  const _VipShopDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final coins = ref.watch(gameControllerProvider.select((s) => s.vipCoins));
    final level = topupVipLevel(ref.watch(gameControllerProvider.select((s) => s.vipExp)));
    final owned = ref.watch(gameControllerProvider.select((s) => s.ownedLimited)).toSet();

    return AlertDialog(
      title: Text(l10n.vipShopTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.vipCoinsLabel(formatNumber(coins.toDouble())),
                  key: const Key('vip-shop-coins'),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(l10n.vipShopHint, style: theme.textTheme.bodySmall),
              const Divider(height: 20),
              for (final item in vipShopItems)
                _row(context, ref, l10n, item, level, coins, owned.contains(item.id)),
            ],
          ),
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

  Widget _row(BuildContext context, WidgetRef ref, AppLocalizations l10n, VipShopItem item,
      int level, int coins, bool owned) {
    final locked = level < item.minLevel;
    final affordable = coins >= item.price;
    return ListTile(
      key: Key('vip-shop-item-${item.id}'),
      contentPadding: EdgeInsets.zero,
      leading: Text(item.accessory.emoji, style: const TextStyle(fontSize: 30)),
      title: Text(accessoryName(l10n, item.id)),
      subtitle: Text(
        owned
            ? l10n.vipShopOwned
            : locked
                ? l10n.vipShopLocked(item.minLevel)
                : l10n.vipShopPrice(formatNumber(item.price.toDouble())),
      ),
      trailing: owned
          ? const Icon(Icons.check_circle, color: Colors.green)
          : FilledButton.tonal(
              key: Key('vip-shop-buy-${item.id}'),
              onPressed: locked || !affordable
                  ? null
                  : () {
                      final r = ref.read(gameControllerProvider.notifier).buyVipShopItem(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(r == VipShopResult.ok
                            ? l10n.vipShopBoughtSnack(accessoryName(l10n, item.id))
                            : l10n.vipShopNeedCoins),
                      ));
                    },
              child: Icon(locked ? Icons.lock : Icons.shopping_bag, size: 18),
            ),
    );
  }
}
