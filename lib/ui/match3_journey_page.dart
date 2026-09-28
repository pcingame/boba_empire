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
import 'match3_play_page.dart';

Future<void> showMatch3Journey(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const Match3JourneyPage()),
  );
}

class Match3JourneyPage extends ConsumerWidget {
  const Match3JourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stars = ref.watch(gameControllerProvider.select((s) => s.m3Stars));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.m3Title)),
      body: Column(
        children: [
          Expanded(
            // Tắt hiệu ứng kéo giãn của Android (StretchingOverscrollIndicator):
            // khi cuộn hết cỡ nó BÓP nội dung ở mép lại — đo trên máy ảo, hàng
            // ô cuối còn 150px trong khi các hàng khác 236px. Lưới ô vuông thì
            // méo rất lộ, khác hẳn danh sách chữ.
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
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
  });

  final Match3Level level;
  final int stars;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: unlocked
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Match3PlayPage(level: level),
                ),
              )
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: unlocked
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        // Ô là hình vuông cố định (do gridDelegate), còn nội dung thì co giãn
        // theo cỡ chữ hệ thống: ở cỡ chữ lớn, cột số-màn + biểu tượng + 3 sao
        // TRÀN khỏi ô (RenderFlex overflow, nhìn như ô bị bóp). FittedBox thu
        // cả cụm cho vừa thay vì để tràn.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (unlocked) ...[
                Text(
                  '${level.id}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Màn thu thập: hiện luôn loại ô phải thu, để nhìn lưới là biết
                // màn nào khác kiểu.
                if (level.goal == Match3GoalKind.collect)
                  Text(
                    match3Icons[level.collectType],
                    style: const TextStyle(fontSize: 12),
                  ),
              ] else
                Icon(Icons.lock, color: theme.disabledColor),
              const SizedBox(height: 2),
              Text(
                '★' * stars + '☆' * (3 - stars),
                style: TextStyle(
                  fontSize: 12,
                  color: unlocked ? Colors.amber.shade800 : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
