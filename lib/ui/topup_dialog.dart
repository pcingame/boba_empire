import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_controller.dart';
import '../state/game_providers.dart';
import 'vip_how_to_dialog.dart';

/// Mốc nạp & cấp VIP theo tổng nạp tích lũy (xem core/topup.dart).
Future<void> showTopupDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _TopupDialog());

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
      final points = ref.read(gameControllerProvider).vipExp;
      ref.read(flairCacheProvider.notifier).reportVip(points);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final level = topupVipLevel(s.vipExp);
    final bonus = (vipIncomeBonusPerLevel * 100).round();

    final next = level < topupTiers.length ? topupTiers[level].exp : null;
    final prev = level > 0 ? topupTiers[level - 1].exp : 0;
    final canBuy = canBuyVipExp(s.gems, s.vipExpFromGems);
    final capped = s.vipExpFromGems + vipExpBlock > vipExpGemCap;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l10n.topupTitle)),
          IconButton(
            key: const Key('vip-how-to-button'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.vipHowToTitle,
            onPressed: () => showVipHowTo(context),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (level > 0) VipTag(level: level) else const Text('—'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${level > 0 ? '${vipName(l10n, level)} · ' : ''}'
                      '${l10n.topupSummary(formatNumber(s.vipExp.toDouble()))}',
                    ),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    key: const Key('vip-exp-bar'),
                    value: ((s.vipExp - prev) / (next - prev)).clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
                Text(
                  '${formatNumber(s.vipExp.toDouble())} / ${formatNumber(next.toDouble())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                l10n.topupBuff(bonus, level * bonus),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                l10n.topupNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('vip-buy-exp'),
                  onPressed: canBuy
                      ? () {
                          if (controller.buyVipExp()) {
                            ref
                                .read(flairCacheProvider.notifier)
                                .reportVip(
                                  ref.read(gameControllerProvider).vipExp,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.vipBuyExpSnack(vipExpBlock)),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    l10n.vipBuyExp(
                      vipExpBlock,
                      formatNumber(vipExpBlockGems.toDouble()),
                    ),
                  ),
                ),
              ),
              if (capped)
                Text(
                  l10n.vipBuyExpCapped(formatNumber(vipExpGemCap.toDouble())),
                  key: const Key('vip-exp-capped'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const Divider(height: 24),
              Text(
                l10n.vipBenefitsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (level == 0)
                Text(
                  l10n.vipBenefitsLocked,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (final period in VipPeriod.values)
                  _benefitRow(context, l10n, period, level, controller),
              const Divider(height: 24),
              for (var i = 0; i < topupTiers.length; i++)
                _tierRow(
                  context,
                  l10n,
                  i,
                  s.vipExp,
                  s.topupClaimed.contains(i),
                  controller,
                ),
            ],
          ),
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

  Widget _benefitRow(
    BuildContext context,
    AppLocalizations l10n,
    VipPeriod period,
    int level,
    GameController controller,
  ) {
    final b = vipBenefit(period, level)!;
    final claimed = controller.vipBenefitClaimed(period);
    final label = switch (period) {
      VipPeriod.daily => l10n.vipDaily,
      VipPeriod.weekly => l10n.vipWeekly,
      VipPeriod.monthly => l10n.vipMonthly,
    };
    return ListTile(
      key: Key('vip-benefit-${period.name}'),
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        '+${formatNumber(b.gems)} 💎${b.accessory == null ? '' : '  ${l10n.topupAccessory}'}',
      ),
      trailing: claimed
          ? Text(l10n.topupClaimed)
          : FilledButton.tonal(
              key: Key('vip-claim-${period.name}'),
              onPressed: () {
                final r = controller.claimVipBenefit(period);
                if (r != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.topupClaimSnack(formatNumber(r.gems))),
                    ),
                  );
                }
              },
              child: Text(l10n.topupClaim),
            ),
    );
  }

  Widget _tierRow(
    BuildContext context,
    AppLocalizations l10n,
    int i,
    int points,
    bool claimed,
    GameController controller,
  ) {
    final t = topupTiers[i];
    final reached = points >= t.exp;
    return ListTile(
      key: Key('topup-tier-$i'),
      contentPadding: EdgeInsets.zero,
      leading: VipTag(level: i + 1),
      title: Text('${vipName(l10n, i + 1)} · ${l10n.topupTier(t.exp)}'),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.topupClaimSnack(formatNumber(r.gems)),
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              child: Text(l10n.topupClaim),
            ),
    );
  }
}
