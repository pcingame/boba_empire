/// Cộng đồng: một điểm vào cho Hội và Bạn bè (trước đây Hội là chip riêng, Bạn bè chôn trong Cài đặt).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../friends/friends.dart' show friendsAlertProvider;
import '../guild/guild_alert.dart';
import '../l10n/app_localizations.dart';
import 'email_gate.dart';
import 'friends_page.dart';
import 'guild_page.dart';
import 'widgets/app_dialog.dart';

Future<void> showCommunityHub(BuildContext context) => showAppDialog<void>(
      context: context,
      builder: (_) => const _CommunityHubDialog(),
    );

class _CommunityHubDialog extends ConsumerWidget {
  const _CommunityHubDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final guildAlert = ref.watch(guildAlertProvider);
    final friends = ref.watch(friendsAlertProvider).value ?? 0;
    return AlertDialog(
      title: Text(l10n.communityTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const Key('community-guild'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups),
            title: Text(l10n.guildTitle),
            trailing: guildAlert
                ? Container(
                    key: const Key('community-guild-dot'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              Navigator.of(context).pop();
              showGuildPage(context);
            },
          ),
          ListTile(
            key: const Key('community-friends'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.group_outlined),
            title: Text(l10n.friendsTitle),
            trailing: friends > 0
                ? Badge(key: const Key('community-friends-badge'), label: Text('$friends'))
                : const Icon(Icons.chevron_right),
            onTap: () {
              // showFriends tự kiểm cổng liên kết email; dùng context của Navigator vì hộp này sắp bị gỡ.
              final nav = Navigator.of(context)..pop();
              showFriends(nav.context);
            },
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
