/// Sự kiện dịp lễ: nhiệm vụ cộng dồn cả dịp + đổi điểm lấy món độc quyền
/// (xem core/event_quests.dart). Mở từ banner ở màn chính.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/accessories.dart';
import '../core/balance.dart';
import '../core/daily_quests.dart' show DailyQuestKind;
import '../core/event_quests.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'event_leaderboard_page.dart';
import 'widgets/clay.dart';

Future<void> showEventDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _EventDialog());

String _title(AppLocalizations l10n, EventQuest q) => switch (q.kind) {
      DailyQuestKind.tap => l10n.dqTap(q.target.toInt()),
      DailyQuestKind.buy => l10n.dqBuy(q.target.toInt()),
      DailyQuestKind.cat => l10n.dqCat,
      DailyQuestKind.vip => l10n.dqVip,
      _ => q.kind.name,
    };

class _EventDialog extends ConsumerWidget {
  const _EventDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final s = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final nowUtc = DateTime.fromMillisecondsSinceEpoch(
        ref.read(clockProvider)(),
        isUtc: true);
    final festival = activeFestival(nowUtc);
    if (festival == null) return const SizedBox.shrink();
    final name = festivalName(l10n, festival.id);
    return AlertDialog(
      title: Text(l10n.eventTitle(name)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.eventEndsIn(formatDuration(
                festival.end.difference(nowUtc).inSeconds))),
            Text(l10n.eventBuff(Balance.festivalIncomeMult.toString())),
            const SizedBox(height: 8),
            for (var i = 0; i < eventQuests.length; i++)
              _QuestRow(
                title: _title(l10n, eventQuests[i]),
                progress: s.eventProgress[eventQuests[i].kind.name] ?? 0,
                target: eventQuests[i].target,
                claimed: s.eventClaimed.contains(eventQuests[i].kind.name),
                onClaim: () => controller.claimEventQuestReward(i),
              ),
            const SizedBox(height: 12),
            Text(l10n.eventPoints(s.eventPoints),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(l10n.eventRedeemHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            for (final a in festival.items)
              ClayTile(
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(accessoryName(l10n, a.id))),
                    // Flexible + FittedBox: nhãn nút dài ở id/th/ko không được
                    // đẩy hàng tràn (cùng lớp lỗi RenderFlex ở các dialog khác).
                    Flexible(
                      child: FilledButton(
                        key: Key('event-redeem-${a.id}'),
                        onPressed: !s.ownedLimited.contains(a.id) &&
                                s.eventPoints >= eventItemCost(a)
                            ? () => controller.redeemEventReward(a.id)
                            : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(s.ownedLimited.contains(a.id)
                              ? '✓'
                              : l10n.eventRedeemCost(eventItemCost(a))),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('event-leaderboard-button'),
          onPressed: () => showEventLeaderboard(context),
          child: Text('🏆 ${l10n.eventLbTitle}'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.title,
    required this.progress,
    required this.target,
    required this.claimed,
    required this.onClaim,
  });

  final String title;
  final double progress;
  final double target;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final done = progress >= target;
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                      value: (progress / target).clamp(0.0, 1.0).toDouble(),
                      minHeight: 6),
                ),
                const SizedBox(height: 2),
                // Số nguyên đầy đủ: formatNumber(decimals: 0) làm tròn 1500 → "2K"
                // trong khi tiêu đề nhiệm vụ ghi 1500.
                Text('${progress.clamp(0, target).floor()} / ${target.floor()}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FilledButton(
              onPressed: done && !claimed ? onClaim : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(claimed
                    ? l10n.dailyQuestClaimed
                    : l10n.dailyReward('${Balance.eventQuestGems}')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
