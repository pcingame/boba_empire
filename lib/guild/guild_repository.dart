/// Nói chuyện với Supabase cho Hội (xem `supabase/guild_schema.sql`). Mọi thao
/// tác đi qua RPC security definer — client không ghi thẳng vào bảng.
///
/// [GuildRepository] là interface để controller/UI test được bằng bản giả (repo
/// này không có mock SupabaseClient).
library;

import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/guild.dart';
import '../core/guild_shop.dart';

class GuildSummary {
  const GuildSummary({
    required this.id,
    required this.name,
    required this.tag,
    required this.emoji,
    required this.memberCount,
    required this.weekTotal,
    this.maxMembers = guildBaseMembers,
    this.requiresApproval = false,
    this.requested = false,
    this.rank,
    this.avgPoints,
    this.streak,
    this.vipExp,
  });

  factory GuildSummary.fromRow(Map<String, dynamic> r) => GuildSummary(
        id: r['id'] as String,
        name: r['name'] as String,
        tag: r['tag'] as String,
        emoji: r['emoji'] as String,
        memberCount: (r['member_count'] as num).toInt(),
        weekTotal: (r['week_total'] as num).toInt(),
        maxMembers: (r['max_members'] as num?)?.toInt() ?? guildBaseMembers,
        requiresApproval: (r['requires_approval'] as bool?) ?? false,
        requested: (r['requested'] as bool?) ?? false,
        rank: (r['rank'] as num?)?.toInt(),
        avgPoints: (r['avg_points'] as num?)?.toInt(),
        streak: (r['streak'] as num?)?.toInt(),
        vipExp: (r['vip_exp'] as num?)?.toInt(),
      );

  final String id;
  final String name;
  final String tag;
  final String emoji;
  final int memberCount;
  final int weekTotal;

  /// Sức chứa của hội (server cũ chưa có cột → mặc định ban đầu).
  final int maxMembers;

  /// Hội cần chủ hội duyệt: bấm "Xin vào" thay vì vào ngay.
  final bool requiresApproval;

  /// Mình đã gửi yêu cầu vào hội này và đang chờ duyệt.
  final bool requested;
  final int? rank;

  /// Điểm trung bình mỗi thành viên (chỉ BXH trung bình) / số tuần liên tiếp đủ 3
  /// mốc (chỉ BXH chuỗi).
  final int? avgPoints;
  final int? streak;

  /// Tổng VIP EXP của thành viên (chỉ BXH VIP; chỉ tính người đã đặt biệt danh và nộp EXP).
  final int? vipExp;
}

/// Quỹ hội tuần (xem guild_shop.dart). [target] 0 = server cũ chưa có quỹ → ẩn thẻ.
class GuildFund {
  const GuildFund({this.progress = 0, this.target = 0, this.mine = 0, this.claimed = false});

  factory GuildFund.fromJson(Map<String, dynamic>? j) => j == null
      ? const GuildFund()
      : GuildFund(
          progress: (j['progress'] as num).toInt(),
          target: (j['target'] as num).toInt(),
          mine: (j['mine'] as num).toInt(),
          claimed: j['claimed'] as bool,
        );

  final int progress;
  final int target;
  final int mine;
  final bool claimed;

  bool get available => target > 0;
  bool get reached => available && progress >= target;
}

enum GuildRole { owner, officer, member }

class GuildMemberInfo {
  const GuildMemberInfo({
    required this.userId,
    required this.nickname,
    required this.points,
    this.role = GuildRole.member,
  });
  final String userId;
  final String nickname;
  final int points;
  final GuildRole role;
}

enum GuildEventKind { joined, left, kicked, promoted, demoted, transferred }

/// Một dòng nhật ký hoạt động hội. [target] null với joined/left.
class GuildEvent {
  const GuildEvent({
    required this.kind,
    required this.actor,
    this.target,
    this.createdAt,
  });

  factory GuildEvent.fromJson(Map<String, dynamic> j) => GuildEvent(
        kind: GuildEventKind.values.firstWhere((k) => k.name == j['kind'],
            orElse: () => GuildEventKind.joined),
        actor: j['actor'] as String,
        target: j['target'] as String?,
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  final GuildEventKind kind;
  final String actor;
  final String? target;
  final DateTime? createdAt;
}

/// Một món quà 💎 do hội viên khác tặng, chưa nhận.
class GuildGift {
  const GuildGift({
    required this.id,
    required this.fromNickname,
    required this.amount,
    this.createdAt,
  });

  factory GuildGift.fromJson(Map<String, dynamic> j) => GuildGift(
        id: (j['id'] as num).toInt(),
        fromNickname: j['from_nickname'] as String? ?? '?',
        amount: (j['amount'] as num).toInt(),
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  final int id;
  final String fromNickname;
  final int amount;
  final DateTime? createdAt;
}

/// Yêu cầu vào hội đang chờ chủ hội duyệt.
class GuildJoinRequest {
  const GuildJoinRequest({required this.userId, required this.nickname});
  final String userId;
  final String nickname;
}

/// Một loại reaction trên một tin: số người bấm và mình có bấm không.
class GuildReaction {
  const GuildReaction({required this.emoji, required this.count, required this.mine});

  factory GuildReaction.fromJson(Map<String, dynamic> j) => GuildReaction(
        emoji: j['emoji'] as String,
        count: (j['count'] as num).toInt(),
        mine: j['mine'] == true,
      );

  final String emoji;
  final int count;
  final bool mine;
}

/// Một tin trong chat hội.
class GuildMessage {
  const GuildMessage({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.body,
    this.reactions = const [],
    this.imageKey,
  });

  factory GuildMessage.fromJson(Map<String, dynamic> j) => GuildMessage(
        id: (j['id'] as num).toInt(),
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String,
        body: j['body'] as String,
        imageKey: j['image_key'] as String?,
        // Server cũ chưa có reaction → không có khoá này.
        reactions: [
          for (final r in (j['reactions'] as List?) ?? const [])
            GuildReaction.fromJson(r as Map<String, dynamic>),
        ],
      );

  final int id;
  final String userId;
  final String nickname;
  final String body;
  final List<GuildReaction> reactions;

  /// Khoá ảnh đính kèm (bucket 'guild-images'); null = tin chữ.
  final String? imageKey;
}

/// Chat hội: tin ghim (nếu có) + các tin mới nhất, MỚI NHẤT Ở ĐẦU.
class GuildChat {
  const GuildChat({this.pinned, this.messages = const []});

  factory GuildChat.fromJson(Map<String, dynamic> j) => GuildChat(
        pinned: j['pinned'] == null
            ? null
            : GuildMessage.fromJson(j['pinned'] as Map<String, dynamic>),
        messages: [
          for (final m in j['messages'] as List)
            GuildMessage.fromJson(m as Map<String, dynamic>),
        ],
      );

  final GuildMessage? pinned;
  final List<GuildMessage> messages;
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
    this.maxMembers = guildBaseMembers,
    this.requiresApproval = false,
    this.requests = const [],
    this.streak = 0,
    this.buffSeconds = 0,
    this.wallet = 0,
    this.questsClaimed = const [],
    this.ownedItems = const [],
    this.donatedToday = 0,
    this.chatLatestId = 0,
    this.fund = const GuildFund(),
    this.teamAvailable = false,
    this.teamClaimed = false,
    this.vipBonus = 0,
    this.vipMembers = 0,
    this.bossHp = 0,
    this.bossTier = 0,
    this.bossClaimed = false,
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
      maxMembers: (g['max_members'] as num?)?.toInt() ?? guildBaseMembers,
      requiresApproval: (g['requires_approval'] as bool?) ?? false,
      requests: [
        for (final r in (j['requests'] as List?) ?? const [])
          GuildJoinRequest(
            userId: (r as Map)['user_id'] as String,
            nickname: r['nickname'] as String,
          ),
      ],
      streak: (j['streak'] as num?)?.toInt() ?? 0,
      buffSeconds: (j['buff_seconds'] as num?)?.toInt() ?? 0,
      wallet: (j['wallet'] as num?)?.toInt() ?? 0,
      questsClaimed: [
        for (final c in (j['quests_claimed'] as List?) ?? const [])
          (c as num).toInt(),
      ],
      ownedItems: [
        for (final c in (j['owned_items'] as List?) ?? const []) c as String,
      ],
      donatedToday: (j['donated_today'] as num?)?.toInt() ?? 0,
      chatLatestId: (j['chat_latest'] as num?)?.toInt() ?? 0,
      fund: GuildFund.fromJson(j['fund'] as Map<String, dynamic>?),
      teamAvailable: j.containsKey('team_claimed'),
      teamClaimed: (j['team_claimed'] as bool?) ?? false,
      vipBonus: (j['vip_bonus'] as num?)?.toInt() ?? 0,
      vipMembers: (j['vip_members'] as num?)?.toInt() ?? 0,
      bossHp: ((j['boss'] as Map?)?['hp'] as num?)?.toInt() ?? 0,
      bossTier: ((j['boss'] as Map?)?['tier'] as num?)?.toInt() ?? 0,
      bossClaimed: ((j['boss'] as Map?)?['claimed'] as bool?) ?? false,
      total: (j['total'] as num).toInt(),
      claimed: [for (final c in j['claimed'] as List) (c as num).toInt()],
      members: [
        for (final m in j['members'] as List)
          GuildMemberInfo(
            userId: (m as Map)['user_id'] as String,
            nickname: m['nickname'] as String,
            points: (m['points'] as num).toInt(),
            // Server cũ chưa có 'role': suy từ chủ hội.
            role: switch (m['role']) {
              'owner' => GuildRole.owner,
              'officer' => GuildRole.officer,
              null when m['user_id'] == g['owner_id'] => GuildRole.owner,
              _ => GuildRole.member,
            },
          ),
      ],
    );
  }

  final String id;
  final String name;
  final String tag;
  final String emoji;
  final String ownerId;
  final int maxMembers;
  final bool requiresApproval;

  /// Yêu cầu chờ duyệt — server chỉ trả cho CHỦ hội (người khác nhận rỗng).
  final List<GuildJoinRequest> requests;

  /// Tổng điểm cả hội tuần này.
  final int total;

  /// Mốc (1-based, như server) mình đã nhận tuần này.
  final List<int> claimed;

  /// Số tuần liên tiếp cả hội đạt đủ 3 mốc.
  final int streak;

  /// Giây còn lại của buff thu nhập cả hội (0 = không có).
  final int buffSeconds;

  /// Xu Hội cá nhân; nhiệm vụ tuần đã nhận (1-based); id vật phẩm đã đổi; số 💎
  /// đã nạp hôm nay.
  final int wallet;
  final List<int> questsClaimed;
  final List<String> ownedItems;
  final int donatedToday;

  /// Id tin chat mới nhất người này còn thấy (0 = chưa có / server cũ).
  final int chatLatestId;

  /// Quỹ hội tuần này.
  final GuildFund fund;

  /// Nhiệm vụ chung: [teamAvailable] false = server cũ chưa có → ẩn thẻ; [teamClaimed] = mình
  /// đã nhận tuần này. Số người đạt/cần tính từ [members] (điểm tuần đã có sẵn).
  final bool teamAvailable;
  final bool teamClaimed;
  int get teamActive => members.where((m) => m.points >= guildTeamMinPoints).length;
  int get teamNeed => guildTeamNeed(members.length);
  bool get teamReached => teamNeed > 0 && teamActive >= teamNeed;

  /// Số thành viên VIP đủ cấp và % thưởng thu nhập cả hội nhận được từ họ (server tính).
  final int vipMembers;
  final int vipBonus;

  /// Boss tuần: HP (0 = server cũ chưa có boss → ẩn thẻ), bậc và đã nhận rương chưa.
  /// Sát thương = [total] (tổng điểm tuần cả hội).
  final int bossHp;
  final int bossTier;
  final bool bossClaimed;
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

  /// Hội đã ở sức chứa tối đa, không mở thêm được.
  guildMaxed,

  /// Thiếu 💎 để tạo hội (kiểm cục bộ, không đến từ server).
  notEnoughGems,

  /// Thiếu 💎 để nạp vào hội / tặng hội viên (kiểm cục bộ).
  notEnoughGemsToSpend,

  /// Boss tuần chưa bị hạ nên chưa nhận được rương.
  bossAlive,

  /// Hội này cần duyệt — phải xin vào thay vì vào thẳng.
  approvalRequired,

  alreadyClaimed,
  dailyLimit,

  /// Vượt trần tặng 💎 trong ngày (của bạn hoặc của người nhận).
  giftLimit,
  notEnoughCoins,
  alreadyOwned,
  buffMaxed,
  invalidInput,

  /// Hội đang có quá nhiều yêu cầu chờ duyệt.
  requestsFull,

  /// Trong hội đã có thành viên trùng tên (không phân biệt hoa thường).
  nicknameTaken,

  /// Chưa liên kết email (tài khoản chưa/còn ẩn danh) nên chưa dùng được Hội.
  notLinked,

  /// Không đủ quyền với người này (vd. phó hội kick phó hội khác).
  notAllowed,

  /// Quỹ hội chưa đạt mục tiêu / bạn chưa góp đủ mức tối thiểu.
  fundNotReached,
  fundDonationLow,

  /// Nhiệm vụ chung chưa đủ người / bạn chưa đạt điểm tối thiểu.
  teamNotReached,
  teamPointsLow,

  /// Đã đủ số phó hội tối đa.
  officersFull,

  /// Chat: gửi quá nhanh / nội dung bị lọc.
  chatRateLimited,
  textBlocked,

  /// Phó bản: ải chưa qua / đã đổi vai trò một lần trong tuần.
  dungeonLocked,
  dungeonRoleLocked,
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
  // 'nickname taken' chứa 'name taken' → phải xét TRƯỚC.
  if (m.contains('nickname taken')) return GuildFailure.nicknameTaken;
  if (m.contains('name taken')) return GuildFailure.nameTaken;
  if (m.contains('guild full')) return GuildFailure.guildFull;
  if (m.contains('guild maxed')) return GuildFailure.guildMaxed;
  if (m.contains('already in guild')) return GuildFailure.alreadyInGuild;
  if (m.contains('invalid name')) return GuildFailure.invalidName;
  if (m.contains('approval required')) return GuildFailure.approvalRequired;
  if (m.contains('already claimed')) return GuildFailure.alreadyClaimed;
  if (m.contains('daily limit')) return GuildFailure.dailyLimit;
  if (m.contains('not enough coins')) return GuildFailure.notEnoughCoins;
  if (m.contains('already owned')) return GuildFailure.alreadyOwned;
  if (m.contains('buff maxed')) return GuildFailure.buffMaxed;
  if (m.contains('invalid amount') ||
      m.contains('invalid item') ||
      m.contains('invalid tier')) {
    return GuildFailure.invalidInput;
  }
  if (m.contains('too many requests')) return GuildFailure.requestsFull;
  if (m.contains('not allowed')) return GuildFailure.notAllowed;
  if (m.contains('team not reached')) return GuildFailure.teamNotReached;
  if (m.contains('team points too low')) return GuildFailure.teamPointsLow;
  if (m.contains('goal not reached')) return GuildFailure.fundNotReached;
  if (m.contains('fund donation too low')) return GuildFailure.fundDonationLow;
  if (m.contains('too many officers')) return GuildFailure.officersFull;
  if (m.contains('boss alive')) return GuildFailure.bossAlive;
  if (m.contains('stage not cleared')) return GuildFailure.dungeonLocked;
  if (m.contains('role locked')) return GuildFailure.dungeonRoleLocked;
  if (m.contains('chat rate limited')) return GuildFailure.chatRateLimited;
  if (m.contains('text blocked')) return GuildFailure.textBlocked;
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
  Future<List<GuildSummary>> leaderboardAvg();
  Future<List<GuildSummary>> leaderboardStreak();

  /// BXH Hội theo tổng VIP EXP của thành viên.
  Future<List<GuildSummary>> leaderboardVip();
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

  /// Nhận rương boss tuần này (server cộng Xu Hội vào ví; client cộng [gems] 💎 sau khi OK).
  Future<({int gems, int coins})> claimBoss();

  /// Xu Hội (server giữ ví). Client trừ 💎 / cấp vật phẩm SAU KHI các lệnh này thành công.
  Future<void> donate(int gems);
  Future<void> claimQuest(int tier);

  /// Nhận thưởng quỹ hội tuần (+[guildFundReward] Xu Hội, server giữ ví).
  Future<void> claimFund();

  /// Nhận thưởng nhiệm vụ chung tuần (+[guildTeamReward] Xu Hội).
  Future<void> claimTeam();
  Future<void> buyItem(String itemId);
  Future<void> buyBuff();

  /// Giây buff thu nhập cả hội còn lại (nhẹ — gọi khi mở app).
  Future<int> buffSeconds();

  /// % thưởng thu nhập từ thành viên VIP của hội mình (nhẹ — gọi khi mở app).
  Future<int> vipBonus();

  /// Tặng [amount] 💎 cho hội viên [toUserId] (server kiểm cùng hội + trần ngày).
  Future<void> giftSend(String toUserId, int amount);

  /// Quà chưa nhận, chưa hết hạn, mới nhất trước.
  Future<List<GuildGift>> giftInbox();

  /// Nhận quà [id]; trả số 💎 (server đánh dấu đã nhận — mỗi quà một lần).
  Future<int> giftClaim(int id);

  /// Chủ hội bổ nhiệm ([on] true) / bãi nhiệm phó hội.
  Future<void> setOfficer(String userId, {required bool on});

  /// Chủ hội nhường quyền cho [userId].
  Future<void> transferOwner(String userId);

  /// Chủ hội mở thêm [guildExpandStep] chỗ; trả sức chứa mới. Client tự trừ 💎 sau đó.
  Future<int> expand();

  /// Nhật ký hoạt động, mới nhất trước.
  Future<List<GuildEvent>> activity();

  Future<GuildChat> chat();
  Future<void> chatPost(String body);

  /// Gửi ảnh JPEG [bytes] (đã nén) kèm chữ [body] (có thể rỗng).
  Future<void> chatPostImage(Uint8List bytes, String body);

  /// URL công khai của ảnh chat có khoá [key].
  String chatImageUrl(String key);
  Future<void> chatDelete(int id);

  /// Báo cáo tin của người khác; đủ 3 báo cáo thì server ẩn tin.
  Future<void> chatReport(int id);

  /// Chỉ chủ hội; [id] null = bỏ ghim.
  Future<void> chatPin(int? id);

  /// Bật/tắt reaction [emoji] của mình trên tin [id].
  Future<void> chatReact(int id, String emoji);
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
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) throw const GuildException(GuildFailure.notLinked);
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
  Future<List<GuildSummary>> leaderboardAvg() async =>
      _rows(await _rpc('guild_leaderboard_avg', {'p_limit': 50}));

  @override
  Future<List<GuildSummary>> leaderboardStreak() async =>
      _rows(await _rpc('guild_leaderboard_streak', {'p_limit': 50}));

  @override
  Future<List<GuildSummary>> leaderboardVip() async =>
      _rows(await _rpc('guild_leaderboard_vip', {'p_limit': 50}));

  @override
  Future<({int gems, int coins})> claimBoss() async {
    final r = await _rpc('guild_claim_boss') as Map<String, dynamic>;
    return (gems: (r['gems'] as num).toInt(), coins: (r['coins'] as num).toInt());
  }

  @override
  Future<void> claimReward(int milestone) =>
      _rpc('guild_claim_reward', {'p_milestone': milestone});

  @override
  Future<void> donate(int gems) => _rpc('guild_donate', {'p_gems': gems});

  @override
  Future<void> claimFund() => _rpc('guild_claim_fund');

  @override
  Future<void> claimTeam() => _rpc('guild_claim_team');

  @override
  Future<void> claimQuest(int tier) =>
      _rpc('guild_claim_quest', {'p_tier': tier});

  @override
  Future<void> buyItem(String itemId) =>
      _rpc('guild_buy_item', {'p_item': itemId});

  @override
  Future<void> buyBuff() => _rpc('guild_buy_buff');

  @override
  Future<int> buffSeconds() async =>
      ((await _rpc('guild_buff_seconds')) as num).toInt();

  @override
  Future<int> vipBonus() async => ((await _rpc('guild_vip_bonus')) as num).toInt();

  @override
  Future<void> giftSend(String toUserId, int amount) =>
      _rpc('guild_gift_send', {'p_to': toUserId, 'p_amount': amount});

  @override
  Future<List<GuildGift>> giftInbox() async => [
        for (final g in (await _rpc('guild_gift_inbox')) as List)
          GuildGift.fromJson(g as Map<String, dynamic>),
      ];

  @override
  Future<int> giftClaim(int id) async =>
      ((await _rpc('guild_gift_claim', {'p_id': id})) as num).toInt();

  @override
  Future<void> setOfficer(String userId, {required bool on}) =>
      _rpc('guild_set_officer', {'p_user': userId, 'p_on': on});

  @override
  Future<void> transferOwner(String userId) =>
      _rpc('guild_transfer_owner', {'p_user': userId});

  @override
  Future<int> expand() async => ((await _rpc('guild_expand', {})) as num).toInt();

  @override
  Future<List<GuildEvent>> activity() async => [
        for (final e in (await _rpc('guild_activity', {'p_limit': 50})) as List)
          GuildEvent.fromJson(e as Map<String, dynamic>),
      ];

  @override
  Future<GuildChat> chat() async => GuildChat.fromJson(
      await _rpc('guild_chat_list', {'p_limit': 50}) as Map<String, dynamic>);

  @override
  Future<void> chatPost(String body) => _rpc('guild_chat_post', {'p_body': body});

  @override
  Future<void> chatPostImage(Uint8List bytes, String body) async {
    final key = await _rpc('guild_image_new_key', {}) as String;
    await _client.storage
        .from('guild-images')
        .uploadBinary('$key.jpg', bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    await _rpc('guild_chat_post', {'p_body': body, 'p_image_key': key});
  }

  @override
  String chatImageUrl(String key) => _client.storage.from('guild-images').getPublicUrl('$key.jpg');

  @override
  Future<void> chatDelete(int id) => _rpc('guild_chat_delete', {'p_id': id});

  @override
  Future<void> chatReport(int id) => _rpc('guild_chat_report', {'p_id': id});

  @override
  Future<void> chatPin(int? id) => _rpc('guild_chat_pin', {'p_id': id});

  @override
  Future<void> chatReact(int id, String emoji) =>
      _rpc('guild_chat_react', {'p_id': id, 'p_emoji': emoji});
}
