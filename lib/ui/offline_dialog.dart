import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import 'widgets/anim_assets.dart';
import 'widgets/one_shot_lottie.dart';
import '../state/game_providers.dart';
import 'widgets/app_dialog.dart';

/// Popup "chào mừng trở lại": nhận tiền offline, hoặc xem quảng cáo để nhân đôi.
Future<void> showOfflineDialog(BuildContext context, double earned) {
  return showAppDialog<void>(
    context: context,
    barrierDismissible: false,
    celebrate: true,
    builder: (_) => _OfflineDialog(earned: earned),
  );
}

class _OfflineDialog extends ConsumerStatefulWidget {
  const _OfflineDialog({required this.earned});

  final double earned;

  @override
  ConsumerState<_OfflineDialog> createState() => _OfflineDialogState();
}

class _OfflineDialogState extends ConsumerState<_OfflineDialog> {
  bool _watchingAd = false;

  Future<void> _doubleWithAd() async {
    setState(() => _watchingAd = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context)!;
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    if (!mounted) return;
    double bonus = 0;
    if (outcome == RewardOutcome.earned) {
      bonus = ref.read(gameControllerProvider.notifier).claimDoubleOffline();
    }
    navigator.pop();
    if (bonus > 0) {
      messenger..clearSnackBars()..showSnackBar(
        SnackBar(content: Text(l10n.offlineDoubleSnack(formatNumber(bonus)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comeback = ref.watch(gameControllerProvider.select((s) => s.comebackGems));
    return AlertDialog(
      title: Text(l10n.offlineTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.offlineBody(formatNumber(widget.earned))),
          if (comeback > 0) ...[
            const SizedBox(height: 10),
            Text(l10n.offlineComeback(comeback),
                key: const Key('offline-comeback'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _watchingAd
              ? null
              : () {
                  // Xu đã vào ví lúc mở app; hiệu ứng chỉ để "nhận" có cảm giác.
                  playEffect(context, AnimAssets.coinFly, size: 220, heavy: false);
                  Navigator.of(context).pop();
                },
          child: Text(l10n.offlineClaim),
        ),
        FilledButton.icon(
          key: const Key('offline-double'),
          onPressed: _watchingAd ? null : _doubleWithAd,
          icon: const Icon(Icons.play_circle_outline),
          label: Text(l10n.offlineDoubleButton),
        ),
      ],
    );
  }
}
