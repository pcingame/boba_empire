/// Đột kích quán bạn bè: sức mạnh quán, xác suất thắng, thưởng. Hằng số KHỚP supabase/friends_schema.sql
/// (test so khớp); mọi con số là ước lượng chưa playtest. Không ai mất Xu — chỉ có thưởng.
library;

import 'accessories.dart';

const int raidsPerDay = 3;

/// Thưởng (giây thu nhập của quán mình): thắng · bị chặn (an ủi) · người phòng thủ chặn được.
const int raidWinSeconds = 600;
const int raidBlockedSeconds = 120;
const int raidDefenseSeconds = 180;

/// Sàn Xu cho thưởng (người mới thu nhập rất nhỏ), như quà bạn bè.
const double raidRewardFloor = 100.0;

const Map<AccessoryRarity, int> raidRarityPower = {
  AccessoryRarity.common: 1,
  AccessoryRarity.rare: 3,
  AccessoryRarity.epic: 8,
  AccessoryRarity.legendary: 20,
};

/// Sức mạnh quán = Σ điểm độ hiếm của món đang trưng bày × (1 + 25%/cấp tinh luyện) + 3 × giai đoạn, kẹp 0..1000.
int raidPower({required Iterable<String> equipped, required Map<String, int> refineLevels, required int stage}) {
  var p = 0.0;
  for (final id in equipped) {
    final a = accessoryOrNull(id);
    if (a == null) continue;
    final refine = (refineLevels[id] ?? 0).clamp(0, 3);
    p += raidRarityPower[a.rarity]! * (1 + 0.25 * refine);
  }
  p += 3 * stage.clamp(0, 100);
  return p.round().clamp(0, 1000);
}

/// Xác suất kẻ đột kích thắng — khớp SQL `raid_win_chance`: 50% ngang sức, kẹp 15%..85%.
double raidWinChance(int attack, int defense) {
  final m = [attack, defense, 1].reduce((a, b) => a > b ? a : b);
  return (0.5 + (attack - defense) / (2 * m)).clamp(0.15, 0.85);
}
