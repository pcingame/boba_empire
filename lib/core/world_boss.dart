/// Boss Thế Giới hàng tuần: cả server cùng đánh một boss. Hằng số KHỚP supabase/world_boss_schema.sql
/// (test so khớp); mọi con số là ước lượng chưa playtest.
library;

/// Số boss luân phiên (tuần nào boss đó theo `boss` server trả). Cùng một animation sói (`AnimAssets.bossWolfie`), khác tên.
const int worldBossCount = 8;
const List<String> worldBossEmoji = ['🐺', '🐺', '🐺', '🐺', '🐺', '🐺', '🐺', '🐺'];

/// Máu tuần đầu / mức sàn các tuần sau.
const int worldBossBaseHp = 150000;

/// 1 sát thương / lần chạm · 1 / 30 giây offline · 40 / điểm Công thức.
const int worldBossDmgPerTap = 1;
const int worldBossOffSecondsPerDmg = 30;
const int worldBossDmgPerRec = 40;

/// Tự động đánh (mua bằng 💎, hiệu lực tới hết tuần, server tự cộng theo giờ).
const int worldBossAutoPerHour = 25;
const int worldBossAutoGems = 100;

/// Xem quảng cáo thưởng → sát thương cố định, tối đa mỗi ngày (UTC).
const int worldBossAdDamage = 120;
const int worldBossAdPerDay = 5;

/// Sát thương tối thiểu để nhận quà mốc.
const int worldBossMinDamageToClaim = 100;

/// 5 mốc (20% máu mỗi mốc); mốc cuối = hạ boss, có rương phụ kiện.
const int worldBossPhases = 5;
const List<int> worldBossPhaseGems = [50, 80, 120, 180, 300];

/// Boss tuần chỉ xuất hiện Chủ Nhật (UTC) nên thưởng nhiều: thêm Xu = số giây thu nhập quán chính (app cấp sau khi server OK).
const List<int> worldBossPhaseSeconds = [3600, 7200, 10800, 14400, 21600];

/// Sát thương ước tính từ bộ đếm tuần (server là nguồn thật, đây để hiển thị).
int worldBossDamage({required int tap, required int off, required int rec}) =>
    tap * worldBossDmgPerTap + off ~/ worldBossOffSecondsPerDmg + rec * worldBossDmgPerRec;

/// Boss NGÀY (nhỏ, đổi mỗi ngày UTC): cùng nguồn sát thương với boss tuần. Khớp SQL `wb_day_*`.
const int worldBossDayBaseHp = 20000;
const int worldBossDayMinDamageToClaim = 30;

/// 5 mốc: thưởng Xu = số giây thu nhập quán chính (app cấp), 💎 chỉ mốc cuối (server).
const List<int> worldBossDayPhaseSeconds = [600, 900, 1200, 1800, 2700];
const List<int> worldBossDayPhaseGems = [0, 0, 0, 0, 10];
