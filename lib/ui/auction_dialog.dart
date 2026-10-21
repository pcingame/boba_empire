/// Đấu giá cuối tuần (xem auction/auction.dart, supabase/auction_schema.sql).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auction/auction.dart';
import '../core/accessories.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/bobbing.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/reward_burst.dart';
import 'widgets/vip_shine.dart';

Future<void> showAuction(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _AuctionDialog());

class _AuctionDialog extends ConsumerStatefulWidget {
  const _AuctionDialog();

  @override
  ConsumerState<_AuctionDialog> createState() => _AuctionDialogState();
}

class _AuctionDialogState extends ConsumerState<_AuctionDialog> {
  AuctionInfo? _info;
  bool _failed = false;
  bool _busy = false;
  final _itemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(auctionRepositoryProvider);
    final ctl = ref.read(gameControllerProvider.notifier);
    try {
      // Nhận 💎 hoàn + món thắng trước, áp vào save rồi mới báo server (hai pha).
      final p = await repo.collect();
      if (!mounted) return;
      if (!p.isEmpty) {
        ctl.applyAuctionPickups(refundGems: p.refundGems, itemIds: p.wonItems);
        await repo.ack(p);
        if (!mounted) return;
      }
      final info = await repo.current();
      if (!mounted) return;
      setState(() => _info = info);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _bid(AuctionInfo info) async {
    final l10n = AppLocalizations.of(context)!;
    final ctl = ref.read(gameControllerProvider.notifier);
    final repo = ref.read(auctionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Máy trừ 💎 trước; server từ chối thì hoàn lại ngay.
    if (!ctl.spendGems(info.nextMin)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.auctionNeedGems)));
      return;
    }
    setState(() => _busy = true);
    try {
      await repo.bid(info.nextMin);
      if (mounted) showRewardBurst(_itemKey.currentContext ?? context, emojis: const ['🔨', '💎', '✨'], label: '-${info.nextMin} 💎');
    } catch (e) {
      ctl.applyAuctionPickups(refundGems: info.nextMin, itemIds: const []);
      messenger.showSnackBar(SnackBar(content: Text('$e'.contains('bid_too_low') ? l10n.auctionLow : l10n.auctionError)));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = _info;
    final emoji = info == null ? '🔨' : (accessoryOrNull(info.itemId)?.emoji ?? '🎁');
    return AlertDialog(
      title: Text(l10n.auctionTitle),
      content: SingleChildScrollView(
        child: info == null
            ? Center(child: _failed ? Text(l10n.auctionError) : const CircularProgressIndicator())
            : Column(mainAxisSize: MainAxisSize.min, children: [
                VipShine(
                  radius: 70,
                  circle: true,
                  sweep: false,
                  child: Container(
                    key: _itemKey,
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    child: Bobbing(child: Text(emoji, style: const TextStyle(fontSize: 72))),
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.auctionIntro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                if (!info.open)
                  ClayTile(child: Center(child: Text(l10n.auctionClosed, key: const Key('auction-closed'), textAlign: TextAlign.center)))
                else ...[
                  ClayTile(
                    child: Column(children: [
                      PulseOnIncrease(
                        value: info.topBid,
                        peak: 1.15,
                        child: info.topBid == 0
                            ? Text(l10n.auctionNoBids, key: const Key('auction-top'), style: const TextStyle(fontWeight: FontWeight.w800))
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(l10n.auctionTop(info.topBid),
                                    key: const Key('auction-top'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                              ),
                      ),
                      if (info.topIsMe)
                        Text(l10n.auctionLeadYou, key: const Key('auction-me'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w800))
                      else if (info.topNick != null)
                        Text(l10n.auctionLead(info.topNick!), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(l10n.auctionEnds(formatDuration(info.endsAt.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 1 << 30))),
                          style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('auction-bid'),
                      onPressed: _busy || info.topIsMe || info.nextMin > info.maxBid ? null : () => _bid(info),
                      child: Text(l10n.auctionBid(info.nextMin), maxLines: 1),
                    ),
                  ),
                ],
              ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
