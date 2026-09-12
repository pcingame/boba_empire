/// Lớp nói chuyện trực tiếp với Supabase cho Bảng xếp hạng — xem
/// PROPOSAL_LEADERBOARD.md và `supabase/leaderboard_schema.sql`.
///
/// Dùng chung BẤT KỲ phiên nào đang có (ẩn danh từ Đấu Trường, permanent từ
/// Đồng bộ đám mây, hoặc tự đăng nhập ẩn danh mới nếu chưa có gì) — không
/// bắt người chơi phải làm thêm bước riêng để xếp hạng.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.lifetimeEarnings,
    required this.prestigeStars,
    required this.stage,
    required this.rank,
  });

  factory LeaderboardEntry.fromRow(Map<String, dynamic> row) => LeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        lifetimeEarnings: (row['lifetime_earnings'] as num).toDouble(),
        prestigeStars: (row['prestige_stars'] as num).toInt(),
        stage: (row['stage'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final double lifetimeEarnings;
  final int prestigeStars;
  final int stage;

  /// Hạng 1-based theo Xu cả đời — server tính sẵn (xem
  /// `leaderboard_around_me` trong leaderboard_schema.sql).
  final int rank;
}

class LeaderboardRepository {
  LeaderboardRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _nicknameKey = 'leaderboard_nickname';

  /// Tên đã đặt lần trước (cache local) — null nếu chưa từng đặt. Luôn gửi
  /// kèm tên ở MỌI lần nộp điểm (kể cả cập nhật) để tránh phải phân biệt
  /// "chèn mới" (bắt buộc có tên, cột NOT NULL) với "cập nhật" (có thể bỏ
  /// tên) — upsert của Postgres vẫn kiểm NOT NULL trên toàn bộ hàng đề
  /// xuất kể cả khi cuối cùng là UPDATE do đụng khoá, nên đơn giản nhất là
  /// luôn gửi đủ.
  String? get cachedNickname => _prefs.getString(_nicknameKey);

  Future<void> _cacheNickname(String nickname) =>
      _prefs.setString(_nicknameKey, nickname);

  /// Đăng nhập ẩn danh nếu chưa có phiên nào (kể cả phiên có sẵn từ Đấu
  /// Trường/Đồng bộ đám mây) — trả về user id.
  Future<String> ensureSignedIn() async {
    final existing = _client.auth.currentUser;
    if (existing != null) return existing.id;
    final res = await _client.auth.signInAnonymously();
    final user = res.user;
    if (user == null) {
      throw StateError('Đăng nhập ẩn danh Supabase thất bại (user null).');
    }
    return user.id;
  }

  /// Nộp/cập nhật điểm của CHÍNH mình — LUÔN kèm [nickname] (xem
  /// [cachedNickname]). Tự cache lại tên sau khi nộp thành công.
  Future<void> submit({
    required String nickname,
    required double lifetimeEarnings,
    required int prestigeStars,
    required int stage,
  }) async {
    final uid = await ensureSignedIn();
    final row = <String, dynamic>{
      'user_id': uid,
      'nickname': nickname,
      'lifetime_earnings': lifetimeEarnings,
      'prestige_stars': prestigeStars,
      'stage': stage,
    };
    await _client.from('leaderboard_entries').upsert(row);
    await _cacheNickname(nickname);
  }

  /// [window] người TRÊN + chính bạn + [window] người DƯỚI, theo hạng Xu cả
  /// đời — đã kèm sẵn `rank` (xem `leaderboard_around_me` trong
  /// leaderboard_schema.sql). Top 50 tuyệt đối gần như chắc chắn không có
  /// tên bạn lúc còn ít người chơi — danh sách quanh hạng của mình thì luôn
  /// có 1 mục tiêu vừa tầm để vượt qua.
  Future<List<LeaderboardEntry>> fetchAroundMe({int window = 5}) async {
    final rows = await _client.rpc(
      'leaderboard_around_me',
      params: {'p_window': window},
    ) as List;
    return rows.map((r) => LeaderboardEntry.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Thử nhận thưởng Kim Cương theo hạng — trả về số Kim Cương vừa nhận (0
  /// nếu chưa đủ điều kiện: hạng chưa đủ cao, hoặc còn trong thời gian chờ
  /// giữa 2 lần nhận). An toàn gọi lại nhiều lần — server tự kiểm tra điều
  /// kiện, không phải lỗi nếu trả về 0. Xem `leaderboard_claim_reward()`
  /// trong leaderboard_schema.sql cho bậc thưởng/thời gian chờ thật.
  Future<int> claimReward() async {
    final result = await _client.rpc('leaderboard_claim_reward');
    return (result as num).toInt();
  }
}
