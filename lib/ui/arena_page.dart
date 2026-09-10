/// Màn hình chế độ "Đấu Trường" (Arena PvP) — xem PROPOSAL_ARENA_PVP.md.
///
/// Trang độc lập (push, không phải dialog như shop/prestige/thành tựu) vì có
/// nhiều pha (chờ ghép → trong trận → kết quả) và cần đồng hồ đếm ngược.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../arena/arena_config.dart';
import '../arena/arena_controller.dart';
import '../core/format.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
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
            child: Center(
              child: switch (viewState) {
                ArenaIdle() => _IdleView(l10n: l10n),
                ArenaQueued() => _QueuedView(l10n: l10n),
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

class _IdleView extends ConsumerWidget {
  const _IdleView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.arenaIntro, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () =>
              ref.read(arenaControllerProvider.notifier).startMatchmaking(),
          child: Text(l10n.arenaStartButton),
        ),
      ],
    );
  }
}

class _QueuedView extends ConsumerWidget {
  const _QueuedView({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(l10n.arenaQueueWaiting),
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
        if (resolving) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text(l10n.arenaResolving),
        ] else ...[
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
