/// Thưởng đăng nhập hằng ngày + chuỗi ngày (streak) — hàm thuần, không thời gian
/// ẩn (nhận [nowMillis] từ ngoài để test bơm được).
library;

import 'models.dart';

const int _msPerDay = 24 * 60 * 60 * 1000;

/// Bảng thưởng Kim Cương theo chu kỳ 7 ngày; streak dài hơn quay vòng lại.
const List<int> dailyRewardGems = [10, 15, 20, 25, 30, 40, 60];

/// Chỉ số ngày (UTC) từ epoch ms — mốc so sánh "đã sang ngày mới".
int dayIndex(int nowMillis) => nowMillis ~/ _msPerDay;

/// Có phần thưởng hằng ngày để nhận không (đã qua ngày mới kể từ lần nhận cuối).
bool dailyAvailable(GameState s, int nowMillis) =>
    dayIndex(nowMillis) > s.lastDailyDay;

/// Streak sẽ đạt nếu nhận NGAY BÂY GIỜ (không mutate): +1 nếu liên tiếp, giữ
/// nguyên nếu đã nhận hôm nay, reset về 1 nếu lần đầu hoặc bỏ lỡ ≥1 ngày.
int nextDailyStreak(GameState s, int nowMillis) {
  final today = dayIndex(nowMillis);
  if (s.lastDailyDay == 0) return 1;
  if (today == s.lastDailyDay + 1) return s.dailyStreak + 1;
  if (today <= s.lastDailyDay) return s.dailyStreak;
  return 1;
}

/// Gems thưởng cho một [streak] (theo bảng, chu kỳ 7).
int dailyGemsForStreak(int streak) =>
    dailyRewardGems[(streak - 1) % dailyRewardGems.length];

/// Giá cứu streak bằng 💎 (hoặc xem 1 quảng cáo rewarded thay thế).
const int streakRestoreGems = 20;

/// Bỏ lỡ ĐÚNG 1 ngày và chuỗi đáng cứu (≥2) → còn cứu được trong lần nhận này.
/// Suy ra từ mốc ngày nên không cần state mới; nhận xong là hết cơ hội.
bool streakRestorable(GameState s, int nowMillis) =>
    s.dailyStreak >= 2 && dayIndex(nowMillis) == s.lastDailyDay + 2;

/// Nhận thưởng hằng ngày: cập nhật streak + mốc ngày, cộng gems. Trả về gems
/// nhận (0 nếu chưa tới ngày mới). [restore] (chỉ có tác dụng khi
/// [streakRestorable]) coi ngày bỏ lỡ như đã nhận → streak +1. MUTATE [s].
int claimDaily(GameState s, int nowMillis, {bool restore = false}) {
  if (!dailyAvailable(s, nowMillis)) return 0;
  final streak = restore && streakRestorable(s, nowMillis)
      ? s.dailyStreak + 1
      : nextDailyStreak(s, nowMillis);
  s.dailyStreak = streak;
  s.lastDailyDay = dayIndex(nowMillis);
  final gems = dailyGemsForStreak(streak);
  s.gems += gems;
  return gems;
}
