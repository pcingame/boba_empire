import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_service.dart';
import '../audio/audio_service.dart';
import '../core/balance.dart';
import '../core/format.dart';
import '../iap/iap_products.dart';
import '../iap/iap_service.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';

/// "Kiếm thêm 🎁" — các ưu đãi xem quảng cáo thưởng: x2 thu nhập 24h, nhận Kim
/// Cương, tua nhanh. Người đã mua "Gỡ QC" nhận thẳng, không phải xem.
Future<void> showRewards(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _RewardsDialog(),
  );
}

class _RewardsDialog extends ConsumerStatefulWidget {
  const _RewardsDialog();

  @override
  ConsumerState<_RewardsDialog> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends ConsumerState<_RewardsDialog> {
  bool _busy = false;
  late final Future<Map<IapProduct, String>> _prices =
      ref.read(iapServiceProvider).loadPrices();

  /// Xem QC (hoặc bỏ qua nếu đã mua Gỡ QC) → nếu nhận thưởng thì gọi [onEarned].
  Future<void> _watch(void Function() onEarned) async {
    if (_busy) return;
    setState(() => _busy = true);
    final adsRemoved = ref.read(gameControllerProvider).adsRemoved;
    final outcome = adsRemoved
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    if (outcome == RewardOutcome.earned) {
      ref.read(audioServiceProvider).play(Sfx.reward);
      onEarned();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final x2sec = ref.watch(
      gameControllerProvider.select((s) => s.x2IncomeRemainingSeconds),
    );
    final x2Hours = (x2sec / 3600).ceil();
    final piggy = ref.watch(
      gameControllerProvider.select((s) => s.piggyGems),
    );

    return AlertDialog(
      title: Text(l10n.rewardsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heo đất (IAP) — nổi bật ở trên cùng.
          FutureBuilder<Map<IapProduct, String>>(
            future: _prices,
            builder: (context, snap) => _PiggyCard(
              gems: piggy,
              price: snap.data?[IapProduct.piggyBreak],
              onBreak: () =>
                  ref.read(iapServiceProvider).buy(IapProduct.piggyBreak),
            ),
          ),
          _OfferRow(
            emoji: '⚡',
            name: l10n.rewardX2Name,
            note: x2sec > 0 ? l10n.rewardX2Active(x2Hours) : null,
            busy: _busy,
            onWatch: () => _watch(() {
              controller.activateX2Income();
              _snack(l10n.rewardX2Snack);
            }),
          ),
          _OfferRow(
            emoji: '💎',
            name: l10n.rewardGemsName(Balance.rewardedFreeGems),
            busy: _busy,
            onWatch: () => _watch(() {
              controller.grantFreeGems();
              _snack(l10n.iapGemsSnack(
                  formatNumber(Balance.rewardedFreeGems.toDouble())));
            }),
          ),
          _OfferRow(
            emoji: '⏩',
            name: l10n.rewardTimeSkip(Balance.rewardedTimeSkipSeconds ~/ 3600),
            busy: _busy,
            onWatch: () => _watch(() {
              final reward = controller.claimTimeSkip();
              if (reward > 0) {
                _snack(l10n.instantCashSnack(formatNumber(reward)));
              }
            }),
          ),
        ],
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

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    required this.emoji,
    required this.name,
    required this.busy,
    required this.onWatch,
    this.note,
  });

  final String emoji;
  final String name;
  final String? note;
  final bool busy;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ClayTile(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: busy ? null : onWatch,
            icon: const Icon(Icons.play_circle_outline, size: 20),
            label: Text(l10n.watchAd),
          ),
        ],
      ),
    );
  }
}

/// Thẻ Heo đất: hiện Kim Cương đã tích + tiến độ; đủ ngưỡng thì cho "đập" (IAP).
class _PiggyCard extends StatelessWidget {
  const _PiggyCard({
    required this.gems,
    required this.price,
    required this.onBreak,
  });

  final double gems;
  final String? price;
  final VoidCallback onBreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ratio = (gems / Balance.piggyMaxGems).clamp(0.0, 1.0).toDouble();
    // Đập được khi đủ ngưỡng VÀ store có giá (mua thật được).
    final canBreak = gems >= Balance.piggyMinBreak && price != null;

    return ClayTile(
      child: Row(
        children: [
          const Text('🐷', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.piggyName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatNumber(gems)} / ${formatNumber(Balance.piggyMaxGems)} 💎',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: canBreak ? onBreak : null,
            child: Text(
              price != null ? '${l10n.piggyBreak} $price' : l10n.piggyBreak,
            ),
          ),
        ],
      ),
    );
  }
}
