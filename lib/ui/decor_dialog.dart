/// Trang trí quán: cảnh cắt ngang 8 ô, chạm ô để đặt/mua/gỡ món (xem core/decor.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/decor.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/bobbing.dart';
import 'widgets/motion.dart' show reduceMotion;
import 'widgets/reward_burst.dart';

Future<void> showDecor(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _DecorDialog());

String _slotLabel(AppLocalizations l, DecorSlotKind k) => switch (k) {
      DecorSlotKind.sign => l.decorSlotSign,
      DecorSlotKind.wall => l.decorSlotWall,
      DecorSlotKind.counter => l.decorSlotCounter,
      DecorSlotKind.floor => l.decorSlotFloor,
    };

String _themeName(AppLocalizations l, int t) => switch (t) {
      0 => l.decorTheme0,
      1 => l.decorTheme1,
      2 => l.decorTheme2,
      _ => l.decorTheme3,
    };

class _DecorDialog extends ConsumerWidget {
  const _DecorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final theme = Theme.of(context);
    final bonus = (decorIncomeMultiplier(g.decorPlaced) - 1) * 100;
    final done = decorCompleteThemes(g.decorPlaced);
    Widget row(DecorSlotKind k) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < decorSlotCount[k]!; i++)
            Padding(padding: const EdgeInsets.all(4), child: _Slot(slotKey: '${k.name}#$i', placed: g.decorPlaced['${k.name}#$i'], glow: done)),
        ]);
    return AlertDialog(
      title: Text(l10n.decorTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.decorHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: [for (final k in DecorSlotKind.values) row(k)]),
          ),
          const SizedBox(height: 8),
          Text('+${bonus.toStringAsFixed(1)}% ${l10n.decorBonus}',
              key: const Key('decor-bonus'), style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 4, children: [
            for (var t = 0; t < decorThemeCount; t++)
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text('${decorThemeEmoji[t]} ${_themeName(l10n, t)} ${decorThemeCountPlaced(g.decorPlaced, t)}/$decorThemeSize'),
                backgroundColor: done.contains(t) ? theme.colorScheme.primaryContainer : null,
              ),
          ]),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}

class _Slot extends ConsumerWidget {
  const _Slot({required this.slotKey, required this.placed, required this.glow});
  final String slotKey;
  final String? placed;
  final Set<int> glow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final item = placed == null ? null : decorById(placed!);
    final kind = decorSlotKind(slotKey)!;
    final shine = item != null && glow.contains(item.theme);
    Widget face = item == null
        ? Icon(Icons.add_rounded, color: theme.colorScheme.outline)
        : Text(item.emoji, style: const TextStyle(fontSize: 28));
    if (item != null && kind == DecorSlotKind.floor && !reduceMotion) face = Bobbing(amplitude: 2, child: face);
    return Semantics(
      button: true,
      child: InkWell(
        key: Key('decor-slot-$slotKey'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(context, ref),
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: item == null ? null : theme.colorScheme.surface,
            border: Border.all(
              color: shine ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: shine ? 2.5 : 1,
            ),
            boxShadow: shine ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.5), blurRadius: 10)] : null,
          ),
          child: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
            child: KeyedSubtree(key: ValueKey(placed), child: face),
          ),
        ),
      ),
    );
  }

  void _pick(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _Picker(slotKey: slotKey, anchor: context),
    );
  }
}

class _Picker extends ConsumerWidget {
  const _Picker({required this.slotKey, required this.anchor});
  final String slotKey;
  final BuildContext anchor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final ctl = ref.read(gameControllerProvider.notifier);
    final kind = decorSlotKind(slotKey)!;
    final cur = g.decorPlaced[slotKey];
    final xuPrice = ctl.decorXuPrice;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_slotLabel(l10n, kind), style: Theme.of(context).textTheme.titleMedium),
          for (final it in decorItems.where((d) => d.kind == kind))
            Builder(builder: (_) {
              final owned = g.decorOwned.contains(it.id);
              final here = cur == it.id;
              final canPay = it.gems > 0 ? g.gems >= it.gems : g.money >= xuPrice;
              return ListTile(
                key: Key('decor-item-${it.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Text(it.emoji, style: const TextStyle(fontSize: 28)),
                title: Text('${decorThemeEmoji[it.theme]} ${_themeName(l10n, it.theme)}', maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: here
                    ? const Icon(Icons.check_circle_rounded)
                    : owned
                        ? FilledButton(
                            key: Key('decor-place-${it.id}'),
                            onPressed: () {
                              ctl.placeDecor(slotKey, it.id);
                              showRewardBurst(anchor, emojis: [it.emoji, '✨'], label: '');
                              Navigator.of(context).pop();
                            },
                            child: Text(l10n.decorPlace))
                        : FilledButton.tonal(
                            key: Key('decor-buy-${it.id}'),
                            onPressed: canPay
                                ? () {
                                    if (ctl.buyDecor(it.id)) {
                                      ctl.placeDecor(slotKey, it.id);
                                      showRewardBurst(anchor, emojis: [it.emoji, '✨'], label: '');
                                      Navigator.of(context).pop();
                                    }
                                  }
                                : null,
                            child: Text(it.gems > 0 ? '${it.gems} 💎' : '${formatNumber(xuPrice)} 🪙')),
              );
            }),
          if (cur != null)
            TextButton(
              key: const Key('decor-remove'),
              onPressed: () {
                ctl.clearDecor(slotKey);
                Navigator.of(context).pop();
              },
              child: Text(l10n.decorRemove),
            ),
        ]),
      ),
    );
  }
}
