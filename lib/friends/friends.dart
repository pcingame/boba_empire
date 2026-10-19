/// Bạn bè: tìm theo biệt danh, lời mời, danh sách, BXH bạn bè và quà mỗi ngày
/// (RPC `friend_*`, supabase/friends_schema.sql). Chỉ tài khoản liên kết email.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class FriendsOverview {
  const FriendsOverview({
    this.myIncome = 0,
    this.mySeasonXp = 0,
    this.myOrders = 0,
    this.friends = const [],
    this.incoming = const [],
    this.giftsWaiting = 0,
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
    );
  }
  final double myIncome;
  final int mySeasonXp;
  final int myOrders;
  final List<Friend> friends;
  final List<FriendRequestIn> incoming;
  final int giftsWaiting;

  FriendsOverview copyWith({List<Friend>? friends, List<FriendRequestIn>? incoming, int? giftsWaiting}) =>
      FriendsOverview(
        myIncome: myIncome,
        mySeasonXp: mySeasonXp,
        myOrders: myOrders,
        friends: friends ?? this.friends,
        incoming: incoming ?? this.incoming,
        giftsWaiting: giftsWaiting ?? this.giftsWaiting,
      );
}

/// Lỗi nghiệp vụ từ server, đã gom về vài loại để UI báo đúng câu.
enum FriendError { limit, notFound, alreadySent, linkRequired, network }

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
  if (m.contains('email link required')) return FriendError.linkRequired;
  if (m.contains('not found') || m.contains('not friends') || m.contains('bad target')) return FriendError.notFound;
  return FriendError.network;
}

/// Tách để test thay bằng bản giả.
abstract class FriendsRepository {
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
}

final friendsRepositoryProvider = Provider<FriendsRepository>((_) => SupabaseFriendsRepository());

/// Trạng thái trang Bạn bè. Lỗi tải → AsyncError (UI hiện nút thử lại).
class FriendsController extends AsyncNotifier<FriendsOverview> {
  @override
  Future<FriendsOverview> build() => ref.read(friendsRepositoryProvider).overview();

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
