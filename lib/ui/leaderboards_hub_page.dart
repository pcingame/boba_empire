/// Một màn duy nhất liệt kê MỌI bảng xếp hạng (trước đây rải ở hub Thi đấu, Trò chơi, Thẻ Mùa, Kho...). Mỗi dòng mở
/// đúng trang bảng cũ — các trang đó và lối vào trong từng tính năng giữ nguyên.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'accessory_leaderboard_page.dart';
import 'arena_leaderboard_page.dart';
import 'branch_leaderboard_page.dart';
import 'email_gate.dart';
import 'leaderboard_page.dart';
import 'm3_leaderboard_page.dart';
import 'recipe_leaderboard_page.dart';
import 'season_leaderboard_page.dart';
import 'story_speedrun_page.dart';
import 'vip_leaderboard_page.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';
import 'widgets/stagger_in.dart';

Future<void> showLeaderboardsHub(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardsHubPage()));

class LeaderboardsHubPage extends StatelessWidget {
  const LeaderboardsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Tính năng online → mỗi dòng qua cổng liên kết email (xem email_gate.dart) rồi mở đúng trang bảng.
    var n = 0;
    Widget tile(String id, IconData icon, String title, void Function() open, Color color) => StaggerIn(
          index: n++,
          child: ClayTile(
          key: Key('lbh-$id'),
          onTap: () async {
            if (!await ensureOnlineLinked(context) || !context.mounted) return;
            open();
          },
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.75)],
                ),
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.chevron_right),
          ]),
        ));
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.leaderboardMenuTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            tile('income', Icons.leaderboard, l10n.profileBoardIncome, () => showLeaderboardPage(context), const Color(0xFF42A5F5)),
            tile('pearls', Icons.bubble_chart, l10n.m3LbTitle, () => showM3Leaderboard(context), const Color(0xFFAB47BC)),
            tile('collection', Icons.collections_bookmark, l10n.accessoryLbTitle, () => showAccessoryLeaderboard(context), const Color(0xFFFF7043)),
            tile('recipes', Icons.local_cafe, l10n.rlbTitle, () => showRecipeLeaderboard(context), const Color(0xFF8D6E63)),
            tile('vip', Icons.workspace_premium, l10n.vipLbTitle, () => showVipLeaderboard(context), const Color(0xFFFFB300)),
            tile('speedrun', Icons.timer, l10n.storySpeedrunMenuTitle, () => showStorySpeedrunPage(context), const Color(0xFF26A69A)),
            tile('arena', Icons.military_tech, l10n.arenaLeaderboardMenuTitle, () => showArenaLeaderboardPage(context), const Color(0xFFEF5350)),
            tile('season', Icons.card_giftcard, l10n.seasonLbTitle, () => showSeasonLeaderboard(context), const Color(0xFFEC407A)),
            tile('branches', Icons.public, l10n.branchLbTitle, () => showBranchLeaderboard(context), const Color(0xFF26C6DA)),
          ],
        ),
      ),
    );
  }
}
