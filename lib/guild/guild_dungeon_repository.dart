/// Phó bản Hội: mô hình trạng thái + gọi RPC `guild_dungeon_*` (supabase/guild_dungeon_schema.sql).
/// Tách riêng khỏi [GuildRepository] để không đụng các bản giả của test Hội cũ.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/guild_dungeon.dart';
import 'guild_repository.dart';

/// Một hàng bảng đóng góp (đã nhân hệ số vai).
class DungeonMember {
  const DungeonMember({
    required this.userId,
    required this.nickname,
    required this.role,
    required this.tap,
    required this.off,
    required this.rec,
  });

  factory DungeonMember.fromJson(Map<String, dynamic> j) => DungeonMember(
        userId: j['user_id'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        role: DungeonBar.fromWire(j['role']),
        tap: (j['tap'] as num?)?.toInt() ?? 0,
        off: (j['off'] as num?)?.toInt() ?? 0,
        rec: (j['rec'] as num?)?.toInt() ?? 0,
      );

  final String userId;
  final String nickname;
  final DungeonBar? role;
  final int tap;
  final int off;
  final int rec;

  int of(DungeonBar b) => switch (b) { DungeonBar.tap => tap, DungeonBar.off => off, DungeonBar.rec => rec };
}

class DungeonState {
  const DungeonState({
    required this.tier,
    required this.role,
    required this.roleChanges,
    required this.bars,
    required this.targets,
    required this.cleared,
    required this.claimed,
    required this.mine,
    required this.board,
  });

  factory DungeonState.fromJson(Map<String, dynamic> j) {
    Map<DungeonBar, int> bars(Object? o) {
      final m = o is Map ? o : const {};
      return {for (final b in DungeonBar.values) b: (m[b.wire] as num?)?.toInt() ?? 0};
    }

    final t = j['targets'];
    return DungeonState(
      tier: (j['tier'] as num?)?.toInt() ?? 0,
      role: DungeonBar.fromWire(j['role']),
      roleChanges: (j['role_changes'] as num?)?.toInt() ?? 0,
      bars: bars(j['bars']),
      targets: [
        for (final e in (t is List ? t : const [])) bars(e),
      ],
      cleared: ((j['cleared'] as num?)?.toInt() ?? 0).clamp(0, dungeonStages),
      claimed: {
        for (final e in (j['claimed'] is List ? j['claimed'] as List : const []))
          if (e is num) e.toInt(),
      },
      mine: bars(j['mine']),
      board: [
        for (final e in (j['board'] is List ? j['board'] as List : const []))
          if (e is Map<String, dynamic>) DungeonMember.fromJson(e),
      ],
    );
  }

  final int tier;

  /// Vai trò đã chọn tuần này (null = chưa chọn).
  final DungeonBar? role;

  /// Số lần đã ĐỔI vai (0 hoặc 1): lần chọn đầu không tính. 1 = hết lượt đổi.
  final int roleChanges;
  final Map<DungeonBar, int> bars;

  /// [ải 1..3] → ngưỡng từng thanh.
  final List<Map<DungeonBar, int>> targets;
  final int cleared;
  final Set<int> claimed;
  final Map<DungeonBar, int> mine;
  final List<DungeonMember> board;

  bool get canChangeRole => roleChanges < 1;

  /// Ải đang đánh = ải kế tiếp chưa qua (3 = đã qua hết).
  int get currentStage => cleared >= dungeonStages ? dungeonStages : cleared + 1;

  /// Thanh [b] đã đủ ngưỡng của ải đang đánh chưa.
  bool barDone(DungeonBar b) {
    if (targets.length < currentStage) return false;
    return (bars[b] ?? 0) >= (targets[currentStage - 1][b] ?? 1 << 62);
  }

  /// Ải [stage] đã qua, chưa nhận, và bạn đủ mức đóng góp tối thiểu.
  bool canClaim(int stage) =>
      stage <= cleared && !claimed.contains(stage) && meetsMinimum;

  bool get meetsMinimum => DungeonBar.values.any((b) => (mine[b] ?? 0) >= dungeonMinToClaim[b]!);

  /// Số ải qua rồi nhưng chưa nhận (chấm đỏ).
  int get claimableCount => [for (var s = 1; s <= cleared; s++) if (canClaim(s)) s].length;
}

abstract class GuildDungeonRepository {
  /// null nếu không ở hội.
  Future<DungeonState?> state();
  Future<void> submit({required int tap, required int off, required int rec});
  Future<void> setRole(DungeonBar role);
  Future<({int gems, int coins, bool chest})> claim(int stage);
}

class SupabaseGuildDungeonRepository implements GuildDungeonRepository {
  SupabaseGuildDungeonRepository(this._client);
  final SupabaseClient _client;

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null || user.isAnonymous) throw const GuildException(GuildFailure.notLinked);
      return await _client.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw GuildException(guildFailureFromMessage(e.message));
    } on GuildException {
      rethrow;
    } catch (_) {
      throw const GuildException(GuildFailure.network);
    }
  }

  @override
  Future<DungeonState?> state() async {
    final r = await _rpc('guild_dungeon_state');
    return r is Map<String, dynamic> ? DungeonState.fromJson(r) : null;
  }

  @override
  Future<void> submit({required int tap, required int off, required int rec}) =>
      _rpc('guild_dungeon_submit', {'p_tap': tap, 'p_off': off, 'p_rec': rec});

  @override
  Future<void> setRole(DungeonBar role) => _rpc('guild_dungeon_set_role', {'p_role': role.wire});

  @override
  Future<({int gems, int coins, bool chest})> claim(int stage) async {
    final r = await _rpc('guild_dungeon_claim', {'p_stage': stage}) as Map<String, dynamic>;
    return (
      gems: (r['gems'] as num?)?.toInt() ?? 0,
      coins: (r['coins'] as num?)?.toInt() ?? 0,
      chest: r['chest'] == true,
    );
  }
}
