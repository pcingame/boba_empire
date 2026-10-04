import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
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

  bool _watchingAd = false;

  void _claim({bool restore = false, bool payGems = false}) {
    final r = ref
        .read(gameControllerProvider.notifier)
        .claimDailyReward(restore: restore, payGems: payGems);
    ref.read(audioServiceProvider).play(Sfx.reward);
    setState(() {
      _gems = r.gems;
      _streak = r.streak;
    });
  }

  Future<void> _restoreWithAd() async {
    setState(() => _watchingAd = true);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    if (!mounted) return;
    setState(() => _watchingAd = false);
    if (outcome == RewardOutcome.earned) _claim(restore: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final claimed = _gems != null;
    final game = ref.watch(gameControllerProvider);
    final atRisk = !claimed && game.dailyStreakRestorable;

    return AlertDialog(
      title: Text(l10n.dailyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            if (atRisk)
              Text(
                l10n.dailyStreakAtRisk(game.dailyStreak),
                textAlign: TextAlign.center,
              )
            else if (!claimed)
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
      ),
      actions: [
        if (atRisk) ...[
          FilledButton(
            key: const Key('daily-restore-gems'),
            onPressed: game.gems < streakRestoreGems
                ? null
                : () => _claim(restore: true, payGems: true),
            child: Text(l10n.dailyRestoreGems(streakRestoreGems)),
          ),
          FilledButton.icon(
            key: const Key('daily-restore-ad'),
            onPressed: _watchingAd ? null : _restoreWithAd,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l10n.dailyRestoreAd),
          ),
          TextButton(
            key: const Key('daily-claim'),
            onPressed: _watchingAd ? null : _claim,
            child: Text(l10n.dailySkipRestore),
          ),
        ] else if (!claimed)
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
                  : theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: i == active
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
              boxShadow: i == active
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
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
