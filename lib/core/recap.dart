/// Tổng kết tuần: khi sang tuần mới (UTC, như nhiệm vụ tuần) chụp lại những gì người chơi làm được trong tuần vừa qua
/// để hiện MỘT popup khi mở app. Như Thử thách tháng, không thêm điểm hook: số liệu = bộ đếm tích lũy có sẵn trừ mốc chụp
/// đầu tuần. Save cũ/người chơi mới chỉ chụp mốc (chưa có tuần nào để tổng kết). Hàm thuần; chỉ mutate [GameState] ở
/// các hàm ghi MUTATE.
library;

import 'dart:math';

import 'models.dart';
import 'weekly_quests.dart' show weekIndex;

/// Thứ tự hiển thị; `earned` luôn hiện, các mục còn lại ẩn khi bằng 0.
const List<String> recapKeys = ['earned', 'taps', 'buys', 'items', 'achievements'];

double _current(GameState s, String k) => switch (k) {
      'earned' => s.lifetimeEarnings,
      'taps' => s.tapCount.toDouble(),
      'buys' => s.buyCount.toDouble(),
      'items' => (s.ownedAccessories.length + s.ownedLimited.length).toDouble(),
      _ => s.achievementsClaimed.length.toDouble(),
    };

/// Sang tuần mới thì chốt số liệu tuần vừa qua (nếu có mốc và người chơi có làm gì) rồi chụp mốc mới. True nếu đổi tuần. MUTATE.
bool rollRecap(GameState s, int nowMillis) {
  final w = weekIndex(nowMillis);
  if (w == s.recapWeek) return false;
  if (s.recapWeek != 0 && s.recapBase.isNotEmpty) {
    final data = {
      for (final k in recapKeys) k: max(0.0, _current(s, k) - (s.recapBase[k] ?? 0)),
    };
    s.recapData
      ..clear()
      ..addAll(data);
    s.recapPending = data.values.any((v) => v > 0);
  }
  s.recapWeek = w;
  s.recapBase
    ..clear()
    ..addEntries([for (final k in recapKeys) MapEntry(k, _current(s, k))]);
  return true;
}
