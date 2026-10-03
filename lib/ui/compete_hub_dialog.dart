/// Dialog nhỏ gộp 2 mục "cạnh tranh với người khác" (Đấu Trường + Bảng xếp
/// hạng) làm 1 điểm vào duy nhất ở thanh điều hướng chính — đỡ chật thanh
/// điều hướng, thay vì mỗi tính năng chiếm 1 icon riêng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../market/market_highlight.dart';
import 'accessory_inventory_page.dart';
import 'accessory_market_page.dart';
import 'arena_leaderboard_page.dart';
import 'arena_page.dart';
import 'leaderboard_page.dart';
import 'story_speedrun_page.dart';

Future<void> showCompeteHub(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _CompeteHubDialog(),
  );
}

class _CompeteHubDialog extends ConsumerWidget {
  const _CompeteHubDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newMarket = ref.watch(marketHighlightProvider).value != null;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.navCompete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sports_kabaddi),
            title: Text(l10n.navArena),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showArenaPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard),
            title: Text(l10n.leaderboardMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showLeaderboardPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text(l10n.storySpeedrunMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showStorySpeedrunPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.military_tech),
            title: Text(l10n.arenaLeaderboardMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showArenaLeaderboardPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text(l10n.accessoryMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showAccessoryInventory(context);
            },
          ),
          ListTile(
            key: const Key('compete-market-tile'),
            leading: const Icon(Icons.storefront),
            title: Text(l10n.marketTitle),
            trailing: newMarket
                ? const Badge(key: Key('compete-market-dot'))
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              showAccessoryMarket(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
