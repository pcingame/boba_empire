/// Hội (Guild): chưa có hội → danh sách hội công khai + tạo hội + nhập mã mời;
/// đã có hội → mục tiêu tuần, thưởng mốc, danh sách thành viên.
/// Cùng khuôn các trang xếp hạng khác (controller Notifier + trạng thái sealed).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/guild.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import 'guild_leaderboard_page.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildPage(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const GuildPage()));

/// Emoji chọn khi tạo hội (chip cố định: không cho nhập tự do để khỏi nhét chữ).
const guildEmojis = ['🧋', '🐉', '🦊', '🐼', '🔥', '⭐', '🌸', '👑'];

String guildFailureText(AppLocalizations l10n, GuildFailure f) => switch (f) {
      GuildFailure.nameTaken => l10n.guildErrNameTaken,
      GuildFailure.guildFull => l10n.guildErrFull,
      GuildFailure.alreadyInGuild => l10n.guildErrAlready,
      GuildFailure.invalidName => l10n.guildErrInvalid,
      GuildFailure.notFound => l10n.guildErrNotFound,
      GuildFailure.notEnoughContribution => l10n.guildErrContribution,
      GuildFailure.notEnoughGems => l10n.guildErrGems(guildCreateCostGems),
      GuildFailure.approvalRequired => l10n.guildErrApproval,
      GuildFailure.requestsFull => l10n.guildErrRequestsFull,
      GuildFailure.network => l10n.guildErrNetwork,
    };

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));

class GuildPage extends ConsumerStatefulWidget {
  const GuildPage({super.key});

  @override
  ConsumerState<GuildPage> createState() => _GuildPageState();
}

class _GuildPageState extends ConsumerState<GuildPage> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(guildControllerProvider.notifier).refresh());
    }
    final view = ref.watch(guildControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.guildTitle),
          actions: [
            IconButton(
              key: const Key('guild-leaderboard-button'),
              tooltip: l10n.guildLbTitle,
              icon: const Icon(Icons.leaderboard),
              onPressed: () => showGuildLeaderboard(context),
            ),
          ],
        ),
        body: switch (view) {
          GuildLoading() => const Center(child: CircularProgressIndicator()),
          GuildNone() => _NoGuild(view: view),
          GuildMine() => _MyGuildView(view: view),
          GuildError() => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.guildErrNetwork, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(guildControllerProvider.notifier).refresh(),
                      child: Text(l10n.leaderboardRetry),
                    ),
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }
}

// --- Chưa có hội -------------------------------------------------------------

class _NoGuild extends ConsumerWidget {
  const _NoGuild({required this.view});
  final GuildNone view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(guildControllerProvider.notifier).refresh(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(l10n.guildIntro, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('guild-create-button'),
            onPressed: () => _showCreateDialog(context, ref),
            child: Text(l10n.guildCreate),
          ),
          const SizedBox(height: 12),
          if (view.listing.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.guildEmpty, textAlign: TextAlign.center),
            ),
          for (final g in view.listing)
            ClayTile(
              child: Row(
                children: [
                  Text(g.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  // Tên dài phải co lại, không đẩy nút ra khỏi hàng.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g.requiresApproval ? '🔒 ' : ''}[${g.tag}] ${g.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${l10n.guildMembersCount(g.memberCount, guildMaxMembers)}'
                          ' · ${l10n.guildPoints(g.weekTotal)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('guild-menu-${g.id}'),
                    icon: const Icon(Icons.more_vert),
                    onSelected: (_) => _report(context, ref, g.id),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'report', child: Text(l10n.guildReport)),
                    ],
                  ),
                  Flexible(
                    child: g.requested
                        // Đã xin: bấm để HỦY yêu cầu.
                        ? OutlinedButton(
                            key: Key('guild-cancel-request-${g.id}'),
                            onPressed: () => _cancelRequest(context, ref),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.guildRequestPending)),
                          )
                        : FilledButton(
                            key: Key('guild-join-${g.id}'),
                            onPressed: () => _joinOrRequest(context, ref, g),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(g.requiresApproval
                                    ? l10n.guildRequestJoin
                                    : l10n.guildJoin)),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Hội thường: vào ngay. Hội cần duyệt: gửi yêu cầu, chờ chủ hội.
  Future<void> _joinOrRequest(
      BuildContext context, WidgetRef ref, GuildSummary g) async {
    final l10n = AppLocalizations.of(context)!;
    final nick = await _askNickname(context, ref);
    if (nick == null || !context.mounted) return;
    final ctrl = ref.read(guildControllerProvider.notifier);
    final out = g.requiresApproval
        ? await ctrl.requestJoin(guildId: g.id, nickname: nick)
        : await ctrl.join(guildId: g.id, nickname: nick);
    if (!context.mounted) return;
    if (!out.ok) {
      _toast(context, guildFailureText(l10n, out.failure!));
    } else if (g.requiresApproval) {
      _toast(context, l10n.guildRequestSent);
    }
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref) async {
    final out = await ref.read(guildControllerProvider.notifier).cancelRequest();
    if (!context.mounted || out.ok) return;
    _toast(context, guildFailureText(AppLocalizations.of(context)!, out.failure!));
  }

  Future<void> _report(BuildContext context, WidgetRef ref, String id) async {
    final l10n = AppLocalizations.of(context)!;
    final out =
        await ref.read(guildControllerProvider.notifier).report(id, 'report');
    if (!context.mounted) return;
    _toast(context,
        out.ok ? l10n.guildReportSent : guildFailureText(l10n, out.failure!));
  }
}

/// Hỏi tên hiển thị (điền sẵn tên đã đặt ở bảng xếp hạng). Null nếu huỷ/rỗng.
Future<String?> _askNickname(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final ctrl = TextEditingController(
      text: ref.read(guildRepositoryProvider).cachedNickname ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: TextField(
        key: const Key('guild-nickname-field'),
        controller: ctrl,
        maxLength: 20,
        decoration: InputDecoration(labelText: l10n.leaderboardNicknameHint),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('guild-nickname-ok'),
          onPressed: () {
            final n = ctrl.text.trim();
            Navigator.pop(ctx, n.isEmpty ? null : n);
          },
          child: Text(l10n.guildJoin),
        ),
      ],
    ),
  );
}

Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final name = TextEditingController();
  final tag = TextEditingController();
  final nick = TextEditingController(
      text: ref.read(guildRepositoryProvider).cachedNickname ?? '');
  var emoji = guildEmojis.first;
  var requiresApproval = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.guildCreate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.guildCreateCost(guildCreateCostGems),
                  key: const Key('guild-create-cost')),
              TextField(
                key: const Key('guild-name-field'),
                controller: name,
                maxLength: 20,
                decoration: InputDecoration(labelText: l10n.guildNameLabel),
              ),
              TextField(
                key: const Key('guild-tag-field'),
                controller: tag,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.guildTagLabel),
              ),
              TextField(
                key: const Key('guild-create-nickname-field'),
                controller: nick,
                maxLength: 20,
                decoration:
                    InputDecoration(labelText: l10n.leaderboardNicknameHint),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final e in guildEmojis)
                    ChoiceChip(
                      key: Key('guild-emoji-$e'),
                      label: Text(e, style: const TextStyle(fontSize: 20)),
                      selected: emoji == e,
                      onSelected: (_) => setState(() => emoji = e),
                    ),
                ],
              ),
              SwitchListTile(
                key: const Key('guild-approval-switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.guildApprovalSwitch),
                value: requiresApproval,
                onChanged: (v) => setState(() => requiresApproval = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('guild-create-ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.guildCreate),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final n = name.text.trim();
  final t = tag.text.trim();
  final nk = nick.text.trim();
  // Chặn sớm ca rõ ràng sai (đỡ một vòng mạng); server vẫn là nơi quyết định.
  if (n.length < 3 || !RegExp(r'^[A-Za-z0-9]{2,4}$').hasMatch(t) || nk.isEmpty) {
    _toast(context, l10n.guildErrInvalid);
    return;
  }
  final out = await ref.read(guildControllerProvider.notifier).create(
        name: n,
        tag: t,
        emoji: emoji,
        requiresApproval: requiresApproval,
        nickname: nk,
      );
  if (!context.mounted || out.ok) return;
  _toast(context, guildFailureText(l10n, out.failure!));
}

// --- Đang ở hội ---------------------------------------------------------------

class _MyGuildView extends ConsumerWidget {
  const _MyGuildView({required this.view});
  final GuildMine view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final g = view.guild;
    final top = guildMilestones.last.threshold;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(guildControllerProvider.notifier).refresh(silent: true),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ClayTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '${g.requiresApproval ? '🔒 ' : ''}[${g.tag}] ${g.name}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(l10n.guildMembersCount(g.members.length, guildMaxMembers),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.guildGoalTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              key: const Key('guild-progress'),
              value: (g.total / top).clamp(0.0, 1.0).toDouble(),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
              '${l10n.guildWeekTotal(g.total)} · '
              '${l10n.guildYourPoints(view.myPoints)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          for (var i = 0; i < guildMilestones.length; i++)
            _MilestoneRow(index: i, view: view),
          const SizedBox(height: 8),
          if (view.isOwner && g.requests.isNotEmpty) ...[
            Text(l10n.guildRequestsTitle(g.requests.length),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final r in g.requests)
              ClayTile(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(r.nickname,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      key: Key('guild-accept-${r.userId}'),
                      tooltip: l10n.guildAccept,
                      icon: const Icon(Icons.check_circle, size: 24),
                      onPressed: () => _respond(context, ref, r.userId, true),
                    ),
                    IconButton(
                      key: Key('guild-reject-${r.userId}'),
                      tooltip: l10n.guildReject,
                      icon: const Icon(Icons.cancel, size: 24),
                      onPressed: () => _respond(context, ref, r.userId, false),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          for (final m in g.members)
            ClayTile(
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (m.userId == g.ownerId) const Text('👑 '),
                        Flexible(
                          child: Text(m.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: m.userId == view.myUserId
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.guildPoints(m.points),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (view.isOwner && m.userId != view.myUserId)
                    IconButton(
                      key: Key('guild-kick-${m.userId}'),
                      tooltip: l10n.guildKick,
                      icon: const Icon(Icons.person_remove, size: 20),
                      onPressed: () => _kick(context, ref, m),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('guild-leave-button'),
            onPressed: () => _leave(context, ref),
            child: Text(l10n.guildLeave),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(
      BuildContext context, WidgetRef ref, String userId, bool accept) async {
    final out = await ref
        .read(guildControllerProvider.notifier)
        .respond(userId, accept: accept);
    if (!context.mounted || out.ok) return;
    _toast(context, guildFailureText(AppLocalizations.of(context)!, out.failure!));
  }

  Future<void> _kick(
      BuildContext context, WidgetRef ref, GuildMemberInfo m) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(
        context, l10n.guildKickConfirm(m.nickname), l10n.guildKick);
    if (!ok || !context.mounted) return;
    final out = await ref.read(guildControllerProvider.notifier).kick(m.userId);
    if (!context.mounted || out.ok) return;
    _toast(context, guildFailureText(l10n, out.failure!));
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await _confirm(context, l10n.guildLeaveConfirm, l10n.guildLeave);
    if (!ok || !context.mounted) return;
    final out = await ref.read(guildControllerProvider.notifier).leave();
    if (!context.mounted || out.ok) return;
    _toast(context, guildFailureText(l10n, out.failure!));
  }
}

Future<bool> _confirm(BuildContext context, String text, String action) async {
  final l10n = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(text),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            FilledButton(
              key: const Key('guild-confirm-ok'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

class _MilestoneRow extends ConsumerWidget {
  const _MilestoneRow({required this.index, required this.view});
  final int index;
  final GuildMine view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ms = guildMilestones[index];
    final claimed = view.guild.claimed.contains(index + 1);
    final reached = view.guild.total >= ms.threshold;
    final enough = view.myPoints >= guildMinPointsToClaim;
    final canClaim = reached && enough && !claimed;
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatNumber(ms.threshold.toDouble(), decimals: 0)} · '
                  '+${ms.gems} 💎${ms.accessory ? ' 🎁' : ''}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (reached && !enough && !claimed)
                  Text(l10n.guildNeedPoints(guildMinPointsToClaim),
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton(
              key: Key('guild-claim-$index'),
              onPressed: canClaim ? () => _claim(context, ref) : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    claimed ? l10n.dailyQuestClaimed : l10n.guildClaim),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await ref.read(guildControllerProvider.notifier).claim(index);
    if (!context.mounted) return;
    if (!out.ok) {
      _toast(context, guildFailureText(l10n, out.failure!));
      return;
    }
    _toast(
        context,
        out.drop == null
            ? l10n.guildRewardGot(out.gems)
            : l10n.guildRewardGotAccessory(
                out.gems, accessoryName(l10n, out.drop!.accessory.id)));
  }
}
