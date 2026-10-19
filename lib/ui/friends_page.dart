/// Bạn bè: danh sách + tặng quà mỗi ngày, lời mời, thêm bạn theo biệt danh, BXH bạn bè.
/// Mở từ Cài đặt (và nút "Kết bạn" ở hồ sơ người khác). Cần tài khoản liên kết email.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/raid.dart';
import '../friends/friends.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/player_avatar.dart';
import '../state/game_providers.dart';
import 'email_gate.dart';
import 'friend_shop_page.dart';
import 'widgets/avatar_circle.dart';
import 'widgets/phone_width.dart';
import 'widgets/app_dialog.dart';

Future<void> showFriends(BuildContext context, {String initialQuery = ''}) async {
  if (!await ensureOnlineLinked(context) || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  await Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => FriendsPage(initialQuery: initialQuery)));
  container.invalidate(friendsAlertProvider);
}

String friendErrorText(AppLocalizations l10n, Object e) {
  if (e is! FriendException) return l10n.friendsErrNetwork;
  return switch (e.error) {
    FriendError.limit => l10n.friendsErrLimit,
    FriendError.notFound => l10n.friendsErrNotFound,
    FriendError.alreadySent => l10n.friendsErrAlreadySent,
    FriendError.raidLimit => l10n.friendsErrRaidLimit,
    FriendError.raidAlready => l10n.friendsErrRaidAlready,
    FriendError.linkRequired || FriendError.network => l10n.friendsErrNetwork,
  };
}

class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(friendsControllerProvider);
    final requests = async.value?.incoming.length ?? 0;
    return PhoneWidth(
      child: DefaultTabController(
        length: 5,
        initialIndex: initialQuery.isEmpty ? 0 : 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.friendsTitle),
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(key: const Key('friends-tab-list'), text: l10n.friendsTabList),
                Tab(
                    key: const Key('friends-tab-requests'),
                    text: requests > 0 ? '${l10n.friendsTabRequests} ($requests)' : l10n.friendsTabRequests),
                Tab(key: const Key('friends-tab-add'), text: l10n.friendsTabAdd),
                Tab(key: const Key('friends-tab-rank'), text: l10n.friendsTabRank),
                Tab(
                    key: const Key('friends-tab-raids'),
                    text: (async.value?.defenseWaiting ?? 0) > 0 ? '${l10n.raidTab} ●' : l10n.raidTab),
              ],
            ),
          ),
          body: switch (async) {
            AsyncError() => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(l10n.friendsErrNetwork, key: const Key('friends-error')),
                  const SizedBox(height: 8),
                  FilledButton(
                      key: const Key('friends-retry'),
                      onPressed: () => ref.invalidate(friendsControllerProvider),
                      child: Text(l10n.friendsRetry)),
                ]),
              ),
            AsyncData(:final value) => TabBarView(children: [
                _ListTab(value),
                _RequestsTab(value),
                _AddTab(initialQuery: initialQuery),
                _RankTab(value),
                _RaidsTab(value),
              ]),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(text)));

class _NameRow extends ConsumerWidget {
  const _NameRow({super.key, required this.nickname, required this.subtitle, this.trailing, this.onTap});
  final String nickname;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(playerAvatarProvider(nickname)).value ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LayoutBuilder(builder: (context, box) => Row(children: [
          AvatarCircle(avatarKey: avatar, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nickname,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          // Nút bên phải tối đa nửa hàng và tự co (chữ to/ngôn ngữ dài) thay vì đẩy tên ra khỏi màn.
          if (trailing != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.5),
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: trailing),
            ),
          ],
        ])),
      ),
    );
  }
}

class _ListTab extends ConsumerWidget {
  const _ListTab(this.data);
  final FriendsOverview data;

  Future<void> _gift(BuildContext context, WidgetRef ref, Friend f) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final xu = await ref.read(friendsControllerProvider.notifier).sendGift(f);
      if (context.mounted) _snack(context, l10n.friendsGiftSentSnack(formatNumber(xu)));
    } catch (e) {
      if (context.mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final (n, xu) = await ref.read(friendsControllerProvider.notifier).claimGifts();
      if (context.mounted && n > 0) _snack(context, l10n.friendsGiftClaimedSnack(n, formatNumber(xu)));
    } catch (e) {
      if (context.mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Friend f) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.friendsRemoveConfirm(f.nickname)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(
              key: const Key('friend-remove-confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.friendsRemove)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(friendsControllerProvider.notifier).remove(f);
    } catch (e) {
      if (context.mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(children: [
      if (data.giftsWaiting > 0)
        Material(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Expanded(child: Text('🎁 ${l10n.friendsGiftWaiting(data.giftsWaiting)}')),
              const SizedBox(width: 8),
              FilledButton(
                  key: const Key('friends-gift-claim'),
                  onPressed: () => _claim(context, ref),
                  child: Text(l10n.friendsGiftClaim)),
            ]),
          ),
        ),
      Expanded(
        child: data.friends.isEmpty
            ? Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.friendsEmpty, key: const Key('friends-empty'), textAlign: TextAlign.center)))
            : ListView(children: [
                for (final f in data.friends)
                  _NameRow(
                    key: Key('friend-${f.userId}'),
                    nickname: f.nickname,
                    subtitle: l10n.friendsStage(f.stage),
                    onTap: () => showFriendShop(context, f),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      FilledButton.tonal(
                        key: Key('friend-gift-${f.userId}'),
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: f.giftSent ? null : () => _gift(context, ref, f),
                        child: Text(f.giftSent ? '✓' : '🎁'),
                      ),
                      IconButton(
                        key: Key('friend-remove-${f.userId}'),
                        tooltip: l10n.friendsRemove,
                        icon: const Icon(Icons.person_remove_outlined),
                        onPressed: () => _remove(context, ref, f),
                      ),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab(this.data);
  final FriendsOverview data;

  Future<void> _answer(BuildContext context, WidgetRef ref, FriendRequestIn r, bool accept) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(friendsControllerProvider.notifier).respond(r, accept);
      if (accept && context.mounted) _snack(context, l10n.friendsAccepted(r.nickname));
    } catch (e) {
      if (context.mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (data.incoming.isEmpty) {
      return Center(child: Text(l10n.friendsRequestsEmpty, key: const Key('friends-requests-empty')));
    }
    return ListView(children: [
      for (final r in data.incoming)
        _NameRow(
          key: Key('request-${r.userId}'),
          nickname: r.nickname,
          subtitle: '',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                key: Key('request-decline-${r.userId}'),
                tooltip: l10n.friendsDecline,
                icon: const Icon(Icons.close),
                onPressed: () => _answer(context, ref, r, false)),
            IconButton.filled(
                key: Key('request-accept-${r.userId}'),
                tooltip: l10n.friendsAccept,
                icon: const Icon(Icons.check),
                onPressed: () => _answer(context, ref, r, true)),
          ]),
        ),
    ]);
  }
}

class _AddTab extends ConsumerStatefulWidget {
  const _AddTab({this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends ConsumerState<_AddTab> {
  late final _ctrl = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery.trim();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search() => setState(() => _query = _ctrl.text.trim());

  Future<void> _add(FriendCandidate c) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final r = await ref.read(friendsControllerProvider.notifier).request(c.userId);
      if (!mounted) return;
      _snack(context, r == 'already' ? l10n.friendsAlready : r == 'accepted' ? l10n.friendsAccepted(c.nickname) : l10n.friendsRequestSent);
    } catch (e) {
      if (mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _query.isEmpty ? null : ref.watch(friendSearchProvider(_query));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: TextField(
              key: const Key('friends-search-field'),
              controller: _ctrl,
              maxLength: 20,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(hintText: l10n.friendsSearchHint, counterText: ''),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(key: const Key('friends-search-button'), onPressed: _search, child: Text(l10n.friendsSearchButton)),
        ]),
      ),
      Expanded(
        child: switch (results) {
          null => const SizedBox.shrink(),
          AsyncData(:final value) when value.isEmpty => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.friendsSearchEmpty, key: const Key('friends-search-empty'), textAlign: TextAlign.center)),
          AsyncData(:final value) => ListView(children: [
              for (final c in value)
                _NameRow(
                  key: Key('candidate-${c.userId}'),
                  nickname: c.nickname,
                  subtitle: l10n.friendsStage(c.stage),
                  trailing: FilledButton(
                      key: Key('candidate-add-${c.userId}'),
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _add(c),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.friendsAddButton))),
                ),
            ]),
          AsyncError(:final error) => Padding(padding: const EdgeInsets.all(24), child: Text(friendErrorText(l10n, error))),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    ]);
  }
}

class _RankTab extends ConsumerStatefulWidget {
  const _RankTab(this.data);
  final FriendsOverview data;
  @override
  ConsumerState<_RankTab> createState() => _RankTabState();
}

class _RankTabState extends ConsumerState<_RankTab> {
  FriendBoard _board = FriendBoard.income;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mine = ref.read(sharedPreferencesProvider).getString('leaderboard_nickname') ?? '';
    final rows = friendRanking(widget.data, _board, mine.isEmpty ? l10n.friendsRankMe : mine);
    String label(FriendBoard b) => switch (b) {
          FriendBoard.income => l10n.friendsRankIncome,
          FriendBoard.season => l10n.friendsRankSeason,
          FriendBoard.orders => l10n.friendsRankOrders,
        };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, children: [
          for (final b in FriendBoard.values)
            ChoiceChip(
              key: Key('friends-rank-${b.name}'),
              label: Text(label(b)),
              selected: _board == b,
              onSelected: (_) => setState(() => _board = b),
            ),
        ]),
      ),
      Expanded(
        child: widget.data.friends.isEmpty
            ? Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.friendsRankEmpty, key: const Key('friends-rank-empty'), textAlign: TextAlign.center)))
            : ListView(children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    key: Key('friends-rank-row-$i'),
                    color: rows[i].isMe ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      SizedBox(width: 36, child: Text('#${i + 1}', style: theme.textTheme.titleMedium)),
                      Expanded(
                          child: Text(rows[i].isMe && mine.isNotEmpty ? '${rows[i].nickname} ${l10n.friendsRankMe}' : rows[i].nickname,
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      // Chiều rộng cố định: số khổng lồ co chữ (FittedBox) thay vì đẩy tên/tràn hàng.
                      SizedBox(
                          width: 96,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(formatNumber(rows[i].value)))),
                    ]),
                  ),
              ]),
      ),
    ]);
  }
}


/// Nhật ký đột kích vào quán mình + thưởng phòng thủ. Đột kích bạn thì bấm vào quán bạn (trang quán).
class _RaidsTab extends ConsumerWidget {
  const _RaidsTab(this.data);
  final FriendsOverview data;

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final (n, xu) = await ref.read(friendsControllerProvider.notifier).claimDefense();
      if (context.mounted && n > 0) _snack(context, l10n.raidDefenseSnack(formatNumber(xu)));
    } catch (e) {
      if (context.mounted) _snack(context, friendErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(l10n.raidIntro(raidsPerDay), key: const Key('raid-intro'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(l10n.raidLeft(data.raidsLeft), key: const Key('raid-left'), style: theme.textTheme.titleSmall),
      if (data.defenseWaiting > 0) ...[
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('raid-claim'),
          onPressed: () => _claim(context, ref),
          child: Text('🛡️ ${l10n.raidClaimDefense(data.defenseWaiting)}'),
        ),
      ],
      const SizedBox(height: 12),
      if (data.raidLog.isEmpty)
        Text(l10n.raidLogEmpty, key: const Key('raid-log-empty'))
      else
        for (var i = 0; i < data.raidLog.length; i++)
          Padding(
            key: Key('raid-log-$i'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(data.raidLog[i].win
                ? '⚔️ ${l10n.raidLogWin(data.raidLog[i].nickname)}'
                : l10n.raidLogBlocked(data.raidLog[i].nickname)),
          ),
    ]);
  }
}
