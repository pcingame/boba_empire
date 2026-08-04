import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../core/format.dart';
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
    final outcome = await ref.read(adServiceProvider).showRewardedAd();
    double bonus = 0;
    if (outcome == RewardOutcome.earned) {
      bonus = ref.read(gameControllerProvider.notifier).claimDoubleOffline();
    }
    navigator.pop();
    if (bonus > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('Nhân đôi! +${formatNumber(bonus)} Xu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chào mừng trở lại! 🧋'),
      content: Text(
        'Quán vẫn bán trong lúc bạn vắng mặt.\n'
        'Bạn kiếm được ${formatNumber(widget.earned)} Xu.',
      ),
      actions: [
        TextButton(
          onPressed:
              _watchingAd ? null : () => Navigator.of(context).pop(),
          child: const Text('Nhận'),
        ),
        FilledButton.icon(
          key: const Key('offline-double'),
          onPressed: _watchingAd ? null : _doubleWithAd,
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Xem QC ×2'),
        ),
      ],
    );
  }
}
