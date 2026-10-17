/// Danh hiệu hồ sơ: mở khoá từ tiến độ có sẵn, người chơi chọn một cái để hiện trên hồ sơ công khai.
/// Id PHẢI khớp whitelist trong supabase/player_title_schema.sql (test so khớp).
library;

class TitleStats {
  const TitleStats({
    required this.stage,
    required this.ascension,
    required this.prestigeStars,
    required this.vipLevel,
    required this.owned,
  });
  final int stage;
  final int ascension;
  final double prestigeStars;
  final int vipLevel;
  final int owned;
}

class PlayerTitle {
  const PlayerTitle(this.id, this.emoji, this.unlocked);
  final String id;
  final String emoji;
  final bool Function(TitleStats) unlocked;
}

final List<PlayerTitle> playerTitles = [
  PlayerTitle('tycoon', '🏢', (s) => s.stage >= 5),
  PlayerTitle('mogul', '🏆', (s) => s.stage >= 10),
  PlayerTitle('legend', '🪐', (s) => s.stage >= 18),
  PlayerTitle('timewalker', '⏳', (s) => s.ascension >= 1),
  PlayerTitle('stargazer', '⭐', (s) => s.prestigeStars >= 50),
  PlayerTitle('collector', '🎀', (s) => s.owned >= 100),
  PlayerTitle('vip', '👑', (s) => s.vipLevel >= 5),
];

PlayerTitle? playerTitleById(String id) => playerTitles.where((t) => t.id == id).firstOrNull;
