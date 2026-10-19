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
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scroll) => Consumer(
          builder: (ctx, ref, _) {
            final l10n = AppLocalizations.of(ctx)!;
            final theme = Theme.of(ctx);
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
            String hours(int sec) {
              final h = sec / 3600;
              return h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);
            }

            Widget tierRow(BranchSet set, int tier) {
              final key = branchSetKey(set, tier);
              final done = branchSetDone(s.branchLevels, set, tier);
              final total = set.cityIds.length;
              final claimed = s.branchSetClaims.contains(key);
              final r = branchSetReward(set, tier);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  key: Key('branch-set-$key'),
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tier == 1 ? l10n.branchSetTier1 : l10n.branchSetTier2} · $done/$total',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(value: done / total, minHeight: 6),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.branchSetReward(r.gems, hours(r.seconds)),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (claimed)
                      const Text('✅', style: TextStyle(fontSize: 22))
                    else
                      FilledButton(
                        key: Key('branch-set-claim-$key'),
                        onPressed: done == total
                            ? () {
                                if (ref.read(gameControllerProvider.notifier).claimBranchSet(key)) {
                                  _snack(ctx, l10n.branchSetClaimed(r.gems));
                                }
                              }
                            : null,
                        child: Text(l10n.branchSetClaim),
                      ),
                  ],
                ),
              );
            }

            return ListView(
              key: const Key('branch-sets-sheet'),
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              children: [
                Text('🏅 ${l10n.branchSetsTitle}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(l10n.branchSetsHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                for (final set in branchSets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClayCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(names[set.id]!, style: theme.textTheme.titleSmall),
                          tierRow(set, 1),
                          tierRow(set, 2),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showQuests(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final theme = Theme.of(ctx);
          final s = ref.watch(gameControllerProvider);
          final today = s.branchQuestDayKey == branchQuestDay(ref.read(clockProvider)());
          final prog = today ? s.branchQuestProgress : const [0, 0, 0, 0];
          final mask = today ? s.branchQuestClaimed : 0;
          final names = [
            l10n.branchQuest0(branchQuestTargets[0]),
            l10n.branchQuest1(branchQuestTargets[1]),
            l10n.branchQuest2(branchQuestTargets[2]),
            l10n.branchQuest3(branchQuestTargets[3]),
            l10n.branchQuestAll,
          ];
          final claimable = branchQuestClaimable(prog, mask);
          Widget row(int i) {
            final done = i == 4
                ? [for (var k = 0; k < 4; k++) prog[k] >= branchQuestTargets[k]].every((b) => b)
                : prog[i] >= branchQuestTargets[i];
            final claimed = mask & (1 << i) != 0;
            final gems = i == 4 ? branchQuestAllGems : branchQuestGems;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                key: Key('branch-quest-$i'),
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(names[i], style: theme.textTheme.labelLarge),
                        if (i < 4) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (prog[i] / branchQuestTargets[i]).clamp(0.0, 1.0),
                              minHeight: 6,
                            ),
                          ),
                          Text('${prog[i].clamp(0, branchQuestTargets[i])}/${branchQuestTargets[i]}', style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (claimed)
                    const Text('✅', style: TextStyle(fontSize: 22))
                  else
                    FilledButton(
                      key: Key('branch-quest-claim-$i'),
                      onPressed: done && claimable.contains(i)
                          ? () {
                              if (ref.read(gameControllerProvider.notifier).claimBranchQuest(i)) {
                                _snack(ctx, l10n.branchSetClaimed(gems));
                              }
                            }
                          : null,
                      child: Text('$gems 💎'),
                    ),
                ],
              ),
            );
          }

          return Padding(
            key: const Key('branch-quest-sheet'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📜 ${l10n.branchQuestTitle}', style: theme.textTheme.titleMedium),
                Text(l10n.branchQuestHint, style: theme.textTheme.bodySmall),
                for (var i = 0; i < 5; i++) row(i),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSkins(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final cur = ref.watch(gameControllerProvider.select((s) => s.branchMapSkin));
          final names = [l10n.branchSkin0, l10n.branchSkin1, l10n.branchSkin2, l10n.branchSkin3];
          const icons = ['🗺️', '❄️', '🧧', '🌸'];
          return Padding(
            key: const Key('branch-skin-sheet'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎨 ${l10n.branchSkinTitle}', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < branchMapSkinCount; i++)
                      ChoiceChip(
                        key: Key('branch-skin-$i'),
                        label: Text('${icons[i]} ${names[i]}'),
                        selected: cur == i,
                        onSelected: (_) => ref.read(gameControllerProvider.notifier).setBranchMapSkin(i),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManager(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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
    final evSlot = branchEventSlot(now);
    final ev = s.branchEventClaimedSlot == evSlot ? null : branchEventFor(s.branchLevels, evSlot);
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
              key: const Key('branch-quest-btn'),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.branchQuestTitle,
              icon: Badge(
                isLabelVisible: s.branchQuestDayKey == branchQuestDay(now) &&
                    branchQuestClaimable(s.branchQuestProgress, s.branchQuestClaimed).isNotEmpty,
                smallSize: 8,
                child: const Text('📜', style: TextStyle(fontSize: 22)),
              ),
              onPressed: () => _showQuests(context),
            ),
            IconButton(
              key: const Key('branch-skin-btn'),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.branchSkinTitle,
              icon: const Text('🎨', style: TextStyle(fontSize: 22)),
              onPressed: () => _showSkins(context),
            ),
            IconButton(
              key: const Key('branch-sets-btn'),
              visualDensity: VisualDensity.compact,
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
              visualDensity: VisualDensity.compact,
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.branchEmpireBonus(
                                branchTotalLevels(s.branchLevels),
                                (branchTotalLevels(s.branchLevels) * branchIncomeBonusPerLevel * 100).toStringAsFixed(1),
                              ),
                              key: const Key('branch-empire-bonus'),
                              style: theme.textTheme.bodySmall,
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
                              skin: s.branchMapSkin,
                              eventCityId: ev?.cityId,
                              eventType: ev?.type ?? 0,
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
                                l10n.branchEmpireBonus(
                                  branchTotalLevels(s.branchLevels),
                                  (branchTotalLevels(s.branchLevels) * branchIncomeBonusPerLevel * 100).toStringAsFixed(1),
                                ),
                                key: const Key('branch-empire-bonus-list'),
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
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

/// Sự kiện đang diễn ra ở chi nhánh này (nhận 1 lần/ô 3h) + chuyên ngành khi đạt cấp tối đa.
class _CityExtras extends ConsumerWidget {
  const _CityExtras({required this.c, required this.s, required this.now});
  final BranchCity c;
  final GameSnapshot s;
  final int now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ctl = ref.read(gameControllerProvider.notifier);
    final lvl = branchLevel(s.branchLevels, c.id);
    final slot = branchEventSlot(now);
    final e = s.branchEventClaimedSlot == slot ? null : branchEventFor(s.branchLevels, slot);
    final spec = s.branchSpecs[c.id];
    void snack(String t) => ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t)));
    String evHours(int type) {
      final h = branchEventRewardSeconds(type, lvl) / 3600;
      return h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);
    }

    final evNames = [l10n.branchEvent0, l10n.branchEvent1, l10n.branchEvent2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e != null && e.cityId == c.id)
          Container(
            key: Key('branch-event-card-${c.id}'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(c.color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(branchEventEmoji[e.type], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.branchEventBody(evNames[e.type], evHours(e.type)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                FilledButton(
                  key: Key('branch-event-claim-${c.id}'),
                  onPressed: () {
                    final xu = ctl.claimBranchEvent();
                    if (xu != null) snack(l10n.branchEventClaimed(formatNumber(xu)));
                  },
                  child: Text(l10n.branchEventClaim),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.branchStallsTitle((branchStallBonusPerLevel * 100).round()),
          style: theme.textTheme.labelLarge,
        ),
        for (var i = 0; i < branchStallCount; i++)
          Builder(builder: (_) {
            final sl = branchStallLevel(s.branchStalls, c.id, i);
            final unlocked = lvl >= branchStallUnlock[i];
            final cost = sl >= branchStallMaxLevel
                ? 0.0
                : branchStallCost(c, sl, i, ctl.branchIncome,
                    discount: branchPerk(s.branchLevels, BranchPerk.discount));
            final names = [l10n.branchStall0, l10n.branchStall1, l10n.branchStall2];
            return Padding(
              key: Key('branch-stall-${c.id}-$i'),
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unlocked
                          ? '${const ['🧋', '🍡', '🛵'][i]} ${names[i]} · $sl/$branchStallMaxLevel'
                          : '🔒 ${names[i]} · ${l10n.branchStallLocked(branchStallUnlock[i])}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unlocked && sl < branchStallMaxLevel)
                    FilledButton.tonal(
                      key: Key('branch-stall-act-${c.id}-$i'),
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: s.money >= cost ? () => ctl.upgradeBranchStall(c.id, i) : null,
                      child: Text(formatNumber(cost)),
                    ),
                  if (unlocked && sl >= branchStallMaxLevel) const Text('✅'),
                ],
              ),
            );
          }),
        if (lvl >= branchMaxLevel) ...[
          const SizedBox(height: 8),
          Text(l10n.branchSpecTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in const [1, 2]) ...[
                if (i == 2) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: spec == i ? Color(c.color).withValues(alpha: 0.35) : Color(c.color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key('branch-spec-${c.id}-$i'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (!ctl.setBranchSpec(c.id, i) && spec != null && spec != i) snack(l10n.branchSpecFail);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          i == 1 ? l10n.branchSpecExport : l10n.branchSpecTourism,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: spec == i ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (spec != null)
            Text(l10n.branchSpecRespec(branchSpecRespecGems), style: theme.textTheme.bodySmall),
        ],
      ],
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
            if (!locked && lvl > 0) _CityExtras(c: c, s: s, now: now),
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
