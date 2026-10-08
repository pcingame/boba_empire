/// Nói chuyện với Supabase cho "Bảng xếp hạng Sự kiện" — mỗi dịp lễ một bảng,
/// xếp theo điểm sự kiện (core/event_quests.dart `eventScore`). Xem
/// `supabase/event_leaderboard_schema.sql`: client chỉ nộp qua RPC có kiểm tra
/// server-side, không ghi thẳng vào bảng.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventLeaderboardEntry {
  const EventLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.rank,
  });

  factory EventLeaderboardEntry.fromRow(Map<String, dynamic> row) =>
      EventLeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        score: (row['score'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int score;
  final int rank;
}

class EventLeaderboardRepository {
  EventLeaderboardRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  /// CÙNG key với các bảng xếp hạng khác — một tên dùng chung.
  static const _nicknameKey = 'leaderboard_nickname';

  String? get cachedNickname => _prefs.getString(_nicknameKey);

  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentUser != null) return;
    final res = await _client.auth.signInAnonymously();
    if (res.user == null) {
      throw StateError('Đăng nhập ẩn danh Supabase thất bại (user null).');
    }
  }

  Future<void> submit({
    required String festivalId,
    required String nickname,
    required int score,
  }) async {
    await _ensureSignedIn();
    await _client.rpc('event_leaderboard_submit', params: {
      'p_festival': festivalId,
      'p_nickname': nickname,
      'p_score': score,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  Future<List<EventLeaderboardEntry>> fetchTop(String festivalId,
      {int limit = 50}) async {
    final rows = await _client.rpc('event_leaderboard_top',
        params: {'p_festival': festivalId, 'p_limit': limit}) as List;
    return rows
        .map((r) => EventLeaderboardEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
