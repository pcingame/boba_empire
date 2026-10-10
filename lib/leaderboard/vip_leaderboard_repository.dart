/// Bảng xếp hạng VIP — xếp theo VIP EXP (RPC `vip_leaderboard_top`, ghi qua
/// `submit_vip_exp` trong FlairCache.reportVip). Xem supabase/accessory_market_schema.sql.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class VipLeaderboardEntry {
  const VipLeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.vipExp,
    required this.level,
    required this.rank,
    required this.online,
  });

  factory VipLeaderboardEntry.fromRow(Map<String, dynamic> row) =>
      VipLeaderboardEntry(
        userId: row['user_id'] as String,
        nickname: row['nickname'] as String,
        vipExp: (row['vip_exp'] as num).toInt(),
        level: (row['level'] as num).toInt(),
        rank: (row['rank'] as num).toInt(),
        online: row['online'] == true,
      );

  final String userId;
  final String nickname;
  final int vipExp;
  final int level;
  final int rank;
  final bool online;
}

class VipLeaderboardRepository {
  const VipLeaderboardRepository(this._client);

  final SupabaseClient _client;

  Future<List<VipLeaderboardEntry>> fetchTop({int limit = 50}) async {
    final rows = await _client.rpc('vip_leaderboard_top', params: {'p_limit': limit})
        as List;
    return rows
        .map((r) => VipLeaderboardEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
