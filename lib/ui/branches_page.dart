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
import 'widgets/count_up.dart';
import 'widgets/motion.dart' show PulseOnIncrease, reduceMotion;
import 'widgets/reward_burst.dart';
import 'widgets/phone_width.dart';
import 'widgets/stagger_in.dart';

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
    showRewardBurst(
      context,
      emojis: r.rushes > 0 ? const ['🪙', '🔥', '✨'] : const ['🪙', '✨'],
      label: '+${formatNumber(r.xu)}',
      count: r.rushes > 0 ? 16 : 10,
    );
    _snack(
      context,
      r.rushes > 0
          ? '${l10n.branchCollected(formatNumber(r.xu))}\n${l10n.branchRush(r.rushes)}'
          : l10n.branchCollected(formatNumber(r.xu)),
    );
  }

  /// Khung chung của các bottom sheet: thanh kéo, tiêu đề có huy hiệu emoji tô màu, nội dung.
  Future<void> _sheet(
    BuildContext context, {
    required Widget Function(BuildContext ctx, WidgetRef ref) builder,
    bool tall = false,
  }) {
    final content = Consumer(builder: (ctx, ref, _) => builder(ctx, ref));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => tall
          ? DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, scroll) =>
                  PrimaryScrollController(controller: scroll, child: content),
            )
          : content,
    );
  }

  void _showSets(BuildContext context) {
    _sheet(
      context,
      tall: true,
      builder: (ctx, ref) {
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
        const emojis = {
          'asia': '🌏', 'europe': '🏰', 'africa': '🦁', 'northamerica': '🗽',
          'southamerica': '🌴', 'oceania': '🦘', 'space': '🌙', 'all': '🌍', //
        };
        const colors = {
          'asia': 0xFF8FB074,
          'europe': 0xFFE0B94A,
          'africa': 0xFFD9904A,
          'northamerica': 0xFF4DB6AC,
          'southamerica': 0xFFAB7BC8,
          'oceania': 0xFFE57C93,
          'space': 0xFF7E7BD8,
          'all': 0xFF42A5F5, //
        };
        String hours(int sec) {
          final h = sec / 3600;
          return h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);
        }

        Widget tierRow(BranchSet set, int tier, Color tint) {
          final key = branchSetKey(set, tier);
          final done = branchSetDone(s.branchLevels, set, tier);
          final total = set.cityIds.length;
          final claimed = s.branchSetClaims.contains(key);
          final r = branchSetReward(set, tier);
          final ready = done == total && !claimed;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
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
                      _AnimBar(value: done / total, color: tint),
                      const SizedBox(height: 2),
                      Text(
                        l10n.branchSetReward(r.gems, hours(r.seconds)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ClaimSlot(
                  claimed: claimed,
                  button: Builder(
                    builder: (btn) => FilledButton(
                      key: Key('branch-set-claim-$key'),
                      onPressed: ready
                          ? () {
                              if (ref
                                  .read(gameControllerProvider.notifier)
                                  .claimBranchSet(key)) {
                                showRewardBurst(btn, emojis: const ['💎', '✨'], label: '+${r.gems} 💎');
                                _snack(ctx, l10n.branchSetClaimed(r.gems));
                              }
                            }
                          : null,
                      child: Text(l10n.branchSetClaim),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          key: const Key('branch-sets-sheet'),
          controller: PrimaryScrollController.of(ctx),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          children: [
            _sheetHead(
              ctx,
              '🏅',
              l10n.branchSetsTitle,
              const Color(0xFFFFB300),
              hint: l10n.branchSetsHint,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < branchSets.length; i++)
              StaggerIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(
                        colors[branchSets[i].id]!,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Color(
                          colors[branchSets[i].id]!,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              emojis[branchSets[i].id]!,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                names[branchSets[i].id]!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        tierRow(
                          branchSets[i],
                          1,
                          Color(colors[branchSets[i].id]!),
                        ),
                        tierRow(
                          branchSets[i],
                          2,
                          Color(colors[branchSets[i].id]!),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showQuests(BuildContext context) {
    _sheet(
      context,
      builder: (ctx, ref) {
        final l10n = AppLocalizations.of(ctx)!;
        final theme = Theme.of(ctx);
        final s = ref.watch(gameControllerProvider);
        final today =
            s.branchQuestDayKey == branchQuestDay(ref.read(clockProvider)());
        final prog = today ? s.branchQuestProgress : const [0, 0, 0, 0];
        final mask = today ? s.branchQuestClaimed : 0;
        final names = [
          l10n.branchQuest0(branchQuestTargets[0]),
          l10n.branchQuest1(branchQuestTargets[1]),
          l10n.branchQuest2(branchQuestTargets[2]),
          l10n.branchQuest3(branchQuestTargets[3]),
          l10n.branchQuestAll,
        ];
        const emojis = ['💰', '⚡', '⬆️', '🎉', '🏆'];
        const colors = [
          0xFFFFB300,
          0xFFEF5350,
          0xFF42A5F5,
          0xFFAB47BC,
          0xFF26A69A,
        ];
        final claimable = branchQuestClaimable(prog, mask);
        Widget row(int i) {
          final tint = Color(colors[i]);
          final done = i == 4
              ? [
                  for (var k = 0; k < 4; k++) prog[k] >= branchQuestTargets[k],
                ].every((b) => b)
              : prog[i] >= branchQuestTargets[i];
          final claimed = mask & (1 << i) != 0;
          final ready = done && claimable.contains(i);
          final gems = i == 4 ? branchQuestAllGems : branchQuestGems;
          return StaggerIn(
            index: i,
            child: AnimatedContainer(
              key: Key('branch-quest-$i'),
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: claimed ? 0.06 : 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tint.withValues(alpha: ready ? 0.9 : 0.35),
                  width: ready ? 2 : 1,
                ),
                boxShadow: ready
                    ? [
                        BoxShadow(
                          color: tint.withValues(alpha: 0.45),
                          blurRadius: 12,
                        ),
                      ]
                    : const [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    child: Text(
                      emojis[i],
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(names[i], style: theme.textTheme.labelLarge),
                        if (i < 4) ...[
                          const SizedBox(height: 4),
                          _AnimBar(
                            value: (prog[i] / branchQuestTargets[i]).clamp(
                              0.0,
                              1.0,
                            ),
                            color: tint,
                          ),
                          Text(
                            '${prog[i].clamp(0, branchQuestTargets[i])}/${branchQuestTargets[i]}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ClaimSlot(
                    claimed: claimed,
                    button: Builder(builder: (btn) => FilledButton(
                      key: Key('branch-quest-claim-$i'),
                      onPressed: ready
                          ? () {
                              if (ref
                                  .read(gameControllerProvider.notifier)
                                  .claimBranchQuest(i)) {
                                showRewardBurst(btn, emojis: const ['💎', '✨'], label: '+$gems 💎');
                                _snack(ctx, l10n.branchSetClaimed(gems));
                              }
                            }
                          : null,
                      child: Text('$gems 💎'),
                    )),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          key: const Key('branch-quest-sheet'),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHead(
                ctx,
                '📜',
                l10n.branchQuestTitle,
                const Color(0xFF8D6E63),
                hint: l10n.branchQuestHint,
              ),
              for (var i = 0; i < 5; i++) row(i),
            ],
          ),
        );
      },
    );
  }

  void _showSkins(BuildContext context) {
    _sheet(
      context,
      builder: (ctx, ref) {
        final l10n = AppLocalizations.of(ctx)!;
        final theme = Theme.of(ctx);
        final cur = ref.watch(
          gameControllerProvider.select((s) => s.branchMapSkin),
        );
        final names = [
          l10n.branchSkin0,
          l10n.branchSkin1,
          l10n.branchSkin2,
          l10n.branchSkin3,
        ];
        const icons = ['🗺️', '❄️', '🧧', '🌸'];
        const grads = [
          [Color(0xFF9ED8F2), Color(0xFFB4D88C)],
          [Color(0xFFEAF4FF), Color(0xFF9CC7F2)],
          [Color(0xFFE53935), Color(0xFFFFD54F)],
          [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        ];
        Widget card(int i) => Expanded(
          child: StaggerIn(
            index: i,
            child: GestureDetector(
              key: Key('branch-skin-$i'),
              onTap: () =>
                  ref.read(gameControllerProvider.notifier).setBranchMapSkin(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                constraints: const BoxConstraints(minHeight: 96),
                padding: const EdgeInsets.symmetric(vertical: 12),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grads[i],
                  ),
                  border: Border.all(
                    color: cur == i ? theme.colorScheme.primary : Colors.white,
                    width: cur == i ? 3.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: grads[i].last.withValues(
                        alpha: cur == i ? 0.7 : 0.3,
                      ),
                      blurRadius: cur == i ? 12 : 4,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icons[i], style: const TextStyle(fontSize: 30)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              names[i],
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4E342E),
                              ),
                            ),
                          ),
                          AnimatedScale(
                            scale: cur == i ? 1 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: const Text(' ✅'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        return SingleChildScrollView(
          key: const Key('branch-skin-sheet'),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHead(
                ctx,
                '🎨',
                l10n.branchSkinTitle,
                const Color(0xFFEC407A),
              ),
              const SizedBox(height: 8),
              Row(children: [card(0), card(1)]),
              Row(children: [card(2), card(3)]),
            ],
          ),
        );
      },
    );
  }

  void _showRoutes(BuildContext context) {
    String? from, to;
    _sheet(
      context,
      tall: true,
      builder: (ctx, ref) {
        final l10n = AppLocalizations.of(ctx)!;
        final theme = Theme.of(ctx);
        final s = ref.watch(gameControllerProvider);
        final income = ref.read(gameControllerProvider.notifier).branchIncome;
        final discount = branchPerk(s.branchLevels, BranchPerk.discount);
        final routes = s.branchRoutes;
        final keys = routes.keys.toList()..sort();
        final open = [
          for (final c in branchCities)
            if (c.id != 'moon' && branchLevel(s.branchLevels, c.id) > 0) c,
        ];
        String name(String id) => branchCityName(l10n, id);
        String pct(String a, String b, int lvl) => (lvl * branchRouteBonusPerLevel(a, b) * 100).round().toString();
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final canNew = from != null && to != null && branchRouteCanOpen(s.branchLevels, routes, from!, to!);
            Widget picker(String label, String? sel, void Function(String) on) => Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                for (final c in open)
                  ChoiceChip(
                    key: Key('route-$label-${c.id}'),
                    label: Text('${c.emoji} ${name(c.id)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    selected: sel == c.id,
                    onSelected: (_) => setSt(() => on(c.id)),
                  ),
              ],
            );
            return SingleChildScrollView(
              key: const Key('branch-routes-sheet'),
              controller: PrimaryScrollController.of(ctx),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sheetHead(
                    ctx,
                    '🚢',
                    l10n.branchRouteTitle,
                    const Color(0xFFFFB300),
                    hint: l10n.branchRouteDesc(
                      (branchRouteBonusSame * 100).round(),
                      (branchRouteBonusCross * 100).round(),
                      branchRouteMaxPerCity,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (keys.isEmpty) Text(l10n.branchRouteNone, key: const Key('route-none')),
                  for (var i = 0; i < keys.length; i++)
                    () {
                      final p = keys[i].split('|');
                      final lvl = routes[keys[i]]!;
                      final maxed = lvl >= branchRouteMaxLevel;
                      final cost = branchRouteCost(p[0], p[1], lvl, income, discount: discount);
                      return StaggerIn(
                        index: i + 1,
                        child: Card(
                          key: Key('route-${keys[i]}'),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${name(p[0])} ⇄ ${name(p[1])}', style: theme.textTheme.titleSmall),
                                Text(l10n.branchRouteLevel(lvl, branchRouteMaxLevel, int.parse(pct(p[0], p[1], lvl))),
                                    style: theme.textTheme.bodySmall),
                                const SizedBox(height: 6),
                                FilledButton.tonal(
                                  key: Key('route-up-${keys[i]}'),
                                  onPressed: maxed
                                      ? null
                                      : () {
                                          if (!ref.read(gameControllerProvider.notifier).upgradeBranchRoute(p[0], p[1])) {
                                            _snack(ctx, l10n.branchRouteFail);
                                          }
                                        },
                                  child: Text(maxed ? l10n.branchRouteMax : l10n.branchRouteUpgrade(formatNumber(cost))),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }(),
                  const SizedBox(height: 12),
                  Text(l10n.branchRouteNewTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  picker(l10n.branchRoutePickA, from, (v) => from = v),
                  const SizedBox(height: 6),
                  picker(l10n.branchRoutePickB, to, (v) => to = v),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('route-open'),
                    onPressed: !canNew
                        ? null
                        : () {
                            if (ref.read(gameControllerProvider.notifier).upgradeBranchRoute(from!, to!)) {
                              setSt(() {
                                from = null;
                                to = null;
                              });
                            } else {
                              _snack(ctx, l10n.branchRouteFail);
                            }
                          },
                    child: Text(
                      canNew
                          ? l10n.branchRouteOpen(
                              formatNumber(branchRouteCost(from!, to!, 0, income, discount: discount)),
                            )
                          : l10n.branchRouteNewTitle,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showManager(BuildContext context) {
    _sheet(
      context,
      builder: (ctx, ref) {
        final l10n = AppLocalizations.of(ctx)!;
        final theme = Theme.of(ctx);
        final s = ref.watch(gameControllerProvider);
        final now = ref.read(clockProvider)();
        final left = s.branchManagerUntilMillis - now;
        final days = left > 0 ? (left / 86400000).ceil() : 0;
        return SingleChildScrollView(
          key: const Key('branch-manager-sheet'),
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sheetHead(
                ctx,
                '🧑‍💼',
                l10n.branchManagerTitle,
                const Color(0xFF42A5F5),
                hint: l10n.branchManagerDesc(
                  branchManagerCollectEverySeconds ~/ 60,
                  branchManagerCapSeconds ~/ 3600,
                ),
              ),
              const SizedBox(height: 12),
              StaggerIn(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF42A5F5,
                    ).withValues(alpha: days > 0 ? 0.14 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF42A5F5).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        days > 0
                            ? l10n.branchManagerActive(days)
                            : l10n.branchManagerNone,
                        key: const Key('branch-manager-status'),
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      _AnimBar(
                        value: (days / branchManagerMaxDays).clamp(0.0, 1.0),
                        color: const Color(0xFF42A5F5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StaggerIn(
                index: 2,
                child: FilledButton(
                  key: const Key('branch-manager-hire'),
                  onPressed: () {
                    final ok = ref
                        .read(gameControllerProvider.notifier)
                        .hireBranchManager();
                    if (!ok) _snack(ctx, l10n.branchManagerFail);
                  },
                  child: Text(
                    l10n.branchManagerHire(
                      branchManagerDays,
                      branchManagerGems,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final readyCount = branchCities
        .where(
          (c) => branchFull(
            s.branchLevels,
            s.branchSince,
            c,
            now,
            manager: manager,
          ),
        )
        .length;
    final evSlot = branchEventSlot(now);
    final ev = s.branchEventClaimedSlot == evSlot
        ? null
        : branchEventFor(s.branchLevels, evSlot);
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
          centerTitle: false,
          actions: [
            IconButton(
              key: const Key('branch-quest-btn'),
              visualDensity: VisualDensity.compact,
              tooltip: l10n.branchQuestTitle,
              icon: Badge(
                isLabelVisible:
                    s.branchQuestDayKey == branchQuestDay(now) &&
                    branchQuestClaimable(
                      s.branchQuestProgress,
                      s.branchQuestClaimed,
                    ).isNotEmpty,
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
                isLabelVisible: branchSetsClaimable(
                  s.branchLevels,
                  s.branchSetClaims,
                ).isNotEmpty,
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
                                  child: CountUpText(
                                    key: const Key('branch-total'),
                                    value: pendingXu,
                                    builder: (v) => l10n.branchPendingTotal(formatNumber(v)),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PulseOnIncrease(
                                value: readyCount,
                                peak: 1.12,
                                child: Builder(
                                  builder: (btn) => FilledButton(
                                    key: const Key('branch-collect'),
                                    onPressed: pendingSec > 0
                                        ? () => _collect(btn, ref)
                                        : null,
                                    child: Text('💰 ${l10n.branchCollectAll}'),
                                  ),
                                ),
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
                                (branchTotalLevels(s.branchLevels) *
                                        branchIncomeBonusPerLevel *
                                        100)
                                    .toStringAsFixed(1),
                              ),
                              key: const Key('branch-empire-bonus'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              key: const Key('branch-routes-btn'),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              onPressed: () => _showRoutes(context),
                              child: Text(
                                '🚢 ${l10n.branchRouteBtn(s.branchRoutes.length)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                              routes: s.branchRoutes,
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
                                  (branchTotalLevels(s.branchLevels) *
                                          branchIncomeBonusPerLevel *
                                          100)
                                      .toStringAsFixed(1),
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
                                child: CountUpText(
                                  key: const Key('branch-total'),
                                  value: pendingXu,
                                  builder: (v) => l10n.branchPendingTotal(formatNumber(v)),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(height: 8),
                              PulseOnIncrease(
                                value: readyCount,
                                peak: 1.12,
                                child: Builder(
                                  builder: (btn) => FilledButton(
                                    key: const Key('branch-collect'),
                                    onPressed: pendingSec > 0
                                        ? () => _collect(btn, ref)
                                        : null,
                                    child: Text('💰 ${l10n.branchCollectAll}'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final c in branchCities)
                          StaggerIn(
                            index: branchCities.indexOf(c),
                            child: _Card(
                              c: c,
                              s: s,
                              now: now,
                              income: income,
                              onAct: () => _act(context, ref, c),
                            ),
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
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
    final e = s.branchEventClaimedSlot == slot
        ? null
        : branchEventFor(s.branchLevels, slot);
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
                    Text(
                      branchEventEmoji[e.type],
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.branchEventBody(evNames[e.type], evHours(e.type)),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                Builder(
                  builder: (btn) => FilledButton(
                    key: Key('branch-event-claim-${c.id}'),
                    onPressed: () {
                      final xu = ctl.claimBranchEvent();
                      if (xu != null) {
                        showRewardBurst(btn, emojis: ['🪙', branchEventEmoji[e.type], '✨'], label: '+${formatNumber(xu)}');
                        snack(l10n.branchEventClaimed(formatNumber(xu)));
                      }
                    },
                    child: Text(l10n.branchEventClaim),
                  ),
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
          Builder(
            builder: (_) {
              final sl = branchStallLevel(s.branchStalls, c.id, i);
              final unlocked = lvl >= branchStallUnlock[i];
              final cost = sl >= branchStallMaxLevel
                  ? 0.0
                  : branchStallCost(
                      c,
                      sl,
                      i,
                      ctl.branchIncome,
                      discount: branchPerk(s.branchLevels, BranchPerk.discount),
                    );
              final names = [
                l10n.branchStall0,
                l10n.branchStall1,
                l10n.branchStall2,
              ];
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
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: s.money >= cost
                            ? () => ctl.upgradeBranchStall(c.id, i)
                            : null,
                        child: Text(formatNumber(cost)),
                      ),
                    if (unlocked && sl >= branchStallMaxLevel) const Text('✅'),
                  ],
                ),
              );
            },
          ),
        if (lvl >= branchMaxLevel) ...[
          const SizedBox(height: 8),
          Text(l10n.branchSpecTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final i in const [1, 2]) ...[
                if (i == 2) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: spec == i
                        ? Color(c.color).withValues(alpha: 0.35)
                        : Color(c.color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: Key('branch-spec-${c.id}-$i'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (!ctl.setBranchSpec(c.id, i) &&
                            spec != null &&
                            spec != i) {
                          snack(l10n.branchSpecFail);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          i == 1
                              ? l10n.branchSpecExport
                              : l10n.branchSpecTourism,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: spec == i
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          ),
          if (spec != null)
            Text(
              l10n.branchSpecRespec(branchSpecRespecGems),
              style: theme.textTheme.bodySmall,
            ),
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

  String _payback(double cost, int lvl) {
    final sec = branchPaybackSeconds(c, lvl, income, discount: branchPerk(s.branchLevels, BranchPerk.discount));
    return sec.isFinite ? formatDuration(sec.round()) : '∞';
  }

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
    final pendingSec = branchPendingIncomeSeconds(
      levels,
      since,
      c,
      now,
      manager: manager,
    );
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
              if (lvl > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.branchPayback(_payback(cost, lvl)),
                    key: Key('branch-payback-${c.id}'),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: FilledButton.tonal(
                    key: Key('branch-act-${c.id}'),
                    onPressed: (lvl == 0 ? s.gems >= branchOpenGems(c) : money >= cost) ? onAct : null,
                    child: Text(
                      lvl == 0
                          ? l10n.branchOpen('💎 ${branchOpenGems(c)}')
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

/// Tiêu đề bottom sheet: huy hiệu emoji tô màu + tên + gợi ý, nền gradient nhạt.
Widget _sheetHead(
  BuildContext context,
  String emoji,
  String title,
  Color color, {
  String? hint,
}) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.08)],
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (hint != null) Text(hint, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Thanh tiến độ chạy mượt tới giá trị mới (0 → value lần đầu); tắt khi giảm chuyển động.
class _AnimBar extends StatelessWidget {
  const _AnimBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: value),
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: v,
        minHeight: 8,
        color: color,
        backgroundColor: color.withValues(alpha: 0.18),
      ),
    ),
  );
}

/// Ô bên phải của một mục thưởng: nút Nhận, hoặc ✅ nảy ra khi đã nhận.
class _ClaimSlot extends StatelessWidget {
  const _ClaimSlot({required this.claimed, required this.button});
  final bool claimed;
  final Widget button;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
    switchInCurve: Curves.easeOutBack,
    transitionBuilder: (child, anim) =>
        ScaleTransition(scale: anim, child: child),
    child: claimed
        ? const Text('✅', key: ValueKey('done'), style: TextStyle(fontSize: 26))
        : KeyedSubtree(key: const ValueKey('btn'), child: button),
  );
}
