/// Thưởng top bảng xếp hạng theo tuần: đọc thưởng của mình + nhận thưởng qua RPC `lb_reward_status` /
/// `lb_reward_claim`. Chỉ tài khoản đã liên kết email (xem data/linked_session.dart). Cách tính ở phía
/// server — xem supabase/leaderboard_rewards_schema.sql.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/lb_rewards.dart';
import '../data/linked_session.dart';
import '../state/game_providers.dart';

/// Một phần thưởng của mình: tuần chốt (ISO yyyy-mm-dd, thứ Hai UTC), bảng, hạng, 💎, đã nhận chưa.
class LbReward {
  const LbReward({
    required this.week,
    required this.board,
    required this.rank,
    required this.gems,
    required this.claimed,
  });

  final String week;
  final LbBoard board;
  final int rank;
  final int gems;
  final bool claimed;

  /// Khoá ổn định để chống nhận trùng trong phiên.
  String get id => '$week/${board.name}';
}

/// Chuyển JSON trả về thành danh sách; bỏ dòng có `board` lạ (server mới hơn) hoặc dữ liệu hỏng.
List<LbReward> parseLbRewards(Object? raw) {
  final out = <LbReward>[];
  if (raw is! List) return out;
  for (final r in raw) {
    if (r is! Map) continue;
    final board = LbBoard.values.where((b) => b.name == r['board']).firstOrNull;
    final week = r['week'];
    final rank = r['rank'];
    final gems = r['gems'];
    if (board == null || week is! String || rank is! num || gems is! num) continue;
    out.add(LbReward(
      week: week,
      board: board,
      rank: rank.toInt(),
      gems: gems.toInt(),
      claimed: r['claimed'] == true,
    ));
  }
  return out;
}

/// Lỗi nhận thưởng đã dịch.
enum LbRewardFailure { alreadyClaimed, notFound, notLinked, network }

class LbRewardException implements Exception {
  const LbRewardException(this.failure);
  final LbRewardFailure failure;
  @override
  String toString() => 'LbRewardException($failure)';
}

LbRewardFailure lbRewardFailureFromMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('already claimed')) return LbRewardFailure.alreadyClaimed;
  if (m.contains('not found')) return LbRewardFailure.notFound;
  return LbRewardFailure.network;
}

/// Lớp gọi server. [_rpc] được tiêm vào để test thay bản giả.
class LbRewardRepository {
  LbRewardRepository(this._rpc, this._user);

  final Future<dynamic> Function(String fn, Map<String, dynamic>? params) _rpc;
  final User? Function() _user;

  Future<List<LbReward>> status() async {
    requireLinkedId(_user());
    return parseLbRewards(await _rpc('lb_reward_status', null));
  }

  /// Nhận thưởng; trả số 💎 server xác nhận.
  Future<int> claim(LbReward r) async {
    try {
      requireLinkedId(_user());
      final gems = await _rpc('lb_reward_claim', {'p_week': r.week, 'p_board': r.board.name});
      return (gems as num).toInt();
    } on NotLinkedException {
      throw const LbRewardException(LbRewardFailure.notLinked);
    } on PostgrestException catch (e) {
      throw LbRewardException(lbRewardFailureFromMessage(e.message));
    }
  }
}

final lbRewardRepositoryProvider = Provider<LbRewardRepository>((ref) {
  final client = Supabase.instance.client;
  return LbRewardRepository(
    (fn, params) => client.rpc(fn, params: params),
    () => client.auth.currentUser,
  );
});

class LbRewardsState {
  const LbRewardsState({this.rewards = const [], this.loaded = false});
  final List<LbReward> rewards;
  final bool loaded;

  List<LbReward> get claimable => [for (final r in rewards) if (!r.claimed) r];
}

class LbRewardsController extends Notifier<LbRewardsState> {
  @override
  LbRewardsState build() => const LbRewardsState();

  LbRewardRepository get _repo => ref.read(lbRewardRepositoryProvider);

  int _lastSyncMs = 0;

  /// Tải thưởng của mình. [force] bỏ qua giới hạn tần suất (10 phút). Mọi lỗi (mạng, chưa liên kết,
  /// server chưa có SQL) bị nuốt: thưởng chỉ là phần thêm, không được làm hỏng màn khác.
  Future<void> refresh({bool force = false}) async {
    final now = ref.read(clockProvider)();
    if (!force && _lastSyncMs != 0 && now - _lastSyncMs < 10 * 60 * 1000) return;
    _lastSyncMs = now;
    try {
      state = LbRewardsState(rewards: await _repo.status(), loaded: true);
    } on NotLinkedException {
      state = const LbRewardsState(loaded: true);
    } catch (e) {
      developer.log('lb_reward_status: $e', name: 'LbRewards');
    }
  }

  final _claiming = <String>{};

  /// Nhận thưởng: server xác nhận TRƯỚC, rồi mới cộng 💎 cục bộ (app tắt giữa chừng thì mất phần 💎 chứ
  /// không bao giờ được 💎 ảo). Trả số 💎 nhận được, hoặc ném [LbRewardException].
  Future<int> claim(LbReward r) async {
    if (!_claiming.add(r.id)) return 0; // đang xử lý, chống bấm đúp
    try {
      final gems = await _repo.claim(r);
      ref.read(gameControllerProvider.notifier).grantLeaderboardRewardGems(gems);
      await refresh(force: true);
      return gems;
    } finally {
      _claiming.remove(r.id);
    }
  }
}

final lbRewardsControllerProvider =
    NotifierProvider<LbRewardsController, LbRewardsState>(LbRewardsController.new);

/// Có thưởng chưa nhận không (chấm đỏ ở menu Thi đấu).
final lbRewardAlertProvider =
    Provider<bool>((ref) => ref.watch(lbRewardsControllerProvider).claimable.isNotEmpty);
