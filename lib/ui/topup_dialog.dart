import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/flair.dart';
import '../state/game_controller.dart';
import '../state/game_providers.dart';

/// Mốc nạp & cấp VIP theo tổng nạp tích lũy (xem core/topup.dart).
Future<void> showTopupDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _TopupDialog(),
    );

class _TopupDialog extends ConsumerStatefulWidget {
  const _TopupDialog();

  @override
  ConsumerState<_TopupDialog> createState() => _TopupDialogState();
}

class _TopupDialogState extends ConsumerState<_TopupDialog> {
  @override
  void initState() {
    super.initState();
    // Đồng bộ cấp VIP lên server mỗi lần mở (bù lần báo lỡ vì mất mạng).
    Future.microtask(() {
      if (!mounted) return;
      final points = ref.read(gameControllerProvider).topupPoints;
      ref.read(flairCacheProvider.notifier).reportVip(topupVipLevel(points));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final level = topupVipLevel(s.topupPoints);
    final bonus = (vipIncomeBonusPerLevel * 100).round();

    return AlertDialog(
      title: Text(l10n.topupTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                if (level > 0) VipTag(level: level) else const Text('—'),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.topupSummary(s.topupPoints))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.topupBuff(bonus, level * bonus),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              l10n.topupNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            for (var i = 0; i < topupTiers.length; i++)
              _tierRow(context, l10n, i, s.topupPoints,
                  s.topupClaimed.contains(i), controller),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _tierRow(BuildContext context, AppLocalizations l10n, int i,
      int points, bool claimed, GameController controller) {
    final t = topupTiers[i];
    final reached = points >= t.points;
    return ListTile(
      key: Key('topup-tier-$i'),
      contentPadding: EdgeInsets.zero,
      leading: VipTag(level: i + 1),
      title: Text(l10n.topupTier(t.points)),
      subtitle: Text(
        '+${formatNumber(t.gems)} 💎${t.accessory == null ? '' : '  ${l10n.topupAccessory}'}',
      ),
      trailing: claimed
          ? Text(l10n.topupClaimed)
          : FilledButton.tonal(
              key: Key('topup-claim-$i'),
              onPressed: reached
                  ? () {
                      final r = controller.claimTopupTier(i);
                      if (r != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(l10n.topupClaimSnack(formatNumber(r.gems))),
                        ));
                      }
                    }
                  : null,
              child: Text(l10n.topupClaim),
            ),
    );
  }
}
