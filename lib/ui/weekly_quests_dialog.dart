/// Nhiệm vụ tuần — 3 mục tiêu lớn + rương tuần (💎 và 1 phụ kiện). Mở bằng nút trong hộp thoại
/// Nhiệm vụ ngày (không thêm chip/popup mới ở màn chính).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/accessories.dart';
import '../core/format.dart';
import '../core/weekly_quests.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../state/game_snapshot.dart';
import 'daily_quests_dialog.dart' show AccessoryReveal;
import 'widgets/accessory_reveal.dart';
import 'widgets/clay.dart';

Future<void> showWeeklyQuests(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _WeeklyQuestsDialog(),
    );

String _title(AppLocalizations l10n, WeeklyQuestView q) => switch (q.kind) {
      WeeklyQuestKind.prestige => l10n.wqPrestige(q.target),
      WeeklyQuestKind.m3Win => l10n.wqM3Win(q.target),
      WeeklyQuestKind.trade => l10n.wqTrade(q.target),
      WeeklyQuestKind.dailyDone => l10n.wqDailyDone(q.target),
      WeeklyQuestKind.spin => l10n.wqSpin(q.target),
      WeeklyQuestKind.buy => l10n.wqBuy(q.target),
    };

class _WeeklyQuestsDialog extends ConsumerStatefulWidget {
  const _WeeklyQuestsDialog();

  @override
  ConsumerState<_WeeklyQuestsDialog> createState() => _WeeklyQuestsDialogState();
}

class _WeeklyQuestsDialogState extends ConsumerState<_WeeklyQuestsDialog> {
  /// Phụ kiện vừa rớt từ rương — chỉ hiện trong phiên hộp thoại này (đã có trong Kho).
  AccessoryDrop? _revealed;

  void _reward() {
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
  }

  void _openChest() {
    final controller = ref.read(gameControllerProvider.notifier);
    if (controller.claimWeeklyChestReward() <= 0) return;
    _reward();
    final drop = controller.lastAccessoryDrop;
    if (drop == null) return;
    setState(() => _revealed = drop);
    playAccessoryReveal(context, drop);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final quests = ref.watch(gameControllerProvider.select((s) => s.weeklyQuests));
    final chestAvailable =
        ref.watch(gameControllerProvider.select((s) => s.weeklyChestAvailable));
    final chestClaimed =
        ref.watch(gameControllerProvider.select((s) => s.weeklyChestClaimed));
    final now = ref.read(clockProvider)();
    final controller = ref.read(gameControllerProvider.notifier);

    return AlertDialog(
      title: Text(l10n.weeklyQuestsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < quests.length; i++)
              _Row(
                index: i,
                title: _title(l10n, quests[i]),
                view: quests[i],
                onClaim: () {
                  if (controller.claimWeeklyQuestReward(i) > 0) _reward();
                },
              ),
            ClayTile(
              child: Row(
                children: [
                  const Text('🧰', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.weeklyChestLabel,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FilledButton(
                      key: const Key('weekly-chest'),
                      onPressed: chestAvailable ? _openChest : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(chestClaimed
                            ? l10n.dailyQuestClaimed
                            : l10n.dailyReward('$weeklyChestGems')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_revealed != null) AccessoryReveal(drop: _revealed!),
            const SizedBox(height: 8),
            Text(
              l10n.weeklyResetsIn(formatDuration(weeklySecondsLeft(now))),
              key: const Key('weekly-resets-in'),
              style: theme.textTheme.bodySmall,
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

class _Row extends StatelessWidget {
  const _Row({
    required this.index,
    required this.title,
    required this.view,
    required this.onClaim,
  });

  final int index;
  final String title;
  final WeeklyQuestView view;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ratio = (view.progress / view.target).clamp(0.0, 1.0).toDouble();
    return ClayTile(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
                const SizedBox(height: 2),
                Text(
                  '${view.progress.clamp(0, view.target)} / ${view.target}',
                  key: Key('weekly-quest-progress-$index'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FilledButton(
              key: Key('weekly-quest-claim-$index'),
              onPressed: (view.done && !view.claimed) ? onClaim : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(view.claimed
                    ? l10n.dailyQuestClaimed
                    : l10n.dailyReward('${view.rewardGems}')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
