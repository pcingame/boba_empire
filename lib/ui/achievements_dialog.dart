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

/// Thành tựu: liệt kê mốc, tô đã đạt (✓) hoặc khoá kèm tiến độ + thưởng. Là tab thứ 4 của hộp
/// "Nhiệm vụ & Quà" (daily_hub_dialog.dart); mở tab = đã xem (xoá chấm đỏ).
class AchievementsPanel extends ConsumerStatefulWidget {
  const AchievementsPanel({super.key});

  @override
  ConsumerState<AchievementsPanel> createState() => _AchievementsPanelState();
}

class _AchievementsPanelState extends ConsumerState<AchievementsPanel> {
  @override
  void initState() {
    super.initState();
    // Không đổi state ngay trong initState (đang dựng cây) → đợi hết khung.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(gameControllerProvider.notifier).acknowledgeAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Không đọc GameSnapshot ở tầng này — mỗi hàng tự theo dõi đúng chỉ
    // số của nó (xem _AchievementRow) để tránh rebuild TOÀN BỘ danh sách
    // mỗi giây (lifetimeEarnings đổi mỗi tick) trong khi phần lớn thành
    // tựu (stage/levels/prestige, hoặc đã đạt) không đổi thường xuyên
    // vậy — nguyên nhân giật khi mở bảng này lúc đang chơi.
    // ListView.builder: chỉ dựng hàng đang hiển thị. Thủ phạm giật thật là Opacity/saveLayer ở
    // _AchievementRow, xem bên dưới.
    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, i) =>
          _AchievementRow(achievement: achievements[i], l10n: l10n, theme: theme),
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
        AchievementMetric.ascension => s.ascensionCount,
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

    // KHÔNG dùng Opacity(0.8) cho hàng chưa đạt: mỗi Opacity là một saveLayer
    // (vùng đệm ngoài màn hình) trên GPU, nhân với số hàng hiển thị — đo trên Android
    // thật là một nguyên nhân khiến mở bảng này rớt ~66% khung. Hàng chưa đạt vẫn
    // khác biệt nhờ thanh tiến độ + chữ nhạt hơn.
    final dim = unlocked ? 1.0 : 0.8;
    return ClayTile(
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: dim),
                    ),
                  ),
                  if (!unlocked) ...[
                    const SizedBox(height: 5),
                    // borderRadius có sẵn của widget, không bọc thêm ClipRRect.
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(5),
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: dim),
                    ),
                  ),
          ],
        ),
    );
  }
}
