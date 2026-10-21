/// Thống kê cá nhân (chỉ đọc) để hiện màn "Thống kê của tôi" và ảnh khoe. Hàm thuần.
library;

import 'daily.dart' show dayIndex;
import 'models.dart';
import 'topup.dart' show topupVipLevel;

class PlayerStats {
  const PlayerStats({
    required this.daysPlayed,
    required this.lifetime,
    required this.taps,
    required this.buys,
    required this.ascensions,
    required this.chapter,
    required this.items,
    required this.vipLevel,
    required this.bestRecipeStreak,
  });

  final int daysPlayed;
  final double lifetime;
  final int taps;
  final int buys;
  final int ascensions;
  final int chapter;

  /// Phụ kiện sưu tập chính + độc quyền đã có.
  final int items;
  final int vipLevel;
  final int bestRecipeStreak;

  factory PlayerStats.from(GameState s, int nowMillis) => PlayerStats(
        daysPlayed: s.firstPlayedMillis > 0 && nowMillis >= s.firstPlayedMillis
            ? dayIndex(nowMillis) - dayIndex(s.firstPlayedMillis) + 1
            : 1,
        lifetime: s.lifetimeEarnings.isFinite ? s.lifetimeEarnings : 0,
        taps: s.tapCount,
        buys: s.buyCount,
        ascensions: s.ascensionCount,
        chapter: s.storyChapter,
        items: s.ownedAccessories.length + s.ownedLimited.length,
        vipLevel: topupVipLevel(s.vipExp),
        bestRecipeStreak: s.recipeStreakBest,
      );
}
