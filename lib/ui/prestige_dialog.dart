import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/balance.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/anim_assets.dart';
import 'widgets/one_shot_lottie.dart';

/// Mở dialog Nhượng quyền (prestige).
Future<void> showPrestigeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _PrestigeDialog(),
  );
}

int _percent(int stars) => (stars * Balance.bonusPerStar * 100).round();

/// ConsumerWidget để các con số cập nhật trực tiếp khi thu nhập tăng lúc dialog
/// đang mở (số Sao khả dụng phụ thuộc tổng thu nhập cả đời).
class _PrestigeDialog extends ConsumerWidget {
  const _PrestigeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars =
        ref.watch(gameControllerProvider.select((s) => s.prestigeStars));
    final available = ref.watch(
      gameControllerProvider.select((s) => s.prestigeStarsAvailable),
    );
    final canPrestige = available > 0;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.prestigeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.prestigeIntro(_percent(1))),
          const SizedBox(height: 16),
          _row(l10n.prestigeStarsNow,
              l10n.prestigeStarsValue(stars, _percent(stars))),
          _row(l10n.prestigeNow, l10n.prestigeGain(available)),
          const Divider(),
          _row(
            l10n.prestigeTotalBonus,
            l10n.prestigeTotalValue(_percent(stars + available)),
            highlight: true,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.prestigeWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('prestige-confirm'),
          onPressed: canPrestige ? () => _confirm(context, ref) : null,
          child: Text(
            canPrestige ? l10n.prestigeConfirm(available) : l10n.prestigeNotEnough,
          ),
        ),
      ],
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);
    final gained = ref.read(gameControllerProvider.notifier).doPrestige();
    if (gained > 0) {
      ref.read(audioServiceProvider).play(Sfx.prestige);
      // Chèn vào overlay gốc trước khi đóng dialog → pháo hoa nổ trên màn chính.
      playEffect(context, AnimAssets.fireworks, size: 320);
    }
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    if (gained > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.prestigeSuccess(gained))),
      );
    }
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: highlight
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }
}
