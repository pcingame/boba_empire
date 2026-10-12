/// Chat hội: tin ghim (thông báo của chủ hội) + các tin gần nhất. Không realtime —
/// tự tải lại mỗi 15 giây khi đang mở và ngay sau khi gửi/xoá/ghim.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild.dart' show guildReactionEmojis;
import '../guild/chat_optimistic.dart';
import '../guild/guild_chat_unread.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../guild/mentions.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'guild_page.dart' show guildFailureText;
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

/// Mở chat Hội; [prefill] điền sẵn vào ô nhập (vd "@Bob " khi chọn "Nhắc trong chat" ở danh sách thành viên).
Future<void> showGuildChat(BuildContext context, {String? prefill}) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => GuildChatPage(prefill: prefill)));

// Riverpod 3 tự thử lại provider lỗi → tắt, để lỗi hiện ngay.
final guildChatProvider = FutureProvider.autoDispose<GuildChat>(
    (ref) => ref.read(guildRepositoryProvider).chat(),
    retry: (_, _) => null);

/// Chat đã tải lần gần nhất của một hội: mở lại trang thì hiện ngay (không spinner) rồi tải mới ở nền.
class GuildChatCache extends Notifier<({String guildId, GuildChat chat})?> {
  @override
  ({String guildId, GuildChat chat})? build() => null;
  void put(String guildId, GuildChat chat) => state = (guildId: guildId, chat: chat);
}

final guildChatCacheProvider =
    NotifierProvider<GuildChatCache, ({String guildId, GuildChat chat})?>(GuildChatCache.new);

/// Tin đang gửi (chưa được server xác nhận) — hiện ngay ở cuối danh sách.
class _Pending {
  _Pending(this.id, this.body);
  final int id;
  final String body;
}

class GuildChatPage extends ConsumerStatefulWidget {
  const GuildChatPage({super.key, this.prefill});

  /// Chữ điền sẵn vào ô nhập (có thể null).
  final String? prefill;

  @override
  ConsumerState<GuildChatPage> createState() => _GuildChatPageState();
}

class _GuildChatPageState extends ConsumerState<GuildChatPage> with WidgetsBindingObserver {
  final _input = TextEditingController();
  Timer? _timer;
  bool _sending = false;
  final _pending = <_Pending>[];
  int _pendingSeq = 0;

  /// Reaction đã bấm nhưng server chưa xác nhận ("id|emoji") — hiện lạc quan trên danh sách.
  final _toggled = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
    final pre = widget.prefill;
    if (pre != null && pre.isNotEmpty) {
      _input.value = TextEditingValue(text: pre, selection: TextSelection.collapsed(offset: pre.length));
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => ref.invalidate(guildChatProvider));
  }

  /// Chạy nền thì dừng tải định kỳ (đỡ tốn pin/mạng); quay lại thì tải ngay rồi chạy tiếp.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
      ref.invalidate(guildChatProvider);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _input.dispose();
    super.dispose();
  }

  /// Tải lại và CHỜ xong (để bỏ lớp lạc quan đúng lúc dữ liệu thật đã có, không nháy).
  Future<void> _refetch() async {
    ref.invalidate(guildChatProvider);
    try {
      await ref.read(guildChatProvider.future);
    } catch (_) {}
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
    final p = _Pending(++_pendingSeq, text);
    // Hiện tin NGAY và xoá ô nhập; lỗi thì trả lại chữ để người dùng sửa.
    setState(() {
      _sending = true;
      _pending.add(p);
    });
    _input.clear();
    final out = await ref.read(guildControllerProvider.notifier).chatPost(text);
    if (!mounted) return;
    if (out.ok) await _refetch();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _pending.remove(p);
    });
    if (!out.ok) {
      if (_input.text.isEmpty) _input.text = text;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(guildFailureText(l10n, out.failure!))));
    }
  }

  /// Bật/tắt reaction: chip đổi NGAY, server xác nhận sau; lỗi thì chip trở lại và báo.
  Future<void> _react(GuildMessage m, String emoji) async {
    final k = '${m.id}|$emoji';
    if (!_toggled.add(k)) return; // đang chờ server cho đúng reaction này
    setState(() {});
    final out = await ref.read(guildControllerProvider.notifier).chatReact(m.id, emoji);
    if (!mounted) return;
    if (out.ok) await _refetch();
    if (!mounted) return;
    setState(() => _toggled.remove(k));
    if (!out.ok) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(guildFailureText(l10n, out.failure!))));
    }
  }

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
    // Đã mở/tải chat = đã đọc tới tin mới nhất trong danh sách; đồng thời nhớ lại để mở lần sau hiện ngay.
    ref.listen(guildChatProvider, (_, next) {
      final value = next.asData?.value;
      if (value == null || view is! GuildMine) return;
      final latest = value.messages.firstOrNull?.id;
      if (latest != null) {
        ref.read(guildChatSeenProvider.notifier).markSeen(view.guild.id, latest);
      }
      ref.read(guildChatCacheProvider.notifier).put(view.guild.id, value);
    });
    final myId = ref.read(guildRepositoryProvider).myUserId;
    // Danh sách biệt danh thành viên để nhận ra/gợi ý @tên; biệt danh của mình để biết tin nào nhắc mình.
    final members = view is GuildMine ? view.guild.members : const <GuildMemberInfo>[];
    final names = [for (final m in members) m.nickname];
    final myNick = members.where((m) => m.userId == myId).map((m) => m.nickname).firstOrNull;
    final cached = ref.watch(guildChatCacheProvider);
    final cachedChat = view is GuildMine && cached != null && cached.guildId == view.guild.id
        ? cached.chat
        : null;
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildChatTitle)),
        body: Column(
          children: [
            Expanded(
              child: switch (chat) {
                // Giữ nội dung cũ khi tải lại (tránh nháy mỗi 15 giây).
                AsyncValue(hasValue: true, :final value?) => _List(
                    chat: GuildChat(
                        pinned: value.pinned,
                        messages: applyPendingToggles(value.messages, _toggled)),
                    pending: _pending,
                    names: names,
                    myNick: myNick,
                    myId: myId,
                    isOwner: isOwner,
                    onLongPress: _menu,
                    onReact: _react,
                  ),
                // Mở lại trang: hiện bản đã nhớ ngay trong lúc tải mới (không spinner trắng).
                AsyncLoading() when cachedChat != null => _List(
                    chat: cachedChat,
                    pending: _pending,
                    names: names,
                    myNick: myNick,
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
            _MentionSuggestions(controller: _input, names: names, myNick: myNick),
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
    required this.pending,
    required this.names,
    required this.myNick,
    required this.myId,
    required this.isOwner,
    required this.onLongPress,
    required this.onReact,
  });

  final GuildChat chat;
  final List<_Pending> pending;
  final List<String> names;
  final String? myNick;
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
          child: chat.messages.isEmpty && pending.isEmpty
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
                  itemCount: pending.length + chat.messages.length,
                  itemBuilder: (_, i) {
                    // Đáy danh sách (index 0) = tin đang gửi mới nhất, rồi tới tin thật mới nhất.
                    if (i < pending.length) {
                      final p = pending[pending.length - 1 - i];
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Opacity(
                          key: Key('guild-chat-pending-${p.id}'),
                          opacity: 0.6,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            constraints:
                                BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(p.body),
                          ),
                        ),
                      );
                    }
                    final m = chat.messages[i - pending.length];
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
                            names: names,
                            myNick: myNick,
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
  const _Bubble({
    required this.message,
    required this.mine,
    required this.theme,
    required this.onReact,
    required this.names,
    required this.myNick,
  });

  final GuildMessage message;
  final bool mine;
  final ThemeData theme;
  final List<String> names;
  final String? myNick;
  final Future<void> Function(GuildMessage, String emoji) onReact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final level = mine
        ? topupVipLevel(ref.watch(gameControllerProvider.select((s) => s.vipExp)))
        : (ref.watch(vipLevelProvider.select((v) => v[m.userId])) ?? 0);
    final vip = level >= vipTitleMinLevel ? vipFrameDecoration(level) : null;
    // Tin nhắc MÌNH (của người khác): viền nhấn + biểu tượng @ để dễ thấy.
    final mentionsMe = !mine && myNick != null && mentionsNickname(m.body, myNick!, names);
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
        border: vip?.border ?? (mentionsMe ? Border.all(color: theme.colorScheme.tertiary, width: 1.5) : null),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mentionsMe)
                Padding(
                  padding: const EdgeInsets.only(right: 4, top: 2),
                  child: Icon(Icons.alternate_email,
                      key: Key('guild-chat-mention-me-${m.id}'),
                      size: 14,
                      color: theme.colorScheme.tertiary),
                ),
              Flexible(child: _MentionText(body: m.body, names: names, myNick: myNick, theme: theme)),
            ],
          ),
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

/// Nội dung tin có tô đậm các "@tên" khớp thành viên; "@tên" của chính mình còn có nền nhấn.
class _MentionText extends StatelessWidget {
  const _MentionText({required this.body, required this.names, required this.myNick, required this.theme});
  final String body;
  final List<String> names;
  final String? myNick;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final spans = findMentions(body, names);
    if (spans.isEmpty) return Text(body);
    final children = <InlineSpan>[];
    var at = 0;
    for (final m in spans) {
      if (m.start > at) children.add(TextSpan(text: body.substring(at, m.start)));
      final me = myNick != null && m.nickname.toLowerCase() == myNick!.toLowerCase();
      children.add(TextSpan(
        text: body.substring(m.start, m.end),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.primary,
          backgroundColor: me ? theme.colorScheme.tertiaryContainer : null,
        ),
      ));
      at = m.end;
    }
    if (at < body.length) children.add(TextSpan(text: body.substring(at)));
    return Text.rich(TextSpan(children: children), key: const Key('guild-chat-mention-text'));
  }
}

/// Dải gợi ý khi đang gõ "@…" trong ô nhập: chạm một tên để chèn "@tên ".
class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({required this.controller, required this.names, required this.myNick});
  final TextEditingController controller;
  final List<String> names;
  final String? myNick;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final cursor = value.selection.isValid ? value.selection.baseOffset : value.text.length;
        final q = activeMentionQuery(value.text, cursor);
        if (q == null) return const SizedBox.shrink();
        final list = mentionSuggestions(q, names, exclude: myNick);
        if (list.isEmpty) return const SizedBox.shrink();
        return Container(
          key: const Key('guild-mention-suggestions'),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final n in list)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      key: Key('guild-mention-pick-$n'),
                      label: Text('@$n', maxLines: 1, overflow: TextOverflow.ellipsis),
                      onPressed: () {
                        final (t, c) = insertMention(value.text, cursor, n);
                        controller.value =
                            TextEditingValue(text: t, selection: TextSelection.collapsed(offset: c));
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
