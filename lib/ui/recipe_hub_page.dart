import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../core/daily.dart';
import '../core/recipe_mastery.dart';
import '../core/recipe_names.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import 'recipe_leaderboard_page.dart';
import 'email_gate.dart';
import 'recipe_quiz_page.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/idle_mascot.dart';
import 'widgets/motion.dart';
import 'widgets/recipe_motion.dart';

/// Màn "Công thức pha chế": tiến độ, nút luyện tập, danh sách món kèm bậc thuộc.
Future<void> showRecipeHub(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecipeHubPage()));

/// Tên bậc 0..3.
String recipeBoxName(AppLocalizations l10n, int box) => switch (box) {
      0 => l10n.recipeBox0,
      1 => l10n.recipeBox1,
      2 => l10n.recipeBox2,
      _ => l10n.recipeBox3,
    };

Color recipeBoxColor(int box) => switch (box) {
      0 => Colors.blueGrey,
      1 => Colors.blue,
      2 => Colors.orange,
      _ => Colors.green,
    };

class RecipeHubPage extends ConsumerWidget {
  const RecipeHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(recipeCatalogProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipeTitle),
        actions: [
          IconButton(
            key: const Key('recipe-leaderboard'),
            tooltip: l10n.rlbTitle,
            icon: const Icon(Icons.emoji_events),
            onPressed: () async {
              // Tính năng online: cần đã liên kết email (xem email_gate.dart).
              if (!await ensureOnlineLinked(context) || !context.mounted) return;
              showRecipeLeaderboard(context);
            },
          ),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.guildErrNetwork)),
        data: (c) => _Body(catalog: c),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.catalog});
  final RecipeCatalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = ref.watch(gameControllerProvider.select((s) => s.recipeProgress));
    final today = dayIndex(ref.watch(clockProvider)());
    final labels = recipeLabelsOf(ref, context);
    RecipeProgress p(Recipe r) => progress[r.id] ?? const RecipeProgress();
    int bestOf(int id) => progress[id]?.best ?? 0;
    // Chỉ các nhóm ĐÃ MỞ mới tính vào tiến độ/ôn/danh sách (xem recipeGroupUnlocked).
    final recipes = unlockedRecipes(catalog, bestOf);
    final streak = ref.watch(gameControllerProvider.select((s) => s.recipeStreak));
    final alive = streak.aliveDays(today);
    final restorable = streak.restorable(today);
    final mastered = recipes.where((r) => p(r).box == recipeMaxBox).length;
    final due = recipes.where((r) => p(r).isDue(today)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClayCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(l10n.recipeMastered(mastered, recipes.length),
                      key: const Key('recipe-mastered'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ),
                // Cốc trà bốc hơi (Lottie, 30Hz qua nhịp chung; Tắt hiệu ứng thì về emoji tĩnh).
                IdleMascot(
                    key: const Key('recipe-steam'),
                    asset: AnimAssets.steam,
                    emoji: '☕',
                    size: 48,
                    animate: !reduceMotion),
              ]),
              const SizedBox(height: 10),
              _MilestoneBar(
                  mastered: mastered, total: recipes.length, everMastered: progress.values.where((p) => p.best == recipeMaxBox).length),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Pill(
                  color: due > 0 ? Colors.deepOrange : Colors.green,
                  icon: due > 0 ? Icons.menu_book_rounded : Icons.check_circle_rounded,
                  child: Text(due > 0 ? l10n.recipeDueToday(due) : l10n.recipeAllDone,
                      key: const Key('recipe-due'), style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (alive > 0 && !restorable)
                  PulseOnIncrease(
                    value: alive,
                    peak: 1.08,
                    child: _Pill(
                      color: Colors.orange,
                      child: Text(l10n.recipeStreak(alive),
                          key: const Key('recipe-streak'),
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]),
              if (alive > 0 && !restorable) ...[
                const SizedBox(height: 4),
                Text(streak.reviewedToday(today) ? l10n.recipeStreakToday : l10n.recipeStreakPending,
                    key: const Key('recipe-streak-status'), style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('recipe-practice'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const RecipeQuizPage())),
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: Text(l10n.recipePractice),
                ),
              ),
            ],
          ),
        ),
        // Thẻ cứu chuỗi nảy hai nhịp khi hiện ra để gây chú ý (hữu hạn, không lặp vô hạn).
        if (restorable) PulseOnMount(child: _RescueCard(days: streak.days)),
        const SizedBox(height: 6),
        Text(l10n.recipeDisclaimer, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        for (final g in recipePlayableGroups)
          if (recipeGroupUnlocked(catalog, g, bestOf)) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text('🧋 ${labels.group(g, catalog.groupNames[g] ?? '')}',
                  key: Key('recipe-group-$g'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final r in catalog.inGroup(g))
              AppearIn(child: _RecipeTile(recipe: r, progress: p(r), today: today, labels: labels)),
          ] else
            _LockedGroup(
              key: Key('recipe-group-locked-$g'),
              name: labels.group(g, catalog.groupNames[g] ?? ''),
              // Chỉ nhóm KẾ TIẾP hiện tiến độ mở khoá; các nhóm xa hơn chỉ ghi tên + khoá.
              learned: recipeGroupUnlocked(catalog, recipePlayableGroups[recipePlayableGroups.indexOf(g) - 1], bestOf)
                  ? recipeGroupLearned(catalog, recipePlayableGroups[recipePlayableGroups.indexOf(g) - 1], bestOf)
                  : null,
            ),
      ],
    );
  }
}

class _BoxChip extends StatelessWidget {
  const _BoxChip(this.box);
  final int box;

  @override
  Widget build(BuildContext context) {
    final color = recipeBoxColor(box);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(recipeBoxName(AppLocalizations.of(context)!, box),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.progress, required this.today, required this.labels});
  final RecipeLabels labels;
  final Recipe recipe;
  final RecipeProgress progress;
  final int today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClayTile(
      key: Key('recipe-tile-${recipe.id}'),
      onTap: () => _showCard(context),
      child: Row(
        children: [
          // Vạch màu theo bậc ở mép trái: nhìn lướt biết món nào thạo/chưa.
          Container(
            width: 5,
            height: 42,
            decoration: BoxDecoration(color: recipeBoxColor(progress.box), borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labels.recipe(recipe),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Wrap(spacing: 2, children: [
                  for (final i in recipe.ingredients) Text(ingredientEmoji(i.name), style: const TextStyle(fontSize: 17)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chip sát mép phải (không dùng Flexible: nó chia đôi chỗ trống với Expanded và nằm lưng chừng).
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: PulseOnIncrease(value: progress.box, peak: 1.15, child: _BoxChip(progress.box)),
          ),
        ],
      ),
    );
  }

  void _showCard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RecipeCard(recipe: recipe, progress: progress, today: today, labels: labels),
    );
  }
}

/// Thẻ công thức: nguyên liệu kèm lượng + lịch ôn kế tiếp.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.progress, required this.today, required this.labels});
  final RecipeLabels labels;
  final Recipe recipe;
  final RecipeProgress progress;
  final int today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wait = progress.dueDay - today;
    return SingleChildScrollView(
      key: const Key('recipe-card'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(labels.recipe(recipe),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 110), child: _BoxChip(progress.box)),
          ]),
          const SizedBox(height: 4),
          Text(wait <= 0 ? l10n.recipeReviewToday : l10n.recipeReviewIn(wait), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(l10n.recipeIngredients, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final i in recipe.ingredients)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Text(ingredientEmoji(i.name), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(labels.ingredient(i.name), style: theme.textTheme.bodyLarge)),
                const SizedBox(width: 8),
                Text(i.amount, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
        ],
      ),
    );
  }
}

/// Cứu chuỗi ôn đã đứt đúng một ngày: trả 💎 hoặc xem quảng cáo thưởng (người đã gỡ QC/VIP được cứu thẳng).
class _RescueCard extends ConsumerStatefulWidget {
  const _RescueCard({required this.days});
  final int days;

  @override
  ConsumerState<_RescueCard> createState() => _RescueCardState();
}

class _RescueCardState extends ConsumerState<_RescueCard> {
  bool _busy = false;

  void _say(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _withGems() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = ref.read(gameControllerProvider.notifier).restoreRecipeStreakNow(payGems: true);
    _say(ok ? l10n.recipeRescued : l10n.recipeRescueNoGems);
  }

  Future<void> _withAd() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree ? RewardOutcome.earned : await ref.read(adServiceProvider).showRewardedAd();
    if (!mounted) return;
    setState(() => _busy = false);
    if (outcome != RewardOutcome.earned) {
      _say(l10n.adNotReadySnack);
      return;
    }
    ref.read(gameControllerProvider.notifier).restoreRecipeStreakNow(payGems: false);
    _say(l10n.recipeRescued);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ClayTile(
      key: const Key('recipe-rescue'),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recipeRescueTitle(widget.days),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.deepOrange)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: const Key('recipe-rescue-gems'),
              onPressed: _busy ? null : _withGems,
              child: Text(l10n.recipeRescueGems(recipeStreakRestoreGems)),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('recipe-rescue-ad'),
              onPressed: _busy ? null : _withAd,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l10n.recipeRescueAd),
            ),
          ),
        ],
      ),
    );
  }
}

/// Viên thuốc nhỏ: nền nhạt + viền màu + (tuỳ chọn) biểu tượng.
class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child, this.icon});
  final Color color;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
        Flexible(child: child),
      ]),
    );
  }
}

/// Thanh "Thạo" kèm các hòm quà mốc (5/10/20 món): hòm sáng khi đã đạt, mờ khi chưa.
class _MilestoneBar extends StatelessWidget {
  const _MilestoneBar({required this.mastered, required this.total, required this.everMastered});
  final int mastered;
  final int total;
  final int everMastered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SmoothBar(key: const Key('recipe-mastered-bar'), value: total == 0 ? 0 : mastered / total, minHeight: 14, radius: 8),
        const SizedBox(height: 4),
        SizedBox(
          key: const Key('recipe-milestones'),
          // Cao đủ cho emoji 🎁 (18) + nhãn số (~14) theo cỡ chữ của máy: cỡ chữ lớn từng cắt mất nhãn ở đáy.
          height: 6 + MediaQuery.textScalerOf(context).scale(40),
          child: LayoutBuilder(builder: (context, box) {
            // Bề rộng ô nhãn cũng theo cỡ chữ, để số 2 chữ số ở chữ lớn không tràn ra ngoài.
            final w = MediaQuery.textScalerOf(context).scale(36);
            return Stack(children: [
              for (final m in recipeAccessoryMilestones.keys.where((m) => m <= total))
                Positioned(
                  // Căn hòm theo vị trí mốc trên thanh, kẹp để không tràn mép.
                  left: (box.maxWidth * m / total - w / 2).clamp(0.0, box.maxWidth - w),
                  width: w,
                  child: Opacity(
                    opacity: everMastered >= m ? 1 : 0.4,
                    child: Column(children: [
                      const Text('🎁', style: TextStyle(fontSize: 18)),
                      Text('$m', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
            ]);
          }),
        ),
      ],
    );
  }
}

/// Nhóm chưa mở: một dòng khoá (kèm tiến độ "x/10" nếu là nhóm kế tiếp).
class _LockedGroup extends StatelessWidget {
  const _LockedGroup({super.key, required this.name, required this.learned});
  final String name;

  /// Số món đã thuộc của nhóm trước; null = nhóm còn xa (chưa tới lượt).
  final int? learned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Opacity(
      opacity: learned == null ? 0.55 : 0.85,
      child: ClayTile(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          learned == null
              ? l10n.recipeGroupLockedFar(name)
              : l10n.recipeGroupLocked(name, recipeGroupUnlockLearned, learned!),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
