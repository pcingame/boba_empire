/// Khách quen: danh sách 12 người quen, 4 người ghé mỗi ngày; phục vụ bằng cách chọn đồ uống (xem core/regulars.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/daily.dart';
import '../core/format.dart';
import '../core/regulars.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';
import 'widgets/chibi_customer.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/reward_burst.dart';
import 'widgets/stagger_in.dart';

Future<void> showRegulars(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _RegularsDialog());

class _RegularsDialog extends ConsumerWidget {
  const _RegularsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final today = dayIndex(ref.watch(clockProvider)());
    final visiting = regularsVisiting(today);
    final served = g.regularDay == today ? g.regularServed : const <int>[];
    // Khách đang ghé lên đầu danh sách.
    final order = [
      ...visiting,
      for (var i = 0; i < regularCount; i++)
        if (!visiting.contains(i)) i,
    ];
    return AlertDialog(
      title: Text(l10n.regularsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(shrinkWrap: true, children: [
          Text(l10n.regularsIntro, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (var n = 0; n < order.length; n++)
            StaggerIn(
              index: n,
              child: _RegularTile(
                i: order[n],
                points: regularPoints(g.regularPoints, order[n]),
                visiting: visiting.contains(order[n]),
                served: served.contains(order[n]),
                day: today,
              ),
            ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}

class _RegularTile extends ConsumerWidget {
  const _RegularTile({required this.i, required this.points, required this.visiting, required this.served, required this.day});

  final int i;
  final int points;
  final bool visiting;
  final bool served;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final level = regularLevelOf(points);
    final maxed = level >= regularMaxLevel;
    final from = level == 0 ? 0 : regularLevelPoints[level - 1];
    final to = maxed ? from : regularLevelPoints[level];
    final canServe = visiting && !served;
    return Builder(builder: (tileCtx) {
      return ClayTile(
        key: Key('regular-$i'),
        onTap: canServe ? () => _pick(tileCtx, ref) : null,
        child: Row(children: [
          Opacity(
            opacity: visiting ? 1 : 0.5,
            child: ChibiCustomer(seed: 100 + i, mood: served ? CustomerMood.delighted : CustomerMood.waiting, size: 52),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(regularNames[i], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
              PulseOnIncrease(
                value: level,
                peak: 1.2,
                child: Text('${'❤️' * level}${'🤍' * (regularMaxLevel - level)}', style: const TextStyle(fontSize: 12)),
              ),
              if (!maxed)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: (points - from) / (to - from), minHeight: 5),
                ),
              Text(
                level >= 1 ? l10n.regularsWants(regularDrinks[regularFavorite(i)]) : l10n.regularsUnknown,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ]),
          ),
          const SizedBox(width: 6),
          if (served)
            Flexible(child: Text(l10n.regularsServed, key: Key('regular-served-$i'), textAlign: TextAlign.end, style: theme.textTheme.labelSmall))
          else if (visiting)
            Flexible(
              child: Text(l10n.regularsVisiting,
                  key: Key('regular-visiting-$i'),
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.w800)),
            ),
        ]),
      );
    });
  }

  Future<void> _pick(BuildContext tileCtx, WidgetRef ref) async {
    final l10n = AppLocalizations.of(tileCtx)!;
    final ctl = ref.read(gameControllerProvider.notifier);
    final cost = regularServeCost(ctl.petIncome);
    final drink = await showDialog<int>(
      context: tileCtx,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regularsPick(formatNumber(cost), regularNames[i]), style: const TextStyle(fontSize: 16)),
        content: Wrap(alignment: WrapAlignment.center, children: [
          for (final d in regularOptions(i, day))
            InkWell(
              key: Key('regular-drink-$d'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(ctx).pop(d),
              child: Padding(padding: const EdgeInsets.all(10), child: Text(regularDrinks[d], style: const TextStyle(fontSize: 38))),
            ),
        ]),
      ),
    );
    if (drink == null || !tileCtx.mounted) return;
    final before = regularLevelOf(points);
    final gain = ctl.serveRegular(i, drink);
    if (!tileCtx.mounted) return;
    final messenger = ScaffoldMessenger.of(tileCtx);
    if (gain == 0) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.regularsNoMoney)));
      return;
    }
    final after = regularLevelOf(points + gain);
    showRewardBurst(tileCtx,
        emojis: [regularDrinks[drink], if (gain == 2) '✨' else '💕'],
        label: after > before ? l10n.regularsLevelUp(after) : l10n.regularsGain(gain));
    if (gain == 2) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.regularsFav)));
    }
  }
}
