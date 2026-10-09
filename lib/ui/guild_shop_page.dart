/// Cửa hàng hội: ví Xu Hội cá nhân, nạp 💎, nhiệm vụ hội tuần, đổi phụ kiện độc quyền
/// và mua buff thu nhập cả hội. Số liệu lấy từ [GuildMine] (server giữ ví).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/format.dart';
import '../core/guild_shop.dart';
import '../guild/guild_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'guild_page.dart' show guildFailureText;
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showGuildShop(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const GuildShopPage()));

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class GuildShopPage extends ConsumerWidget {
  const GuildShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final view = ref.watch(guildControllerProvider);
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildShopTitle)),
        body: switch (view) {
          GuildMine() => _Body(view: view),
          // Mất hội giữa chừng (bị kick/rời) hoặc đang tải lại: không có gì để bán.
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.view});
  final GuildMine view;

  Future<void> _run(BuildContext context, Future<GuildOutcome> action,
      String Function(AppLocalizations) okText) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await action;
    if (!context.mounted) return;
    _toast(context, out.ok ? okText(l10n) : guildFailureText(l10n, out.failure!));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ctrl = ref.read(guildControllerProvider.notifier);
    final g = view.guild;
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final myPoints = view.myPoints;
    final remaining = (guildDonateDailyCap - g.donatedToday).clamp(0, guildDonateDailyCap);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ClayTile(
          child: Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.guildCoinsLabel(g.wallet),
                    key: const Key('guild-wallet'),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(l10n.guildDonateTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(l10n.guildDonateHint(g.donatedToday, guildDonateDailyCap),
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final n in guildDonateChoices)
              FilledButton.tonal(
                key: Key('guild-donate-$n'),
                onPressed: gems >= n && n <= remaining
                    ? () => _run(context, ctrl.donate(n),
                        (l) => l.guildDonated(n * guildCoinsPerGem))
                    : null,
                child: Text(l10n.guildDonateGems(n)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(l10n.guildQuestsTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        for (var i = 0; i < guildQuests.length; i++)
          _QuestRow(
            index: i,
            quest: guildQuests[i],
            myPoints: myPoints,
            claimed: g.questsClaimed.contains(i + 1),
            onClaim: () => _run(context, ctrl.claimQuest(i),
                (l) => l.guildQuestGot(guildQuests[i].reward)),
          ),
        const SizedBox(height: 14),
        Text(l10n.guildItemsTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        for (final item in guildShopItems)
          ClayTile(
            child: Row(
              children: [
                Text(item.accessory.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(accessoryName(l10n, item.id),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton(
                    key: Key('guild-buy-${item.id}'),
                    onPressed: g.ownedItems.contains(item.id) ||
                            g.wallet < item.price
                        ? null
                        : () => _run(context, ctrl.buyItem(item.id),
                            (l) => l.guildItemBought),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(g.ownedItems.contains(item.id)
                          ? l10n.guildItemOwned
                          : l10n.guildItemPrice(item.price)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        Text(l10n.guildBuffTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        ClayTile(
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l10n.guildBuffDesc(
                            ((Balance.guildBuffMult - 1) * 100).round(),
                            guildBuffHours),
                        style: theme.textTheme.bodyMedium),
                    if (g.buffSeconds > 0)
                      Text(l10n.guildBuffLeft(formatDuration(g.buffSeconds)),
                          key: const Key('guild-buff-left'),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FilledButton(
                  key: const Key('guild-buy-buff'),
                  onPressed: g.wallet < guildBuffPrice
                      ? null
                      : () => _run(
                          context, ctrl.buyBuff(), (l) => l.guildBuffBought),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.guildItemPrice(guildBuffPrice)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.index,
    required this.quest,
    required this.myPoints,
    required this.claimed,
    required this.onClaim,
  });

  final int index;
  final GuildQuest quest;
  final int myPoints;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final done = myPoints >= quest.need;
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    l10n.guildQuestProgress(
                        myPoints.clamp(0, quest.need), quest.need),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (myPoints / quest.need).clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FilledButton(
              key: Key('guild-quest-$index'),
              onPressed: done && !claimed ? onClaim : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(claimed
                    ? l10n.dailyQuestClaimed
                    : l10n.guildQuestReward(quest.reward)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
