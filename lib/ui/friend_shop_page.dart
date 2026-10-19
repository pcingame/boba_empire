/// Ghé thăm quán của một người bạn: cảnh theo giai đoạn, phụ kiện đang trưng bày và số liệu (chỉ đọc).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/format.dart';
import '../core/raid.dart';
import '../friends/friends.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'collection_peek_dialog.dart';
import 'friends_page.dart' show friendErrorText;
import 'player_profile_dialog.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/clay.dart';
import 'widgets/app_dialog.dart';

Future<void> showFriendShop(BuildContext context, Friend f) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => FriendShopPage(friend: f)));

class FriendShopPage extends ConsumerWidget {
  const FriendShopPage({super.key, required this.friend});
  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(friendShopProvider(friend.userId));
    return Scaffold(
      key: const Key('friend-shop'),
      appBar: AppBar(title: Text(l10n.friendShopTitle(friend.nickname), maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(friendErrorText(l10n, e), key: const Key('friend-shop-error'), textAlign: TextAlign.center),
              TextButton(
                key: const Key('friend-shop-retry'),
                onPressed: () => ref.invalidate(friendShopProvider(friend.userId)),
                child: Text(l10n.friendsRetry),
              ),
            ]),
          ),
        ),
        data: (shop) => _Body(friend: friend, shop: shop),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.friend, required this.shop});
  final Friend friend;
  final FriendShop shop;

  Future<void> _raid(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final (r, xu) = await ref.read(friendsControllerProvider.notifier).raid(friend.userId);
      if (!context.mounted) return;
      await showAppDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const Key('raid-result'),
          title: Text(r.win ? '⚔️ 🎉' : '🛡️', textAlign: TextAlign.center, style: const TextStyle(fontSize: 40)),
          content: Text(r.win ? l10n.raidWin(formatNumber(xu)) : l10n.raidBlocked(formatNumber(xu)), textAlign: TextAlign.center),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.close))],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(friendErrorText(l10n, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = [for (final id in shop.equipped) ?accessoryOrNull(id)];
    final n = shop.stage.clamp(1, 18);
    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: theme.textTheme.titleMedium))),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(16), children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFFFAE9D4)),
            Image.asset('assets/scene/stage$n.png',
                key: const Key('friend-shop-scene'),
                fit: BoxFit.fitWidth,
                alignment: Alignment.bottomCenter,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      Text(stageName(l10n, shop.stage),
          key: const Key('friend-shop-stage'), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Text(l10n.friendShopDisplay, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (items.isEmpty)
        Text(l10n.friendShopDisplayEmpty, key: const Key('friend-shop-empty'))
      else
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final a in items)
            SizedBox(
              key: Key('friend-shop-item-${a.id}'),
              width: 84,
              child: Column(children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: rarityColor(a.rarity), borderRadius: BorderRadius.circular(14)),
                  child: Text(a.emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 4),
                Text(accessoryName(l10n, a.id),
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ]),
            ),
        ]),
      const SizedBox(height: 16),
      Builder(builder: (context) {
        final g = ref.watch(gameControllerProvider);
        final mine = raidPower(equipped: g.equippedAccessories, refineLevels: g.refineLevels, stage: g.stage);
        final left = ref.watch(friendsControllerProvider).value?.raidsLeft ?? raidsPerDay;
        return ClayTile(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('⚔️ ${l10n.raidPower(shop.power)}', key: const Key('friend-shop-power')),
            Text(l10n.raidChance((raidWinChance(mine, shop.power) * 100).round()), key: const Key('friend-shop-chance')),
            Text(l10n.raidLeft(left), style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            FilledButton(
              key: const Key('friend-shop-raid'),
              onPressed: left > 0 ? () => _raid(context, ref) : null,
              child: Text('⚔️ ${l10n.raidButton}'),
            ),
          ]),
        );
      }),
      const SizedBox(height: 8),
      stat('💰 ${l10n.friendsRankIncome}', formatNumber(shop.income)),
      stat('🎫 ${l10n.friendsRankSeason}', '${shop.seasonXp}'),
      stat('🧋 ${l10n.friendsRankOrders}', '${shop.orders}'),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        OutlinedButton(
          key: const Key('friend-shop-collection'),
          onPressed: () => showCollectionPeek(context, userId: friend.userId, nickname: friend.nickname),
          child: Text('🎀 ${l10n.friendShopCollection}'),
        ),
        OutlinedButton(
          key: const Key('friend-shop-profile'),
          onPressed: () => showPlayerProfile(context, friend.nickname),
          child: Text(l10n.friendShopProfile),
        ),
      ]),
    ]);
  }
}
