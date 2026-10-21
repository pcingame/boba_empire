/// Nhân viên: 6 tổ trưởng, mỗi người tăng thu nhập một dải 3 giai đoạn (xem core/staff.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/format.dart';
import '../core/staff.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/reward_burst.dart';
import 'widgets/stagger_in.dart';

const _roleEmoji = ['☕', '🧋', '💰', '📋', '🔍', '👨‍🍳'];

Future<void> showStaff(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _StaffDialog());

class _StaffDialog extends ConsumerWidget {
  const _StaffDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final staff = ref.watch(gameControllerProvider.select((s) => s.staff));
    final money = ref.watch(gameControllerProvider.select((s) => s.money));
    final gems = ref.watch(gameControllerProvider.select((s) => s.gems));
    final roles = [l10n.staffRole0, l10n.staffRole1, l10n.staffRole2, l10n.staffRole3, l10n.staffRole4, l10n.staffRole5];
    return AlertDialog(
      title: Text(l10n.staffTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: staffCount,
          itemBuilder: (_, i) => StaggerIn(
            index: i,
            child: Builder(builder: (tileCtx) {
              final lvl = staffLevel(staff, i);
              final maxed = lvl >= staffMaxLevel;
              final cost = lvl == 0 ? 0.0 : staffUpgradeCost(i, lvl, Balance.generators);
              final can = !maxed && (lvl == 0 ? gems >= staffHireGems(i) : money >= cost);
              final pct = (lvl * staffPerLevel * 100).round();
              return ClayTile(
                key: Key('staff-$i'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Opacity(opacity: lvl == 0 ? 0.45 : 1, child: Text(_roleEmoji[i], style: const TextStyle(fontSize: 30))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(roles[i], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                    if (lvl > 0) PulseOnIncrease(value: lvl, peak: 1.2, child: Text('Lv $lvl', style: const TextStyle(fontWeight: FontWeight.w900))),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: lvl / staffMaxLevel),
                      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
                      builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.staffDesc(lvl == 0 ? (staffMaxLevel * staffPerLevel * 100).round() : pct),
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  if (!maxed)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        key: Key('staff-up-$i'),
                        onPressed: can
                            ? () {
                                if (ref.read(gameControllerProvider.notifier).upgradeStaff(i)) {
                                  showRewardBurst(tileCtx, emojis: [_roleEmoji[i], '✨'], label: '+${(staffPerLevel * 100).round()}%');
                                }
                              }
                            : null,
                        child: Text(lvl == 0 ? l10n.staffHire(staffHireGems(i)) : '🪙 ${formatNumber(cost)}', maxLines: 1),
                      ),
                    )
                  else
                    const Align(alignment: Alignment.centerRight, child: Icon(Icons.check_circle, color: Colors.green)),
                ]),
              );
            }),
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
