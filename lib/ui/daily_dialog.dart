import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/daily.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

/// Popup điểm danh hằng ngày: bấm nhận → cộng Kim Cương theo chuỗi ngày.
Future<void> showDailyReward(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DailyDialog(),
  );
}

class _DailyDialog extends ConsumerStatefulWidget {
  const _DailyDialog();

  @override
  ConsumerState<_DailyDialog> createState() => _DailyDialogState();
}

class _DailyDialogState extends ConsumerState<_DailyDialog> {
  int? _gems; // null = chưa nhận
  int _streak = 0;

  void _claim() {
    final r = ref.read(gameControllerProvider.notifier).claimDailyReward();
    ref.read(audioServiceProvider).play(Sfx.reward);
    setState(() {
      _gems = r.gems;
      _streak = r.streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final claimed = _gems != null;

    return AlertDialog(
      title: Text(l10n.dailyTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          if (!claimed)
            Text(l10n.dailyPrompt, textAlign: TextAlign.center)
          else ...[
            Text(
              l10n.dailyReward(formatNumber(_gems!.toDouble())),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.dailyStreak(_streak)),
            const SizedBox(height: 14),
            _WeekRow(streak: _streak),
          ],
        ],
      ),
      actions: [
        if (!claimed)
          FilledButton(
            key: const Key('daily-claim'),
            onPressed: _claim,
            child: Text(l10n.dailyClaim),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
      ],
    );
  }
}

/// Dải 7 ngày của chu kỳ thưởng, tô đậm ngày tương ứng streak hiện tại.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = (streak - 1) % dailyRewardGems.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < dailyRewardGems.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: i == active
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: i == active
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
              boxShadow: i == active
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${dailyRewardGems[i]}💎',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: i == active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }
}
