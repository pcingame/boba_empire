/// Thưởng top bảng xếp hạng tuần: danh sách thưởng của mình (🥇🥈🥉 + bảng + tuần) và nút nhận.
/// Server chốt top 3 mỗi bảng vào đầu tuần (xem supabase/leaderboard_rewards_schema.sql).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/lb_rewards.dart';
import '../l10n/app_localizations.dart';
import '../leaderboard/lb_rewards.dart';
import 'widgets/clay.dart';

Future<void> showLbRewards(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _LbRewardsDialog(),
    );

String _boardName(AppLocalizations l10n, LbBoard b) => switch (b) {
      LbBoard.income => l10n.lbrBoardIncome,
      LbBoard.pearls => l10n.lbrBoardPearls,
      LbBoard.collection => l10n.lbrBoardCollection,
      LbBoard.vip => l10n.lbrBoardVip,
      LbBoard.recipes => l10n.lbrBoardRecipes,
    };

/// 'yyyy-mm-dd' → 'dd/mm' (không đoán múi giờ: tuần chốt đã là ngày UTC).
String _shortDate(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
}

class _LbRewardsDialog extends ConsumerStatefulWidget {
  const _LbRewardsDialog();

  @override
  ConsumerState<_LbRewardsDialog> createState() => _LbRewardsDialogState();
}

class _LbRewardsDialogState extends ConsumerState<_LbRewardsDialog> {
  @override
  void initState() {
    super.initState();
    // Mở hộp là tải mới ngay (bỏ giới hạn tần suất) — đúng lúc người chơi muốn xem.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(lbRewardsControllerProvider.notifier).refresh(force: true));
  }

  Future<void> _claim(LbReward r) async {
    final l10n = AppLocalizations.of(context)!;
    String text;
    try {
      final gems = await ref.read(lbRewardsControllerProvider.notifier).claim(r);
      text = gems > 0 ? l10n.lbrGot(gems) : '';
    } on LbRewardException catch (e) {
      text = switch (e.failure) {
        LbRewardFailure.alreadyClaimed => l10n.guildErrClaimed,
        LbRewardFailure.notFound => l10n.lbrErrGone,
        LbRewardFailure.notLinked => l10n.emailGateOnlineBody,
        LbRewardFailure.network => l10n.guildErrNetwork,
      };
    } catch (_) {
      text = l10n.guildErrNetwork;
    }
    if (!mounted || text.isEmpty) return;
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(lbRewardsControllerProvider);
    const medals = ['🥇', '🥈', '🥉'];
    return AlertDialog(
      title: Text(l10n.lbrTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lbrIntro(lbRewardGemsByRank[0], lbRewardGemsByRank[1], lbRewardGemsByRank[2]),
              key: const Key('lbr-intro'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (!state.loaded)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.rewards.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.lbrEmpty, key: const Key('lbr-empty')),
              )
            else
              for (final r in state.rewards)
                ClayTile(
                  key: Key('lbr-${r.id}'),
                  child: Row(
                    children: [
                      Text(medals[(r.rank - 1).clamp(0, 2)], style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.lbrRow(_boardName(l10n, r.board), _shortDate(r.week)),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FilledButton(
                          key: Key('lbr-claim-${r.id}'),
                          onPressed: r.claimed ? null : () => _claim(r),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(r.claimed ? l10n.dailyQuestClaimed : l10n.lbrClaim(r.gems)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
    );
  }
}
