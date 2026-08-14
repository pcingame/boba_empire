import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/achievements.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';

/// Bảng Thành tựu: liệt kê mốc, tô đã đạt (✓) hoặc khoá kèm tiến độ + thưởng.
Future<void> showAchievements(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AchievementsDialog(),
  );
}

class _AchievementsDialog extends ConsumerWidget {
  const _AchievementsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final totalLevels =
        Balance.generators.fold<int>(0, (a, c) => a + s.levelOf(c.id));
    num progressOf(Achievement a) => switch (a.metric) {
          AchievementMetric.earn => s.lifetimeEarnings,
          AchievementMetric.stage => s.stage,
          AchievementMetric.levels => totalLevels,
          AchievementMetric.prestige => s.prestigeStars,
        };

    return AlertDialog(
      title: Text(l10n.achievementsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in achievements)
              _AchievementRow(
                achievement: a,
                unlocked: s.achievementsClaimed.contains(a.id),
                progress: progressOf(a),
                l10n: l10n,
                theme: theme,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.unlocked,
    required this.progress,
    required this.l10n,
    required this.theme,
  });

  final Achievement achievement;
  final bool unlocked;
  final num progress;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final ratio = (progress / a.threshold).clamp(0.0, 1.0).toDouble();

    return Opacity(
      opacity: unlocked ? 1.0 : 0.75,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Text(a.emoji, style: const TextStyle(fontSize: 26)),
        title: Text(achievementDesc(l10n, a)),
        subtitle: unlocked
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: ratio, minHeight: 5),
                ),
              ),
        trailing: unlocked
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : Text(
                l10n.dailyReward(formatNumber(a.rewardGems.toDouble())),
                style: theme.textTheme.labelMedium,
              ),
      ),
    );
  }
}
