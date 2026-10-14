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
      {this.milestone = 0, this.drop});

  final RecipeProgress before;
  final RecipeProgress after;
  final RecipeAnswerOutcome outcome;

  /// Thưởng vừa trao (0 nếu không phải kỷ lục mới).
  final double cash;
  final int gems;

  /// Mốc rương phụ kiện vừa đạt (số món Thạo; 0 = không) và phụ kiện nhận được.
  final int milestone;
  final AccessoryDrop? drop;
}
