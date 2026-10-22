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
import 'widgets/reward_burst.dart';
import 'widgets/app_dialog.dart';

Future<void> showWorldBoss(BuildContext context) async {
  if (!await ensureOnlineLinked(context) || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  await Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const WorldBossPage()));
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

class _State extends ConsumerState<WorldBossPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Máu chung đổi liên tục khi cả server đánh → làm mới nền mỗi 20 giây trong lúc đang xem.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        ref.read(worldBossControllerProvider.notifier).refresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _flush?.cancel();
    _shake.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _claim(int phase) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final gems = await ref
          .read(worldBossControllerProvider.notifier)
          .claim(phase);
      if (mounted) {
        showRewardBurst(context, emojis: const ['💎', '✨'], label: '+$gems 💎', count: 14);
        _snack(l10n.worldBossClaimedSnack(gems));
      }
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  Future<void> _claimDay(int phase) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final (_, xu) = await ref
          .read(worldBossControllerProvider.notifier)
          .claimDay(phase);
      if (mounted) {
        showRewardBurst(context, emojis: const ['🪙', '✨'], label: '+${formatNumber(xu)}', count: 14);
        _snack(l10n.worldBossDayClaimedSnack(formatNumber(xu)));
      }
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  Future<void> _buyAuto() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await ref.read(worldBossControllerProvider.notifier).buyAuto();
      if (mounted) {
        _snack(ok ? l10n.worldBossAutoSnack : l10n.worldBossNotEnoughGems);
      }
    } catch (_) {
      if (mounted) _snack(l10n.friendsErrNetwork);
    }
  }

  bool _watching = false;

  /// Chạm vào boss / nút ⚔️: +1 chạm vào bộ đếm tuần (cùng bộ đếm với chạm cốc), thanh máu giảm NGAY ở máy;
  /// gom các lần chạm 700ms rồi mới báo server + tải lại (không gọi mạng mỗi lần chạm).
  int _pending = 0;
  Timer? _flush;

  void _strike() {
    ref.read(gameControllerProvider.notifier).bossTap();
    setState(() => _pending++);
    if (!reduceMotion) _shake.forward(from: 0);
    _flush?.cancel();
    _flush = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      await ref
          .read(worldBossControllerProvider.notifier)
          .refresh(silent: true);
      if (mounted) setState(() => _pending = 0);
    });
  }

  Future<void> _adStrike() async {
    if (_watching) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _watching = true);
    String? msg;
    try {
      final left = await ref
          .read(worldBossControllerProvider.notifier)
          .adStrike();
      if (left == null) {
        msg = l10n.adNotReadySnack;
      } else {
        msg = l10n.worldBossAdSnack(worldBossAdDamage);
        if (mounted && !reduceMotion) _shake.forward(from: 0);
      }
    } catch (e) {
      msg = '$e'.contains('ad limit')
          ? l10n.worldBossAdNone
          : l10n.friendsErrNetwork;
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
    ref.listen(
      worldBossControllerProvider.select((a) => a.value?.damage ?? 0),
      (prev, next) {
        if (prev != null && next > prev && !reduceMotion) {
          _shake.forward(from: 0);
        }
      },
    );
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.friendsErrNetwork,
                    key: const Key('wb-error'),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    key: const Key('wb-retry'),
                    onPressed: () => ref
                        .read(worldBossControllerProvider.notifier)
                        .refresh(),
                    child: Text(l10n.friendsRetry),
                  ),
                ],
              ),
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
              onHit: _strike,
              pending: _pending,
            );
            final day = s.daily;
            if (day == null) {
              // server chưa chạy bản SQL có boss ngày
              return body(s, daily: false);
            }
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(
                        key: const Key('wb-tab-day'),
                        text: l10n.worldBossTabDay,
                      ),
                      Tab(
                        key: const Key('wb-tab-week'),
                        text: l10n.worldBossTabWeek,
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [body(day, daily: true), body(s, daily: false)],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.s,
    required this.daily,
    required this.shake,
    required this.onClaim,
    required this.onHit,
    required this.pending,
    required this.onBuyAuto,
    required this.onAd,
    required this.watching,
  });
  final WorldBossState s;

  /// true = boss ngày (Frankenstein, thưởng Xu), false = boss tuần (sói, thưởng 💎).
  final bool daily;
  final AnimationController shake;
  final Future<void> Function(int phase) onClaim;
  final VoidCallback onHit;

  /// Số lần chạm chưa báo server (hiện ngay trên thanh máu).
  final int pending;
  final Future<void> Function() onBuyAuto;
  final Future<void> Function() onAd;
  final bool watching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nowSec = ref.read(clockProvider)() ~/ 1000;
    final closed = !daily && !s.open;
    final left = ((closed ? s.startsAtSeconds : s.endsAtSeconds) - nowSec)
        .clamp(0, 1 << 40);
    final hpLeft = (s.hpLeft - pending).clamp(0, s.hp);
    final frac = s.hp == 0 ? 0.0 : hpLeft / s.hp;
    // Bảng màu pastel theo boss (hợp tông nền app): ngày = xanh bạc hà (Frankenstein), tuần = hồng-tím (sói).
    final heroColors = daily
        ? const [Color(0xFFE3F6EA), Color(0xFFB7E4CB)]
        : const [Color(0xFFF4E3F8), Color(0xFFFFCFD6)];
    const ink = Color(0xFF4E342E);
    Widget pill(String text, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: heroColors,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: heroColors.last.withValues(alpha: 0.6),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                daily ? l10n.worldBossDailyName : _bossName(l10n, s.boss),
                key: const Key('wb-name'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ink,
                  shadows: const [
                    Shadow(
                      color: Colors.white70,
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  pill(
                    closed
                        ? l10n.worldBossOpensIn(formatDuration(left.toInt()))
                        : l10n.worldBossEndsIn(formatDuration(left.toInt())),
                    key: const Key('wb-ends'),
                  ),
                  pill('👥 ${l10n.worldBossPlayers(s.players)}'),
                ],
              ),
              const SizedBox(height: 4),
              // Chạm vào boss = ra đòn. Quầng sáng sau boss cho nổi khỏi nền.
              Builder(builder: (hitCtx) => GestureDetector(
                key: const Key('wb-boss-tap'),
                behavior: HitTestBehavior.opaque,
                onTap: closed
                    ? null
                    : () {
                        onHit();
                        showRewardBurst(hitCtx, emojis: const ['💥'], label: '+1', count: 3);
                      },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: shake,
                        // Trúng đòn: nhún nhẹ một nhịp (co 4% rồi về), KHÔNG rung ngang — chạm liên tục vẫn êm mắt.
                        builder: (_, child) => Transform.scale(
                          scale: 1 - 0.04 * math.sin(shake.value * math.pi),
                          child: child,
                        ),
                        // Hạ gục → xám + mờ.
                        child: Opacity(
                          opacity: s.defeated ? 0.35 : 1,
                          child: ColorFiltered(
                            key: const Key('wb-boss'),
                            colorFilter: s.defeated
                                ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                            child: Mascot(
                              asset: daily
                                  ? AnimAssets.bossFrankenstein
                                  : AnimAssets.bossWolfie,
                              emoji: daily ? '🧟' : worldBossEmoji[s.boss],
                              size: 200,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (pending > 0)
                      Container(
                        key: const Key('wb-pending'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$pending 💥',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              // Thanh máu: nền tối, phần còn lại tô gradient đỏ→cam, vạch ở 4 mốc, chữ máu nằm giữa thanh.
              LayoutBuilder(
                builder: (context, box) => Container(
                  key: const Key('wb-hp-bar'),
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ink.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.5),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: frac.clamp(0.0, 1.0)),
                            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            builder: (_, w, child) => FractionallySizedBox(widthFactor: w, heightFactor: 1, child: child),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF8A80),
                                    Color(0xFFFFB74D),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (var p = 1; p < worldBossPhases; p++)
                          Positioned(
                            left: box.maxWidth * (1 - p / worldBossPhases) - 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: ink.withValues(alpha: 0.3),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              s.defeated
                                  ? l10n.worldBossDefeated
                                  : l10n.worldBossHp(
                                      formatNumber(hpLeft.toDouble()),
                                      formatNumber(s.hp.toDouble()),
                                    ),
                              key: const Key('wb-hp-text'),
                              style: const TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: Colors.white, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('wb-hit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: closed ? null : onHit,
                  child: Text(
                    '⚔️ ${l10n.worldBossHit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('wb-ad'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ink,
                    side: BorderSide(color: ink.withValues(alpha: 0.5)),
                  ),
                  onPressed: s.adLeft > 0 && !watching && !closed ? onAd : null,
                  child: Text(
                    l10n.worldBossAdButton(
                      worldBossAdDamage,
                      s.adLeft,
                      worldBossAdPerDay,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('wb-guide'),
            onPressed: () => _showGuide(context, l10n, theme),
            icon: const Text('❓'),
            label: Text(l10n.worldBossGuideTitle),
          ),
        ),
        ClayCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Text('💥', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.worldBossMine(formatNumber(s.mine.toDouble())),
                  key: const Key('wb-mine'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (s.rank != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.worldBossRank(s.rank!),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        ClayTile(
          key: const Key('wb-auto'),
          child: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.worldBossAutoTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.worldBossAutoDesc(worldBossAutoPerHour),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    if (s.auto)
                      Text(
                        '✓ ${l10n.worldBossAutoOn}',
                        key: const Key('wb-auto-on'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: FilledButton.tonal(
                          key: const Key('wb-auto-buy'),
                          onPressed: onBuyAuto,
                          child: Text(l10n.worldBossAutoBuy(worldBossAutoGems)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!s.meetsMinimum)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              l10n.worldBossNeedDamage(s.minDamage),
              key: const Key('wb-need'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 6),
        _RewardsBoard(
          rewards: [
            for (var p = 1; p <= worldBossPhases; p++)
              _phaseTile(context, l10n, theme, p),
          ],
          board: [
            if (s.board.isEmpty)
              Text(l10n.worldBossBoardEmpty, key: const Key('wb-board-empty'))
            else
              for (var i = 0; i < s.board.length; i++)
                ClayTile(
                  key: Key('wb-row-${i + 1}'),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          i < 3 ? const ['🥇', '🥈', '🥉'][i] : '#${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: i < 3 ? 22 : 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s.board[i].nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: i < 3 ? FontWeight.w800 : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 96,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '💥 ${formatNumber(s.board[i].damage.toDouble())}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  /// Hộp hướng dẫn: nguồn sát thương, điều kiện nhận quà, cách hoạt động của boss đang xem.
  void _showGuide(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showAppDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('wb-guide-dialog'),
        title: Text('❓ ${l10n.worldBossGuideTitle}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                daily ? l10n.worldBossDayHow : l10n.worldBossHow,
                key: const Key('wb-how'),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.worldBossGuideSources(
                  worldBossDmgPerTap,
                  worldBossOffSecondsPerDmg,
                  worldBossDmgPerRec,
                  worldBossAdDamage,
                  worldBossAdPerDay,
                  worldBossAutoPerHour,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.worldBossGuideRules(s.minDamage)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.worldBossGuideClose),
          ),
        ],
      ),
    );
  }

  /// Một mốc thưởng: vòng số (xám = khoá, vàng = nhận được, xanh = đã nhận) + phần thưởng dạng thẻ nhỏ + nút nhận.
  Widget _phaseTile(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    int p,
  ) {
    final claimed = s.claimed.contains(p);
    final ready = s.canClaim(p);
    final badge = claimed
        ? Colors.green
        : (ready ? const Color(0xFFFFB300) : theme.colorScheme.outline);
    final gems = daily
        ? worldBossDayPhaseGems[p - 1]
        : worldBossPhaseGems[p - 1];
    final minutes =
        (daily
            ? worldBossDayPhaseSeconds[p - 1]
            : worldBossPhaseSeconds[p - 1]) ~/
        60;
    Widget chip(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        t,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
    return ClayTile(
      key: Key('wb-phase-$p'),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badge.withValues(alpha: 0.9),
              boxShadow: ready
                  ? [
                      BoxShadow(
                        color: badge.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              claimed ? '✓' : '$p',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.worldBossPhase(p * 100 ~/ worldBossPhases),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (gems > 0) chip('💎 $gems'),
                    chip('💰 ${l10n.worldBossDayXu(minutes)}'),
                    if (!daily && p == worldBossPhases) chip('🎁'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: claimed
                  ? Text(l10n.worldBossClaimed)
                  : FilledButton(
                      key: Key('wb-claim-$p'),
                      onPressed: ready ? () => onClaim(p) : null,
                      child: Text(
                        s.phaseReached(p)
                            ? l10n.worldBossClaim
                            : l10n.worldBossLocked,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chuyển qua lại giữa Phần thưởng (mặc định) và Bảng xếp hạng — bảng không còn nằm dưới đáy trang.
class _RewardsBoard extends StatefulWidget {
  const _RewardsBoard({required this.rewards, required this.board});
  final List<Widget> rewards;
  final List<Widget> board;
  @override
  State<_RewardsBoard> createState() => _RewardsBoardState();
}

class _RewardsBoardState extends State<_RewardsBoard> {
  bool _board = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(
                  '🎁 ${l10n.worldBossTabRewards}',
                  key: const Key('wb-seg-rewards'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ButtonSegment(
                value: true,
                label: Text(
                  '🏆 ${l10n.worldBossBoard}',
                  key: const Key('wb-seg-board'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            selected: {_board},
            onSelectionChanged: (v) => setState(() => _board = v.first),
          ),
        ),
        const SizedBox(height: 6),
        ...(_board ? widget.board : widget.rewards),
      ],
    );
  }
}
