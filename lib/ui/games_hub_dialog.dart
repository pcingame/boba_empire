/// Dialog gộp các trò chơi nhỏ (Trân Châu Rơi + Công thức pha chế) thành MỘT điểm vào ở thanh điều
/// hướng chính — cùng kiểu với [showCompeteHub], đỡ chật thanh dưới khi thêm trò mới.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/daily.dart';
import '../core/recipe_mastery.dart';
import '../core/recipes.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/recipe_providers.dart';
import 'match3_journey_page.dart';
import 'recipe_hub_page.dart';

Future<void> showGamesHub(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _GamesHubDialog());

class _GamesHubDialog extends ConsumerWidget {
  const _GamesHubDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Số món công thức cần ôn hôm nay (chỉ hiện khi danh mục đã nạp xong).
    final catalog = ref.watch(recipeCatalogProvider).asData?.value;
    final progress = ref.watch(gameControllerProvider.select((s) => s.recipeProgress));
    final today = dayIndex(ref.watch(clockProvider)());
    final due = catalog == null
        ? 0
        : unlockedRecipes(catalog, (id) => progress[id]?.best ?? 0)
            .where((r) => (progress[r.id] ?? const RecipeProgress()).isDue(today))
            .length;

    return AlertDialog(
      title: Text(l10n.navMatch3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('games-match3'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.grid_view_rounded),
              title: Text(l10n.m3Title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                showMatch3Journey(context);
              },
            ),
            ListTile(
              key: const Key('games-recipes'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(l10n.recipeTitle),
              subtitle: due > 0 ? Text(l10n.recipeDueToday(due), key: const Key('games-recipes-due')) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                showRecipeHub(context);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
    );
  }
}
