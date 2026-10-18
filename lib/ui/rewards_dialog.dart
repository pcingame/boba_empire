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
import 'daily_hub_dialog.dart';
import 'wheel_dialog.dart';
import 'widgets/clay.dart';
import 'email_gate.dart';
import 'invite_dialog.dart';
import '../referral/referral_repository.dart';

/// "Kiếm thêm 🎁" — các ưu đãi xem quảng cáo thưởng: x2 thu nhập 24h, nhận Kim
/// Cương, tua nhanh. Người đã mua "Gỡ QC" nhận thẳng, không phải xem.
Future<void> showRewards(BuildContext context) => showDailyHub(context, DailyHubTab.rewards);

class RewardsPanel extends ConsumerStatefulWidget {
  const RewardsPanel({super.key, this.embedded = false});

  /// true: chỉ phần nội dung (không khung hộp thoại) — dùng trong hộp thoại gộp có tab (daily_hub_dialog.dart).
  final bool embedded;

  @override
  ConsumerState<RewardsPanel> createState() => _RewardsDialogState();
}

class _RewardsDialogState extends ConsumerState<RewardsPanel> {
  bool _busy = false;
  late final Future<Map<IapProduct, String>> _prices = ref
      .read(iapServiceProvider)
      .loadPrices();

  /// Xem QC (hoặc bỏ qua nếu đã mua Gỡ QC) → nếu nhận thưởng thì gọi [onEarned].
  Future<void> _watch(void Function() onEarned) async {
    if (_busy) return;
    setState(() => _busy = true);
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree
        ? RewardOutcome.earned
        : await ref.read(adServiceProvider).showRewardedAd();
    if (!mounted) return;
    if (outcome == RewardOutcome.earned) {
      ref.read(audioServiceProvider).play(Sfx.reward);
      onEarned();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(gameControllerProvider.notifier);
    final x2sec = ref.watch(
      gameControllerProvider.select((s) => s.x2IncomeRemainingSeconds),
    );
    final x2Hours = (x2sec / 3600).ceil();
    final autoTapSec = ref.watch(
      gameControllerProvider.select((s) => s.autoTapRemainingSeconds),
    );
    final autoTapVip = ref.watch(
      gameControllerProvider.select((s) => s.autoTapActive && s.autoTapRemainingSeconds <= 0),
    );
    final piggy = ref.watch(gameControllerProvider.select((s) => s.piggyGems));
    final freeSpin = ref.watch(
      gameControllerProvider.select((s) => s.freeSpinAvailable),
    );

    final body = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vòng quay may mắn — có badge "miễn phí" khi còn lượt hôm nay.
            _WheelRow(free: freeSpin, onTap: () => showWheel(context)),
            // Heo đất (IAP) — nổi bật ở trên cùng.
            FutureBuilder<Map<IapProduct, String>>(
              future: _prices,
              builder: (context, snap) => _PiggyCard(
                gems: piggy,
                price: snap.data?[IapProduct.piggyBreak],
                onBreak: () async {
                  // Nạp tiền thật cần đã liên kết email (xem email_gate.dart).
                  if (!await ensureEmailLinked(context, ref)) return;
                  if (!mounted) return;
                  ref.read(iapServiceProvider).buy(IapProduct.piggyBreak);
                },
              ),
            ),
            // Cùng dạng hàng + nút như các mục "Xem QC" bên dưới để nhìn ra đây là thứ bấm được.
            _OfferRow(
              emoji: '',
              name: l10n.refEntry,
              note: l10n.refEntryNote(referralInviterReward),
              busy: false,
              buttonKey: const Key('rewards-invite'),
              buttonLabel: l10n.refShare,
              buttonIcon: Icons.group_add,
              onWatch: () async {
                // Mời bạn gắn với tài khoản: cần đã liên kết email (xem email_gate.dart).
                if (!await ensureEmailLinked(context, ref)) return;
                if (!context.mounted) return;
                showInviteDialog(context);
              },
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
              key: const Key('reward-auto-tap'),
              emoji: '🤖',
              name: l10n.rewardAutoTapName(Balance.autoTapAdMs ~/ 60000),
              note: autoTapVip
                  ? l10n.rewardAutoTapVip(Balance.autoTapVipLevel)
                  : autoTapSec > 0
                      ? l10n.rewardAutoTapActive(formatDuration(autoTapSec.ceil()))
                      : l10n.rewardAutoTapHint(Balance.autoTapVipLevel),
              busy: _busy,
              onWatch: () => _watch(() {
                controller.activateAutoTap();
                _snack(l10n.rewardAutoTapSnack);
              }),
            ),
            _OfferRow(
              emoji: '💎',
              name: l10n.rewardGemsName(Balance.rewardedFreeGems),
              busy: _busy,
              onWatch: () => _watch(() {
                controller.grantFreeGems();
                _snack(
                  l10n.iapGemsSnack(
                    formatNumber(Balance.rewardedFreeGems.toDouble()),
                  ),
                );
              }),
            ),
            _OfferRow(
              emoji: '⏩',
              name: l10n.rewardTimeSkip(
                Balance.rewardedTimeSkipSeconds ~/ 3600,
              ),
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
      );
    if (widget.embedded) return body;
    return AlertDialog(
      title: Text(l10n.rewardsTitle),
      content: body,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Hàng "Vòng quay may mắn" mở dialog quay; badge sáng khi còn lượt miễn phí.
class _WheelRow extends StatelessWidget {
  const _WheelRow({required this.free, required this.onTap});

  final bool free;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return ClayTile(
      child: Row(
        children: [
          const Text('🎡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // wheelName đã có 🎡 ở cuối (dùng cho tiêu đề hộp thoại) mà hàng này
                  // đã có 🎡 bên trái — bỏ bớt để chữ không xuống dòng lẻ một emoji.
                  l10n.wheelName.replaceAll('🎡', '').trim(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (free)
                  Text(
                    l10n.spinFree,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Nút icon-only mở dialog: nhãn free/ad dài theo ngôn ngữ nên chỉ
          // hiển thị trong subtitle + trong dialog để hàng không tràn ngang.
          IconButton.filled(
            key: const Key('open-wheel'),
            onPressed: onTap,
            tooltip: l10n.wheelName,
            icon: const Icon(Icons.casino),
          ),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow({
    super.key,
    required this.emoji,
    required this.name,
    required this.busy,
    required this.onWatch,
    this.note,
    this.buttonKey,
    this.buttonLabel,
    this.buttonIcon = Icons.play_circle_outline,
  });

  final Key? buttonKey;

  /// Null = nhãn "Xem QC".
  final String? buttonLabel;
  final IconData buttonIcon;
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
          if (emoji.isNotEmpty) ...[
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Flexible + FittedBox: nhãn dài (en/es/id/pt) co lại thay vì tràn ở màn hẹp.
          Flexible(
            child: FilledButton.icon(
              key: buttonKey,
              onPressed: busy ? null : onWatch,
              icon: Icon(buttonIcon, size: 20),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(buttonLabel ?? l10n.watchAd)),
            ),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
