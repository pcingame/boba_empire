/// Chi nhánh các thành phố: mở/nâng cấp bằng Xu, mỗi chi nhánh tự tích doanh thu để "Thu về" (xem core/branches.dart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branches.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/game_snapshot.dart';
import 'branches_map.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';

Future<void> showBranches(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const BranchesPage()));

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

String _trim(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

String _perkLabel(AppLocalizations l, BranchPerk k, double v) => switch (k) {
  BranchPerk.cap => l.branchPerkCap(_trim(v)),
  BranchPerk.rush => l.branchPerkRush(_trim(v * 100)),
  BranchPerk.collect => l.branchPerkCollect(_trim(v * 100)),
  BranchPerk.discount => l.branchPerkDiscount(_trim(v * 100)),
  BranchPerk.rate => l.branchPerkRate(_trim(v * 100)),
};

class BranchesPage extends ConsumerStatefulWidget {
  const BranchesPage({super.key});

  @override
  ConsumerState<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends ConsumerState<BranchesPage> {
  /// Mặc định xem bản đồ; chuyển sang Danh sách để xem hết thẻ.
  bool _map = true;

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));

  void _collect(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final r = ref.read(gameControllerProvider.notifier).collectBranches();
    if (r.xu <= 0) return _snack(context, l10n.branchNothing);
    _snack(
      context,
      r.rushes > 0
          ? '${l10n.branchCollected(formatNumber(r.xu))}\n${l10n.branchRush(r.rushes)}'
          : l10n.branchCollected(formatNumber(r.xu)),
    );
  }

  void _showSets(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final s = ref.watch(gameControllerProvider);
          final names = {
            'asia': l10n.branchContAsia,
            'europe': l10n.branchContEurope,
            'africa': l10n.branchContAfrica,
            'northamerica': l10n.branchContNorthAmerica,
            'southamerica': l10n.branchContSouthAmerica,
            'oceania': l10n.branchContOceania,
            'space': branchCityName(l10n, 'moon'),
            'all': l10n.branchSetAll,
          };
          return ListView(
            key: const Key('branch-sets-sheet'),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            children: [
              Text(l10n.branchSetsTitle, style: Theme.of(ctx).textTheme.titleMedium),
              Text(l10n.branchSetsHint, style: Theme.of(ctx).textTheme.bodySmall),
              for (final set in branchSets)
                for (final tier in const [1, 2])
                  Builder(builder: (_) {
                    final key = branchSetKey(set, tier);
                    final done = branchSetDone(s.branchLevels, set, tier);
                    final complete = done == set.cityIds.length;
                    final claimed = s.branchSetClaims.contains(key);
                    final r = branchSetReward(set, tier);
                    return ListTile(
                      key: Key('branch-set-$key'),
                      dense: true,
                      title: Text(
                          '${names[set.id]} · ${tier == 1 ? l10n.branchSetTier1 : l10n.branchSetTier2}'),
                      subtitle: Text(
                          '$done/${set.cityIds.length} · ${l10n.branchSetReward(r.gems, r.seconds ~/ 3600)}'),
                      trailing: claimed
                          ? const Text('✅')
                          : FilledButton(
                              key: Key('branch-set-claim-$key'),
                              onPressed: complete
                                  ? () {
                                      if (ref.read(gameControllerProvider.notifier).claimBranchSet(key)) {
                                        _snack(ctx, l10n.branchSetClaimed(r.gems));
                                      }
                                    }
                                  : null,
                              child: Text(l10n.branchSetClaim),
                            ),
                    );
                  }),
            ],
          );
        },
      ),
    );
  }

  void _showManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheet) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final s = ref.watch(gameControllerProvider);
          final now = ref.read(clockProvider)();
          final left = s.branchManagerUntilMillis - now;
          final days = left > 0 ? (left / 86400000).ceil() : 0;
          return Padding(
            key: const Key('branch-manager-sheet'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🧑‍💼 ${l10n.branchManagerTitle}', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(l10n.branchManagerDesc(branchManagerCollectEverySeconds ~/ 60, branchManagerCapSeconds ~/ 3600)),
                const SizedBox(height: 6),
                Text(
                  days > 0 ? l10n.branchManagerActive(days) : l10n.branchManagerNone,
                  key: const Key('branch-manager-status'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  key: const Key('branch-manager-hire'),
                  onPressed: () {
                    final ok = ref.read(gameControllerProvider.notifier).hireBranchManager();
                    if (!ok) _snack(ctx, l10n.branchManagerFail);
                  },
                  child: Text(l10n.branchManagerHire(branchManagerDays, branchManagerGems)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Mở/nâng cấp chi nhánh. Trả true nếu VỪA MỞ chi nhánh mới (để đóng bảng cho thấy hiệu ứng khai trương trên bản đồ).
  bool _act(BuildContext context, WidgetRef ref, BranchCity c) {
    final l10n = AppLocalizations.of(context)!;
    final gala = ref.read(gameControllerProvider.notifier).upgradeBranch(c.id);
    if (gala == null) {
      _snack(context, l10n.branchNotEnough);
      return false;
    }
    if (gala > 0) _snack(context, l10n.branchGala(formatNumber(gala)));
    return gala > 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final s = ref.watch(gameControllerProvider);
    final now = ref.read(clockProvider)();
    final income = ref.read(gameControllerProvider.notifier).branchIncome;
    final manager = s.branchManagerUntilMillis > now;
    var pendingSec = 0.0;
    for (final c in branchCities) {
      pendingSec += branchPendingIncomeSeconds(
        s.branchLevels,
        s.branchSince,
        c,
        now,
        manager: manager,
      );
    }
    final pendingXu = income.isFinite ? pendingSec * income : 0.0;
    final opened = branchCities
        .where((c) => branchLevel(s.branchLevels, c.id) > 0)
        .length;
    return PhoneWidth(
      child: Scaffold(
        key: const Key('branches'),
        appBar: AppBar(
          title: Text(l10n.branchTitle),
          actions: [
            IconButton(
              key: const Key('branch-sets-btn'),
              tooltip: l10n.branchSetsTitle,
              icon: Badge(
                isLabelVisible:
                    branchSetsClaimable(s.branchLevels, s.branchSetClaims).isNotEmpty,
                smallSize: 8,
                child: const Text('🏅', style: TextStyle(fontSize: 22)),
              ),
              onPressed: () => _showSets(context),
            ),
            IconButton(
              key: const Key('branch-manager-btn'),
              tooltip: l10n.branchManagerTitle,
              icon: const Text('🧑‍💼', style: TextStyle(fontSize: 22)),
              onPressed: () => _showManager(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(
                        '🗺️ ${l10n.branchViewMap}',
                        key: const Key('branch-view-map'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(
                        '📋 ${l10n.branchViewList}',
                        key: const Key('branch-view-list'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  selected: {_map},
                  onSelectionChanged: (v) => setState(() => _map = v.first),
                ),
              ),
            ),
            Expanded(
              child: _map
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.branchPendingTotal(
                                      formatNumber(pendingXu),
                                    ),
                                    key: const Key('branch-total'),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                key: const Key('branch-collect'),
                                onPressed: pendingSec > 0
                                    ? () => _collect(context, ref)
                                    : null,
                                child: Text('💰 ${l10n.branchCollectAll}'),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.branchCount(opened, branchCities.length),
                              key: const Key('branch-count'),
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: BranchesMap(
                              levels: s.branchLevels,
                              since: s.branchSince,
                              stage: s.stage,
                              now: now,
                              manager: manager,
                              nameOf: (id) => branchCityName(l10n, id),
                              onPin: (c) => _showCity(context, c),
                              continentNames: [
                                l10n.branchContAsia,
                                l10n.branchContEurope,
                                l10n.branchContAfrica,
                                l10n.branchContNorthAmerica,
                                l10n.branchContSouthAmerica,
                                l10n.branchContOceania,
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      children: [
                        ClayCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text(
                                l10n.branchIntro,
                                key: const Key('branch-intro'),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Dải biểu tượng: mỗi thành phố một chấm (sáng = đã mở) để thấy tiến độ sưu tập.
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  for (final c in branchCities)
                                    Opacity(
                                      opacity:
                                          branchLevel(s.branchLevels, c.id) > 0
                                          ? 1
                                          : 0.25,
                                      child: Text(
                                        c.emoji,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.branchCount(opened, branchCities.length),
                                key: const Key('branch-count'),
                                style: theme.textTheme.labelMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.branchPerkHint,
                                key: const Key('branch-perk-hint'),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.branchPendingTotal(
                                    formatNumber(pendingXu),
                                  ),
                                  key: const Key('branch-total'),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                key: const Key('branch-collect'),
                                onPressed: pendingSec > 0
                                    ? () => _collect(context, ref)
                                    : null,
                                child: Text('💰 ${l10n.branchCollectAll}'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final c in branchCities)
                          _Card(
                            c: c,
                            s: s,
                            now: now,
                            income: income,
                            onAct: () => _act(context, ref, c),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bấm ghim trên bản đồ → bảng dưới với đúng thẻ chi nhánh (mở/nâng cấp như ở Danh sách), cập nhật theo Xu.
  void _showCity(BuildContext context, BranchCity c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Consumer(
        builder: (ctx, ref, _) {
          final s = ref.watch(gameControllerProvider);
          final now = ref.read(clockProvider)();
          final income = ref.read(gameControllerProvider.notifier).branchIncome;
          return SingleChildScrollView(
            key: const Key('branch-sheet'),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            child: _Card(
              c: c,
              s: s,
              now: now,
              income: income,
              onAct: () {
                if (_act(ctx, ref, c)) Navigator.pop(sheet);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.c,
    required this.s,
    required this.now,
    required this.income,
    required this.onAct,
  });
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
    final cost = maxed
        ? 0.0
        : branchCost(
            c,
            lvl + 1,
            income,
            discount: branchPerk(levels, BranchPerk.discount),
          );
    final manager = s.branchManagerUntilMillis > now;
    final pendingSec = branchPendingIncomeSeconds(levels, since, c, now, manager: manager);
    final frac = branchFill(levels, since, c, now, manager: manager);
    final tint = Color(c.color);
    return Container(
      key: Key('branch-card-${c.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            tint.withValues(alpha: locked ? 0.08 : 0.26),
            tint.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tint.withValues(alpha: locked ? 0.2 : 0.55),
          width: maxed ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Landmark trong vòng màu + huy hiệu signature (món đặc trưng) ở góc dưới.
                SizedBox(
                  width: 60,
                  height: 56,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.9),
                              tint.withValues(alpha: 0.55),
                            ],
                          ),
                          border: Border.all(color: tint, width: 2),
                        ),
                        child: Text(
                          locked ? '🔒' : c.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
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
                          child: Text(
                            c.signature,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branchCityName(l10n, c.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        locked
                            ? l10n.branchNeedStage(c.minStage)
                            : lvl == 0
                            ? l10n.branchRate(
                                (branchRate(c, 1) * 100).toStringAsFixed(1),
                              )
                            : '${l10n.branchLevel(lvl, branchMaxLevel)} · ${l10n.branchRate((branchRate(c, lvl) * 100).toStringAsFixed(1))}',
                        key: Key('branch-info-${c.id}'),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!locked)
                        Text(
                          '${c.signature} ${_perkLabel(l10n, c.perk, branchPerkValue(c, lvl == 0 ? branchMaxLevel : lvl))}${lvl == 0 ? ' · ${l10n.branchPerkMax}' : ''}',
                          key: Key('branch-perk-${c.id}'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: lvl == 0 ? null : Color(c.color),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!locked) ...[
                        const SizedBox(height: 4),
                        Row(
                          key: Key('branch-pips-${c.id}'),
                          children: [
                            for (var i = 1; i <= branchMaxLevel; i++)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= lvl
                                      ? tint
                                      : tint.withValues(alpha: 0.2),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (lvl > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 8,
                  color: tint,
                  backgroundColor: tint.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                frac >= 1
                    ? l10n.branchFull
                    : l10n.branchPending(
                        formatNumber(income.isFinite ? pendingSec * income : 0),
                      ),
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
                    child: Text(
                      lvl == 0
                          ? l10n.branchOpen(formatNumber(cost))
                          : l10n.branchUpgrade(formatNumber(cost)),
                    ),
                  ),
                ),
              ),
            ] else if (maxed)
              Align(
                alignment: Alignment.centerRight,
                child: Text('★ ${l10n.branchMaxed}'),
              ),
          ],
        ),
      ),
    );
  }
}
