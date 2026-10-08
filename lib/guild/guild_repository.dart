/// Nói chuyện với Supabase cho Hội (xem `supabase/guild_schema.sql`). Mọi thao
/// tác đi qua RPC security definer — client không ghi thẳng vào bảng.
///
/// [GuildRepository] là interface để controller/UI test được bằng bản giả (repo
/// này không có mock SupabaseClient).
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuildSummary {
  const GuildSummary({
    required this.id,
    required this.name,
    required this.tag,
    required this.emoji,
    required this.memberCount,
    required this.weekTotal,
    this.requiresApproval = false,
    this.requested = false,
    this.rank,
  });

  factory GuildSummary.fromRow(Map<String, dynamic> r) => GuildSummary(
        id: r['id'] as String,
        name: r['name'] as String,
        tag: r['tag'] as String,
        emoji: r['emoji'] as String,
        memberCount: (r['member_count'] as num).toInt(),
        weekTotal: (r['week_total'] as num).toInt(),
        requiresApproval: (r['requires_approval'] as bool?) ?? false,
        requested: (r['requested'] as bool?) ?? false,
        rank: (r['rank'] as num?)?.toInt(),
      );

  final String id;
  final String name;
  final String tag;
  final String emoji;
  final int memberCount;
  final int weekTotal;

  /// Hội cần chủ hội duyệt: bấm "Xin vào" thay vì vào ngay.
  final bool requiresApproval;

  /// Mình đã gửi yêu cầu vào hội này và đang chờ duyệt.
  final bool requested;
  final int? rank;
}

class GuildMemberInfo {
  const GuildMemberInfo(
      {required this.userId, required this.nickname, required this.points});
  final String userId;
  final String nickname;
  final int points;
}

/// Yêu cầu vào hội đang chờ chủ hội duyệt.
class GuildJoinRequest {
  const GuildJoinRequest({required this.userId, required this.nickname});
  final String userId;
  final String nickname;
}

class MyGuild {
  const MyGuild({
    required this.id,
    required this.name,
    required this.tag,
    required this.emoji,
    required this.ownerId,
    required this.total,
    required this.claimed,
    required this.members,
    this.requiresApproval = false,
    this.requests = const [],
  });

  /// Đọc JSON trả về từ `guild_my()`.
  factory MyGuild.fromJson(Map<String, dynamic> j) {
    final g = j['guild'] as Map<String, dynamic>;
    return MyGuild(
      id: g['id'] as String,
      name: g['name'] as String,
      tag: g['tag'] as String,
      emoji: g['emoji'] as String,
      ownerId: g['owner_id'] as String,
      requiresApproval: (g['requires_approval'] as bool?) ?? false,
      requests: [
        for (final r in (j['requests'] as List?) ?? const [])
          GuildJoinRequest(
            userId: (r as Map)['user_id'] as String,
            nickname: r['nickname'] as String,
          ),
      ],
      total: (j['total'] as num).toInt(),
      claimed: [for (final c in j['claimed'] as List) (c as num).toInt()],
      members: [
        for (final m in j['members'] as List)
          GuildMemberInfo(
            userId: (m as Map)['user_id'] as String,
            nickname: m['nickname'] as String,
            points: (m['points'] as num).toInt(),
          ),
      ],
    );
  }

  final String id;
  final String name;
  final String tag;
  final String emoji;
  final String ownerId;
  final bool requiresApproval;

  /// Yêu cầu chờ duyệt — server chỉ trả cho CHỦ hội (người khác nhận rỗng).
  final List<GuildJoinRequest> requests;

  /// Tổng điểm cả hội tuần này.
  final int total;

  /// Mốc (1-based, như server) mình đã nhận tuần này.
  final List<int> claimed;
  final List<GuildMemberInfo> members;

  int pointsOf(String? userId) {
    for (final m in members) {
      if (m.userId == userId) return m.points;
    }
    return 0;
  }
}

enum GuildFailure {
  nameTaken,
  guildFull,
  alreadyInGuild,
  invalidName,
  notFound,
  notEnoughContribution,

  /// Thiếu 💎 để tạo hội (kiểm cục bộ, không đến từ server).
  notEnoughGems,

  /// Hội này cần duyệt — phải xin vào thay vì vào thẳng.
  approvalRequired,

  /// Hội đang có quá nhiều yêu cầu chờ duyệt.
  requestsFull,
  network,
}

class GuildException implements Exception {
  const GuildException(this.failure);
  final GuildFailure failure;
  @override
  String toString() => 'GuildException($failure)';
}

/// Dịch thông điệp lỗi của RPC (RAISE EXCEPTION '...') sang [GuildFailure].
/// Thông điệp lạ / lỗi mạng → [GuildFailure.network].
GuildFailure guildFailureFromMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('name taken')) return GuildFailure.nameTaken;
  if (m.contains('guild full')) return GuildFailure.guildFull;
  if (m.contains('already in guild')) return GuildFailure.alreadyInGuild;
  if (m.contains('invalid name')) return GuildFailure.invalidName;
  if (m.contains('approval required')) return GuildFailure.approvalRequired;
  if (m.contains('too many requests')) return GuildFailure.requestsFull;
  if (m.contains('not found')) return GuildFailure.notFound;
  if (m.contains('not enough contribution') ||
      m.contains('milestone not reached')) {
    return GuildFailure.notEnoughContribution;
  }
  return GuildFailure.network;
}

abstract class GuildRepository {
  /// Tên đã đặt ở bất kỳ bảng xếp hạng nào (dùng chung key).
  String? get cachedNickname;
  String? get myUserId;

  Future<MyGuild?> myGuild();
  Future<List<GuildSummary>> list();
  Future<List<GuildSummary>> leaderboard();
  Future<void> create({
    required String name,
    required String tag,
    required String emoji,
    required bool requiresApproval,
    required String nickname,
    required int score,
  });

  /// Vào thẳng hội thường [guildId] (hội cần duyệt → [requestJoin]).
  Future<void> join({
    required String guildId,
    required String nickname,
    required int score,
  });
  /// Xin vào hội cần duyệt (gửi sang hội khác thì thay yêu cầu cũ).
  Future<void> requestJoin({
    required String guildId,
    required String nickname,
    required int score,
  });
  Future<void> cancelRequest();

  /// Chủ hội duyệt ([accept] true) hoặc từ chối yêu cầu của [userId].
  Future<void> respondRequest(String userId, {required bool accept});
  Future<void> leave();
  Future<void> kick(String userId);
  Future<void> submitScore(int score);
  Future<void> report(String guildId, String reason);

  /// [milestone] 1-based (khớp server).
  Future<void> claimReward(int milestone);
}

class SupabaseGuildRepository implements GuildRepository {
  SupabaseGuildRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _nicknameKey = 'leaderboard_nickname';

  @override
  String? get cachedNickname => _prefs.getString(_nicknameKey);

  @override
  String? get myUserId => _client.auth.currentUser?.id;

  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentUser != null) return;
    final res = await _client.auth.signInAnonymously();
    if (res.user == null) throw const GuildException(GuildFailure.network);
  }

  Future<dynamic> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      await _ensureSignedIn();
      return await _client.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw GuildException(guildFailureFromMessage(e.message));
    } on GuildException {
      rethrow;
    } catch (_) {
      throw const GuildException(GuildFailure.network);
    }
  }

  List<GuildSummary> _rows(dynamic res) => [
        for (final r in res as List)
          GuildSummary.fromRow(r as Map<String, dynamic>),
      ];

  @override
  Future<MyGuild?> myGuild() async {
    final res = await _rpc('guild_my');
    return res == null ? null : MyGuild.fromJson(res as Map<String, dynamic>);
  }

  @override
  Future<List<GuildSummary>> list() async =>
      _rows(await _rpc('guild_list', {'p_limit': 30}));

  @override
  Future<List<GuildSummary>> leaderboard() async =>
      _rows(await _rpc('guild_leaderboard', {'p_limit': 50}));

  @override
  Future<void> create({
    required String name,
    required String tag,
    required String emoji,
    required bool requiresApproval,
    required String nickname,
    required int score,
  }) async {
    await _rpc('guild_create', {
      'p_name': name,
      'p_tag': tag,
      'p_emoji': emoji,
      'p_requires_approval': requiresApproval,
      'p_nickname': nickname,
      'p_score': score,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  @override
  Future<void> join({
    required String guildId,
    required String nickname,
    required int score,
  }) async {
    await _rpc('guild_join', {
      'p_guild': guildId,
      'p_nickname': nickname,
      'p_score': score,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  @override
  Future<void> requestJoin({
    required String guildId,
    required String nickname,
    required int score,
  }) async {
    await _rpc('guild_request_join', {
      'p_guild': guildId,
      'p_nickname': nickname,
      'p_score': score,
    });
    await _prefs.setString(_nicknameKey, nickname);
  }

  @override
  Future<void> cancelRequest() => _rpc('guild_cancel_request');

  @override
  Future<void> respondRequest(String userId, {required bool accept}) =>
      _rpc('guild_respond_request', {'p_user': userId, 'p_accept': accept});

  @override
  Future<void> leave() => _rpc('guild_leave');

  @override
  Future<void> kick(String userId) => _rpc('guild_kick', {'p_user': userId});

  @override
  Future<void> submitScore(int score) =>
      _rpc('guild_submit_score', {'p_score': score});

  @override
  Future<void> report(String guildId, String reason) =>
      _rpc('guild_report', {'p_guild': guildId, 'p_reason': reason});

  @override
  Future<void> claimReward(int milestone) =>
      _rpc('guild_claim_reward', {'p_milestone': milestone});
}
