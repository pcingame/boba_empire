/// Phó bản Hội hàng tuần: cả hội phối hợp theo vai trò (xem PROPOSAL_GUILD_DUNGEON.md). Hằng số KHỚP
/// supabase/guild_dungeon_schema.sql (test so khớp); mọi con số là ước lượng chưa playtest.
library;

import 'guild.dart';
import 'models.dart';

/// Ba thanh tiến độ = ba "vai trò" đóng góp.
enum DungeonBar {
  /// ⚔️ Thợ chạm: số lần chạm ly.
  tap,

  /// 🌙 Người gác: giây offline được tính.
  off,

  /// 📜 Đầu bếp: điểm Công thức / Pha theo đơn / Ghép 3.
  rec;

  /// Tên trong SQL (cột `role`, khoá JSON).
  String get wire => name;

  static DungeonBar? fromWire(Object? v) {
    for (final b in values) {
      if (b.name == v) return b;
    }
    return null;
  }
}

const int dungeonStages = 3;

/// Đóng góp đúng vai nhân [dungeonRoleBonusNum]/[dungeonRoleBonusDen] = ×1.5 (làm ở server lúc báo).
const int dungeonRoleBonusNum = 3;
const int dungeonRoleBonusDen = 2;

/// Đơn vị ngưỡng mỗi thành viên ở ải 1 (tuần, chưa nhân hệ số ải/bậc).
const Map<DungeonBar, int> dungeonUnit = {
  DungeonBar.tap: 1500,
  DungeonBar.off: 21600, // 6 giờ
  DungeonBar.rec: 25,
};

const List<int> dungeonStageMult = [1, 2, 4];

/// Hội ít người vẫn tính như tối thiểu ngần này thành viên.
const int dungeonMinMembers = 3;

/// Mức đóng góp tối thiểu (đã nhân vai) để nhận thưởng một ải: đạt MỘT trong ba.
const Map<DungeonBar, int> dungeonMinToClaim = {
  DungeonBar.tap: 200,
  DungeonBar.off: 1800,
  DungeonBar.rec: 5,
};

const List<int> dungeonRewardCoins = [100, 200, 300];
const List<int> dungeonRewardGems = [0, 0, 100];

/// Ải cuối còn có một rương phụ kiện.
const int dungeonChestStage = 3;

/// Ngưỡng thanh [bar] ở ải [stage] (1-based) cho hội [members] người, bậc Boss [tier] (+25%/bậc).
/// Làm tròn LÊN như SQL `ceil(...)`.
int dungeonTarget(DungeonBar bar, int stage, int members, int tier) {
  final n = members < dungeonMinMembers ? dungeonMinMembers : members;
  final raw = dungeonUnit[bar]! * n * dungeonStageMult[stage - 1] * (100 + 25 * tier);
  return (raw + 99) ~/ 100;
}

/// Sang tuần mới thì xoá bộ đếm. MUTATE. Trả true nếu vừa đổi tuần.
bool rollDungeonWeek(GameState s, int nowMillis) {
  final w = guildWeekIndex(nowMillis);
  if (w == s.dungeonWeek) return false;
  s.dungeonWeek = w;
  s.dungeonTap = 0;
  s.dungeonOffline = 0;
  s.dungeonRecipe = 0;
  return true;
}

/// Cộng [n] vào thanh [bar] của tuần hiện tại. MUTATE. Số không hữu hạn / âm bị bỏ.
void addDungeon(GameState s, DungeonBar bar, num n, int nowMillis) {
  if (!n.isFinite || n <= 0) return;
  rollDungeonWeek(s, nowMillis);
  switch (bar) {
    case DungeonBar.tap:
      s.dungeonTap += n.floor();
    case DungeonBar.off:
      s.dungeonOffline += n.toDouble();
    case DungeonBar.rec:
      s.dungeonRecipe += n.floor();
  }
}

/// Tổng luỹ kế tuần này để báo server: (chạm, giây offline làm tròn xuống, điểm Công thức).
({int tap, int off, int rec}) dungeonTotals(GameState s, int nowMillis) {
  rollDungeonWeek(s, nowMillis);
  return (tap: s.dungeonTap, off: s.dungeonOffline.floor(), rec: s.dungeonRecipe);
}
