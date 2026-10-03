/// Nhiệm vụ hằng ngày — 3 nhiệm vụ + thưởng "xong cả bộ". Mở từ chip "Nhiệm vụ"
/// ở đầu màn chính (không tự bật popup: chuỗi popup mở app đã dài).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_service.dart';
import '../core/accessories.dart';
import '../core/balance.dart';
import '../core/daily_quests.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import '../state/game_snapshot.dart';
import 'widgets/accessory_rarity.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart';
import 'widgets/one_shot_lottie.dart';

Future<void> showDailyQuests(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _DailyQuestsDialog(),
  );
}

String _title(AppLocalizations l10n, DailyQuestView q) => switch (q.kind) {
      DailyQuestKind.tap => l10n.dqTap(q.target.toInt()),
      DailyQuestKind.buy => l10n.dqBuy(q.target.toInt()),
      DailyQuestKind.earn => l10n.dqEarn(formatNumber(q.target)),
      DailyQuestKind.cat => l10n.dqCat,
      DailyQuestKind.vip => l10n.dqVip,
      DailyQuestKind.spin => l10n.dqSpin,
    };

class _DailyQuestsDialog extends ConsumerStatefulWidget {
  const _DailyQuestsDialog();

  @override
  ConsumerState<_DailyQuestsDialog> createState() => _DailyQuestsDialogState();
}

class _DailyQuestsDialogState extends ConsumerState<_DailyQuestsDialog> {
  /// Phụ kiện vừa rớt khi nhận thưởng "xong cả bộ" — hiện NỘI TUYẾN ngay trong hộp
  /// thoại (không thêm popup mới; chuỗi popup mở app đã dài). Chỉ trong phiên hộp
  /// thoại này: mở lại sau đó thì không còn (đã có trong Kho).
  AccessoryDrop? _revealed;

  void _claimBonus() {
    final controller = ref.read(gameControllerProvider.notifier);
    final got = controller.claimDailyBonus();
    if (got <= 0) return;
    HapticFeedback.mediumImpact();
    ref.read(audioServiceProvider).play(Sfx.reward);
    final drop = controller.lastAccessoryDrop;
    if (drop == null) return;
    setState(() => _revealed = drop);
    // Sử thi/Huyền thoại đáng ăn mừng: pháo giấy (huyền thoại thêm rung mạnh).
    if (drop.accessory.rarity.index >= AccessoryRarity.epic.index) {
      playEffect(context, AnimAssets.confetti, size: 200);
    }
    if (drop.accessory.rarity == AccessoryRarity.legendary) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final quests = ref.watch(gameControllerProvider.select((s) => s.dailyQuests));
    final bonusAvailable = ref
        .watch(gameControllerProvider.select((s) => s.dailyBonusAvailable));
    final bonusClaimed =
        ref.watch(gameControllerProvider.select((s) => s.dailyBonusClaimed));
    // Đếm ngược tới 00:00 UTC (cùng ngày với điểm danh). Dialog build lại mỗi
    // tick vì `dailyQuests` là danh sách mới ở mỗi snapshot → số tự nhảy.
    final now = ref.read(clockProvider)();
    const msPerDay = 24 * 60 * 60 * 1000;
    final secondsLeft = ((msPerDay - now % msPerDay) / 1000).ceil();
    final controller = ref.read(gameControllerProvider.notifier);

    void claim(int Function() action) {
      if (action() > 0) {
        HapticFeedback.mediumImpact();
        ref.read(audioServiceProvider).play(Sfx.reward);
      }
    }

    return AlertDialog(
      title: Text(l10n.dailyQuestsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < quests.length; i++)
              _QuestRow(
                title: _title(l10n, quests[i]),
                view: quests[i],
                onClaim: () => claim(() => controller.claimDailyQuestReward(i)),
              ),
            ClayTile(
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.dailyQuestsBonusLabel,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: FilledButton(
                      key: const Key('daily-quest-bonus'),
                      onPressed: bonusAvailable ? _claimBonus : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(bonusClaimed
                            ? l10n.dailyQuestClaimed
                            : l10n.dailyReward('${Balance.dailyQuestBonusGems}')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_revealed != null) _AccessoryReveal(drop: _revealed!),
            const SizedBox(height: 8),
            Text(
              l10n.dailyQuestsResetsIn(formatDuration(secondsLeft)),
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

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.title,
    required this.view,
    required this.onClaim,
  });

  final String title;
  final DailyQuestView view;
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatNumber(view.progress.clamp(0, view.target).toDouble(), decimals: 0)} / ${formatNumber(view.target.toDouble(), decimals: 0)}',
                  key: Key('daily-quest-progress-${view.kind.name}'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Flexible + FittedBox: ngưỡng "Kiếm Xu" có thể là số rất lớn và nhãn
          // nút dài ở id/th — cùng lớp bug tràn RenderFlex đã gặp ở các dialog khác.
          Flexible(
            child: FilledButton(
              key: Key('daily-quest-claim-${view.kind.name}'),
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

/// Hàng "khoảnh khắc nhận phụ kiện": emoji lớn viền theo độ hiếm + câu mới/trùng + chip độ hiếm.
class _AccessoryReveal extends StatelessWidget {
  const _AccessoryReveal({required this.drop});
  final AccessoryDrop drop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final a = drop.accessory;
    return AppearIn(
      child: ClayTile(
        key: const Key('accessory-reveal'),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityColor(a.rarity).withValues(alpha: 0.35),
                border: Border.all(color: rarityColor(a.rarity), width: 3),
              ),
              child: Text(a.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    accessoryRevealMessage(l10n, drop),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  RarityChip(
                    rarity: a.rarity,
                    label: accessoryRarityLabel(l10n, a.rarity),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
