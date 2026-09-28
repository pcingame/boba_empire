/// Nói chuyện với Supabase cho "Bảng xếp hạng Trân Châu Rơi" — xếp theo TỔNG
/// SAO của Hành trình. Xem `supabase/m3_leaderboard_schema.sql`.
///
/// Khác `story_speedrun_repository.dart` (1 mốc, nộp đúng 1 lần): sao tăng dần
/// nên hàng của mình được cập nhật lại mỗi lần mở trang (upsert).
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class M3LeaderboardEntry {
  const M3LeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.stars,
    required this.levelsCleared,
    required this.rank,
  });

  factory M3LeaderboardEntry.fromRow(Map<String, dynamic> row) =>
      M3LeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        stars: (row['stars'] as num).toInt(),
        levelsCleared: (row['levels_cleared'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int stars;
  final int levelsCleared;
  final int rank;
}

class M3LeaderboardRepository {
  M3LeaderboardRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _table = 'm3_leaderboard_entries';
  static const _topRpc = 'm3_leaderboard_top';

  /// CÙNG key với các bảng xếp hạng khác — một tên dùng chung, không bắt người
  /// chơi đặt tên lại ở từng bảng.
  static const _nicknameKey = 'leaderboard_nickname';

  String? get cachedNickname => _prefs.getString(_nicknameKey);

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

  /// Nộp/cập nhật hàng của mình. Nickname LUÔN gửi kèm: upsert của Postgres vẫn
  /// bắt buộc cột NOT NULL trên hàng đề xuất kể cả khi nó rơi vào nhánh UPDATE
  /// (bài học từ bảng xếp hạng chính).
  Future<void> submit({
    required String nickname,
    required int stars,
    required int levelsCleared,
  }) async {
    final uid = await ensureSignedIn();
    await _client.from(_table).upsert({
      'user_id': uid,
      'nickname': nickname,
      'stars': stars,
      'levels_cleared': levelsCleared,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  Future<List<M3LeaderboardEntry>> fetchTop({int limit = 50}) async {
    final rows = await _client.rpc(_topRpc, params: {'p_limit': limit}) as List;
    return rows
        .map((r) => M3LeaderboardEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
