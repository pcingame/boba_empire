/// Cấu hình kết nối Supabase + hằng số luật Đấu Trường.
///
/// anon/publishable key vốn nhúng thẳng vào app (giống AdMob unit id ở
/// [AdConfig]) nên an toàn để để trong source — không phải bí mật như
/// service_role key.
library;

class ArenaConfig {
  const ArenaConfig._();

  static const String supabaseUrl = 'https://orphyhtnaaqfglytffkn.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_1mFXwBKzUaLm36h4WMLFuQ_3oqju0RV';

  /// Thời lượng một trận (giây). Khớp `ends_at default (now() + interval
  /// '60 seconds')` trong `supabase/arena_schema.sql`.
  static const int matchSeconds = 60;

  /// Giá 3 mốc nâng cấp trong trận — PHẢI khớp `arena_compute_score` trong
  /// `supabase/arena_schema.sql`. Đổi một bên thì đổi cả hai.
  static const List<double> tierCosts = [20, 80, 200];

  /// Mỗi mốc nhân đôi giá trị chạm (khớp SQL: `tap_value := tap_value * 2`).
  static const double tierMultiplier = 2.0;

  /// Thưởng Kim Cương sau trận — cộng qua `grantGems` như IAP/quest hiện có,
  /// không đụng tới `GameState`/kinh tế chính.
  static const int winGems = 3;
  static const int loseGems = 1;
}
