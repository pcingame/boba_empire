/// Bạn bè: tìm theo biệt danh, lời mời, danh sách, BXH bạn bè và quà mỗi ngày
/// (RPC `friend_*`, supabase/friends_schema.sql). Chỉ tài khoản liên kết email.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/raid.dart';
import '../data/cloud_save_controller.dart';
import '../state/game_providers.dart';

/// Quà mỗi ngày = ngần này giây thu nhập (sàn [friendGiftFloor] Xu) — cả người tặng lẫn người nhận.
const friendGiftSeconds = 180;
const friendGiftFloor = 100.0;

class Friend {
  const Friend({
    required this.userId,
    required this.nickname,
    required this.stage,
    required this.income,
    required this.seasonXp,
    required this.orders,
    required this.giftSent,
  });
  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        userId: j['user_id'] as String,
        nickname: j['nickname'] as String,
        stage: (j['stage'] as num).toInt(),
        income: (j['income'] as num).toDouble(),
        seasonXp: (j['season_xp'] as num).toInt(),
        orders: (j['orders'] as num).toInt(),
        giftSent: j['gift_sent'] == true,
      );
  final String userId;
  final String nickname;
  final int stage;
  final double income;
  final int seasonXp;
  final int orders;
  final bool giftSent;

  Friend copyWith({bool? giftSent}) => Friend(
      userId: userId,
      nickname: nickname,
      stage: stage,
      income: income,
      seasonXp: seasonXp,
      orders: orders,
      giftSent: giftSent ?? this.giftSent);
}

class FriendRequestIn {
  const FriendRequestIn(this.userId, this.nickname);
  final String userId;
  final String nickname;
}

class FriendCandidate {
  const FriendCandidate(this.userId, this.nickname, this.stage);
  final String userId;
  final String nickname;
  final int stage;
}

/// Một lượt đột kích vào quán mình (nhật ký): ai, thắng hay bị chặn.
class RaidLogEntry {
  const RaidLogEntry(this.nickname, this.win);
  final String nickname;
  final bool win;
}

/// Kết quả một lượt mình đột kích bạn.
class RaidResult {
  const RaidResult({required this.win, required this.chance});
  final bool win;
  final double chance;
}

class FriendsOverview {
  const FriendsOverview({
    this.myIncome = 0,
    this.mySeasonXp = 0,
    this.myOrders = 0,
    this.friends = const [],
    this.incoming = const [],
    this.giftsWaiting = 0,
    this.raidsLeft = raidsPerDay,
    this.defenseWaiting = 0,
    this.raidLog = const [],
  });
  factory FriendsOverview.fromJson(Map<String, dynamic> j) {
    final me = (j['me'] as Map?) ?? const {};
    return FriendsOverview(
      myIncome: ((me['income'] ?? 0) as num).toDouble(),
      mySeasonXp: ((me['season_xp'] ?? 0) as num).toInt(),
      myOrders: ((me['orders'] ?? 0) as num).toInt(),
      friends: [for (final f in (j['friends'] as List? ?? const [])) Friend.fromJson(f as Map<String, dynamic>)],
      incoming: [
        for (final r in (j['incoming'] as List? ?? const []))
          FriendRequestIn((r as Map)['user_id'] as String, r['nickname'] as String)
      ],
      giftsWaiting: ((j['gifts_waiting'] ?? 0) as num).toInt(),
      raidsLeft: ((j['raids_left'] ?? raidsPerDay) as num).toInt(),
      defenseWaiting: ((j['defense_waiting'] ?? 0) as num).toInt(),
      raidLog: [
        for (final r in (j['raid_log'] as List? ?? const []))
          RaidLogEntry((r as Map)['nickname'] as String? ?? '???', r['win'] == true)
      ],
    );
  }
  final double myIncome;
  final int mySeasonXp;
  final int myOrders;
  final List<Friend> friends;
  final List<FriendRequestIn> incoming;
  final int giftsWaiting;
  final int raidsLeft;
  final int defenseWaiting;
  final List<RaidLogEntry> raidLog;

  FriendsOverview copyWith(
          {List<Friend>? friends, List<FriendRequestIn>? incoming, int? giftsWaiting, int? raidsLeft, int? defenseWaiting}) =>
      FriendsOverview(
        myIncome: myIncome,
        mySeasonXp: mySeasonXp,
        myOrders: myOrders,
        friends: friends ?? this.friends,
        incoming: incoming ?? this.incoming,
        giftsWaiting: giftsWaiting ?? this.giftsWaiting,
        raidsLeft: raidsLeft ?? this.raidsLeft,
        defenseWaiting: defenseWaiting ?? this.defenseWaiting,
        raidLog: raidLog,
      );
}

/// Lỗi nghiệp vụ từ server, đã gom về vài loại để UI báo đúng câu.
enum FriendError { limit, notFound, alreadySent, linkRequired, raidLimit, raidAlready, network }

class FriendException implements Exception {
  const FriendException(this.error);
  final FriendError error;
  @override
  String toString() => 'FriendException($error)';
}

FriendError friendErrorOf(Object e) {
  final m = e is PostgrestException ? e.message : '$e';
  if (m.contains('too many requests') || m.contains('friend limit')) return FriendError.limit;
  if (m.contains('already sent')) return FriendError.alreadySent;
  if (m.contains('raid limit')) return FriendError.raidLimit;
  if (m.contains('already raided')) return FriendError.raidAlready;
  if (m.contains('email link required')) return FriendError.linkRequired;
  if (m.contains('not found') || m.contains('not friends') || m.contains('bad target')) return FriendError.notFound;
  return FriendError.network;
}

/// Quán của một người bạn (RPC `friend_shop`): cảnh theo giai đoạn + món đang trưng bày + số liệu.
class FriendShop {
  const FriendShop({
    required this.nickname,
    this.stage = 1,
    this.income = 0,
    this.seasonXp = 0,
    this.orders = 0,
    this.equipped = const [],
    this.power = 0,
  });
  factory FriendShop.fromJson(Map<String, dynamic> j) => FriendShop(
        nickname: j['nickname'] as String,
        stage: ((j['stage'] ?? 1) as num).toInt(),
        income: ((j['income'] ?? 0) as num).toDouble(),
        seasonXp: ((j['season_xp'] ?? 0) as num).toInt(),
        orders: ((j['orders'] ?? 0) as num).toInt(),
        equipped: [for (final e in (j['equipped'] as List?) ?? const []) e as String],
        power: ((j['power'] ?? 0) as num).toInt(),
      );
  final String nickname;
  final int stage;
  final double income;
  final int seasonXp;
  final int orders;
  final List<String> equipped;

  /// Sức mạnh quán (core/raid.dart) — dùng tính xác suất đột kích.
  final int power;
}

/// Tách để test thay bằng bản giả.
abstract class FriendsRepository {
  Future<FriendShop> shop(String userId);

  /// Đẩy món đang trưng bày của mình lên để bạn bè thấy.
  Future<void> setDisplay(List<String> ids, int power);

  /// Đột kích quán bạn (server quyết định thắng/thua).
  Future<RaidResult> raid(String userId);

  /// Gom thưởng phòng thủ; trả số lượt.
  Future<int> claimDefense();
  Future<FriendsOverview> overview();
  Future<List<FriendCandidate>> search(String nickname);

  /// 'sent' | 'accepted' | 'already'
  Future<String> request(String userId);
  Future<void> respond(String userId, bool accept);
  Future<void> remove(String userId);
  Future<void> sendGift(String userId);
  Future<int> claimGifts();
}

class SupabaseFriendsRepository implements FriendsRepository {
  SupabaseClient get _c => Supabase.instance.client;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      developer.log('$e', name: 'Friends');
      throw FriendException(friendErrorOf(e));
    }
  }

  @override
  Future<FriendsOverview> overview() => _guard(() async =>
      FriendsOverview.fromJson(Map<String, dynamic>.from(await _c.rpc('friend_overview') as Map)));

  @override
  Future<List<FriendCandidate>> search(String nickname) => _guard(() async {
        final rows = await _c.rpc('friend_search', params: {'p_nickname': nickname}) as List;
        return [
          for (final r in rows)
            FriendCandidate((r as Map)['user_id'] as String, r['nickname'] as String, (r['stage'] as num).toInt())
        ];
      });

  @override
  Future<String> request(String userId) =>
      _guard(() async => (await _c.rpc('friend_request', params: {'p_to': userId})) as String);

  @override
  Future<void> respond(String userId, bool accept) =>
      _guard(() => _c.rpc('friend_respond', params: {'p_from': userId, 'p_accept': accept}));

  @override
  Future<void> remove(String userId) => _guard(() => _c.rpc('friend_remove', params: {'p_friend': userId}));

  @override
  Future<void> sendGift(String userId) => _guard(() => _c.rpc('friend_gift_send', params: {'p_to': userId}));

  @override
  Future<int> claimGifts() => _guard(() async => ((await _c.rpc('friend_gift_claim')) as num).toInt());

  @override
  Future<FriendShop> shop(String userId) => _guard(() async =>
      FriendShop.fromJson(Map<String, dynamic>.from(await _c.rpc('friend_shop', params: {'p_friend': userId}) as Map)));

  @override
  Future<void> setDisplay(List<String> ids, int power) =>
      _guard(() => _c.rpc('set_shop_display', params: {'p_equipped': ids, 'p_power': power}));

  @override
  Future<RaidResult> raid(String userId) => _guard(() async {
        final r = await _c.rpc('friend_raid', params: {'p_target': userId}) as Map;
        return RaidResult(win: r['win'] == true, chance: ((r['chance'] ?? 0.5) as num).toDouble());
      });

  @override
  Future<int> claimDefense() => _guard(() async => ((await _c.rpc('friend_raid_claim')) as num).toInt());
}

/// Đẩy trưng bày lên server; là phần thêm nên mọi lỗi (mạng, chưa liên kết, chưa chạy SQL) bị nuốt.
Future<void> pushShopDisplay(FriendsRepository repo, List<String> ids, int power) async {
  try {
    await repo.setDisplay(ids, power);
  } catch (_) {}
}

final friendShopProvider = FutureProvider.autoDispose.family<FriendShop, String>(
    (ref, userId) => ref.read(friendsRepositoryProvider).shop(userId));

final friendsRepositoryProvider = Provider<FriendsRepository>((_) => SupabaseFriendsRepository());

/// Trạng thái trang Bạn bè. Lỗi tải → AsyncError (UI hiện nút thử lại).
class FriendsController extends AsyncNotifier<FriendsOverview> {
  @override
  Future<FriendsOverview> build() {
    final g = ref.read(gameControllerProvider);
    unawaited(pushShopDisplay(ref.read(friendsRepositoryProvider), g.equippedAccessories,
        raidPower(equipped: g.equippedAccessories, refineLevels: g.refineLevels, stage: g.stage)));
    return ref.read(friendsRepositoryProvider).overview();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(friendsRepositoryProvider).overview());
  }

  FriendsRepository get _repo => ref.read(friendsRepositoryProvider);

  /// Trả 'sent' | 'accepted' | 'already'; ném [FriendException].
  Future<String> request(String userId) async {
    final r = await _repo.request(userId);
    if (r == 'accepted') await refresh();
    return r;
  }

  Future<void> respond(FriendRequestIn r, bool accept) async {
    await _repo.respond(r.userId, accept);
    await refresh();
  }

  Future<void> remove(Friend f) async {
    await _repo.remove(f.userId);
    await refresh();
  }

  /// Tặng quà: server xác nhận TRƯỚC rồi mới cộng Xu cục bộ. Trả số Xu nhận được.
  Future<double> sendGift(Friend f) async {
    await _repo.sendGift(f.userId);
    final cur = state.value;
    if (cur != null) {
      state = AsyncData(cur.copyWith(friends: [for (final x in cur.friends) x.userId == f.userId ? x.copyWith(giftSent: true) : x]));
    }
    return ref.read(gameControllerProvider.notifier).grantFriendGift(1);
  }

  /// Đột kích bạn [f]: server quyết định; thưởng cộng SAU khi server trả kết quả. Trả (kết quả, Xu nhận).
  Future<(RaidResult, double)> raid(String userId) async {
    final r = await _repo.raid(userId);
    final cur = state.value;
    if (cur != null) state = AsyncData(cur.copyWith(raidsLeft: (cur.raidsLeft - 1).clamp(0, raidsPerDay)));
    final xu = ref
        .read(gameControllerProvider.notifier)
        .grantRaidReward(r.win ? raidWinSeconds : raidBlockedSeconds);
    return (r, xu);
  }

  /// Nhận thưởng phòng thủ (các lượt đột kích vào quán mình bị chặn). Trả (số lượt, Xu).
  Future<(int, double)> claimDefense() async {
    final n = await _repo.claimDefense();
    if (n <= 0) return (0, 0.0);
    final cur = state.value;
    if (cur != null) state = AsyncData(cur.copyWith(defenseWaiting: 0));
    return (n, ref.read(gameControllerProvider.notifier).grantRaidReward(raidDefenseSeconds * n));
  }

  /// Nhận mọi quà đang chờ. Trả (số quà, Xu).
  Future<(int, double)> claimGifts() async {
    final n = await _repo.claimGifts();
    if (n <= 0) return (0, 0.0);
    final cur = state.value;
    if (cur != null) state = AsyncData(cur.copyWith(giftsWaiting: 0));
    return (n, ref.read(gameControllerProvider.notifier).grantFriendGift(n));
  }
}

final friendsControllerProvider =
    AsyncNotifierProvider.autoDispose<FriendsController, FriendsOverview>(FriendsController.new);

/// Số việc đang chờ (lời mời + quà) cho chấm đỏ ở màn chính; 0 nếu chưa liên kết
/// email hoặc lỗi mạng. Gọi `ref.invalidate` khi mở lại app / đóng trang Bạn bè.
final friendsAlertProvider = FutureProvider<int>((ref) async {
  if (ref.watch(cloudSaveControllerProvider) is! CloudSaveLinked) return 0;
  try {
    final o = await ref.read(friendsRepositoryProvider).overview();
    return o.incoming.length + o.giftsWaiting + o.defenseWaiting;
  } catch (_) {
    return 0;
  }
});

/// Tìm theo biệt danh (autoDispose theo từng từ khoá).
final friendSearchProvider = FutureProvider.autoDispose.family<List<FriendCandidate>, String>(
    (ref, nickname) => ref.read(friendsRepositoryProvider).search(nickname));

enum FriendBoard { income, season, orders }

/// Bản thân + bạn bè, xếp giảm dần theo [board]; [isMe] đánh dấu dòng của mình.
class FriendRankRow {
  const FriendRankRow(this.nickname, this.value, this.isMe);
  final String nickname;
  final double value;
  final bool isMe;
}

List<FriendRankRow> friendRanking(FriendsOverview o, FriendBoard board, String myNickname) {
  double v(Friend f) => switch (board) {
        FriendBoard.income => f.income,
        FriendBoard.season => f.seasonXp.toDouble(),
        FriendBoard.orders => f.orders.toDouble(),
      };
  final mine = switch (board) {
    FriendBoard.income => o.myIncome,
    FriendBoard.season => o.mySeasonXp.toDouble(),
    FriendBoard.orders => o.myOrders.toDouble(),
  };
  final rows = [
    FriendRankRow(myNickname, mine, true),
    for (final f in o.friends) FriendRankRow(f.nickname, v(f), false),
  ];
  // Hoà: mình xếp trước (sort ổn định giữ thứ tự ban đầu).
  rows.sort((a, b) => b.value.compareTo(a.value));
  return rows;
}
