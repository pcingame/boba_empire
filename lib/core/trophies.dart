/// Phòng truyền thống: huy hiệu cột mốc suy THẲNG từ [GameState] (không lưu thêm gì, không SQL) nên người chơi cũ
/// có sẵn những huy hiệu đã đạt. Chỉ xem trên Hồ sơ của tôi; mở rộng = thêm một dòng + tên dịch `trophy*` (ARB ×7).
library;

import 'accessories.dart';
import 'achievements.dart';
import 'branches.dart';
import 'story.dart';
import 'topup.dart';

/// Đầu vào tối thiểu để xét huy hiệu (như TitleStats): dựng được từ cả [GameState] lẫn ảnh chụp cho UI.
class TrophyStats {
  const TrophyStats({
    required this.branchLevels,
    required this.stage,
    required this.ascension,
    required this.owned,
    required this.achievements,
    required this.storyChapter,
    required this.vipExp,
  });
  final Map<String, int> branchLevels;
  final int stage;
  final int ascension;
  final int owned;
  final int achievements;
  final int storyChapter;
  final int vipExp;
}

class Trophy {
  const Trophy(this.id, this.emoji, this.earned);
  final String id;
  final String emoji;
  final bool Function(TrophyStats) earned;
}

final List<Trophy> trophies = [
  Trophy('firstBranch', '🌍', (s) => branchCities.any((c) => branchLevel(s.branchLevels, c.id) > 0)),
  Trophy('allBranches', '🗺️', (s) => branchCities.every((c) => branchLevel(s.branchLevels, c.id) > 0)),
  Trophy('maxBranch', '🏙️', (s) => branchCities.any((c) => branchLevel(s.branchLevels, c.id) >= branchMaxLevel)),
  Trophy('moon', '🪐', (s) => s.stage >= 18),
  Trophy('ascend', '⏳', (s) => s.ascension >= 1),
  Trophy('ascend4', '🌌', (s) => s.ascension >= 4),
  Trophy('collector', '🎀', (s) => s.owned >= 100),
  Trophy('fullCollection', '💎', (s) => s.owned >= accessories.length),
  Trophy('achievements', '🏅', (s) => s.achievements >= achievements.length),
  Trophy('story', '📖', (s) => s.storyChapter >= storyChapters.last.id),
  Trophy('vip', '👑', (s) => topupVipLevel(s.vipExp) >= topupTiers.length),
];
