/// Mục "Nhiệm vụ Hội" trên màn Hội: gom các nhiệm vụ tuần (nhiệm vụ chung của hội, nhiệm vụ cá nhân theo điểm,
/// quỹ hội) kèm tiến độ + nút nhận ngay tại đây — trước đây nằm trong Cửa hàng Hội. Logic nhận thưởng dùng chung
/// với cửa hàng (cùng hàm của [GuildController]); khoá widget có tiền tố `gq-` để không trùng khoá trang cửa hàng.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/guild_shop.dart';
import '../guild/guild_controller.dart';
import '../l10n/app_localizations.dart';
import 'guild_page.dart' show guildFailureText;
import 'guild_shop_page.dart';
import 'widgets/clay.dart';

class GuildQuestsSection extends ConsumerWidget {
  const GuildQuestsSection({super.key, required this.view});
  final GuildMine view;

  Future<void> _run(BuildContext context, Future<GuildOutcome> action, String Function(AppLocalizations) ok) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await action;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        SnackBar(content: Text(out.ok ? ok(l10n) : guildFailureText(l10n, out.failure!))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ctrl = ref.read(guildControllerProvider.notifier);
    final g = view.guild;
    final my = view.myPoints;
    final fund = g.fund;
    final fundCanClaim = fund.reached && !fund.claimed && fund.mine >= guildFundMinDonation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
          child: Text('📋 ${l10n.guildQuestsSection}',
              key: const Key('gq-header'),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(l10n.guildQuestsSectionHint, style: theme.textTheme.bodySmall),
        ),
        // Nhiệm vụ chung: cả hội cùng tham gia.
        if (g.teamAvailable)
          _QuestTile(
            tileKey: const Key('gq-team-tile'),
            title: l10n.guildTeamTitle,
            progressText: l10n.guildTeamProgress(g.teamActive, g.teamNeed),
            progress: g.teamNeed == 0 ? 0 : g.teamActive / g.teamNeed,
            buttonKey: const Key('gq-team'),
            label: g.teamClaimed ? l10n.dailyQuestClaimed : l10n.guildTeamClaim(guildTeamReward),
            enabled: g.teamReached && !g.teamClaimed && my >= guildTeamMinPoints,
            onPressed: () => _run(context, ctrl.claimTeam(), (l) => l.guildTeamGot(guildTeamReward)),
            note: l10n.guildTeamHint(guildTeamMinPoints),
          ),
        // Nhiệm vụ cá nhân theo điểm tuần.
        for (var i = 0; i < guildQuests.length; i++)
          _QuestTile(
            tileKey: Key('gq-quest-tile-$i'),
            title: l10n.guildQuestProgress(my.clamp(0, guildQuests[i].need), guildQuests[i].need),
            progress: my / guildQuests[i].need,
            buttonKey: Key('gq-quest-$i'),
            label: g.questsClaimed.contains(i + 1)
                ? l10n.dailyQuestClaimed
                : l10n.guildQuestReward(guildQuests[i].reward),
            enabled: my >= guildQuests[i].need && !g.questsClaimed.contains(i + 1),
            onPressed: () => _run(context, ctrl.claimQuest(i), (l) => l.guildQuestGot(guildQuests[i].reward)),
          ),
        // Quỹ hội: cả hội cùng nạp 💎 (mở cửa hàng để góp).
        if (fund.available)
          _QuestTile(
            tileKey: const Key('gq-fund-tile'),
            title: l10n.guildFundTitle,
            progressText: l10n.guildFundProgress(fund.progress > fund.target ? fund.target : fund.progress, fund.target),
            progress: fund.target == 0 ? 0 : fund.progress / fund.target,
            buttonKey: const Key('gq-fund'),
            label: fund.claimed
                ? l10n.dailyQuestClaimed
                : fundCanClaim
                    ? l10n.guildFundClaim(guildFundReward)
                    : l10n.guildShopButton,
            // Chưa nhận được thì nút dẫn tới cửa hàng để góp 💎; nhận được thì nhận ngay.
            enabled: fundCanClaim || (!fund.claimed && !fund.reached),
            onPressed: fundCanClaim
                ? () => _run(context, ctrl.claimFund(), (l) => l.guildFundGot(guildFundReward))
                : () => showGuildShop(context),
            note: l10n.guildFundMine(fund.mine),
          ),
      ],
    );
  }
}

/// Một nhiệm vụ: tiêu đề + thanh tiến độ + (ghi chú) + nút nhận/hành động.
class _QuestTile extends StatelessWidget {
  const _QuestTile({
    required this.tileKey,
    required this.title,
    required this.progress,
    required this.buttonKey,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.progressText,
    this.note,
  });

  final Key tileKey;
  final String title;
  final String? progressText;
  final String? note;
  final double progress;
  final Key buttonKey;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final details = [
      if (progressText != null) Text(progressText!, style: theme.textTheme.bodySmall),
      if (note != null)
        Text(note!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    ];
    // Tiêu đề + thanh tiến độ chiếm TRỌN bề ngang (trước đây bị nút ép hẹp nên tiêu đề rớt 3 dòng);
    // nút nhỏ gọn nằm hàng dưới, cạnh phần ghi chú.
    return ClayTile(
      key: tileKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0).toDouble(), minHeight: 8),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: details),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: FilledButton(
                  key: buttonKey,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: enabled ? onPressed : null,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, textAlign: TextAlign.center)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
