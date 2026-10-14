/// Nói chuyện với Supabase cho "Bảng xếp hạng Thợ pha chế" — xếp theo SỐ MÓN CÔNG THỨC ĐÃ TỪNG ĐẠT
/// "THẠO". Xem `supabase/recipe_leaderboard_schema.sql`.
///
/// Cùng khuôn `accessory_leaderboard_repository.dart`: số lượng TĂNG DẦN nên hàng của mình được cập
/// nhật lại mỗi lần mở trang (upsert).
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/linked_session.dart';

/// Hai bảng của trò công thức: số món Thạo (trắc nghiệm) và số món pha hoàn hảo không công thức mẫu (Pha theo đơn).
enum RecipeBoard {
  quiz('recipe_leaderboard_entries', 'recipe_leaderboard_top', 'mastered'),
  orders('recipe_order_leaderboard_entries', 'recipe_order_leaderboard_top', 'perfected');

  const RecipeBoard(this.table, this.topRpc, this.column);
  final String table;
  final String topRpc;

  /// Tên cột số lượng (cả ở bảng lẫn kết quả RPC).
  final String column;
}

class RecipeLeaderboardEntry {
  const RecipeLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.mastered,
    required this.rank,
  });

  factory RecipeLeaderboardEntry.fromRow(Map<String, dynamic> row, [RecipeBoard board = RecipeBoard.quiz]) =>
      RecipeLeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        mastered: (row[board.column] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
      );

  final String userId;
  final String nickname;
  final int mastered;
  final int rank;
}

class RecipeLeaderboardRepository {
  RecipeLeaderboardRepository(this._client, this._prefs, [this.board = RecipeBoard.quiz]);

  final RecipeBoard board;

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  /// CÙNG key với các bảng xếp hạng khác — một tên dùng chung.
  static const _nicknameKey = 'leaderboard_nickname';

  String? get cachedNickname => _prefs.getString(_nicknameKey);

  Future<String> ensureSignedIn() async => requireLinkedId(_client.auth.currentUser);

  /// Nickname LUÔN gửi kèm: upsert của Postgres vẫn bắt buộc cột NOT NULL trên hàng đề xuất kể cả khi
  /// rơi vào nhánh UPDATE (bài học từ bảng xếp hạng chính).
  Future<void> submit({required String nickname, required int mastered}) async {
    final uid = await ensureSignedIn();
    await _client.from(board.table).upsert({'user_id': uid, 'nickname': nickname, board.column: mastered});
    await _prefs.setString(_nicknameKey, nickname);
  }

  Future<List<RecipeLeaderboardEntry>> fetchTop({int limit = 50}) async {
    final rows = await _client.rpc(board.topRpc, params: {'p_limit': limit}) as List;
    return rows.map((r) => RecipeLeaderboardEntry.fromRow(r as Map<String, dynamic>, board)).toList();
  }
}
