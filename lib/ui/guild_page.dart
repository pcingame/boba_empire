/// Hội (Guild): chưa có hội → danh sách hội công khai + tạo hội + nhập mã mời;
/// đã có hội → mục tiêu tuần, thưởng mốc, danh sách thành viên.
/// Cùng khuôn các trang xếp hạng khác (controller Notifier + trạng thái sealed).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/balance.dart';
import '../core/guild.dart';
import '../core/topup.dart';
import '../core/guild_shop.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import 'guild_leaderboard_page.dart';
import '../guild/guild_chat_unread.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'guild_activity_page.dart';
import 'widgets/dispose_with_widget.dart';
import 'guild_chat_page.dart';
import 'guild_members.dart';
import 'guild_quests_section.dart';
import 'guild_shop_page.dart';
import 'widgets/clay.dart';
import 'web_links.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildPage(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const GuildPage()));

/// Emoji chọn khi tạo hội (chip cố định: không cho nhập tự do để khỏi nhét chữ).
const guildEmojis = ['🧋', '🐉', '🦊', '🐼', '🔥', '⭐', '🌸', '👑'];

/// [createCost] = phí tạo hội hiện tại của người chơi (đã trừ ưu đãi VIP) cho lời nhắn thiếu 💎.
String guildFailureText(AppLocalizations l10n, GuildFailure f,
        {int createCost = guildCreateCostGems}) =>
    switch (f) {
      GuildFailure.nameTaken => l10n.guildErrNameTaken,
      GuildFailure.guildFull => l10n.guildErrFull,
      GuildFailure.guildMaxed => l10n.guildExpandMaxed,
      GuildFailure.alreadyInGuild => l10n.guildErrAlready,
      GuildFailure.invalidName => l10n.guildErrInvalid,
      GuildFailure.notFound => l10n.guildErrNotFound,
      GuildFailure.notEnoughContribution => l10n.guildErrContribution,
      GuildFailure.notEnoughGems => l10n.guildErrGems(createCost),
      GuildFailure.notEnoughGemsToSpend => l10n.guildErrGemsSpend,
      GuildFailure.bossAlive => l10n.guildBossErrAlive,
      GuildFailure.approvalRequired => l10n.guildErrApproval,
      GuildFailure.alreadyClaimed => l10n.guildErrClaimed,
      GuildFailure.dailyLimit => l10n.guildErrDailyLimit(guildDonateDailyCap),
      GuildFailure.giftLimit =>
        l10n.guildErrGiftLimit(guildGiftReceiveDailyCap, guildGiftSendDailyCap),
      GuildFailure.notEnoughCoins => l10n.guildErrCoins,
      GuildFailure.alreadyOwned => l10n.guildErrOwned,
      GuildFailure.buffMaxed => l10n.guildErrBuffMaxed,
      GuildFailure.invalidInput => l10n.guildErrInvalidInput,
      GuildFailure.nicknameTaken => l10n.guildErrNicknameTaken,
      GuildFailure.notLinked => l10n.emailGateOnlineBody,
      GuildFailure.requestsFull => l10n.guildErrRequestsFull,
      GuildFailure.notAllowed => l10n.guildErrNotAllowed,
      GuildFailure.fundNotReached => l10n.guildErrFundNotReached,
      GuildFailure.fundDonationLow => l10n.guildErrFundLow(guildFundMinDonation),
      GuildFailure.teamNotReached => l10n.guildErrTeamNotReached,
      GuildFailure.teamPointsLow => l10n.guildErrTeamLow(guildTeamMinPoints),
      GuildFailure.officersFull => l10n.guildErrOfficersFull(guildMaxOfficers),
      GuildFailure.chatRateLimited => l10n.guildErrChatRate,
      GuildFailure.textBlocked => l10n.guildErrTextBlocked,
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
              key: const Key('guild-how-to-button'),
              icon: const Icon(Icons.help_outline),
              tooltip: l10n.guildHowToTitle,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l10n.guildHowToTitle),
                  content: SingleChildScrollView(
                      child: Text(l10n.guildHowTo(guildMinPointsToClaim))),
                  actions: [
                    TextButton(
                      key: const Key('guild-how-to-web'),
                      onPressed: () =>
                          openWebLink(context, ref, webGuideUrl('hoi')),
                      child: Text(l10n.guideOnWeb),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.close),
                    ),
                  ],
                ),
              ),
            ),
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
                          '${l10n.guildMembersCount(g.memberCount, g.maxMembers)}'
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
    builder: (ctx) => DisposeWithWidget(
      controllers: [ctrl],
      child: AlertDialog(
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
    ),
  );
}

Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final name = TextEditingController();
  final tag = TextEditingController();
  final nick = TextEditingController(
      text: ref.read(guildRepositoryProvider).cachedNickname ?? '');
  // Phí tạo hội theo cấp VIP hiện tại (ưu đãi từ VIP 5).
  final vipLevel = topupVipLevel(ref.read(gameControllerProvider).vipExp);
  final createCost = guildCreateCostFor(vipLevel);
  final discount = guildCreateDiscountPercent(vipLevel);
  var emoji = guildEmojis.first;
  var requiresApproval = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => DisposeWithWidget(
      controllers: [name, tag, nick],
      child: StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.guildCreate),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.guildCreateCost(createCost),
                  key: const Key('guild-create-cost')),
              if (discount > 0)
                Text(l10n.guildCreateVipDiscount(discount),
                    key: const Key('guild-create-discount'),
                    style: Theme.of(ctx).textTheme.bodySmall),
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
                      showCheckmark: false,
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
  _toast(
      context,
      guildFailureText(l10n, out.failure!,
          createCost:
              guildCreateCostFor(topupVipLevel(ref.read(gameControllerProvider).vipExp))));
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
          _GuildBanner(guild: g),
          const SizedBox(height: 8),
          const _GiftInbox(),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('guild-shop-button'),
                  icon: const Icon(Icons.storefront),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                        '${l10n.guildShopButton} · ${l10n.guildCoinsLabel(g.wallet)}'),
                  ),
                  onPressed: () => showGuildShop(context),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                key: const Key('guild-chat-button'),
                tooltip: l10n.guildChatTitle,
                icon: Badge(
                  key: const Key('guild-chat-unread'),
                  isLabelVisible: ref.watch(guildChatUnreadProvider),
                  smallSize: 9,
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                onPressed: () => showGuildChat(context),
              ),
              IconButton.filledTonal(
                key: const Key('guild-activity-button'),
                tooltip: l10n.guildActivityTitle,
                icon: const Icon(Icons.history),
                onPressed: () => showGuildActivity(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text('🎯 ${l10n.guildGoalTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Text(
                '${formatNumber(g.total.toDouble(), decimals: 0)} / '
                '${formatNumber(guildMilestones.firstWhere((m) => m.threshold > g.total, orElse: () => guildMilestones.last).threshold.toDouble(), decimals: 0)}',
                key: const Key('guild-goal-target'),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              key: const Key('guild-progress'),
              value: (g.total / top).clamp(0.0, 1.0).toDouble(),
              minHeight: 14,
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
          if (g.bossHp > 0) _BossCard(view: view),
          const SizedBox(height: 8),
          if (view.canModerate && g.requests.isNotEmpty) ...[
            Text(l10n.guildRequestsTitle(g.requests.length),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            for (final r in g.requests)
              ClayTile(
                child: Row(
                  children: [
                    Expanded(
                      child: VipNameBlock(
                        userId: r.userId,
                        child: Row(
                          children: [
                            FlairBadge(userId: r.userId),
                            Flexible(
                              child: Text(r.nickname,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
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
          // Nhiệm vụ Hội nằm TRƯỚC danh sách thành viên (danh sách có thể dài tới 30 người).
          GuildQuestsSection(view: view),
          GuildMembersSection(
            view: view,
            onGift: (m) => _gift(context, ref, m),
            onManage: (m, action) => _manage(context, ref, m, action),
            onKick: (m) => _kick(context, ref, m),
            // "Nhắc trong chat": mở chat với "@tên " điền sẵn.
            onMention: (m) => showGuildChat(context, prefill: '@${m.nickname} '),
          ),
          const SizedBox(height: 12),
          if (view.isOwner && guildExpandCostFor(g.maxMembers) != null) ...[
            FilledButton.tonal(
              key: const Key('guild-expand-button'),
              onPressed: () => _expand(context, ref, g.maxMembers),
              child: Text(
                  l10n.guildExpandButton(guildExpandCostFor(g.maxMembers)!, g.maxMembers + guildExpandStep),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
          ],
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

  Future<void> _manage(
      BuildContext context, WidgetRef ref, GuildMemberInfo m, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = ref.read(guildControllerProvider.notifier);
    if (action == 'transfer') {
      final ok = await _confirm(
          context, l10n.guildTransferConfirm(m.nickname), l10n.guildTransfer);
      if (!ok || !context.mounted) return;
    }
    final out = action == 'transfer'
        ? await ctrl.transferOwner(m.userId)
        : await ctrl.setOfficer(m.userId, on: m.role != GuildRole.officer);
    if (!context.mounted || out.ok) return;
    _toast(context, guildFailureText(l10n, out.failure!));
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

  /// Chọn mức tặng ([guildGiftAmounts]) rồi gửi; lỗi hiện toast, thành công báo số 💎.
  Future<void> _gift(
      BuildContext context, WidgetRef ref, GuildMemberInfo m) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('guild-gift-dialog'),
        title: Text(l10n.guildGiftTitle(m.nickname)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in guildGiftAmounts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.tonal(
                  key: Key('guild-gift-amount-$a'),
                  onPressed: () => Navigator.of(ctx).pop(a),
                  child: Text('$a 💎'),
                ),
              ),
            Text(l10n.guildGiftHint(guildGiftSendDailyCap, guildGiftExpireDays),
                style: Theme.of(ctx).textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;
    final out =
        await ref.read(guildControllerProvider.notifier).sendGift(m.userId, amount);
    if (!context.mounted) return;
    _toast(context,
        out.ok ? l10n.guildGiftSent(amount, m.nickname) : guildFailureText(l10n, out.failure!));
  }

  Future<void> _expand(BuildContext context, WidgetRef ref, int current) async {
    final l10n = AppLocalizations.of(context)!;
    final cost = guildExpandCostFor(current)!;
    final next = current + guildExpandStep;
    final ok = await _confirm(context, l10n.guildExpandConfirm(cost, next), l10n.guildExpandAction);
    if (!ok || !context.mounted) return;
    final out = await ref.read(guildControllerProvider.notifier).expand();
    if (!context.mounted) return;
    _toast(context, out.ok ? l10n.guildExpandDone(next) : guildFailureText(l10n, out.failure!));
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
          _StatusDot(done: claimed, ready: canClaim, reached: reached),
          const SizedBox(width: 10),
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

/// Thẻ "Quà từ hội viên": chỉ hiện khi hộp thư có quà chưa nhận. Tải một lần khi mở trang,
/// tải lại sau mỗi lần nhận.
class _GiftInbox extends ConsumerStatefulWidget {
  const _GiftInbox();

  @override
  ConsumerState<_GiftInbox> createState() => _GiftInboxState();
}

class _GiftInboxState extends ConsumerState<_GiftInbox> {
  late Future<List<GuildGift>> _gifts =
      ref.read(guildControllerProvider.notifier).giftInbox();

  Future<void> _claim(GuildGift g) async {
    final l10n = AppLocalizations.of(context)!;
    final r = await ref.read(guildControllerProvider.notifier).claimGift(g.id);
    if (!mounted) return;
    _toast(context,
        r.outcome.ok ? l10n.guildGiftClaimed(r.gems) : guildFailureText(l10n, r.outcome.failure!));
    final next = ref.read(guildControllerProvider.notifier).giftInbox();
    setState(() {
      _gifts = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<GuildGift>>(
      future: _gifts,
      builder: (context, snap) {
        final gifts = snap.data ?? const <GuildGift>[];
        if (gifts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClayTile(
            key: const Key('guild-gift-inbox'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.guildGiftInboxTitle(gifts.length),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                for (final g in gifts)
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.guildGiftFrom(g.amount, g.fromNickname),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      TextButton(
                        key: Key('guild-gift-claim-${g.id}'),
                        onPressed: () => _claim(g),
                        child: Text(l10n.topupClaim),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Thẻ Boss Hội hàng tuần: thanh HP (sát thương = tổng điểm tuần cả hội), bậc theo chuỗi tuần, và
/// nút nhận rương khi boss bị hạ (cần đủ điểm đóng góp tối thiểu như nhận thưởng mốc).
class _BossCard extends ConsumerWidget {
  const _BossCard({required this.view});
  final GuildMine view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final g = view.guild;
    final week = guildWeekIndex(ref.read(clockProvider)());
    final idx = guildBossIndex(week);
    final name = switch (idx) {
      0 => l10n.guildBossName1,
      1 => l10n.guildBossName2,
      2 => l10n.guildBossName3,
      3 => l10n.guildBossName4,
      4 => l10n.guildBossName5,
      _ => l10n.guildBossName6,
    };
    final defeated = g.total >= g.bossHp;
    final enough = view.myPoints >= guildMinPointsToClaim;
    final canClaim = defeated && enough && !g.bossClaimed;
    final gems = guildBossRewardGems(g.bossTier);
    final coins = guildBossRewardCoins(g.bossTier);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [
            theme.colorScheme.errorContainer.withValues(alpha: 0.55),
            theme.colorScheme.surface,
          ]),
        ),
        child: ClayTile(
        key: const Key('guild-boss'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.errorContainer,
                  ),
                  child: Text(guildBossEmojis[idx],
                      style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.guildBossTitle,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(name,
                          key: const Key('guild-boss-name'),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text(l10n.guildBossTier(g.bossTier + 1),
                    key: const Key('guild-boss-tier'),
                    style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                key: const Key('guild-boss-hp'),
                value: g.bossHp == 0 ? 0 : (g.total / g.bossHp).clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                color: defeated ? Colors.green : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.guildBossProgress(formatNumber(g.total.clamp(0, g.bossHp).toDouble()),
                  formatNumber(g.bossHp.toDouble())),
              key: const Key('guild-boss-progress'),
              style: theme.textTheme.bodySmall,
            ),
            if (defeated && !g.bossClaimed && !enough)
              Text(l10n.guildNeedPoints(guildMinPointsToClaim),
                  style: theme.textTheme.bodySmall),
            if (defeated) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('guild-boss-claim'),
                  onPressed: canClaim ? () => _claim(context, ref) : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(g.bossClaimed
                        ? l10n.guildBossClaimedLabel
                        : l10n.guildBossClaim(coins, gems)),
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await ref.read(guildControllerProvider.notifier).claimBoss();
    if (!context.mounted) return;
    _toast(
        context,
        out.ok
            ? l10n.guildBossClaimedSnack(out.coins, out.gems)
            : guildFailureText(l10n, out.failure!));
  }
}

/// Banner đầu trang hội: nền gradient, emoji lớn trong vòng tròn, tên + số thành viên và các chip
/// trạng thái (chuỗi tuần, thưởng VIP, buff). Giữ nguyên chuỗi chữ/khoá cũ — chỉ đổi cách trình bày.
class _GuildBanner extends StatelessWidget {
  const _GuildBanner({required this.guild});
  final MyGuild guild;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final g = guild;
    final onBanner = theme.colorScheme.onPrimaryContainer;
    Widget chip(Key key, String text, {String? tooltip}) {
      final w = Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(text,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
      );
      return tooltip == null
          ? w
          : Tooltip(message: tooltip, triggerMode: TooltipTriggerMode.tap, child: w);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface.withValues(alpha: 0.85),
                ),
                child: Text(g.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${g.requiresApproval ? '🔒 ' : ''}[${g.tag}] ${g.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800, color: onBanner)),
                    Text(l10n.guildMembersCount(g.members.length, g.maxMembers),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: onBanner)),
                  ],
                ),
              ),
            ],
          ),
          if (g.streak > 0 || g.vipBonus > 0 || g.buffSeconds > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (g.streak > 0)
                  chip(const Key('guild-streak'), l10n.guildStreakLine(g.streak)),
                // Thưởng thu nhập từ thành viên VIP: chỉ hiện khi đã có; chạm giữ để xem cách có thưởng.
                if (g.vipBonus > 0)
                  chip(const Key('guild-vip-bonus'),
                      l10n.guildVipBonusLine(g.vipMembers, g.vipBonus),
                      tooltip: l10n.guildVipBonusHint(
                          guildVipBonusCap, guildVipMinLevel, guildVipBonusPerMember)),
                if (g.buffSeconds > 0)
                  chip(
                      const Key('guild-buff-line'),
                      l10n.guildBuffLine(
                          ((Balance.guildBuffMult - 1) * 100).round(),
                          formatDuration(g.buffSeconds))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Vòng trạng thái của một mốc tuần: ✓ đã nhận, 🎁 sẵn sàng nhận, ● đạt nhưng chưa đủ điểm cá nhân,
/// 🔒 chưa đạt.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.done, required this.ready, required this.reached});
  final bool done;
  final bool ready;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (String glyph, Color bg) = done
        ? ('✅', cs.primaryContainer)
        : ready
            ? ('🎁', cs.tertiaryContainer)
            : reached
                ? ('⚠️', cs.errorContainer)
                : ('🔒', cs.surfaceContainerHighest);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Text(glyph, style: const TextStyle(fontSize: 18)),
    );
  }
}
