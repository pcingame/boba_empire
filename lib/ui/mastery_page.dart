/// "Bí quyết": tiêu 🧪 Tinh chất (kiếm từ trò nhỏ) để tăng thu nhập theo từng giai đoạn. Giữ qua Nhượng
/// quyền và Kỷ Nguyên. Xem PROPOSAL_ESSENCE_MASTERY.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/balance.dart';
import '../core/essence.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';
import 'widgets/clay.dart';
import 'widgets/phone_width.dart';
import 'widgets/trailing_box.dart';

Future<void> showMasteryPage(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MasteryPage()));

/// Nút 🧪 trên thanh tiêu đề các trò nhỏ: kèm số Tinh chất đang có, bấm mở màn Bí quyết.
class EssenceAppBarButton extends ConsumerWidget {
  const EssenceAppBarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final essence = ref.watch(gameControllerProvider.select((s) => s.essence));
    return IconButton(
      key: const Key('essence-button'),
      tooltip: AppLocalizations.of(context)!.masteryTitle,
      icon: Badge(
        isLabelVisible: essence > 0,
        label: Text('$essence'),
        child: const Text('🧪', style: TextStyle(fontSize: 20)),
      ),
      onPressed: () => showMasteryPage(context),
    );
  }
}

/// "+16%" gọn: số nguyên thì không để phần thập phân.
String _pct(double fraction) {
  final t = (fraction * 100).toStringAsFixed(1);
  return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
}

class MasteryPage extends ConsumerWidget {
  const MasteryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final essence = ref.watch(gameControllerProvider.select((s) => s.essence));
    final current = ref.watch(gameControllerProvider.select((s) => s.stage));
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.masteryTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ClayCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.masteryEssence(essence),
                      key: const Key('mastery-essence'),
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(l10n.masteryHint, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (var stage = 1; stage <= Balance.stages.length; stage++)
              _StageRow(stage: stage, isCurrent: stage == current, essence: essence),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends ConsumerWidget {
  const _StageRow({required this.stage, required this.isCurrent, required this.essence});

  final int stage;
  final bool isCurrent;
  final int essence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Chỉ dựng lại khi bậc CỦA GIAI ĐOẠN NÀY đổi (int so sánh theo giá trị).
    final tier = ref.watch(gameControllerProvider.select((s) => masteryTier(s.masteryTiers, stage)));
    final cost = masteryNextCost(tier);
    final canBuy = cost != null && essence >= cost;
    return ClayTile(
      key: Key('mastery-row-$stage'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isCurrent ? '⭐ ' : ''}${stageName(l10n, stage)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'●' * tier}${'○' * (Balance.masteryMaxTier - tier)}',
                  key: Key('mastery-dots-$stage'),
                  style: theme.textTheme.bodyMedium,
                ),
                if (tier > 0)
                  Text(
                    l10n.masteryBonus(_pct(tier * Balance.masteryPerTier)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TrailingBox(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: cost == null
                  ? Text(l10n.masteryMaxed,
                      key: Key('mastery-max-$stage'),
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800))
                  : FilledButton(
                      key: Key('mastery-buy-$stage'),
                      onPressed: canBuy
                          ? () {
                              if (ref.read(gameControllerProvider.notifier).buyMasteryTier(stage)) {
                                HapticFeedback.mediumImpact();
                              }
                            }
                          : null,
                      child: Text(l10n.masteryBuy(cost)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
