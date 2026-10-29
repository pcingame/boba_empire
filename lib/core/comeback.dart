/// Quà chào mừng trở lại: vắng từ [comebackMinDays] ngày trở lên thì tặng 💎 theo độ dài vắng (bậc 3/7/14 ngày),
/// tối đa một lần mỗi [comebackCooldownDays] ngày để chỉnh đồng hồ máy tiến không lấy quà liên tục.
/// Mọi con số là ước lượng chưa playtest. Hàm thuần; chỉ mutate [GameState] ở [claimComeback].
library;

import 'models.dart';

const int comebackMinDays = 3;
const int comebackCooldownDays = 7;
const int _dayMs = 24 * 60 * 60 * 1000;

/// 💎 cho khoảng vắng [awayMs] (0 nếu chưa đủ ngày hoặc đồng hồ lùi).
int comebackGems(int awayMs) {
  final days = awayMs ~/ _dayMs;
  if (days >= 14) return 200;
  if (days >= 7) return 100;
  if (days >= comebackMinDays) return 50;
  return 0;
}

/// Lúc [atMillis] người chơi này có nhận được quà trở lại không (đã từng kiếm Xu và qua thời gian chờ)? Dùng để
/// chỉ hứa quà trong thông báo nhắc khi thực sự sẽ có. Không tính bậc ngày.
bool comebackEligibleAt(GameState s, int atMillis) =>
    s.lifetimeEarnings > 0 && atMillis - s.lastComebackMillis >= comebackCooldownDays * _dayMs;

/// Trao quà nếu đủ điều kiện và qua thời gian chờ; trả số 💎 đã cộng (0 nếu không). Save chưa kiếm được Xu nào
/// (người mới/save trống) không phải "người quay lại" nên không có quà. MUTATE.
int claimComeback(GameState s, int nowMillis, int awayMs) {
  final gems = comebackGems(awayMs);
  if (gems == 0 || !comebackEligibleAt(s, nowMillis)) return 0;
  s.lastComebackMillis = nowMillis;
  s.gems += gems;
  return gems;
}
