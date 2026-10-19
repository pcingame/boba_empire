/// Chi nhánh các thành phố: mở/nâng cấp bằng Xu, mỗi chi nhánh tự tích doanh thu để "Thu về" (xem core/branches.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branches.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/game_snapshot.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showBranches(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BranchesPage()));

String branchCityName(AppLocalizations l, String id) => switch (id) {
      'saigon' => l.branchCitySaigon,
      'hanoi' => l.branchCityHanoi,
      'tokyo' => l.branchCityTokyo,
      'seoul' => l.branchCitySeoul,
      'bangkok' => l.branchCityBangkok,
      'paris' => l.branchCityParis,
      'newyork' => l.branchCityNewyork,
      'danang' => l.branchCityDanang,
      'singapore' => l.branchCitySingapore,
      'hongkong' => l.branchCityHongkong,
      'sydney' => l.branchCitySydney,
      'istanbul' => l.branchCityIstanbul,
      'london' => l.branchCityLondon,
      'rio' => l.branchCityRio,
      'cairo' => l.branchCityCairo,
      'moon' => l.branchCityMoon,
      _ => l.branchCityDubai,
    };

class BranchesPage extends ConsumerWidget {
  const BranchesPage({super.key});

  void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _collect(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final r = ref.read(gameControllerProvider.notifier).collectBranches();
    if (r.xu <= 0) return _snack(context, l10n.branchNothing);
    _snack(context, r.rushes > 0
        ? '${l10n.branchCollected(formatNumber(r.xu))}\n${l10n.branchRush(r.rushes)}'
        : l10n.branchCollected(formatNumber(r.xu)));
  }

  void _act(BuildContext context, WidgetRef ref, BranchCity c) {
    final l10n = AppLocalizations.of(context)!;
    final gala = ref.read(gameControllerProvider.notifier).upgradeBranch(c.id);
    if (gala == null) return _snack(context, l10n.branchNotEnough);
    if (gala > 0) _snack(context, l10n.branchGala(formatNumber(gala)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final s = ref.watch(gameControllerProvider);
    final now = ref.read(clockProvider)();
    final income = ref.read(gameControllerProvider.notifier).branchIncome;
    var pendingSec = 0.0;
    for (final c in branchCities) {
      pendingSec += branchPendingIncomeSeconds(s.branchLevels, s.branchSince, c, now);
    }
    final pendingXu = income.isFinite ? pendingSec * income : 0.0;
    final opened = branchCities.where((c) => branchLevel(s.branchLevels, c.id) > 0).length;
    return PhoneWidth(
      child: Scaffold(
        key: const Key('branches'),
        appBar: AppBar(title: Text(l10n.branchTitle)),
        body: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), children: [
          ClayCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Text(l10n.branchIntro, key: const Key('branch-intro'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              // Dải biểu tượng: mỗi thành phố một chấm (sáng = đã mở) để thấy tiến độ sưu tập.
              Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 2, children: [
                for (final c in branchCities)
                  Opacity(
                    opacity: branchLevel(s.branchLevels, c.id) > 0 ? 1 : 0.25,
                    child: Text(c.emoji, style: const TextStyle(fontSize: 18)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(l10n.branchCount(opened, branchCities.length),
                  key: const Key('branch-count'), style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.branchPendingTotal(formatNumber(pendingXu)),
                    key: const Key('branch-total'), style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('branch-collect'),
                onPressed: pendingSec > 0 ? () => _collect(context, ref) : null,
                child: Text('💰 ${l10n.branchCollectAll}'),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          for (final c in branchCities) _Card(c: c, s: s, now: now, income: income, onAct: () => _act(context, ref, c)),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.c, required this.s, required this.now, required this.income, required this.onAct});
  final BranchCity c;
  final GameSnapshot s;
  final int now;
  final double income;
  final VoidCallback onAct;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final levels = s.branchLevels;
    final since = s.branchSince;
    final stage = s.stage;
    final money = s.money;
    final lvl = branchLevel(levels, c.id);
    final locked = lvl == 0 && stage < c.minStage;
    final maxed = lvl >= branchMaxLevel;
    final cost = maxed ? 0.0 : branchCost(c, lvl + 1, income);
    final pendingSec = branchPendingIncomeSeconds(levels, since, c, now);
    final frac = lvl == 0 ? 0.0 : (pendingSec / branchRate(c, lvl) / branchCapSeconds).clamp(0.0, 1.0);
    final tint = Color(c.color);
    return Container(
      key: Key('branch-card-${c.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [tint.withValues(alpha: locked ? 0.08 : 0.26), tint.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: locked ? 0.2 : 0.55), width: maxed ? 2.5 : 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Landmark trong vòng màu + huy hiệu signature (món đặc trưng) ở góc dưới.
            SizedBox(
              width: 60,
              height: 56,
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.9), tint.withValues(alpha: 0.55)]),
                    border: Border.all(color: tint, width: 2),
                  ),
                  child: Text(locked ? '🔒' : c.emoji, style: const TextStyle(fontSize: 28)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    key: Key('branch-sig-${c.id}'),
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: tint, width: 1.5),
                    ),
                    child: Text(c.signature, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(branchCityName(l10n, c.id), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(
                  locked
                      ? l10n.branchNeedStage(c.minStage)
                      : lvl == 0
                          ? l10n.branchRate((branchRate(c, 1) * 100).toStringAsFixed(1))
                          : '${l10n.branchLevel(lvl, branchMaxLevel)} · ${l10n.branchRate((branchRate(c, lvl) * 100).toStringAsFixed(1))}',
                  key: Key('branch-info-${c.id}'),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!locked) ...[
                  const SizedBox(height: 4),
                  Row(key: Key('branch-pips-${c.id}'), children: [
                    for (var i = 1; i <= branchMaxLevel; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= lvl ? tint : tint.withValues(alpha: 0.2),
                        ),
                      ),
                  ]),
                ],
              ]),
            ),
          ]),
          if (lvl > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: frac, minHeight: 8, color: tint, backgroundColor: tint.withValues(alpha: 0.18)),
            ),
            const SizedBox(height: 2),
            Text(
              frac >= 1 ? l10n.branchFull : l10n.branchPending(formatNumber(income.isFinite ? pendingSec * income : 0)),
              key: Key('branch-pending-${c.id}'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (!locked && !maxed) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: FilledButton.tonal(
                  key: Key('branch-act-${c.id}'),
                  onPressed: money >= cost ? onAct : null,
                  child: Text(lvl == 0 ? l10n.branchOpen(formatNumber(cost)) : l10n.branchUpgrade(formatNumber(cost))),
                ),
              ),
            ),
          ] else if (maxed)
            Align(alignment: Alignment.centerRight, child: Text('★ ${l10n.branchMaxed}')),
        ]),
      ),
    );
  }
}
