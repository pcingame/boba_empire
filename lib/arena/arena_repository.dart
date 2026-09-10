/// Lớp nói chuyện trực tiếp với Supabase cho chế độ Đấu Trường. Không chứa
/// luật chơi (xem [arenaComputeScore] ở `arena_rules.dart`) — chỉ gọi RPC/
/// đọc bảng theo đúng hợp đồng của `supabase/arena_schema.sql`.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'arena_models.dart';
import 'arena_rules.dart';

class ArenaRepository {
  ArenaRepository(this._client);

  final SupabaseClient _client;

  /// Đăng nhập ẩn danh nếu chưa có phiên. Đấu Trường không cần tài khoản đầy
  /// đủ ở bản MVP (xem PROPOSAL_ARENA_PVP.md §1).
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

  String? get myUserId => _client.auth.currentUser?.id;

  /// Gọi `arena_join_queue()` — trả về trận đang/mới ghép được, hoặc null nếu
  /// vẫn đang chờ (client tự gọi lại, xem [ArenaController]).
  ///
  /// ⚠️ Khi hàm SQL `return null` cho kiểu trả về là ROW (`arena_matches`),
  /// PostgREST KHÔNG serialize thành JSON `null` trơn — nó trả về 1 object
  /// với TẤT CẢ field đều null (`{"id":null,"player_a":null,...}`). Đã verify
  /// trực tiếp bằng curl. Nếu chỉ check `row == null` sẽ luôn sai ở đúng
  /// trường hợp phổ biến nhất (đang chờ ghép) và ném lỗi ép kiểu khi
  /// `ArenaMatch.fromRow` gặp `id: null`.
  Future<ArenaMatch?> joinQueue() async {
    final row = await _client.rpc('arena_join_queue') as Map<String, dynamic>?;
    if (row == null || row['id'] == null) return null;
    return ArenaMatch.fromRow(row);
  }

  Future<void> leaveQueue() => _client.rpc('arena_leave_queue');

  Future<void> submitAction(String matchId, ArenaActionKind kind) => _client.rpc(
        'arena_submit_action',
        params: {'p_match_id': matchId, 'p_kind': kind.wireValue},
      );

  /// Chốt trận (idempotent — cả 2 người có thể gọi, ai gọi trước cũng được).
  /// Server tự chối nếu gọi sớm hơn `ends_at`.
  Future<ArenaMatch> resolveMatch(String matchId) async {
    final row = await _client.rpc(
      'arena_resolve_match',
      params: {'p_match_id': matchId},
    ) as Map<String, dynamic>;
    return ArenaMatch.fromRow(row);
  }

  /// Log hành động của TRẬN (cả 2 người chơi — RLS chỉ cho thấy log của trận
  /// mình đang tham gia) theo thời gian thực, dùng để tự tính điểm 2 bên
  /// bằng [arenaComputeScore] mà không cần đợi server chốt trận. Trả về gộp
  /// cả 2 người (kèm `playerId`) — bên gọi tự tách trước khi tính điểm.
  Stream<List<ArenaLogEntry>> watchActions(String matchId) => _client
      .from('arena_actions')
      .stream(primaryKey: ['id'])
      .eq('match_id', matchId)
      .map((rows) => rows.map(arenaLogEntryFromRow).toList());
}
