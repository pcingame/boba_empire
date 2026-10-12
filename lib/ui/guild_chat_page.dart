/// Chat hội: tin ghim (thông báo của chủ hội) + các tin gần nhất. Không realtime —
/// tự tải lại mỗi 15 giây khi đang mở và ngay sau khi gửi/xoá/ghim.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild.dart' show guildReactionEmojis;
import '../guild/guild_chat_unread.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'guild_page.dart' show guildFailureText;
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildChat(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const GuildChatPage()));

// Riverpod 3 tự thử lại provider lỗi → tắt, để lỗi hiện ngay.
final guildChatProvider = FutureProvider.autoDispose<GuildChat>(
    (ref) => ref.read(guildRepositoryProvider).chat(),
    retry: (_, _) => null);

class GuildChatPage extends ConsumerStatefulWidget {
  const GuildChatPage({super.key});

  @override
  ConsumerState<GuildChatPage> createState() => _GuildChatPageState();
}

class _GuildChatPageState extends ConsumerState<GuildChatPage> {
  final _input = TextEditingController();
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 15), (_) => ref.invalidate(guildChatProvider));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(Future<GuildOutcome> action,
      {String Function(AppLocalizations)? okText}) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await action;
    if (!mounted) return;
    if (!out.ok || okText != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(out.ok ? okText!(l10n) : guildFailureText(l10n, out.failure!))));
    }
    ref.invalidate(guildChatProvider);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final out = await ref.read(guildControllerProvider.notifier).chatPost(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (out.ok) _input.clear();
    // Lỗi (nhanh quá/từ cấm) giữ nguyên chữ để người dùng sửa.
    await _run(Future.value(out));
  }

  Future<void> _react(GuildMessage m, String emoji) =>
      _run(ref.read(guildControllerProvider.notifier).chatReact(m.id, emoji));

  Future<void> _menu(GuildMessage m, bool isOwner, bool pinned) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = ref.read(guildControllerProvider.notifier);
    final mine = m.userId == ref.read(guildRepositoryProvider).myUserId;
    // Chủ hội và phó hội xoá được tin của người khác (ghim chỉ chủ hội).
    final v = ref.read(guildControllerProvider);
    final canDelete = v is GuildMine && v.canModerate;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                for (final e in guildReactionEmojis)
                  IconButton(
                    key: Key('guild-chat-pick-$e'),
                    tooltip: e,
                    isSelected: m.reactions.any((r) => r.emoji == e && r.mine),
                    onPressed: () => Navigator.pop(context, 'react:$e'),
                    icon: Text(e, style: const TextStyle(fontSize: 26)),
                  ),
              ],
            ),
          ),
          if (!mine)
            ListTile(
              key: const Key('guild-chat-report'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.guildChatReport),
              onTap: () => Navigator.pop(context, 'report'),
            ),
          if (isOwner)
            ListTile(
              key: const Key('guild-chat-pin'),
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(pinned ? l10n.guildChatUnpin : l10n.guildChatPin),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
          if (mine || canDelete)
            ListTile(
              key: const Key('guild-chat-delete'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.guildChatDelete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice.startsWith('react:')) await _react(m, choice.substring(6));
    if (choice == 'pin') await _run(ctrl.chatPin(pinned ? null : m.id));
    if (choice == 'delete') await _run(ctrl.chatDelete(m.id));
    if (choice == 'report') {
      await _run(ctrl.chatReport(m.id), okText: (l) => l.guildChatReported);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(guildControllerProvider);
    final isOwner = view is GuildMine && view.isOwner;
    final chat = ref.watch(guildChatProvider);
    // Đã mở/tải chat = đã đọc tới tin mới nhất trong danh sách.
    ref.listen(guildChatProvider, (_, next) {
      final latest = next.asData?.value.messages.firstOrNull?.id;
      if (latest != null && view is GuildMine) {
        ref.read(guildChatSeenProvider.notifier).markSeen(view.guild.id, latest);
      }
    });
    final myId = ref.read(guildRepositoryProvider).myUserId;
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildChatTitle)),
        body: Column(
          children: [
            Expanded(
              child: switch (chat) {
                // Giữ nội dung cũ khi tải lại (tránh nháy mỗi 15 giây).
                AsyncValue(hasValue: true, :final value?) => _List(
                    chat: value,
                    myId: myId,
                    isOwner: isOwner,
                    onLongPress: _menu,
                    onReact: _react,
                  ),
                AsyncError() => Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(guildChatProvider),
                      child: Text(l10n.guildErrNetwork),
                    ),
                  ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('guild-chat-input'),
                        controller: _input,
                        maxLength: 200,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: l10n.guildChatHint,
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('guild-chat-send'),
                      tooltip: l10n.guildChatSend,
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.chat,
    required this.myId,
    required this.isOwner,
    required this.onLongPress,
    required this.onReact,
  });

  final GuildChat chat;
  final String? myId;
  final bool isOwner;
  final Future<void> Function(GuildMessage, bool isOwner, bool pinned) onLongPress;
  final Future<void> Function(GuildMessage, String emoji) onReact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pinned = chat.pinned;
    return Column(
      children: [
        if (pinned != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: GestureDetector(
              onLongPress: () => onLongPress(pinned, isOwner, true),
              child: ClayTile(
                key: const Key('guild-chat-pinned'),
                child: Row(
                  children: [
                    const Text('📌', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.guildChatPinned,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.primary)),
                          Text(pinned.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: chat.messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.guildChatEmpty, textAlign: TextAlign.center),
                  ),
                )
              // Mới nhất ở đầu danh sách → reverse để nó nằm sát ô nhập.
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: chat.messages.length,
                  itemBuilder: (_, i) {
                    final m = chat.messages[i];
                    final mine = m.userId == myId;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () =>
                            onLongPress(m, isOwner, m.id == pinned?.id),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                          child: _Bubble(
                            message: m,
                            mine: mine,
                            theme: theme,
                            onReact: onReact,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Một bong bóng tin nhắn. Tin của VIP từ cấp [vipTitleMinLevel] có nền pha màu + viền theo
/// cấp (8+ có thêm quầng sáng); tin của chính mình theo cấp VIP cục bộ.
class _Bubble extends ConsumerWidget {
  const _Bubble(
      {required this.message, required this.mine, required this.theme, required this.onReact});

  final GuildMessage message;
  final bool mine;
  final ThemeData theme;
  final Future<void> Function(GuildMessage, String emoji) onReact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final level = mine
        ? topupVipLevel(ref.watch(gameControllerProvider.select((s) => s.vipExp)))
        : (ref.watch(vipLevelProvider.select((v) => v[m.userId])) ?? 0);
    final vip = level >= vipTitleMinLevel ? vipFrameDecoration(level) : null;
    final base = mine
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    return Container(
      key: Key('guild-chat-msg-${m.id}'),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: vip == null
            ? base
            : Color.alphaBlend(
                vipTagColors[level.clamp(1, vipTagColors.length) - 1]
                    .first
                    .withValues(alpha: 0.2),
                base),
        borderRadius: BorderRadius.circular(12),
        border: vip?.border,
        boxShadow: vip?.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlairBadge(userId: m.userId),
                Flexible(
                  child: Text(m.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          Text(m.body),
          if (m.reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final r in m.reactions)
                    InkWell(
                      key: Key('guild-chat-chip-${m.id}-${r.emoji}'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onReact(m, r.emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: r.mine
                              ? theme.colorScheme.primary.withValues(alpha: 0.18)
                              : theme.colorScheme.surface.withValues(alpha: 0.6),
                          border: Border.all(
                            color: r.mine ? theme.colorScheme.primary : Colors.transparent,
                          ),
                        ),
                        child: Text('${r.emoji} ${r.count}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
