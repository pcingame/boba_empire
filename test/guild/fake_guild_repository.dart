// Bản giả của GuildRepository cho test controller/UI: ghi lại lệnh gọi, cho phép
// ép lỗi theo tên phương thức, và có trạng thái đủ để refresh() đọc lại.
import 'package:boba_empire/core/guild_shop.dart';
import 'package:boba_empire/guild/guild_repository.dart';

class FakeGuildRepository implements GuildRepository {
  FakeGuildRepository({this.mine, this.listing = const [], this.me = 'me'});

  MyGuild? mine;
  List<GuildSummary> listing;
  List<GuildSummary> board = const [];
  List<GuildSummary> boardAvg = const [];
  List<GuildSummary> boardStreak = const [];

  /// Giây buff mà buffSeconds()/guild_my báo (đổi được trong test).
  int serverBuffSeconds = 0;
  final String me;

  /// Tên phương thức → lỗi sẽ ném (một lần, rồi xoá).
  final Map<String, Object> failures = {};
  final List<String> calls = [];
  int? lastSubmitted;
  Map<String, Object?>? lastCreate;
  Map<String, Object?>? lastJoin;
  Map<String, Object?>? lastRequest;
  final List<String> responded = [];

  @override
  String? cachedNickname = 'Alice';

  @override
  String? get myUserId => me;

  void _hit(String name) {
    calls.add(name);
    final f = failures.remove(name);
    if (f != null) throw f;
  }

  @override
  Future<MyGuild?> myGuild() async {
    _hit('myGuild');
    return mine;
  }

  @override
  Future<List<GuildSummary>> list() async {
    _hit('list');
    return listing;
  }

  @override
  Future<List<GuildSummary>> leaderboard() async {
    _hit('leaderboard');
    return board;
  }

  @override
  Future<List<GuildSummary>> leaderboardAvg() async {
    _hit('leaderboardAvg');
    return boardAvg;
  }

  @override
  Future<List<GuildSummary>> leaderboardStreak() async {
    _hit('leaderboardStreak');
    return boardStreak;
  }

  @override
  Future<void> donate(int gems) async {
    _hit('donate');
    final g = mine!;
    mine = withState(g,
        wallet: g.wallet + gems * guildCoinsPerGem,
        donatedToday: g.donatedToday + gems);
  }

  @override
  Future<void> claimQuest(int tier) async {
    _hit('claimQuest');
    final g = mine!;
    mine = withState(g,
        wallet: g.wallet + guildQuests[tier - 1].reward,
        questsClaimed: [...g.questsClaimed, tier]);
  }

  @override
  Future<void> buyItem(String itemId) async {
    _hit('buyItem');
    final g = mine!;
    final price = guildShopItems.firstWhere((i) => i.id == itemId).price;
    mine = withState(g,
        wallet: g.wallet - price, ownedItems: [...g.ownedItems, itemId]);
  }

  @override
  Future<void> buyBuff() async {
    _hit('buyBuff');
    final g = mine!;
    serverBuffSeconds = guildBuffHours * 3600;
    mine = withState(g,
        wallet: g.wallet - guildBuffPrice, buffSeconds: serverBuffSeconds);
  }

  @override
  Future<int> buffSeconds() async {
    _hit('buffSeconds');
    return serverBuffSeconds;
  }

  @override
  Future<void> create({
    required String name,
    required String tag,
    required String emoji,
    required bool requiresApproval,
    required String nickname,
    required int score,
  }) async {
    _hit('create');
    lastCreate = {
      'name': name,
      'tag': tag,
      'emoji': emoji,
      'requiresApproval': requiresApproval,
      'nickname': nickname,
      'score': score,
    };
    mine = fakeGuild(
        name: name,
        tag: tag,
        emoji: emoji,
        ownerId: me,
        requiresApproval: requiresApproval);
  }

  @override
  Future<void> join({
    required String guildId,
    required String nickname,
    required int score,
  }) async {
    _hit('join');
    lastJoin = {
      'guildId': guildId,
      'nickname': nickname,
      'score': score,
    };
    mine = fakeGuild(ownerId: 'someone');
  }

  @override
  Future<void> requestJoin({
    required String guildId,
    required String nickname,
    required int score,
  }) async {
    _hit('requestJoin');
    lastRequest = {'guildId': guildId, 'nickname': nickname, 'score': score};
    listing = [
      for (final g in listing)
        GuildSummary(
            id: g.id,
            name: g.name,
            tag: g.tag,
            emoji: g.emoji,
            memberCount: g.memberCount,
            weekTotal: g.weekTotal,
            requiresApproval: g.requiresApproval,
            requested: g.id == guildId),
    ];
  }

  @override
  Future<void> cancelRequest() async {
    _hit('cancelRequest');
    listing = [
      for (final g in listing)
        GuildSummary(
            id: g.id,
            name: g.name,
            tag: g.tag,
            emoji: g.emoji,
            memberCount: g.memberCount,
            weekTotal: g.weekTotal,
            requiresApproval: g.requiresApproval),
    ];
  }

  @override
  Future<void> respondRequest(String userId, {required bool accept}) async {
    _hit('respondRequest');
    responded.add('$userId:${accept ? 'accept' : 'reject'}');
    final g = mine!;
    final req = g.requests.where((r) => r.userId == userId).toList();
    mine = fakeGuild(
        name: g.name,
        ownerId: g.ownerId,
        total: g.total,
        claimed: g.claimed,
        requiresApproval: g.requiresApproval,
        requests: g.requests.where((r) => r.userId != userId).toList(),
        members: [
          ...g.members,
          if (accept && req.isNotEmpty)
            GuildMemberInfo(
                userId: userId, nickname: req.first.nickname, points: 0),
        ]);
  }

  @override
  Future<void> leave() async {
    _hit('leave');
    mine = null;
  }

  @override
  Future<void> kick(String userId) async {
    _hit('kick');
    final g = mine;
    if (g == null) return;
    mine = fakeGuild(
        name: g.name,
        ownerId: g.ownerId,
        total: g.total,
        claimed: g.claimed,
        members: g.members.where((m) => m.userId != userId).toList());
  }

  @override
  Future<void> submitScore(int score) async {
    _hit('submitScore');
    lastSubmitted = score;
  }

  @override
  Future<void> report(String guildId, String reason) async => _hit('report');

  @override
  Future<void> claimReward(int milestone) async {
    _hit('claimReward');
    final g = mine!;
    mine = fakeGuild(
        name: g.name,
        ownerId: g.ownerId,
        total: g.total,
        members: g.members,
        claimed: [...g.claimed, milestone]);
  }
}

/// Hội mẫu: mình ('me') + 2 người khác; mặc định mình là chủ hội nếu ownerId='me'.
MyGuild fakeGuild({
  String name = 'Boba Club',
  String tag = 'BB',
  String emoji = '🧋',
  String ownerId = 'me',
  int total = 0,
  List<int> claimed = const [],
  bool requiresApproval = false,
  List<GuildJoinRequest> requests = const [],
  List<GuildMemberInfo>? members,
  int streak = 0,
  int buffSeconds = 0,
  int wallet = 0,
  List<int> questsClaimed = const [],
  List<String> ownedItems = const [],
  int donatedToday = 0,
}) =>
    MyGuild(
      id: 'g1',
      name: name,
      tag: tag,
      emoji: emoji,
      ownerId: ownerId,
      total: total,
      claimed: claimed,
      requiresApproval: requiresApproval,
      requests: requests,
      streak: streak,
      buffSeconds: buffSeconds,
      wallet: wallet,
      questsClaimed: questsClaimed,
      ownedItems: ownedItems,
      donatedToday: donatedToday,
      members: members ??
          const [
            GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 400),
            GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 100),
            GuildMemberInfo(userId: 'u3', nickname: 'Cy', points: 0),
          ],
    );

const sampleListing = [
  GuildSummary(
      id: 'g9',
      name: 'Public Club',
      tag: 'PC',
      emoji: '🐉',
      memberCount: 5,
      weekTotal: 1200),
];

/// Bản sao của [g] với vài trường đổi (MyGuild không có copyWith trong code chính).
MyGuild withState(
  MyGuild g, {
  int? wallet,
  int? buffSeconds,
  List<int>? questsClaimed,
  List<String>? ownedItems,
  int? donatedToday,
}) =>
    MyGuild(
      id: g.id,
      name: g.name,
      tag: g.tag,
      emoji: g.emoji,
      ownerId: g.ownerId,
      total: g.total,
      claimed: g.claimed,
      members: g.members,
      requiresApproval: g.requiresApproval,
      requests: g.requests,
      streak: g.streak,
      buffSeconds: buffSeconds ?? g.buffSeconds,
      wallet: wallet ?? g.wallet,
      questsClaimed: questsClaimed ?? g.questsClaimed,
      ownedItems: ownedItems ?? g.ownedItems,
      donatedToday: donatedToday ?? g.donatedToday,
    );
