/// Lớp nói chuyện trực tiếp với Supabase cho "Bảng xếp hạng tốc độ hoàn
/// thành cốt truyện" — xem `supabase/story_speedrun_schema.sql`.
///
/// Khác `leaderboard_repository.dart` (điểm số cập nhật liên tục, upsert mỗi
/// lần mở trang): đây là 1 MỐC MỘT LẦN — nộp đúng 1 lần khi vừa xem xong
/// Chương 18, không sửa lại được sau đó (bảng không có policy update). Dùng
/// chung BẤT KỲ phiên nào đang có + tên đã đặt ở Bảng xếp hạng chính (cùng
/// key SharedPreferences) để không bắt người chơi đặt tên 2 lần.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bảng nào: "Hồi 1" (tới Chương 18, `story_speedrun_schema.sql`), "Hồi 2"
/// (tới Chương 28, `story_speedrun2_schema.sql`) hay "Hồi 3" (tới Chương 34,
/// `story_speedrun3_schema.sql`). Ba bảng riêng, cùng khuôn.
enum SpeedrunBoard {
  main('story_speedrun_entries', 'story_speedrun_top'),
  ext('story_speedrun2_entries', 'story_speedrun2_top'),
  third('story_speedrun3_entries', 'story_speedrun3_top');

  const SpeedrunBoard(this.table, this.topRpc);
  final String table;
  final String topRpc;
}

class StorySpeedrunEntry {
  const StorySpeedrunEntry({
    required this.userId,
    required this.nickname,
    required this.completeSeconds,
    required this.rank,
  });

  factory StorySpeedrunEntry.fromRow(Map<String, dynamic> row) =>
      StorySpeedrunEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        completeSeconds: (row['complete_seconds'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int completeSeconds;
  final int rank;
}

class StorySpeedrunRepository {
  StorySpeedrunRepository(this._client, this._prefs,
      [this.board = SpeedrunBoard.main]);

  final SupabaseClient _client;
  final SharedPreferences _prefs;
  final SpeedrunBoard board;

  /// CÙNG key với leaderboard_repository.dart — 1 tên dùng chung cho cả 2
  /// bảng xếp hạng, không hỏi lại người chơi đã đặt tên rồi.
  static const _nicknameKey = 'leaderboard_nickname';

  String? get cachedNickname => _prefs.getString(_nicknameKey);

  Future<void> _cacheNickname(String nickname) =>
      _prefs.setString(_nicknameKey, nickname);

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

  /// Nộp mốc hoàn thành — CHỈ 1 LẦN cho mỗi tài khoản (bảng không cho update,
  /// insert lần 2 sẽ lỗi trùng khoá chính). Gọi lại nhiều lần là AN TOÀN: lần
  /// sau luôn lỗi trùng khoá, coi như no-op (không phải lỗi cần báo người
  /// chơi — [GameController] có thể gọi hàm này mỗi lần mở app sau khi hoàn
  /// thành mà không cần tự nhớ "đã nộp chưa").
  Future<void> submitCompletion({
    required String nickname,
    required int completeSeconds,
  }) async {
    final uid = await ensureSignedIn();
    try {
      await _client.from(board.table).insert({
        'user_id': uid,
        'nickname': nickname,
        'complete_seconds': completeSeconds,
      });
      await _cacheNickname(nickname);
    } on PostgrestException catch (e) {
      // '23505' = unique_violation (đã nộp rồi) — no-op, không phải lỗi thật.
      if (e.code != '23505') rethrow;
    }
  }

  /// Top [limit] người hoàn thành nhanh nhất — không phải "quanh hạng của
  /// bạn" như bảng xếp hạng chính: số người hoàn thành cốt truyện chắc chắn
  /// ít hơn nhiều tổng số người chơi, top tuyệt đối vẫn có ý nghĩa (và người
  /// CHƯA hoàn thành thì vốn không có hàng nào để "quanh" cả).
  Future<List<StorySpeedrunEntry>> fetchTop({int limit = 50}) async {
    final rows = await _client.rpc(
      board.topRpc,
      params: {'p_limit': limit},
    ) as List;
    return rows
        .map((r) => StorySpeedrunEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
