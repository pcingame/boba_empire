/// Dialog nhỏ gộp 2 mục "cạnh tranh với người khác" (Đấu Trường + Bảng xếp
/// hạng) làm 1 điểm vào duy nhất ở thanh điều hướng chính — đỡ chật thanh
/// điều hướng, thay vì mỗi tính năng chiếm 1 icon riêng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guild/guild_alert.dart';
import '../leaderboard/lb_rewards.dart';
import '../l10n/app_localizations.dart';
import 'email_gate.dart';
import 'arena_page.dart';
import 'guild_page.dart';
import 'lb_rewards_dialog.dart';
import 'leaderboards_hub_page.dart';
import 'widgets/phone_width.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      // Hộp rộng hơn mặc định (lề 40dp mỗi bên): nhãn dài như "Weekly top rewards" từng chỉ còn ~126dp → bị cắt "…".
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(l10n.navCompete),
      // width: maxFinite — AlertDialog co theo nội dung (IntrinsicWidth) nên với hàng menu ngắn nó chỉ rộng 280dp dù
      // insetPadding cho phép hơn; ép rộng hết cỡ (kẹp ở bề ngang điện thoại trên iPad) để nhãn dài có chỗ.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kPhoneMaxWidth - 48), // + lề nội dung 2×24 = đúng bề ngang điện thoại
        child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 12,
            minLeadingWidth: 28,
            leading: const Icon(Icons.sports_kabaddi),
            title: Text(l10n.navArena),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              Navigator.of(context).pop();
              showArenaPage(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 12,
            minLeadingWidth: 28,
            key: const Key('compete-guild'),
            leading: const Icon(Icons.groups),
            title: Row(children: [
              Text(l10n.guildTitle),
              if (ref.watch(guildAlertProvider)) ...[
                const SizedBox(width: 8),
                Container(
                  key: const Key('compete-guild-dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              Navigator.of(context).pop();
              showGuildPage(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 12,
            minLeadingWidth: 28,
            key: const Key('compete-lb-rewards'),
            leading: const Icon(Icons.emoji_events),
            title: Row(children: [
              // Cho xuống 2 dòng thay vì cắt "…" (từng hiện "Weekly top rew…" ở bản tiếng Anh).
              Flexible(child: Text(l10n.lbrTitle, maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (ref.watch(lbRewardAlertProvider)) ...[
                const SizedBox(width: 8),
                Container(
                  key: const Key('compete-lb-rewards-dot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ]),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              showLbRewards(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            horizontalTitleGap: 12,
            minLeadingWidth: 28,
            key: const Key('compete-leaderboards'),
            leading: const Icon(Icons.leaderboard),
            title: Text(l10n.leaderboardMenuTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              Navigator.of(context).pop();
              showLeaderboardsHub(context);
            },
          ),
          ],
        ),
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
}
