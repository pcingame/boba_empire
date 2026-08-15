/// VIP Pass — vé 30 ngày (mua lại). Hàm thuần, thời gian bơm từ ngoài.
///
/// Quyền lợi (trong lúc còn hạn): gỡ QC, x2 thu nhập, +Kim Cương mỗi ngày, tăng
/// trần offline. Xử lý ở controller/economy; đây chỉ là trạng thái + gems ngày.
library;

import 'balance.dart';
import 'daily.dart' show dayIndex;
import 'models.dart';

/// VIP còn hiệu lực không.
bool vipActive(GameState s, int nowMillis) => nowMillis < s.vipUntilMillis;

/// Kích hoạt/gia hạn VIP thêm [Balance.vipDurationMs] (nối tiếp nếu còn hạn).
void activateVip(GameState s, int nowMillis) {
  final from = nowMillis > s.vipUntilMillis ? nowMillis : s.vipUntilMillis;
  s.vipUntilMillis = from + Balance.vipDurationMs;
}

/// Nếu đang VIP và sang ngày mới thì trao Kim Cương VIP hằng ngày. Trả về số
/// gems trao (0 nếu không). MUTATE.
int claimVipDailyGems(GameState s, int nowMillis) {
  if (!vipActive(s, nowMillis)) return 0;
  final today = dayIndex(nowMillis);
  if (today <= s.vipLastGemDay) return 0;
  s.vipLastGemDay = today;
  s.gems += Balance.vipDailyGems;
  return Balance.vipDailyGems;
}
