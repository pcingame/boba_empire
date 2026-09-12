/// Lớp nói chuyện trực tiếp với Supabase cho "Bảng xếp hạng PK" — xếp hạng
/// thắng/thua Đấu Trường, xem `supabase/arena_leaderboard_schema.sql`.
///
/// Khác [ArenaRepository]: không đụng gì tới hàng đợi/trận đấu, chỉ đọc
/// thống kê đã gộp sẵn (thắng/thua tính thẳng từ arena_matches ở server —
/// không có số nào do client tự báo cần chống gian lận riêng).
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArenaLeaderboardEntry {
  const ArenaLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.wins,
    required this.losses,
    required this.matches,
    required this.rank,
  });

  factory ArenaLeaderboardEntry.fromRow(Map<String, dynamic> row) =>
      ArenaLeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        wins: (row['wins'] as num).toInt(),
        losses: (row['losses'] as num).toInt(),
        matches: (row['matches'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int wins;
  final int losses;
  final int matches;

  /// Hạng 1-based — server tính sẵn (xem `arena_leaderboard_around_me`).
  final int rank;
}

class ArenaLeaderboardRepository {
  ArenaLeaderboardRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  /// CÙNG key với leaderboard_repository.dart/story_speedrun_repository.dart
  /// — 1 tên dùng chung cho cả 3 bảng xếp hạng, không hỏi lại người chơi đã
  /// đặt tên rồi.
  static const _nicknameKey = 'leaderboard_nickname';

  String? get cachedNickname => _prefs.getString(_nicknameKey);

  Future<void> _cacheNickname(String nickname) =>
      _prefs.setString(_nicknameKey, nickname);

  /// Đăng nhập ẩn danh nếu chưa có phiên nào (kể cả phiên có sẵn từ Đấu
  /// Trường/Bảng xếp hạng chính/Đồng bộ đám mây).
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

  /// Đăng ký/đổi tên hiển thị cho CHÍNH mình (qua RPC, không upsert thẳng
  /// bảng — giữ đúng triết lý "không có policy ghi trực tiếp" của Đấu
  /// Trường). Tự cache lại tên sau khi đăng ký thành công.
  Future<void> setNickname(String nickname) async {
    await ensureSignedIn();
    await _client.rpc('arena_set_nickname', params: {'p_nickname': nickname});
    await _cacheNickname(nickname);
  }

  /// [window] người TRÊN + chính bạn + [window] người DƯỚI theo hạng thắng
  /// PK, hoặc top (2×window + 1) nếu bạn chưa có trận nào — đã kèm sẵn
  /// `rank` (xem `arena_leaderboard_around_me` trong
  /// arena_leaderboard_schema.sql).
  Future<List<ArenaLeaderboardEntry>> fetchAroundMe({int window = 5}) async {
    final rows = await _client.rpc(
      'arena_leaderboard_around_me',
      params: {'p_window': window},
    ) as List;
    return rows
        .map((r) => ArenaLeaderboardEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
