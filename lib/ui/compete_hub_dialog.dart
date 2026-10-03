/// Dialog nhỏ gộp 2 mục "cạnh tranh với người khác" (Đấu Trường + Bảng xếp
/// hạng) làm 1 điểm vào duy nhất ở thanh điều hướng chính — đỡ chật thanh
/// điều hướng, thay vì mỗi tính năng chiếm 1 icon riêng.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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

class _CompeteHubDialog extends StatelessWidget {
  const _CompeteHubDialog();

  @override
  Widget build(BuildContext context) {
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
