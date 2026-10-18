/// Một màn duy nhất liệt kê MỌI bảng xếp hạng (trước đây rải ở hub Thi đấu, Trò chơi, Thẻ Mùa, Kho...). Mỗi dòng mở
/// đúng trang bảng cũ — các trang đó và lối vào trong từng tính năng giữ nguyên.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'accessory_leaderboard_page.dart';
import 'arena_leaderboard_page.dart';
import 'email_gate.dart';
import 'leaderboard_page.dart';
import 'm3_leaderboard_page.dart';
import 'recipe_leaderboard_page.dart';
import 'season_leaderboard_page.dart';
import 'story_speedrun_page.dart';
import 'vip_leaderboard_page.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showLeaderboardsHub(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardsHubPage()));

class LeaderboardsHubPage extends StatelessWidget {
  const LeaderboardsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Tính năng online → mỗi dòng qua cổng liên kết email (xem email_gate.dart) rồi mở đúng trang bảng.
    Widget tile(String id, IconData icon, String title, void Function() open) => ClayTile(
          key: Key('lbh-$id'),
          onTap: () async {
            if (!await ensureOnlineLinked(context) || !context.mounted) return;
            open();
          },
          child: Row(children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.chevron_right),
          ]),
        );
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.leaderboardMenuTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            tile('income', Icons.leaderboard, l10n.profileBoardIncome, () => showLeaderboardPage(context)),
            tile('pearls', Icons.bubble_chart, l10n.m3LbTitle, () => showM3Leaderboard(context)),
            tile('collection', Icons.collections_bookmark, l10n.accessoryLbTitle, () => showAccessoryLeaderboard(context)),
            tile('recipes', Icons.local_cafe, l10n.rlbTitle, () => showRecipeLeaderboard(context)),
            tile('vip', Icons.workspace_premium, l10n.vipLbTitle, () => showVipLeaderboard(context)),
            tile('speedrun', Icons.timer, l10n.storySpeedrunMenuTitle, () => showStorySpeedrunPage(context)),
            tile('arena', Icons.military_tech, l10n.arenaLeaderboardMenuTitle, () => showArenaLeaderboardPage(context)),
            tile('season', Icons.card_giftcard, l10n.seasonLbTitle, () => showSeasonLeaderboard(context)),
          ],
        ),
      ),
    );
  }
}
