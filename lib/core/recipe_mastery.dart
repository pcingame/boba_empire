/// Bậc thuộc công thức + ôn cách quãng (kiểu hộp Leitner). Hàm thuần.
///
/// Mỗi món có bậc 0..3 (Mới → Quen → Thuộc → Thạo). Chỉ khi món ĐẾN HẠN ôn ([RecipeProgress.dueDay] ≤ hôm
/// nay) thì trả lời mới đổi bậc: đúng → lên một bậc và hẹn lần ôn sau xa dần; sai → xuống một bậc, ôn lại
/// ngay. Luyện món chưa tới hạn không đổi gì — nên không thể cày một món cho lên bậc trong một buổi.
library;

import 'dart:math' as math;

import 'accessories.dart' show AccessoryDrop, AccessoryRarity;

const int recipeMaxBox = 3;

/// Ngày (dayIndex) bắt đầu có nhiệm vụ công thức xen vào bộ nhiệm vụ ngày/tuần (2026-10-20, thứ Ba).
/// Trước mốc này bộ nhiệm vụ chọn y như cũ — các tuần/ngày đã qua (và test cũ) không đổi.
const int recipeQuestsStartDay = 20746;

/// Số ngày tới lần ôn kế sau khi đạt bậc [i] (chỉ số = bậc).
const List<int> recipeIntervalDays = [0, 1, 3, 7];

/// Thưởng Xu khi LẦN ĐẦU đạt bậc [i] của một món, tính theo giây sản xuất (sàn: số lần chạm tương ứng).
const List<int> recipeRewardSeconds = [0, 30, 60, 120];
const List<int> recipeRewardFloorTaps = [0, 5, 10, 20];

/// Rương phụ kiện theo số món ĐÃ TỪNG đạt Thạo (mốc → độ hiếm tối thiểu của món), nhận tự động một lần
/// mỗi mốc — cùng ý tưởng mốc màn 10/30/60 của Trân Châu Rơi. Đếm theo `best` nên sai-rồi-đúng-lại
/// không làm mất hay nhận lặp mốc.
const Map<int, AccessoryRarity> recipeAccessoryMilestones = {
  5: AccessoryRarity.rare,
  10: AccessoryRarity.epic,
  20: AccessoryRarity.legendary,
};

/// Số món đã từng đạt Thạo (best == [recipeMaxBox]) trong bản lưu `id → [box, dueDay, best]`.
/// Cũng là con số nộp lên bảng xếp hạng "Thợ pha chế" (chỉ tăng, khớp trigger không-hạ-cấp ở server).
int recipeMasteredEver(Map<String, List<int>> progress) =>
    progress.values.where((l) => RecipeProgress.fromList(l).best == recipeMaxBox).length;

/// 💎 thưởng khi lần đầu đạt bậc Thạo của một món.
const int recipeMaxBoxGems = 3;

class RecipeProgress {
  const RecipeProgress({this.box = 0, this.dueDay = 0, this.best = 0});

  /// Từ dạng lưu `[box, dueDay, best]`; giá trị hỏng được kẹp về khoảng hợp lệ.
  factory RecipeProgress.fromList(List<dynamic> l) {
    int at(int i) => i < l.length && l[i] is num ? (l[i] as num).toInt() : 0;
    final box = at(0).clamp(0, recipeMaxBox);
    return RecipeProgress(box: box, dueDay: math.max(at(1), 0), best: math.max(at(2).clamp(0, recipeMaxBox), box));
  }

  /// Bậc hiện tại 0..3.
  final int box;

  /// Ngày (dayIndex) tới hạn ôn kế tiếp; món mới = 0 (luôn tới hạn).
  final int dueDay;

  /// Bậc cao nhất từng đạt — thưởng chỉ trao khi vượt mốc này (xuống rồi lên lại không nhận lần hai).
  final int best;

  List<int> toList() => [box, dueDay, best];

  bool isDue(int today) => today >= dueDay;
}

class RecipeAnswerOutcome {
  const RecipeAnswerOutcome(this.next, {required this.counted, required this.leveledUp, required this.newBest});

  final RecipeProgress next;

  /// Câu trả lời có tính vào bậc không (món đã tới hạn ôn).
  final bool counted;
  final bool leveledUp;

  /// Đạt bậc cao hơn mọi lần trước → được thưởng.
  final bool newBest;
}

RecipeAnswerOutcome applyRecipeAnswer(RecipeProgress p, bool correct, int today) {
  if (!p.isDue(today)) return RecipeAnswerOutcome(p, counted: false, leveledUp: false, newBest: false);
  if (correct) {
    final box = math.min(p.box + 1, recipeMaxBox);
    final next = RecipeProgress(
      box: box,
      dueDay: today + recipeIntervalDays[box],
      best: math.max(p.best, box),
    );
    return RecipeAnswerOutcome(next,
        counted: true, leveledUp: box > p.box, newBest: box > p.best);
  }
  final next = RecipeProgress(box: math.max(p.box - 1, 0), dueDay: today, best: p.best);
  return RecipeAnswerOutcome(next, counted: true, leveledUp: false, newBest: false);
}

/// Kết quả ghi một câu trả lời (do controller trả về cho giao diện).
class RecipeAnswerResult {
  const RecipeAnswerResult(this.before, this.after, this.outcome, this.cash, this.gems,
      {this.milestone = 0, this.drop, this.streakDays = 0, this.streakExtended = false, this.streakGems = 0});

  final RecipeProgress before;
  final RecipeProgress after;
  final RecipeAnswerOutcome outcome;

  /// Thưởng vừa trao (0 nếu không phải kỷ lục mới).
  final double cash;
  final int gems;

  /// Mốc rương phụ kiện vừa đạt (số món Thạo; 0 = không) và phụ kiện nhận được.
  final int milestone;
  final AccessoryDrop? drop;

  /// Chuỗi ngày ôn sau câu này, hôm nay có phải ngày đầu tiên ôn không, và 💎 mốc chuỗi nhận được.
  final int streakDays;
  final bool streakExtended;
  final int streakGems;
}

// --- Chuỗi ngày ôn công thức ------------------------------------------------------------------

/// 💎 thưởng khi chuỗi chạm đúng mốc (số ngày → 💎), CHỈ khi vượt kỷ lục cũ [RecipeStreak.best] — nên bỏ
/// chuỗi rồi gây lại từ đầu không nhận lặp lại các mốc đã nhận.
const Map<int, int> recipeStreakMilestoneGems = {3: 10, 7: 30, 14: 60, 30: 150};

/// Giá cứu chuỗi bằng 💎 (hoặc xem một quảng cáo thưởng thay thế). Chỉ cứu được khi bỏ lỡ ĐÚNG một ngày.
const int recipeStreakRestoreGems = 30;

/// Chuỗi ngày liên tiếp có ít nhất một câu ôn THẬT SỰ được tính bậc (món đến hạn, không dùng gợi ý). Ngày
/// tính theo `dayIndex` (UTC) như điểm danh hằng ngày.
class RecipeStreak {
  const RecipeStreak({this.days = 0, this.lastDay = 0, this.best = 0});

  /// Số ngày của chuỗi tính tới [lastDay] (kể cả khi đã đứt — xem [aliveDays]).
  final int days;

  /// Ngày (dayIndex) của lần ôn được tính gần nhất; 0 = chưa từng.
  final int lastDay;

  /// Chuỗi dài nhất từng đạt.
  final int best;

  /// Chuỗi đang sống tại [today]: ôn hôm nay hoặc hôm qua. Đứt rồi thì 0 (trừ khi còn cứu được).
  int aliveDays(int today) => lastDay != 0 && today - lastDay <= 1 ? days : 0;

  /// Đã ôn hôm nay chưa.
  bool reviewedToday(int today) => lastDay == today;

  /// Bỏ lỡ ĐÚNG một ngày và chuỗi đáng cứu (≥ 2) → còn cứu được cho tới khi ôn lần kế.
  bool restorable(int today) => days >= 2 && lastDay != 0 && today == lastDay + 2;
}

class RecipeStreakUpdate {
  const RecipeStreakUpdate(this.next, {required this.extended, required this.milestoneGems});
  final RecipeStreak next;

  /// Hôm nay là lần ôn đầu tiên của ngày (chuỗi tăng hoặc bắt đầu lại).
  final bool extended;

  /// 💎 mốc nhận được ngay lúc này (0 nếu không).
  final int milestoneGems;
}

/// Ghi nhận một câu ôn được tính bậc vào ngày [today].
RecipeStreakUpdate updateRecipeStreak(RecipeStreak s, int today) {
  if (s.lastDay == today) return RecipeStreakUpdate(s, extended: false, milestoneGems: 0);
  final days = today == s.lastDay + 1 ? s.days + 1 : 1; // đứt (hoặc lần đầu) → bắt đầu lại từ 1
  final gems = days > s.best ? (recipeStreakMilestoneGems[days] ?? 0) : 0;
  return RecipeStreakUpdate(
    RecipeStreak(days: days, lastDay: today, best: math.max(s.best, days)),
    extended: true,
    milestoneGems: gems,
  );
}

/// Cứu chuỗi: coi ngày bỏ lỡ như đã ôn (chuỗi +1, mốc ngày dời về hôm qua) — câu ôn hôm nay sau đó nối tiếp
/// thành +1 nữa. Không đổi gì nếu không còn cứu được.
RecipeStreak restoreRecipeStreak(RecipeStreak s, int today) => s.restorable(today)
    ? RecipeStreak(days: s.days + 1, lastDay: today - 1, best: math.max(s.best, s.days + 1))
    : s;
