/// Thử thách hằng ngày — 2 nhiệm vụ KHÓ mỗi ngày (mục tiêu cao hơn hẳn nhiệm vụ ngày, thưởng cao hơn),
/// chọn XÁC ĐỊNH theo ngày (UTC) như `daily_quests.dart` nên mở lại app không đổi bộ. Góp ý người chơi:
/// "tăng độ khó nhiệm vụ, tăng cả thưởng". Dùng LẠI bộ đếm của nhiệm vụ ngày (`dailyProgress`,
/// `dailyClaimed`) nên không thêm trường lưu nào và tự xoá khi sang ngày; riêng "thắng màn Trân Châu
/// Rơi" có bộ đếm riêng khoá `m3Win`. Tự động chạm KHÔNG tính (xem Balance.autoTapPerSecond).
/// Hàm thuần; chỉ mutate [GameState] ở các hàm ghi rõ MUTATE.
library;

import 'dart:math';

import 'balance.dart';
import 'models.dart';

enum ChallengeKind { tap, buy, cat, vip, m3Win }

class Challenge {
  const Challenge(this.kind, this.target, this.rewardGems);
  final ChallengeKind kind;
  final int target;
  final int rewardGems;
}

/// Khoá bộ đếm trong `dailyProgress`: tap/buy/cat/vip trùng tên `DailyQuestKind` (cùng bộ đếm với nhiệm vụ
/// ngày); m3Win là khoá riêng.
String _progressKey(ChallengeKind k) => k.name;

/// Khoá trong `dailyClaimed` đánh dấu đã nhận (tiền tố khác để không đụng nhiệm vụ ngày).
String _claimKey(ChallengeKind k) => 'challenge:${k.name}';
const String _bonusKey = 'challenge:bonus';

/// Bộ thử thách của ngày [day].
List<Challenge> challengesFor(int day) {
  final rng = Random(day * 1597334677 ^ 0x1b873593);
  final kinds = [...ChallengeKind.values]..shuffle(rng);
  // Rút mọi số theo thứ tự cố định để kết quả không phụ thuộc loại nào được chọn trước.
  final tap = 800 + rng.nextInt(3) * 200; // 800..1200
  final buy = 120 + rng.nextInt(3) * 40; // 120..200
  final cat = 4 + rng.nextInt(3); // 4..6 (mèo xuất hiện mỗi ~3–5 phút khi đang mở app)
  final vip = 3 + rng.nextInt(3); // 3..5
  final m3 = 2 + rng.nextInt(3); // 2..4
  return [
    for (final k in kinds.take(Balance.challengeCount))
      Challenge(
        k,
        switch (k) {
          ChallengeKind.tap => tap,
          ChallengeKind.buy => buy,
          ChallengeKind.cat => cat,
          ChallengeKind.vip => vip,
          ChallengeKind.m3Win => m3,
        },
        Balance.challengeRewardGems,
      ),
  ];
}

List<Challenge> currentChallenges(GameState s) => challengesFor(s.dailyQuestDay);

double challengeProgress(GameState s, Challenge c) => s.dailyProgress[_progressKey(c.kind)] ?? 0;

bool challengeDone(GameState s, Challenge c) => challengeProgress(s, c) >= c.target;

bool challengeClaimed(GameState s, Challenge c) => s.dailyClaimed.contains(_claimKey(c.kind));

/// Thắng một màn Trân Châu Rơi (≥1★) → +1 cho thử thách "thắng màn". MUTATE.
void addChallengeM3Win(GameState s) {
  final v = (s.dailyProgress[_progressKey(ChallengeKind.m3Win)] ?? 0) + 1;
  if (v.isFinite) s.dailyProgress[_progressKey(ChallengeKind.m3Win)] = v;
}

/// Nhận thưởng thử thách thứ [index]. Trả về 💎 (0 nếu chưa xong/đã nhận/index sai). MUTATE.
int claimChallenge(GameState s, int index) {
  final list = currentChallenges(s);
  if (index < 0 || index >= list.length) return 0;
  final c = list[index];
  if (!challengeDone(s, c) || challengeClaimed(s, c)) return 0;
  s.dailyClaimed.add(_claimKey(c.kind));
  s.gems += c.rewardGems;
  return c.rewardGems;
}

/// Đã nhận cả bộ, chưa nhận thưởng thêm.
bool challengeBonusAvailable(GameState s) =>
    !s.dailyClaimed.contains(_bonusKey) &&
    currentChallenges(s).every((c) => challengeClaimed(s, c));

bool challengeBonusClaimed(GameState s) => s.dailyClaimed.contains(_bonusKey);

/// Nhận thưởng "xong cả bộ" một lần/ngày. Trả về 💎 (0 nếu chưa đủ điều kiện). MUTATE.
int claimChallengeBonus(GameState s) {
  if (!challengeBonusAvailable(s)) return 0;
  s.dailyClaimed.add(_bonusKey);
  s.gems += Balance.challengeBonusGems;
  return Balance.challengeBonusGems;
}

/// Số thứ đang chờ nhận (chấm đỏ): thử thách xong chưa nhận + thưởng cả bộ.
int challengeClaimableCount(GameState s) {
  var n = 0;
  for (final c in currentChallenges(s)) {
    if (challengeDone(s, c) && !challengeClaimed(s, c)) n++;
  }
  if (challengeBonusAvailable(s)) n++;
  return n;
}
