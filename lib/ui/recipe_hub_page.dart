import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/daily.dart';
import '../core/recipe_mastery.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import 'recipe_leaderboard_page.dart';
import 'recipe_quiz_page.dart';
import 'widgets/clay.dart';

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
            onPressed: () => showRecipeLeaderboard(context),
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
    final recipes = catalog.playable;
    RecipeProgress p(Recipe r) => progress[r.id] ?? const RecipeProgress();
    final mastered = recipes.where((r) => p(r).box == recipeMaxBox).length;
    final due = recipes.where((r) => p(r).isDue(today)).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClayTile(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.recipeMastered(mastered, recipes.length),
                  key: const Key('recipe-mastered'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: recipes.isEmpty ? 0 : mastered / recipes.length, minHeight: 10),
              ),
              const SizedBox(height: 8),
              Text(due > 0 ? l10n.recipeDueToday(due) : l10n.recipeAllDone,
                  key: const Key('recipe-due'), style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('recipe-practice'),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const RecipeQuizPage())),
                  child: Text(l10n.recipePractice),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.recipeDisclaimer, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        for (final g in recipePlayableGroups) ...[
          if (catalog.groupNames[g] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(catalog.groupNames[g]!,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          for (final r in recipes.where((r) => r.group == g))
            _RecipeTile(recipe: r, progress: p(r), today: today),
        ],
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
  const _RecipeTile({required this.recipe, required this.progress, required this.today});
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Wrap(children: [
                  for (final i in recipe.ingredients)
                    Text(ingredientEmoji(i.name), style: const TextStyle(fontSize: 15)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: _BoxChip(progress.box)),
        ],
      ),
    );
  }

  void _showCard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RecipeCard(recipe: recipe, progress: progress, today: today),
    );
  }
}

/// Thẻ công thức: nguyên liệu kèm lượng + lịch ôn kế tiếp.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.progress, required this.today});
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
                child: Text(recipe.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Flexible(child: _BoxChip(progress.box)),
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
                Expanded(child: Text(i.name, style: theme.textTheme.bodyLarge)),
                const SizedBox(width: 8),
                Text(i.amount, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
        ],
      ),
    );
  }
}
