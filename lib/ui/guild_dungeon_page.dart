/// Phó bản Hội hàng tuần: ba thanh (chạm / gác đêm / Công thức) phải đầy cùng lúc mới qua ải, mỗi người
/// chọn một vai trò (đóng góp đúng vai ×1.5). Xem PROPOSAL_GUILD_DUNGEON.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/guild_dungeon.dart';
import '../guild/guild_dungeon_controller.dart';
import '../guild/guild_controller.dart';
import '../guild/guild_dungeon_repository.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import 'guild_chat_page.dart' show showGuildChat;
import 'guild_page.dart' show guildFailureText;
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/motion.dart' show PopIn, reduceMotion;
import 'widgets/one_shot_lottie.dart';
import 'widgets/phone_width.dart';

const _barEmoji = {DungeonBar.tap: '⚔️', DungeonBar.off: '🌙', DungeonBar.rec: '📜'};

String _barLabel(AppLocalizations l10n, DungeonBar b) => switch (b) {
      DungeonBar.tap => l10n.guildDungeonBarTap,
      DungeonBar.off => l10n.guildDungeonBarOff,
      DungeonBar.rec => l10n.guildDungeonBarRec,
    };

String _roleLabel(AppLocalizations l10n, DungeonBar b) => switch (b) {
      DungeonBar.tap => l10n.guildDungeonRoleTap,
      DungeonBar.off => l10n.guildDungeonRoleOff,
      DungeonBar.rec => l10n.guildDungeonRoleRec,
    };

/// Giá trị thanh để hiện: offline tính bằng giờ, hai thanh kia là số nguyên gọn.
String _barValue(AppLocalizations l10n, DungeonBar b, int v) => b == DungeonBar.off
    ? l10n.guildDungeonHours(formatNumber(v / 3600.0, decimals: 1))
    : formatNumber(v.toDouble(), decimals: 0);

void _snack(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(text)));

/// Thẻ gọn trên màn Hội: số ải đã qua + ba thanh nhỏ của ải đang đánh; chạm để mở chi tiết.
class GuildDungeonCard extends ConsumerStatefulWidget {
  const GuildDungeonCard({super.key});

  @override
  ConsumerState<GuildDungeonCard> createState() => _GuildDungeonCardState();
}

class _GuildDungeonCardState extends ConsumerState<GuildDungeonCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(guildDungeonControllerProvider.notifier).refresh(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = ref.watch(guildDungeonControllerProvider).data;
    if (d == null) return const SizedBox.shrink();
    return ClayTile(
      key: const Key('guild-dungeon-card'),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GuildDungeonPage())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏰', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.guildDungeonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (d.claimableCount > 0)
              PopIn(
                child: Container(
                  key: const Key('guild-dungeon-dot'),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(l10n.guildDungeonCardSub(d.cleared),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelMedium),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            for (final b in DungeonBar.values) ...[
              Expanded(child: _MiniBar(state: d, bar: b)),
              if (b != DungeonBar.rec) const SizedBox(width: 8),
            ],
          ]),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.state, required this.bar});
  final DungeonState state;
  final DungeonBar bar;

  @override
  Widget build(BuildContext context) {
    final done = state.barDone(bar);
    return Row(children: [
      Text(_barEmoji[bar]!, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Expanded(child: _Bar(state: state, bar: bar, height: 6, done: done)),
    ]);
  }
}

/// Thanh tiến độ của ải đang đánh: trượt mượt tới giá trị mới, xanh khi đủ.
class _Bar extends StatelessWidget {
  const _Bar({required this.state, required this.bar, required this.height, required this.done});
  final DungeonState state;
  final DungeonBar bar;
  final double height;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final target = state.targets.length >= state.currentStage
        ? (state.targets[state.currentStage - 1][bar] ?? 0)
        : 0;
    final v = target <= 0 ? 0.0 : ((state.bars[bar] ?? 0) / target).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: v),
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, value, _) => LinearProgressIndicator(
          key: Key('guild-dungeon-bar-${bar.wire}'),
          value: value,
          minHeight: height,
          color: done ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class GuildDungeonPage extends ConsumerStatefulWidget {
  const GuildDungeonPage({super.key});

  @override
  ConsumerState<GuildDungeonPage> createState() => _GuildDungeonPageState();
}

class _GuildDungeonPageState extends ConsumerState<GuildDungeonPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(guildDungeonControllerProvider.notifier).refresh(silent: true);
    });
  }

  Future<void> _setRole(DungeonBar role) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await ref.read(guildDungeonControllerProvider.notifier).setRole(role);
    if (!mounted || out.ok) return;
    _snack(context, guildFailureText(l10n, out.failure!));
  }

  Future<void> _claim(int stage) async {
    final l10n = AppLocalizations.of(context)!;
    final out = await ref.read(guildDungeonControllerProvider.notifier).claim(stage);
    if (!mounted) return;
    if (!out.ok) {
      _snack(context, guildFailureText(l10n, out.failure!));
      return;
    }
    playEffect(context, stage == dungeonChestStage ? AnimAssets.confetti : AnimAssets.sparkle,
        heavy: stage == dungeonChestStage);
    _snack(
        context,
        out.drop == null
            ? l10n.guildDungeonClaimedSnack(out.coins, out.gems)
            : l10n.guildDungeonClaimedSnackChest(
                out.coins, out.gems, accessoryName(l10n, out.drop!.accessory.id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final view = ref.watch(guildDungeonControllerProvider);
    final d = view.data;
    // Hiệu ứng khi đang xem mà một ải xong / một thanh đầy (chỉ khi tiến lên).
    ref.listen(guildDungeonControllerProvider.select((v) => v.data), (prev, next) {
      if (prev == null || next == null) return;
      if (next.cleared > prev.cleared) {
        playEffect(context, AnimAssets.confetti);
      } else if (DungeonBar.values.any((b) => next.barDone(b) && !prev.barDone(b))) {
        playEffect(context, AnimAssets.sparkle, heavy: false);
      }
    });
    return PhoneWidth(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.guildDungeonTitle)),
        body: d == null
            ? Center(
                child: view.loading
                    ? const CircularProgressIndicator()
                    : Text(l10n.guildErrNetwork, textAlign: TextAlign.center))
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(guildDungeonControllerProvider.notifier).refresh(silent: true, force: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    ClayCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(l10n.guildDungeonStage(d.currentStage),
                                  key: const Key('guild-dungeon-stage'),
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            Text(l10n.guildBossTier(d.tier + 1), style: theme.textTheme.labelMedium),
                          ]),
                          const SizedBox(height: 8),
                          for (final b in DungeonBar.values) _BarRow(state: d, bar: b),
                          const SizedBox(height: 4),
                          Text(l10n.guildDungeonHint, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RoleCard(state: d, onPick: _setRole),
                    const SizedBox(height: 8),
                    for (var s = 1; s <= dungeonStages; s++) _StageRow(state: d, stage: s, onClaim: _claim),
                    const SizedBox(height: 8),
                    Text(l10n.guildDungeonBoard,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    for (final m in d.board) _BoardRow(member: m, state: d),
                  ],
                ),
              ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.state, required this.bar});
  final DungeonState state;
  final DungeonBar bar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final done = state.barDone(bar);
    final target = state.targets.length >= state.currentStage
        ? (state.targets[state.currentStage - 1][bar] ?? 0)
        : 0;
    final cur = state.bars[bar] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_barEmoji[bar]!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(_barLabel(l10n, bar),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (done)
              const PopIn(child: Text('✅', key: Key('guild-dungeon-done'), style: TextStyle(fontSize: 16))),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text('${_barValue(l10n, bar, cur)} / ${_barValue(l10n, bar, target)}',
                    key: Key('guild-dungeon-value-${bar.wire}'), style: theme.textTheme.bodySmall),
              ),
            ),
          ]),
          const SizedBox(height: 3),
          _Bar(state: state, bar: bar, height: 10, done: done),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.state, required this.onPick});
  final DungeonState state;
  final void Function(DungeonBar) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locked = state.role != null && !state.canChangeRole;
    return ClayCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.guildDungeonRoleHeader,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in DungeonBar.values)
                ChoiceChip(
                  key: Key('guild-dungeon-role-${b.wire}'),
                  selected: state.role == b,
                  avatar: Text(_barEmoji[b]!),
                  label: Text(_roleLabel(l10n, b)),
                  onSelected: locked || state.role == b ? null : (_) => onPick(b),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.role == null
                ? l10n.guildDungeonNoRole
                : locked
                    ? l10n.guildDungeonRoleLockedNote
                    : l10n.guildDungeonRoleHint,
            key: const Key('guild-dungeon-role-note'),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.state, required this.stage, required this.onClaim});
  final DungeonState state;
  final int stage;
  final void Function(int) onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cleared = stage <= state.cleared;
    final claimed = state.claimed.contains(stage);
    final coins = dungeonRewardCoins[stage - 1];
    final gems = dungeonRewardGems[stage - 1];
    final label = claimed
        ? l10n.guildDungeonClaimed
        : stage == dungeonChestStage
            ? l10n.guildDungeonClaimFinal(coins, gems)
            : l10n.guildDungeonClaim(coins);
    return ClayTile(
      key: Key('guild-dungeon-stage-$stage'),
      child: Row(children: [
        Text(cleared ? '✅' : '🔒', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.guildDungeonStage(stage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (cleared && !claimed && !state.meetsMinimum)
                Text(l10n.guildDungeonNeedMin,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: FilledButton(
              key: Key('guild-dungeon-claim-$stage'),
              onPressed: state.canClaim(stage) ? () => onClaim(stage) : null,
              child: Text(label),
            ),
          ),
        ),
      ]),
    );
  }
}

class _BoardRow extends ConsumerWidget {
  const _BoardRow({required this.member, required this.state});
  final DungeonMember member;
  final DungeonState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = [
      for (final b in DungeonBar.values) '${_barEmoji[b]} ${_barValue(l10n, b, member.of(b))}',
    ].join('  ');
    // Nhắc người khác trong chat về thanh còn thiếu đầu tiên của ải đang đánh (không nhắc chính mình).
    final view = ref.watch(guildControllerProvider);
    final isMe = view is GuildMine && view.myUserId == member.userId;
    DungeonBar? missing;
    for (final b in DungeonBar.values) {
      if (!state.barDone(b)) {
        missing = b;
        break;
      }
    }
    return ClayTile(
      key: Key('guild-dungeon-member-${member.userId}'),
      child: Row(children: [
        Text(member.role == null ? '·' : _barEmoji[member.role!]!, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(stats, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (!isMe && missing != null)
          IconButton(
            key: Key('guild-dungeon-nudge-${member.userId}'),
            tooltip: l10n.guildDungeonNudgeTooltip,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.alternate_email, size: 20),
            onPressed: () => showGuildChat(context,
                prefill: '@${member.nickname} ${l10n.guildDungeonNudge(_barLabel(l10n, missing!))} '),
          ),
      ]),
    );
  }
}
