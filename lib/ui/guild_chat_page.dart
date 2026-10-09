/// Chat hội: tin ghim (thông báo của chủ hội) + các tin gần nhất. Không realtime —
/// tự tải lại mỗi 15 giây khi đang mở và ngay sau khi gửi/xoá/ghim.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
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

  Future<void> _run(Future<GuildOutcome> action) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await action;
    if (!mounted) return;
    if (!out.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(guildFailureText(l10n, out.failure!))));
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

  Future<void> _menu(GuildMessage m, bool isOwner, bool pinned) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = ref.read(guildControllerProvider.notifier);
    final mine = m.userId == ref.read(guildRepositoryProvider).myUserId;
    if (!mine && !isOwner) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (isOwner)
            ListTile(
              key: const Key('guild-chat-pin'),
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(pinned ? l10n.guildChatUnpin : l10n.guildChatPin),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
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
    if (choice == 'pin') await _run(ctrl.chatPin(pinned ? null : m.id));
    if (choice == 'delete') await _run(ctrl.chatDelete(m.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(guildControllerProvider);
    final isOwner = view is GuildMine && view.guild.ownerId == ref.read(guildRepositoryProvider).myUserId;
    final chat = ref.watch(guildChatProvider);
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
  });

  final GuildChat chat;
  final String? myId;
  final bool isOwner;
  final Future<void> Function(GuildMessage, bool isOwner, bool pinned) onLongPress;

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
                          child: Container(
                            key: Key('guild-chat-msg-${m.id}'),
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: mine
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(m.nickname,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontWeight: FontWeight.w700)),
                                Text(m.body),
                              ],
                            ),
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
