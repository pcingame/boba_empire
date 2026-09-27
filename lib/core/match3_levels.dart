/// Hành trình Ghép 3 — màn chơi đơn. HÀM THUẦN, không Flutter, không mạng.
///
/// Màn sinh bằng CÔNG THỨC (không có bảng dữ liệu 60 dòng): mục tiêu điểm tăng
/// theo cấp số nhân, số nước cố định, bàn cờ tất định theo [Match3Level.seed]
/// nên ai chơi màn n cũng gặp đúng bàn đó.
///
/// Luật chơi dùng lại nguyên `lib/arena/match3_rules.dart` — KHÔNG đụng vào đó
/// (phải khớp bit-for-bit với `arena_m3_replay` trong SQL, xem ghi chú đầu file
/// ấy).
library;

import 'dart:math';

import '../arena/match3_rules.dart';
import 'balance.dart';

/// Kiểu mục tiêu của một màn.
enum Match3GoalKind {
  /// Đạt X điểm.
  score,

  /// Thu thập N ô một loại nhất định.
  collect,
}

class Match3Level {
  const Match3Level(this.id);

  /// 1..[Balance.m3LevelCount].
  final int id;

  int get moves => Balance.m3Moves;

  /// Cứ [Balance.m3CollectEvery] màn thì một màn là kiểu thu thập.
  Match3GoalKind get goal =>
      (Balance.m3CollectEvery > 0 && id % Balance.m3CollectEvery == 0)
          ? Match3GoalKind.collect
          : Match3GoalKind.score;

  /// Thứ tự của màn thu thập này trong dãy màn thu thập (1, 2, 3...).
  int get _collectIndex => Balance.m3CollectEvery > 0
      ? id ~/ Balance.m3CollectEvery
      : 0;

  /// Loại ô cần thu thập (0..4, xoay vòng qua các màn thu thập).
  int get collectType => _collectIndex == 0 ? 0 : (_collectIndex - 1) % m3Types;

  /// Ngưỡng 1 sao: điểm (màn [Match3GoalKind.score]) hoặc số ô cần thu thập.
  ///
  /// Cả hai kiểu dùng CHUNG thang sao của [match3Stars], nên "Chơi nốt" để săn
  /// 2-3 sao hoạt động y hệt nhau.
  int get target => switch (goal) {
        Match3GoalKind.score =>
          (Balance.m3TargetBase * pow(Balance.m3TargetGrowth, id - 1)).round(),
        Match3GoalKind.collect => (Balance.m3CollectBase *
                pow(Balance.m3CollectGrowth, _collectIndex - 1))
            .round(),
      };

  /// Số nguyên tố nhân id → bàn khác nhau rõ rệt giữa các màn, và cố định.
  int get seed => id * 7919;

  /// Chuỗi số nuôi bàn cờ (bảng đầu + luồng bù ô). Tất định theo [seed].
  List<int> seq() {
    final rng = Random(seed);
    return [for (var i = 0; i < m3SeqLength; i++) rng.nextInt(m3Types)];
  }
}

/// Sao đạt được với [score]: 1 sao ở [target], 2 sao ở 1.5x, 3 sao ở 2x.
int match3Stars(int score, int target) {
  if (target <= 0) return 0;
  if (score >= (target * Balance.m3Star3Mult).round()) return 3;
  if (score >= (target * Balance.m3Star2Mult).round()) return 2;
  if (score >= target) return 1;
  return 0;
}

/// Sao đã đạt ở màn [id] (1-based) theo bản ghi [stars] của người chơi.
int starsOf(List<int> stars, int id) =>
    (id >= 1 && id <= stars.length) ? stars[id - 1] : 0;

/// Màn [id] đã mở chưa: màn 1 luôn mở, màn n mở khi màn n-1 có >= 1 sao.
bool levelUnlocked(List<int> stars, int id) =>
    id == 1 || starsOf(stars, id - 1) >= 1;

/// Số màn cao nhất đã mở (để cuộn tới đúng chỗ khi vào trang).
int highestUnlocked(List<int> stars) {
  var n = 1;
  while (n < Balance.m3LevelCount && starsOf(stars, n) >= 1) {
    n++;
  }
  return n;
}
