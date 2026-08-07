import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';

/// Popup "chào mừng trở lại": nhận tiền offline, hoặc xem quảng cáo để nhân đôi.
Future<void> showOfflineDialog(BuildContext context, double earned) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
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
    final adsRemoved = ref.read(gameControllerProvider).adsRemoved;
    final outcome = adsRemoved
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    double bonus = 0;
    if (outcome == RewardOutcome.earned) {
      bonus = ref.read(gameControllerProvider.notifier).claimDoubleOffline();
    }
    navigator.pop();
    if (bonus > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.offlineDoubleSnack(formatNumber(bonus)))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.offlineTitle),
      content: Text(l10n.offlineBody(formatNumber(widget.earned))),
      actions: [
        TextButton(
          onPressed:
              _watchingAd ? null : () => Navigator.of(context).pop(),
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
