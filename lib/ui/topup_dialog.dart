import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../core/vip_shop.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_controller.dart';
import '../state/game_providers.dart';
import 'vip_how_to_dialog.dart';
import 'vip_perks_page.dart';
import 'widgets/vip_shine.dart';
import 'vip_shop_dialog.dart';
import 'email_gate.dart';
import 'vip_leaderboard_page.dart';
import 'widgets/app_dialog.dart';

/// Mốc nạp & cấp VIP theo tổng nạp tích lũy (xem core/topup.dart).
Future<void> showTopupDialog(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _TopupDialog());

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
                  if (level > 0) VipShine(radius: 6, child: VipTag(level: level)) else const Text('—'),
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
            // gen-l10n sắp tham số theo THỨ TỰ CHỮ CÁI: topupBuff(now, percent).
              Text(
                l10n.topupBuff(level * bonus, bonus),
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
                            showVipBurst(context);
                            ref
                                .read(flairCacheProvider.notifier)
                                .reportVip(
                                  ref.read(gameControllerProvider).vipExp,
                                );
                            ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
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
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('vip-perks-open'),
                  onPressed: () => showVipPerks(context),
                  icon: const Icon(Icons.workspace_premium),
                  label: Text(l10n.vipPerksOpen),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('vip-shop-open'),
                  onPressed: () => showVipShop(context),
                  child: Text(
                      '${l10n.vipShopOpen} · ${l10n.vipCoinsLabel(formatNumber(s.vipCoins.toDouble()))}'),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('vip-open-leaderboard'),
                  onPressed: () async {
                if (!await ensureOnlineLinked(context) || !context.mounted) return;
                showVipLeaderboard(context);
              },
                  icon: const Icon(Icons.leaderboard),
                  label: Text(l10n.vipLbOpen),
                ),
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
              if (level >= vipTitleMinLevel) ...[
                const Divider(height: 24),
                Text(
                  l10n.vipTitlePick,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                _titlePicker(l10n, level, s.vipTitleChoice, controller),
              ],
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

  /// Chọn danh hiệu hiện dưới tên ở BXH: tự động (cấp cao nhất) · ẩn · hoặc danh hiệu của
  /// bất kỳ cấp nào đã đạt.
  Widget _titlePicker(
      AppLocalizations l10n, int level, int choice, GameController controller) {
    void pick(int v) {
      if (!controller.setVipTitle(v)) return;
      ref
          .read(flairCacheProvider.notifier)
          .reportVip(ref.read(gameControllerProvider).vipExp);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 0,
      children: [
        ChoiceChip(
          key: const Key('vip-title-auto'),
          label: Text(l10n.vipTitleAuto),
          selected: choice == -1,
          onSelected: (_) => pick(-1),
        ),
        for (var n = 1; n <= level; n++)
          ChoiceChip(
            key: Key('vip-title-$n'),
            label: Text(vipName(l10n, n)),
            selected: choice == n,
            onSelected: (_) => pick(n),
          ),
        ChoiceChip(
          key: const Key('vip-title-0'),
          label: Text(l10n.vipTitleHide),
          selected: choice == 0,
          onSelected: (_) => pick(0),
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
        '+${formatNumber(b.gems)} 💎 +${vipCoinsFor(period, level)} 🛍️${b.accessory == null ? '' : '  ${l10n.topupAccessory}'}',
      ),
      trailing: claimed
          ? Text(l10n.topupClaimed)
          : FilledButton.tonal(
              key: Key('vip-claim-${period.name}'),
              onPressed: () {
                final r = controller.claimVipBenefit(period);
                if (r != null) {
                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                    SnackBar(
                      content: Text(l10n.vipBenefitSnack(r.coins, formatNumber(r.gems))),
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('+${formatNumber(t.gems)} 💎${t.accessory == null ? '' : '  ${l10n.topupAccessory}'}'),
          Text(
            // gen-l10n sắp tham số theo chữ cái: buff, daily, monthly, weekly.
            l10n.vipTierPerks(
              (vipIncomeBonusPerLevel * (i + 1) * 100).round(),
              formatNumber(vipBenefit(VipPeriod.daily, i + 1)!.gems),
              formatNumber(vipBenefit(VipPeriod.monthly, i + 1)!.gems),
              formatNumber(vipBenefit(VipPeriod.weekly, i + 1)!.gems),
            ),
            key: Key('topup-tier-perks-$i'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: claimed
          ? Text(l10n.topupClaimed)
          : FilledButton.tonal(
              key: Key('topup-claim-$i'),
              onPressed: reached
                  ? () {
                      final r = controller.claimTopupTier(i);
                      if (r != null) {
                        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
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
