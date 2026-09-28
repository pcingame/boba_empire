/// Hành trình Ghép 3 — danh sách màn (tab thứ 5). Luật ở
/// `lib/arena/match3_rules.dart`, số liệu màn ở `lib/core/match3_levels.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/banner_ad_box.dart';
import '../core/balance.dart';
import '../core/match3_levels.dart';
import '../l10n/app_localizations.dart';
import '../state/game_providers.dart';
import 'match3_board.dart';
import 'm3_leaderboard_page.dart';
import 'match3_how_to_dialog.dart';
import 'match3_play_page.dart';
import 'widgets/clay.dart';

Future<void> showMatch3Journey(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const Match3JourneyPage()),
  );
}

class Match3JourneyPage extends ConsumerStatefulWidget {
  const Match3JourneyPage({super.key});

  @override
  ConsumerState<Match3JourneyPage> createState() => _Match3JourneyPageState();
}

class _Match3JourneyPageState extends ConsumerState<Match3JourneyPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tới màn 20-30 thì màn đang chơi nằm ngoài màn hình — tự cuộn tới đó thay
    // vì bắt người chơi tự tìm.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
      _showHowToOnce();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!_scroll.hasClients) return;
    final current = highestUnlocked(ref.read(gameControllerProvider).m3Stars);
    final row = (current - 1) ~/ 4;
    if (row < 2) return; // đã thấy sẵn ở đầu danh sách
    final target = (row - 1) * 86.0; // ~ chiều cao một hàng, đặt nó gần đỉnh
    _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
  }

  /// Lần đầu mở tab thì tự bật hướng dẫn — luật ghép/kẹo/sao không đoán ra
  /// được, để người chơi tự mò là mất mấy màn đầu.
  Future<void> _showHowToOnce() async {
    if (!mounted) return;
    if (ref.read(gameControllerProvider).m3HowToSeen) return;
    ref.read(gameControllerProvider.notifier).markM3HowToSeen();
    await showMatch3HowTo(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stars = ref.watch(gameControllerProvider.select((s) => s.m3Stars));
    final current = highestUnlocked(stars);
    final earned = stars.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.m3Title),
        actions: [
          IconButton(
            key: const Key('m3-leaderboard-button'),
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.m3LbTitle,
            onPressed: () => showM3Leaderboard(context),
          ),
          IconButton(
            key: const Key('m3-how-to-button'),
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.m3HowToTitle,
            onPressed: () => showMatch3HowTo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tổng sao: thứ duy nhất đo được tiến độ dài hạn ở chế độ này.
          //
          // KHÔNG để trong AppBar: chip này ăn 116px, cộng nút quay lại + 2 nút
          // biểu tượng thì tiêu đề chỉ còn 168px và bị cắt cụt ở MỌI ngôn ngữ
          // ("Falling Pear..." trên máy thật).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                ClayChip(
                  child: Text(
                    '⭐ $earned / ${Balance.m3LevelCount * 3}',
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // Tắt hiệu ứng kéo giãn của Android (StretchingOverscrollIndicator):
            // khi cuộn hết cỡ nó BÓP nội dung ở mép — đo trên máy ảo, hàng ô
            // cuối còn 150px trong khi các hàng khác 236px. Lưới ô vuông thì
            // méo rất lộ, khác hẳn danh sách chữ.
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: GridView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: Balance.m3LevelCount,
                itemBuilder: (context, i) => _LevelTile(
                  level: Match3Level(i + 1),
                  stars: starsOf(stars, i + 1),
                  unlocked: levelUnlocked(stars, i + 1),
                  isCurrent: i + 1 == current,
                ),
              ),
            ),
          ),
          // Banner ở ĐÁY, ngoài vùng cuộn — không bao giờ nằm cạnh ô bấm.
          const BannerAdBox(),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.stars,
    required this.unlocked,
    required this.isCurrent,
  });

  final Match3Level level;
  final int stars;
  final bool unlocked;

  /// Màn đang chơi dở / sắp chơi — được làm nổi để mắt nhìn vào là thấy ngay.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cleared = stars > 0;
    final bg = !unlocked
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : cleared
            ? scheme.primaryContainer
            : scheme.secondaryContainer;

    return InkWell(
      onTap: unlocked
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Match3PlayPage(level: level),
                ),
              )
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: isCurrent
              ? Border.all(color: scheme.primary, width: 3)
              : null,
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        // Ô là hình vuông cố định (do gridDelegate), còn nội dung thì co giãn
        // theo cỡ chữ hệ thống: ở cỡ chữ lớn, cột số-màn + biểu tượng + 3 sao
        // TRÀN khỏi ô (RenderFlex overflow, nhìn như ô bị bóp). FittedBox thu
        // cả cụm cho vừa thay vì để tràn.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (unlocked) ...[
                  Text(
                    '${level.id}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  // Màn thu thập: hiện luôn loại ô phải thu, để nhìn lưới là
                  // biết màn nào khác kiểu.
                  if (level.goal == Match3GoalKind.collect)
                    Text(
                      match3Icons[level.collectType],
                      style: const TextStyle(fontSize: 13),
                    ),
                ] else
                  Icon(Icons.lock_rounded,
                      size: 22, color: theme.disabledColor),
                const SizedBox(height: 2),
                Match3Stars(stars: stars, dim: !unlocked),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
