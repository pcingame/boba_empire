import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/achievements.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import '../state/game_snapshot.dart';
import 'widgets/clay.dart';

/// Bảng Thành tựu: liệt kê mốc, tô đã đạt (✓) hoặc khoá kèm tiến độ + thưởng.
Future<void> showAchievements(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _AchievementsDialog(),
  );
}

class _AchievementsDialog extends StatelessWidget {
  const _AchievementsDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.achievementsTitle),
      content: SizedBox(
        width: double.maxFinite,
        // Không đọc GameSnapshot ở tầng này — mỗi hàng tự theo dõi đúng chỉ
        // số của nó (xem _AchievementRow) để tránh rebuild TOÀN BỘ danh sách
        // mỗi giây (lifetimeEarnings đổi mỗi tick) trong khi phần lớn thành
        // tựu (stage/levels/prestige, hoặc đã đạt) không đổi thường xuyên
        // vậy — nguyên nhân giật khi mở bảng này lúc đang chơi.
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in achievements)
              _AchievementRow(achievement: a, l10n: l10n, theme: theme),
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

class _AchievementRow extends ConsumerWidget {
  const _AchievementRow({
    required this.achievement,
    required this.l10n,
    required this.theme,
  });

  final Achievement achievement;
  final AppLocalizations l10n;
  final ThemeData theme;

  static num _metricValue(GameSnapshot s, Achievement a) => switch (a.metric) {
        AchievementMetric.earn => s.lifetimeEarnings,
        AchievementMetric.stage => s.stage,
        AchievementMetric.levels =>
          Balance.generators.fold<int>(0, (acc, c) => acc + s.levelOf(c.id)),
        AchievementMetric.prestige => s.prestigeStars,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = achievement;
    // select riêng từng phần: 1 khi đã đạt (achievementsClaimed chỉ tăng,
    // không giảm) thì cờ này không đổi nữa — Riverpod tự bỏ qua rebuild cho
    // hàng đó mãi mãi, dù snapshot tổng thể vẫn đổi mỗi giây.
    final unlocked = ref.watch(
      gameControllerProvider.select((s) => s.achievementsClaimed.contains(a.id)),
    );
    final progress =
        ref.watch(gameControllerProvider.select((s) => _metricValue(s, a)));
    final ratio = (progress / a.threshold).clamp(0.0, 1.0).toDouble();

    return Opacity(
      opacity: unlocked ? 1.0 : 0.8,
      child: ClayTile(
        child: Row(
          children: [
            Text(a.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    achievementDesc(l10n, a),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                          value: ratio, minHeight: 6),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            unlocked
                ? Icon(Icons.check_circle,
                    color: theme.colorScheme.primary, size: 28)
                : Text(
                    l10n.dailyReward(formatNumber(a.rewardGems.toDouble())),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
          ],
        ),
      ),
    );
  }
}
