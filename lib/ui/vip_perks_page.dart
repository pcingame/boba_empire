/// Quyền lợi VIP: bảng so sánh 10 cấp (thu nhập, quà ngày/tuần/tháng, món mở ở Cửa hàng VIP, danh hiệu BXH),
/// đánh dấu cấp hiện tại và cho biết cấp kế còn thiếu bao nhiêu EXP (góp ý người chơi: "VIP khó hiểu").
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/topup.dart';
import '../core/vip_shop.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/flair.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/stagger_in.dart';

Future<void> showVipPerks(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _VipPerksDialog());

class _VipPerksDialog extends ConsumerWidget {
  const _VipPerksDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exp = ref.watch(gameControllerProvider.select((s) => s.vipExp));
    final level = topupVipLevel(exp);
    final maxed = level >= topupTiers.length;
    return AlertDialog(
      title: Text(l10n.vipPerksTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(shrinkWrap: true, children: [
          ClayTile(
            child: Text(
              maxed
                  ? l10n.vipPerksMax
                  : l10n.vipPerksNext(formatNumber((topupTiers[level].exp - exp).toDouble()), vipName(l10n, level + 1)),
              key: const Key('vip-perks-next'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < topupTiers.length; i++)
            StaggerIn(
              index: i,
              child: _LevelRow(
                level: i + 1,
                current: level == i + 1,
                reached: level >= i + 1,
                theme: theme,
                l10n: l10n,
              ),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.current, required this.reached, required this.theme, required this.l10n});

  final int level;
  final bool current;
  final bool reached;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final t = topupTiers[level - 1];
    final items = [for (final it in vipShopItems) if (it.minLevel == level) it.accessory.emoji];
    return Container(
      key: Key('vip-perks-row-$level'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: current
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: Opacity(
        opacity: reached ? 1 : 0.7,
        child: ClayTile(
          margin: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              VipTag(level: level),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${vipName(l10n, level)} · ${l10n.topupTier(t.exp)}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              if (reached) const Icon(Icons.check_circle, size: 18, color: Colors.green),
            ]),
            const SizedBox(height: 4),
            Text(
              // gen-l10n sắp tham số theo chữ cái: buff, daily, monthly, weekly.
              l10n.vipTierPerks(
                (vipIncomeBonusPerLevel * level * 100).round(),
                formatNumber(vipBenefit(VipPeriod.daily, level)!.gems),
                formatNumber(vipBenefit(VipPeriod.monthly, level)!.gems),
                formatNumber(vipBenefit(VipPeriod.weekly, level)!.gems),
              ),
              style: theme.textTheme.bodySmall,
            ),
            Text('+${formatNumber(t.gems)} 💎${t.accessory == null ? '' : '  ${l10n.topupAccessory}'}', style: theme.textTheme.bodySmall),
            if (items.isNotEmpty) Text('${l10n.vipPerksUnlocks}: ${items.join(' ')}', style: theme.textTheme.bodySmall),
            if (level == vipTitleMinLevel) Text('🏷️ ${l10n.vipPerksTitleTag}', style: theme.textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}
