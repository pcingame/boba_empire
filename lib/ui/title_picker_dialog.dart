/// Chọn danh hiệu hiện trên hồ sơ công khai (xem core/titles.dart). Danh hiệu chưa mở khoá hiện mờ kèm điều kiện.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/titles.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../leaderboard/player_title.dart';
import '../leaderboard/season_leaderboard.dart';
import '../state/game_providers.dart';

Future<void> showTitlePicker(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const TitlePickerDialog());

class TitlePickerDialog extends ConsumerWidget {
  const TitlePickerDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final g = ref.watch(gameControllerProvider);
    final selected = ref.watch(selectedTitleProvider);
    final stats = TitleStats(
      stage: g.stage,
      ascension: g.ascensionCount,
      prestigeStars: g.prestigeStars,
      vipLevel: topupVipLevel(g.vipExp),
      owned: g.ownedAccessories.length,
      champion: ref.watch(seasonChampionProvider),
    );
    final notifier = ref.read(selectedTitleProvider.notifier);
    return AlertDialog(
      title: Text(l10n.titlePickerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.titlePickerHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (v) => notifier.select(v ?? ''),
              child: Column(
                children: [
                  RadioListTile<String>(
                    key: const Key('title-none'),
                    contentPadding: EdgeInsets.zero,
                    value: '',
                    title: Text(l10n.titlePickerNone),
                  ),
                  for (final t in playerTitles)
                    RadioListTile<String>(
                      key: Key('title-${t.id}'),
                      contentPadding: EdgeInsets.zero,
                      value: t.id,
                      enabled: t.unlocked(stats),
                      title: Text('${t.emoji} ${playerTitleName(l10n, t.id)}'),
                      subtitle: t.unlocked(stats) ? null : Text(playerTitleHint(l10n, t.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
    );
  }
}
