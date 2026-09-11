/// Luật tính điểm Đấu Trường — HÀM THUẦN, phải khớp bit-for-bit với
/// `arena_compute_score` trong `supabase/arena_schema.sql` (server tính lại
/// từ log thô khi chốt trận; client dùng chính hàm này để hiển thị điểm
/// mượt trong lúc chờ server, và để tính điểm đối thủ theo thời gian thực
/// từ log hành động đọc được qua Realtime).
library;

import 'arena_config.dart';

/// Loại hành động trong một trận — khớp cột `kind` (check constraint) ở SQL.
enum ArenaActionKind { tap, buyTier1, buyTier2, buyTier3 }

extension ArenaActionKindJson on ArenaActionKind {
  String get wireValue => switch (this) {
        ArenaActionKind.tap => 'tap',
        ArenaActionKind.buyTier1 => 'buy_tier_1',
        ArenaActionKind.buyTier2 => 'buy_tier_2',
        ArenaActionKind.buyTier3 => 'buy_tier_3',
      };

  static ArenaActionKind fromWire(String value) => switch (value) {
        'tap' => ArenaActionKind.tap,
        'buy_tier_1' => ArenaActionKind.buyTier1,
        'buy_tier_2' => ArenaActionKind.buyTier2,
        'buy_tier_3' => ArenaActionKind.buyTier3,
        _ => throw ArgumentError('unknown arena action kind: $value'),
      };

  /// Chỉ số mốc (0..2) nếu là hành động mua, null nếu là 'tap'.
  int? get tierIndex => switch (this) {
        ArenaActionKind.buyTier1 => 0,
        ArenaActionKind.buyTier2 => 1,
        ArenaActionKind.buyTier3 => 2,
        ArenaActionKind.tap => null,
      };
}

/// Một dòng log hành động, đã sắp theo thời gian (`at`, rồi `id` để phá thế
/// bằng — khớp `order by at, id` ở SQL).
class ArenaAction {
  const ArenaAction({required this.kind, required this.at, this.id = 0});

  final ArenaActionKind kind;
  final DateTime at;

  /// id tăng dần dùng phá thế bằng khi 2 hành động có cùng `at` (hiếm khi so
  /// sánh cục bộ, chủ yếu quan trọng ở server). Client tạo hành động local
  /// (chưa có id thật) có thể để 0.
  final int id;
}

/// Điểm (Xu tích được trong trận) sau khi replay toàn bộ log hành động của
/// MỘT người chơi, theo đúng thứ tự thời gian. Không ném lỗi với log rỗng
/// hay hành động "mua hụt" (tiền không đủ tại thời điểm replay) — bỏ qua
/// thay vì phá vỡ cả phép tính, giống cách server xử lý.
double arenaComputeScore(List<ArenaAction> actions) {
  final sorted = [...actions]
    ..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

  var tapValue = 1.0;
  var money = 0.0;
  for (final action in sorted) {
    final tier = action.kind.tierIndex;
    if (tier == null) {
      money += tapValue;
      continue;
    }
    final cost = ArenaConfig.tierCosts[tier];
    if (money >= cost) {
      money -= cost;
      tapValue *= ArenaConfig.tierMultiplier;
    }
  }
  return money;
}
