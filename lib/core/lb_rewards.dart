/// Thưởng top bảng xếp hạng theo tuần (supabase/leaderboard_rewards_schema.sql). Hằng số PHẢI khớp SQL
/// (test/leaderboard/lb_rewards_test.dart so khớp): top 3 mỗi bảng nhận 300 / 200 / 100 💎, mỗi (tuần, bảng)
/// một lần. ⚠️ ước lượng chưa playtest.
library;

/// Bảng có thưởng tuần; `name` khớp cột `board` của server. `daily` (Thử thách ngày) khác các bảng còn lại: xếp theo
/// TỔNG điểm cả TUẦN TRƯỚC và thưởng top 10 (xem [lbRewardGemsForBoard]).
enum LbBoard { income, pearls, collection, vip, recipes, orders, daily, arena }

/// 💎 theo hạng (1-based); hạng ngoài top 3 = 0.
const List<int> lbRewardGemsByRank = [300, 200, 100];

/// Hạng thấp nhất có thưởng ở bảng `daily` (các bảng khác: top 3). PHẢI khớp `lb_reward_gems_for` ở SQL.
const int lbRewardDailyMaxRank = 10;

/// 💎 cho hạng 4..[lbRewardDailyMaxRank] của bảng `daily`.
const int lbRewardGemsDailyRest = 50;

/// 💎 theo (bảng, hạng) — khớp `lb_reward_gems_for` ở SQL (test so khớp). Server là nguồn thật; hàm này để hiển thị/test.
int lbRewardGemsForBoard(LbBoard board, int rank) =>
    (board == LbBoard.daily || board == LbBoard.arena) && rank > lbRewardGemsByRank.length && rank <= lbRewardDailyMaxRank
        ? lbRewardGemsDailyRest
        : lbRewardGemsFor(rank);

int lbRewardGemsFor(int rank) =>
    rank >= 1 && rank <= lbRewardGemsByRank.length ? lbRewardGemsByRank[rank - 1] : 0;

/// Thưởng còn nhận được trong bấy nhiêu tuần kể từ tuần chốt (tuần chốt + tuần kế).
const int lbRewardValidWeeks = 2;
