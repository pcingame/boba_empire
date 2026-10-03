/// Dialog Kỷ Nguyên (Ascension, prestige tầng 2) — mở từ dialog Nhượng quyền.
/// Xem Balance.ascension* và `ascend()` trong simulation.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/balance.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/one_shot_lottie.dart';

Future<void> showAscensionDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AscensionDialog(),
  );
}

int _cost(int base, int level) => (base * (1 << level));

class _AscensionDialog extends ConsumerWidget {
  const _AscensionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(
      gameControllerProvider.select((s) => s.ascensionPointsAvailable),
    );
    final progress =
        ref.watch(gameControllerProvider.select((s) => s.ascensionProgress));
    final canAscend = available > 0;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.ascensionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ascensionIntro),
            const SizedBox(height: 12),
            if (!canAscend) ...[
              Text(l10n.ascensionProgress((progress * 100).floor())),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: progress, minHeight: 8),
              ),
            ] else
              _row(l10n.ascensionPointsGain, l10n.ascensionPointsValue(available),
                  highlight: true),
            const SizedBox(height: 12),
            Text(
              l10n.ascensionWarning,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            const _AscensionShop(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('ascension-confirm'),
          onPressed: canAscend ? () => _askConfirm(context, ref, available) : null,
          child: Text(canAscend
              ? l10n.ascensionConfirm(available)
              : l10n.ascensionNotEnough),
        ),
      ],
    );
  }

  Future<void> _askConfirm(BuildContext context, WidgetRef ref, int available) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.ascensionTitle),
        content: Text(l10n.ascensionWarning),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('ascension-confirm-yes'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.ascensionConfirm(available)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) _confirm(context, ref);
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final gained = controller.doAscend();
    final drop = gained > 0 ? controller.lastAccessoryDrop : null;
    if (gained > 0) {
      HapticFeedback.heavyImpact();
      ref.read(audioServiceProvider).play(Sfx.prestige);
      playEffect(context, AnimAssets.fireworks, size: 320);
    }
    // Đóng cả dialog Nhượng quyền phía dưới (nó đang hiện số Sao đã reset).
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (gained > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            drop == null
                ? l10n.ascensionSuccess(gained)
                : '${l10n.ascensionSuccess(gained)}\n${accessoryRevealMessage(l10n, drop)}',
          ),
        ),
      );
    }
  }

  /// Flexible + ellipsis ở CẢ HAI bên — cùng lý do như `_row` trong
  /// prestige_dialog.dart (số lớn/nhãn dài ở id/th làm tràn RenderFlex).
  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: highlight
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AscensionShop extends ConsumerWidget {
  const _AscensionShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendable = ref.watch(
      gameControllerProvider.select((s) => s.ascensionPointsSpendable),
    );
    final incomeLv = ref
        .watch(gameControllerProvider.select((s) => s.ascensionIncomeLevel));
    final bonusLv = ref.watch(
        gameControllerProvider.select((s) => s.ascensionStarBonusLevel));
    final gainLv = ref.watch(
        gameControllerProvider.select((s) => s.ascensionStarGainLevel));
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = ref.read(gameControllerProvider.notifier);

    void buy(bool Function() action) {
      if (action()) {
        HapticFeedback.selectionClick();
        ref.read(audioServiceProvider).play(Sfx.buy);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        Text(l10n.ascensionShopTitle, style: theme.textTheme.titleMedium),
        Text(l10n.ascensionShopSpendable(spendable),
            style: theme.textTheme.bodySmall),
        _PerkRow(
          name: l10n.ascensionIncomeName,
          level: incomeLv,
          maxLevel: Balance.ascensionIncomeMaxLevel,
          desc: l10n.ascensionIncomeDesc(
              (Balance.ascensionIncomePerLevel * 100).round()),
          cost: _cost(Balance.ascensionIncomeBaseCost, incomeLv),
          spendable: spendable,
          onBuy: () => buy(controller.buyAscensionIncomeUpgrade),
        ),
        _PerkRow(
          name: l10n.ascensionStarBonusName,
          level: bonusLv,
          maxLevel: Balance.ascensionStarBonusMaxLevel,
          desc: l10n.ascensionStarBonusDesc(
              (Balance.ascensionStarBonusPerLevel * 100).round()),
          cost: _cost(Balance.ascensionStarBonusBaseCost, bonusLv),
          spendable: spendable,
          onBuy: () => buy(controller.buyAscensionStarBonusUpgrade),
        ),
        _PerkRow(
          name: l10n.ascensionStarGainName,
          level: gainLv,
          maxLevel: Balance.ascensionStarGainMaxLevel,
          desc: l10n.ascensionStarGainDesc(
              (Balance.ascensionStarGainPerLevel * 100).round()),
          cost: _cost(Balance.ascensionStarGainBaseCost, gainLv),
          spendable: spendable,
          onBuy: () => buy(controller.buyAscensionStarGainUpgrade),
        ),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.name,
    required this.level,
    required this.maxLevel,
    required this.desc,
    required this.cost,
    required this.spendable,
    required this.onBuy,
  });

  final String name;
  final int level;
  final int maxLevel;
  final String desc;
  final int cost;
  final int spendable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxed = level >= maxLevel;
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.gemItemLevel(name, level),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(desc, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Flexible + FittedBox: cùng lý do như _PerkRow ở prestige_dialog.dart.
          Flexible(
            child: FilledButton.tonal(
              key: Key('ascension-perk-$name'),
              onPressed: (!maxed && spendable >= cost) ? onBuy : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(maxed ? l10n.ascensionMaxed : l10n.ascensionCost(cost)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
