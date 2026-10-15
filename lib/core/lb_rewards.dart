/// Thưởng top bảng xếp hạng theo tuần (supabase/leaderboard_rewards_schema.sql). Hằng số PHẢI khớp SQL
/// (test/leaderboard/lb_rewards_test.dart so khớp): top 3 mỗi bảng nhận 300 / 200 / 100 💎, mỗi (tuần, bảng)
/// một lần. ⚠️ ước lượng chưa playtest.
library;

/// Sáu bảng TÍCH LŨY có thưởng; `name` khớp cột `board` của server.
enum LbBoard { income, pearls, collection, vip, recipes, orders }

/// 💎 theo hạng (1-based); hạng ngoài top 3 = 0.
const List<int> lbRewardGemsByRank = [300, 200, 100];

int lbRewardGemsFor(int rank) =>
    rank >= 1 && rank <= lbRewardGemsByRank.length ? lbRewardGemsByRank[rank - 1] : 0;

/// Thưởng còn nhận được trong bấy nhiêu tuần kể từ tuần chốt (tuần chốt + tuần kế).
const int lbRewardValidWeeks = 2;
