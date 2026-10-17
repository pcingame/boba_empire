/// Thẻ "Món của ngày" ở Cửa hàng 💎: một phụ kiện đích danh, mua bằng 💎, một lần/ngày (UTC).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/daily.dart' show dayIndex;
import '../core/daily_item.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';

class DailyItemCard extends ConsumerWidget {
  const DailyItemCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final now = ref.read(clockProvider)();
    final today = dayIndex(now);
    final bought = ref.watch(gameControllerProvider.select((s) => s.dailyItemDay)) == today;
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    // Theo dõi số món đang có: món của ngày đổi khi mình vừa nhận món đó từ nguồn khác.
    ref.watch(gameControllerProvider.select((s) => s.ownedAccessories.length));
    final owned = ref.read(gameControllerProvider).ownedAccessories.toSet();
    final item = dailyItemFor(today, owned);
    final price = dailyItemPrice(item.rarity);
    final have = owned.contains(item.id);

    return ClayTile(
      key: const Key('daily-item'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l10n.dailyItemTitle,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(accessoryName(l10n, item.id),
                    key: const Key('daily-item-name'),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ),
            RarityChip(rarity: item.rarity, label: accessoryRarityLabel(l10n, item.rarity)),
          ]),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(bought ? l10n.dealClaimed : (have ? l10n.dailyItemOwned : l10n.dailyItemNew),
                  key: const Key('daily-item-status'), style: theme.textTheme.bodySmall),
              FilledButton.tonal(
                key: const Key('daily-item-buy'),
                onPressed: bought || gems < price
                    ? null
                    : () {
                        final drop = ref.read(gameControllerProvider.notifier).buyDailyItem();
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(SnackBar(
                              content: Text(drop == null
                                  ? l10n.dealUnavailable
                                  : l10n.dealGotAccessory(accessoryName(l10n, drop.accessory.id)))));
                      },
                child: Text('$price 💎'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
