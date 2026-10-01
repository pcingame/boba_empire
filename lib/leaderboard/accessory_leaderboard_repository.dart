/// Nói chuyện với Supabase cho "Bảng xếp hạng Sưu tập" — xếp theo SỐ PHỤ
/// KIỆN KHÁC NHAU đã có. Xem `supabase/accessory_leaderboard_schema.sql`.
///
/// Cùng khuôn `m3_leaderboard_repository.dart`: số lượng TĂNG DẦN nên hàng
/// của mình được cập nhật lại mỗi lần mở trang (upsert).
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessoryLeaderboardEntry {
  const AccessoryLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.ownedCount,
    required this.rank,
  });

  factory AccessoryLeaderboardEntry.fromRow(Map<String, dynamic> row) =>
      AccessoryLeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        ownedCount: (row['owned_count'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int ownedCount;
  final int rank;
}

class AccessoryLeaderboardRepository {
  AccessoryLeaderboardRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _table = 'accessory_leaderboard_entries';
  static const _topRpc = 'accessory_leaderboard_top';

  /// CÙNG key với các bảng xếp hạng khác — một tên dùng chung.
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

  Future<void> submit({
    required String nickname,
    required int ownedCount,
  }) async {
    final uid = await ensureSignedIn();
    await _client.from(_table).upsert({
      'user_id': uid,
      'nickname': nickname,
      'owned_count': ownedCount,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  Future<List<AccessoryLeaderboardEntry>> fetchTop({int limit = 50}) async {
    final rows = await _client.rpc(_topRpc, params: {'p_limit': limit}) as List;
    return rows
        .map((r) => AccessoryLeaderboardEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
