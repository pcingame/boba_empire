/// Dialog gộp các trò chơi nhỏ (Chi nhánh, Trân Châu Rơi, Pha chế — Pha chế đã gồm Công thức, Pha theo đơn, Thử thách ngày) thành MỘT điểm vào ở thanh điều
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
import 'branches_page.dart';
import 'match3_journey_page.dart';
import 'recipe_hub_page.dart';
import 'pet_dialog.dart';
import 'staff_dialog.dart';
import 'widgets/app_dialog.dart';

Future<void> showGamesHub(BuildContext context) =>
    showAppDialog<void>(context: context, builder: (_) => const _GamesHubDialog());

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

    final branchReady = ref.watch(branchReadyProvider);
    return AlertDialog(
      title: Text(l10n.navMatch3),
      // Rộng hết cỡ (AlertDialog co theo nội dung): tên trò/dòng phụ dài không bị cắt "…".
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('games-branches'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_city_rounded),
              title: Row(children: [
                Flexible(child: Text(l10n.branchTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (branchReady) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const Key('games-branches-dot'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
                  ),
                ],
              ]),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                showBranches(context);
              },
            ),
            ListTile(
              key: const Key('games-staff'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_rounded),
              title: Text(l10n.staffTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                showStaff(context);
              },
            ),
            ListTile(
              key: const Key('games-pet'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pets_rounded),
              title: Text(l10n.petTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                showPet(context);
              },
            ),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
    );
  }
}
