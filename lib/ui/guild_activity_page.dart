/// Nhật ký hoạt động hội: vào/rời, kick, bổ nhiệm/bãi nhiệm phó hội, nhường chức chủ.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildActivity(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const GuildActivityPage()));

// Riverpod 3 tự thử lại provider lỗi → tắt, để lỗi hiện ngay.
final guildActivityProvider = FutureProvider.autoDispose<List<GuildEvent>>(
    (ref) => ref.read(guildRepositoryProvider).activity(),
    retry: (_, _) => null);

String guildEventText(AppLocalizations l10n, GuildEvent e) {
  final t = e.target ?? '';
  return switch (e.kind) {
    GuildEventKind.joined => l10n.guildEvJoined(e.actor),
    GuildEventKind.left => l10n.guildEvLeft(e.actor),
    GuildEventKind.kicked => l10n.guildEvKicked(e.actor, t),
    GuildEventKind.promoted => l10n.guildEvPromoted(e.actor, t),
    GuildEventKind.demoted => l10n.guildEvDemoted(e.actor, t),
    GuildEventKind.transferred => l10n.guildEvTransferred(e.actor, t),
  };
}

String _icon(GuildEventKind k) => switch (k) {
      GuildEventKind.joined => '👋',
      GuildEventKind.left => '🚪',
      GuildEventKind.kicked => '🚫',
      GuildEventKind.promoted => '⭐',
      GuildEventKind.demoted => '⬇️',
      GuildEventKind.transferred => '👑',
    };

class GuildActivityPage extends ConsumerWidget {
  const GuildActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final events = ref.watch(guildActivityProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildActivityTitle)),
        body: switch (events) {
          AsyncData(:final value) when value.isEmpty => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.guildActivityEmpty, textAlign: TextAlign.center),
              ),
            ),
          AsyncData(:final value) => RefreshIndicator(
              onRefresh: () async => ref.refresh(guildActivityProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: value.length,
                itemBuilder: (_, i) => ClayTile(
                  key: Key('guild-event-$i'),
                  child: Row(
                    children: [
                      Text(_icon(value[i].kind), style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(guildEventText(l10n, value[i]))),
                    ],
                  ),
                ),
              ),
            ),
          AsyncError() => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(guildActivityProvider),
                child: Text(l10n.guildErrNetwork),
              ),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
