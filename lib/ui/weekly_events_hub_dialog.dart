/// Sự kiện tuần: một điểm vào cho Boss Thế Giới và Đấu giá cuối tuần (cả hai online, làm mới theo tuần).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../world_boss/world_boss.dart' show worldBossAlertProvider;
import 'auction_dialog.dart';
import 'widgets/app_dialog.dart';
import 'world_boss_page.dart';

Future<void> showWeeklyEventsHub(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _WeeklyEventsHubDialog());

class _WeeklyEventsHubDialog extends ConsumerWidget {
  const _WeeklyEventsHubDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bossAlert = (ref.watch(worldBossAlertProvider).value ?? 0) > 0;
    return AlertDialog(
      title: Text(l10n.weeklyEventsTitle),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
          key: const Key('weekly-world-boss'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.whatshot),
          title: Row(children: [
            Flexible(child: Text(l10n.worldBossTitle, maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (bossAlert) ...[
              const SizedBox(width: 8),
              Container(
                key: const Key('weekly-world-boss-dot'),
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
              ),
            ],
          ]),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final nav = Navigator.of(context)..pop();
            showWorldBoss(nav.context);
          },
        ),
        ListTile(
          key: const Key('weekly-auction'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.gavel),
          title: Text(l10n.auctionTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final nav = Navigator.of(context)..pop();
            showAuction(nav.context);
          },
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
