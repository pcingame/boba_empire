/// Boss Thế Giới: thanh máu chung của cả server, sát thương của bạn, 5 mốc thưởng và bảng top sát thương.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../core/world_boss.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import '../world_boss/world_boss.dart';
import 'email_gate.dart';
import 'widgets/anim_assets.dart';
import 'widgets/clay.dart';
import 'widgets/mascot.dart';
import 'widgets/motion.dart';
import 'widgets/phone_width.dart';

Future<void> showWorldBoss(BuildContext context) async {
  if (!await ensureOnlineLinked(context) || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WorldBossPage()));
  container.invalidate(worldBossAlertProvider);
}

String _bossName(AppLocalizations l, int i) => switch (i) {
      0 => l.worldBossName0,
      1 => l.worldBossName1,
      2 => l.worldBossName2,
      3 => l.worldBossName3,
      4 => l.worldBossName4,
      5 => l.worldBossName5,
      6 => l.worldBossName6,
      _ => l.worldBossName7,
    };

class WorldBossPage extends ConsumerStatefulWidget {
  const WorldBossPage({super.key});
  @override
  ConsumerState<WorldBossPage> createState() => _State();
}

class _State extends ConsumerState<WorldBossPage> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Máu chung đổi liên tục khi cả server đánh → làm mới nền mỗi 20 giây trong lúc đang xem.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.read(worldBossControllerProvider.notifier).refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _claim(int phase) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gems = await ref.read(worldBossControllerProvider.notifier).claim(phase);
      if (mounted) _snack(l10n.worldBossClaimedSnack(gems));
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  Future<void> _claimDay(int phase) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final (_, xu) = await ref.read(worldBossControllerProvider.notifier).claimDay(phase);
      if (mounted) _snack(l10n.worldBossDayClaimedSnack(formatNumber(xu)));
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  Future<void> _buyAuto() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await ref.read(worldBossControllerProvider.notifier).buyAuto();
      if (mounted) _snack(ok ? l10n.worldBossAutoSnack : l10n.worldBossNotEnoughGems);
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  bool _watching = false;

  Future<void> _adStrike() async {
    if (_watching) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _watching = true);
    String? msg;
    try {
      final left = await ref.read(worldBossControllerProvider.notifier).adStrike();
      if (left == null) {
        msg = l10n.adNotReadySnack;
      } else {
        msg = l10n.worldBossAdSnack(worldBossAdDamage);
        if (mounted && !reduceMotion) _shake.forward(from: 0);
      }
    } catch (e) {
      msg = '$e'.contains('ad limit') ? l10n.worldBossAdNone : l10n.friendsErrNetwork;
    }
    if (!mounted) return;
    setState(() => _watching = false);
    _snack(msg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(worldBossControllerProvider);
    // Máu giảm so với lần trước → boss rung lên.
    ref.listen(worldBossControllerProvider.select((a) => a.value?.damage ?? 0), (prev, next) {
      if (prev != null && next > prev && !reduceMotion) _shake.forward(from: 0);
    });
    return PhoneWidth(
      child: Scaffold(
        key: const Key('world-boss'),
        appBar: AppBar(title: Text(l10n.worldBossTitle)),
        body: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.friendsErrNetwork, key: const Key('wb-error'), textAlign: TextAlign.center),
                TextButton(
                  key: const Key('wb-retry'),
                  onPressed: () => ref.read(worldBossControllerProvider.notifier).refresh(),
                  child: Text(l10n.friendsRetry),
                ),
              ]),
            ),
          ),
          data: (s) {
            Widget body(WorldBossState v, {required bool daily}) => _Body(
                  s: v,
                  daily: daily,
                  shake: _shake,
                  onClaim: daily ? _claimDay : _claim,
                  onBuyAuto: _buyAuto,
                  onAd: _adStrike,
                  watching: _watching,
                  onHit: () async {
                    await ref.read(worldBossControllerProvider.notifier).refresh(silent: true);
                    if (mounted && !reduceMotion) _shake.forward(from: 0);
                  },
                );
            final day = s.daily;
            if (day == null) return body(s, daily: false); // server chưa chạy bản SQL có boss ngày
            return DefaultTabController(
              length: 2,
              child: Column(children: [
                TabBar(tabs: [
                  Tab(key: const Key('wb-tab-day'), text: l10n.worldBossTabDay),
                  Tab(key: const Key('wb-tab-week'), text: l10n.worldBossTabWeek),
                ]),
                Expanded(child: TabBarView(children: [body(day, daily: true), body(s, daily: false)])),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.s, required this.daily, required this.shake, required this.onClaim, required this.onHit, required this.onBuyAuto, required this.onAd, required this.watching});
  final WorldBossState s;

  /// true = boss ngày (Frankenstein, thưởng Xu), false = boss tuần (sói, thưởng 💎).
  final bool daily;
  final AnimationController shake;
  final Future<void> Function(int phase) onClaim;
  final Future<void> Function() onHit;
  final Future<void> Function() onBuyAuto;
  final Future<void> Function() onAd;
  final bool watching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nowSec = ref.read(clockProvider)() ~/ 1000;
    final closed = !daily && !s.open;
    final left = ((closed ? s.startsAtSeconds : s.endsAtSeconds) - nowSec).clamp(0, 1 << 40);
    final frac = s.hp == 0 ? 0.0 : s.hpLeft / s.hp;
    return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 24), children: [
      ClayCard(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(daily ? l10n.worldBossDailyName : _bossName(l10n, s.boss),
              key: const Key('wb-name'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(math.sin(shake.value * math.pi * 7) * 10 * (1 - shake.value), 0),
              child: child,
            ),
            // Cùng một animation sói (màu gốc) cho cả 8 boss; hạ gục → xám + mờ.
            child: Opacity(
              opacity: s.defeated ? 0.35 : 1,
              child: ColorFiltered(
                key: const Key('wb-boss'),
                colorFilter: s.defeated
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Mascot(
                    asset: daily ? AnimAssets.bossFrankenstein : AnimAssets.bossWolfie,
                    emoji: daily ? '🧟' : worldBossEmoji[s.boss],
                    size: 200),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Thanh máu còn lại, có vạch ở 4 mốc 80/60/40/20% (mốc 5 = hết máu).
          LayoutBuilder(builder: (context, box) => SizedBox(
            height: 20,
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  key: const Key('wb-hp-bar'),
                  value: frac,
                  minHeight: 20,
                  color: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              for (var p = 1; p < worldBossPhases; p++)
                Positioned(
                  left: box.maxWidth * (1 - p / worldBossPhases) - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                ),
            ]),
          )),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              s.defeated
                  ? l10n.worldBossDefeated
                  : l10n.worldBossHp(formatNumber(s.hpLeft.toDouble()), formatNumber(s.hp.toDouble())),
              key: const Key('wb-hp-text'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(closed ? l10n.worldBossOpensIn(formatDuration(left.toInt())) : l10n.worldBossEndsIn(formatDuration(left.toInt())),
              key: const Key('wb-ends'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          Text(l10n.worldBossPlayers(s.players), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          FilledButton(key: const Key('wb-hit'), onPressed: closed ? null : onHit, child: Text('⚔️ ${l10n.worldBossHit}')),
          const SizedBox(height: 6),
          OutlinedButton(
            key: const Key('wb-ad'),
            onPressed: s.adLeft > 0 && !watching && !closed ? onAd : null,
            child: Text(l10n.worldBossAdButton(worldBossAdDamage, s.adLeft, worldBossAdPerDay), textAlign: TextAlign.center),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      ClayTile(
        child: Row(children: [
          Expanded(child: Text(l10n.worldBossMine(formatNumber(s.mine.toDouble())), key: const Key('wb-mine'))),
          if (s.rank != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l10n.worldBossRank(s.rank!), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
      ClayTile(
        key: const Key('wb-auto'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.worldBossAutoTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(l10n.worldBossAutoDesc(worldBossAutoPerHour), style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          if (s.auto)
            Text(l10n.worldBossAutoOn, key: const Key('wb-auto-on'), style: const TextStyle(fontWeight: FontWeight.w700))
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: FilledButton.tonal(
                key: const Key('wb-auto-buy'),
                onPressed: onBuyAuto,
                child: Text(l10n.worldBossAutoBuy(worldBossAutoGems)),
              ),
            ),
        ]),
      ),
      if (!s.meetsMinimum)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(l10n.worldBossNeedDamage(s.minDamage),
              key: const Key('wb-need'), style: theme.textTheme.bodySmall),
        ),
      for (var p = 1; p <= worldBossPhases; p++)
        ClayTile(
          key: Key('wb-phase-$p'),
          child: Row(children: [
            Expanded(
              child: Text(
                  daily
                      ? '${l10n.worldBossPhase(p * 100 ~/ worldBossPhases)}  ·  💰 ${l10n.worldBossDayXu(worldBossDayPhaseSeconds[p - 1] ~/ 60)}${worldBossDayPhaseGems[p - 1] > 0 ? '  ·  💎 ${worldBossDayPhaseGems[p - 1]}' : ''}'
                      : '${l10n.worldBossPhase(p * 100 ~/ worldBossPhases)}  ·  💎 ${worldBossPhaseGems[p - 1]}  ·  💰 ${l10n.worldBossDayXu(worldBossPhaseSeconds[p - 1] ~/ 60)}${p == worldBossPhases ? ' 🎁' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: s.claimed.contains(p)
                    ? Text('✓ ${l10n.worldBossClaimed}')
                    : FilledButton(
                        key: Key('wb-claim-$p'),
                        onPressed: s.canClaim(p) ? () => onClaim(p) : null,
                        child: Text(s.phaseReached(p) ? l10n.worldBossClaim : l10n.worldBossLocked),
                      ),
              ),
            ),
          ]),
        ),
      const SizedBox(height: 12),
      Text(l10n.worldBossBoard, style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      if (s.board.isEmpty)
        Text(l10n.worldBossBoardEmpty, key: const Key('wb-board-empty'))
      else
        for (var i = 0; i < s.board.length; i++)
          Padding(
            key: Key('wb-row-${i + 1}'),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 36, child: Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
              Expanded(child: Text(s.board[i].nickname, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(formatNumber(s.board[i].damage.toDouble())),
                ),
              ),
            ]),
          ),
      const SizedBox(height: 12),
      Text(daily ? l10n.worldBossDayHow : l10n.worldBossHow, key: const Key('wb-how'), style: theme.textTheme.bodySmall),
    ]);
  }
}
