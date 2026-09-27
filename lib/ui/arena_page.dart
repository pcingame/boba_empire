/// Màn hình chế độ "Đấu Trường" (Arena PvP) — xem PROPOSAL_ARENA_PVP.md.
///
/// Trang độc lập (push, không phải dialog như shop/prestige/thành tựu) vì có
/// nhiều pha (chờ ghép → trong trận → kết quả) và cần đồng hồ đếm ngược.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../arena/arena_config.dart';
import '../arena/arena_controller.dart';
import '../arena/arena_models.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'arena_match3_board.dart';
import 'widgets/clay.dart';

Future<void> showArenaPage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ArenaPage()),
  );
}

class ArenaPage extends ConsumerWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Gán lại mỗi lần build (rẻ, luôn đúng) thay vì lo initState/dispose —
    // controller Đấu Trường tách biệt, chỉ trao thưởng qua đây.
    ref.read(arenaControllerProvider.notifier).onRewardGems = (gems) =>
        ref.read(gameControllerProvider.notifier).grantArenaReward(gems);

    final viewState = ref.watch(arenaControllerProvider);
    // Giữ kết nối presence suốt lúc trang mở (kể cả trong trận) để người khác
    // vẫn thấy mình đang ở đây; lỗi/đang kết nối -> null -> ẩn số.
    final online = ref.watch(arenaOnlineCountProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.arenaTitle)),
      // SingleChildScrollView: màn "trong trận" có khá nhiều khối xếp dọc
      // (đồng hồ + 2 điểm + nút chạm + 3 mốc) — máy màn hình nhỏ hoặc cỡ chữ
      // hệ thống to (accessibility) dễ tràn nếu chỉ dùng Center/Column cố định.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  kToolbarHeight -
                  40,
            ),
            child: Align(
              alignment: viewState is ArenaInMatch ? Alignment.topCenter : Alignment.center,
              child: switch (viewState) {
                ArenaIdle() => _IdleView(l10n: l10n, online: online),
                ArenaQueued() => _QueuedView(l10n: l10n, online: online),
                ArenaInMatch() => _MatchView(l10n: l10n, view: viewState),
                ArenaFinished() => _ResultView(l10n: l10n, view: viewState),
                ArenaError() => _ErrorView(l10n: l10n, view: viewState),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Chấm xanh + "N người đang online" (N gồm cả bạn, 1 người vẫn hiện).
class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.count, required this.l10n});
  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('arena-online'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              l10n.arenaOnlineCount(count),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
      ],
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.l10n, this.online});
  final AppLocalizations l10n;
  final int? online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (online != null) ...[
          _OnlineBadge(count: online!, l10n: l10n),
          const SizedBox(height: 16),
        ],
        FilledButton(
          key: const Key('arena-start-tap'),
          onPressed: () => ref
              .read(arenaControllerProvider.notifier)
              .startMatchmaking(ArenaMode.tap),
          child: Text(l10n.arenaModeTap),
        ),
        const SizedBox(height: 6),
        Text(l10n.arenaIntro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        FilledButton.tonal(
          key: const Key('arena-start-match3'),
          onPressed: () => ref
              .read(arenaControllerProvider.notifier)
              .startMatchmaking(ArenaMode.match3),
          child: Text(l10n.arenaModeMatch3),
        ),
        const SizedBox(height: 6),
        Text(l10n.arenaMatch3Intro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QueuedView extends ConsumerWidget {
  const _QueuedView({required this.l10n, this.online});
  final AppLocalizations l10n;
  final int? online;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(l10n.arenaQueueWaiting),
        if (online != null) ...[
          const SizedBox(height: 12),
          _OnlineBadge(count: online!, l10n: l10n),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => ref.read(arenaControllerProvider.notifier).cancelQueue(),
          child: Text(l10n.arenaCancelButton),
        ),
      ],
    );
  }
}

class _MatchView extends ConsumerWidget {
  const _MatchView({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final ArenaInMatch view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(arenaControllerProvider.notifier);
    final seconds = view.remaining.inMilliseconds / 1000;
    // Đồng hồ về 0 nhưng server chưa kịp chốt (client tự retry, xem
    // `_finishMatch`) — khoá nút thay vì để người chơi bấm vô ích (server sẽ
    // từ chối "match time is up") và cho biết đang xử lý, không phải treo máy.
    final resolving = view.remaining <= Duration.zero;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (view.mode == ArenaMode.match3) ...[
          _DuelHeader(l10n: l10n, view: view),
          const SizedBox(height: 12),
        ] else ...[
          Chip(label: Text(l10n.arenaTimeLeft(seconds.ceil()))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreTile(label: l10n.arenaYourScore, value: view.myScore),
              _ScoreTile(label: l10n.arenaOpponentScore, value: view.opponentScore),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (resolving) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(l10n.arenaResolving),
        ] else if (view.mode == ArenaMode.match3)
          ArenaMatch3Panel(view: view, onSwap: controller.swap)
        else ...[
          // Kích thước CỐ ĐỊNH (không phải padding-quyết-định-kích-thước) +
          // FittedBox co chữ — bản dịch dài (id/es/pt 2 từ) vẫn nằm gọn trong
          // vòng tròn thay vì méo/tràn ra ngoài. Giống cách `_TapArea` ở màn
          // hình chính đã xử lý (xem ghi chú "Co lại khi vòng bị ép nhỏ").
          SizedBox(
            width: 140,
            height: 140,
            child: FilledButton(
              onPressed: controller.tap,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.arenaTapButton, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (var tier = 0; tier < ArenaConfig.tierCosts.length; tier++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: view.tiersBought.contains(tier) ||
                        view.myScore < ArenaConfig.tierCosts[tier]
                    ? null
                    : () => controller.buyTier(tier),
                child: Text(
                  l10n.arenaTierButton(formatNumber(ArenaConfig.tierCosts[tier])),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Đầu màn trận Ghép 3: thanh thời gian (đỏ khi còn <= 10s), điểm hai bên đếm
/// chạy, và thanh so điểm mình–đối thủ.
class _DuelHeader extends StatelessWidget {
  const _DuelHeader({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final ArenaInMatch view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final seconds = (view.remaining.inMilliseconds / 1000).ceil();
    final frac = (view.remaining.inMilliseconds / (ArenaConfig.matchSeconds * 1000)).clamp(0.0, 1.0);
    final urgent = seconds <= 10;
    final total = view.myScore + view.opponentScore;
    final share = total <= 0 ? 0.5 : (view.myScore / total).clamp(0.08, 0.92);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 20, color: urgent ? scheme.error : scheme.onSurface),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.arenaTimeLeft(seconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: urgent ? scheme.error : null,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            color: urgent ? scheme.error : scheme.primary,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _DuelScore(label: l10n.arenaYourScore, value: view.myScore, color: scheme.primary, end: false)),
            const SizedBox(width: 12),
            Expanded(child: _DuelScore(label: l10n.arenaOpponentScore, value: view.opponentScore, color: scheme.tertiary, end: true)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: scheme.tertiary)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: box.maxWidth * share,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DuelScore extends StatelessWidget {
  const _DuelScore({required this.label, required this.value, required this.color, required this.end});
  final String label;
  final double value;
  final Color color;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: theme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: value, end: value),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          builder: (context, v, _) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatNumber(v), style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(formatNumber(value), style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final ArenaFinished view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = view.result;
    final headline = result.isDraw
        ? l10n.arenaResultDraw
        : (result.won ? l10n.arenaResultWin : l10n.arenaResultLose);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreTile(label: l10n.arenaYourScore, value: result.myScore),
            _ScoreTile(label: l10n.arenaOpponentScore, value: result.opponentScore),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.arenaResultReward(result.won ? ArenaConfig.winGems : ArenaConfig.loseGems),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            ref.read(arenaControllerProvider.notifier).backToIdle();
            Navigator.of(context).pop();
          },
          child: Text(l10n.arenaCloseButton),
        ),
      ],
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.l10n, required this.view});
  final AppLocalizations l10n;
  final ArenaError view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(view.message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => ref.read(arenaControllerProvider.notifier).backToIdle(),
          child: Text(l10n.arenaCloseButton),
        ),
      ],
    );
  }
}
