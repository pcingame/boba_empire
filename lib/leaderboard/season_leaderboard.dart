/// Bảng xếp hạng Thẻ Mùa — xếp theo XP mùa hiện tại (RPC `season_leaderboard_top`, nộp qua `submit_season_xp`;
/// supabase/season_leaderboard_schema.sql). Dùng chung biệt danh `leaderboard_nickname`.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/season.dart';
import '../state/game_providers.dart';

class SeasonLbEntry {
  const SeasonLbEntry(this.userId, this.nickname, this.xp, this.rank);
  factory SeasonLbEntry.fromRow(Map<String, dynamic> r) => SeasonLbEntry(
      r['user_id'] as String, r['nickname'] as String, (r['xp'] as num).toInt(), (r['rank'] as num).toInt());
  final String userId;
  final String nickname;
  final int xp;
  final int rank;
}

/// Thưởng cuối mùa của mình (mùa vừa kết thúc).
class SeasonEndReward {
  const SeasonEndReward(this.season, this.rank, this.gems, this.claimed);
  final int season;
  final int rank;
  final int gems;
  final bool claimed;
}

/// Tách để test thay bằng bản giả.
abstract class SeasonLbRepository {
  Future<List<SeasonEndReward>> rewardStatus();
  Future<int> claimReward(int season);
  Future<void> submit(String nickname, int seasonId, int xp);
  Future<List<SeasonLbEntry>> top();
  String? get myUserId;
}

class SupabaseSeasonLbRepository implements SeasonLbRepository {
  SupabaseClient get _c => Supabase.instance.client;
  @override
  Future<void> submit(String nickname, int seasonId, int xp) async {
    final u = _c.auth.currentUser;
    if (u == null || u.isAnonymous) return; // chỉ tài khoản đã liên kết email
    await _c.rpc('submit_season_xp', params: {'p_nickname': nickname, 'p_season': seasonId, 'p_xp': xp});
  }

  @override
  Future<List<SeasonLbEntry>> top() async {
    final rows = await _c.rpc('season_leaderboard_top', params: {'p_limit': 50}) as List;
    return [for (final r in rows) SeasonLbEntry.fromRow(r as Map<String, dynamic>)];
  }

  @override
  String? get myUserId => _c.auth.currentUser?.id;

  @override
  Future<List<SeasonEndReward>> rewardStatus() async {
    final u = _c.auth.currentUser;
    if (u == null || u.isAnonymous) return const [];
    final rows = await _c.rpc('season_reward_status') as List;
    return [
      for (final r in rows)
        SeasonEndReward((r['season'] as num).toInt(), (r['rank'] as num).toInt(), (r['gems'] as num).toInt(),
            r['claimed'] == true)
    ];
  }

  @override
  Future<int> claimReward(int season) async =>
      ((await _c.rpc('season_reward_claim', params: {'p_season': season})) as num).toInt();
}

final seasonLbRepositoryProvider = Provider<SeasonLbRepository>((_) => SupabaseSeasonLbRepository());

sealed class SeasonLbState {
  const SeasonLbState();
}

class SeasonLbLoading extends SeasonLbState {
  const SeasonLbLoading();
}

class SeasonLbNeedsNickname extends SeasonLbState {
  const SeasonLbNeedsNickname();
}

class SeasonLbError extends SeasonLbState {
  const SeasonLbError();
}

class SeasonLbLoaded extends SeasonLbState {
  const SeasonLbLoaded(this.entries, this.myUserId);
  final List<SeasonLbEntry> entries;
  final String? myUserId;
}

class SeasonLbController extends Notifier<SeasonLbState> {
  static const _nicknameKey = 'leaderboard_nickname';

  @override
  SeasonLbState build() => const SeasonLbLoading();

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const SeasonLbLoading();
    try {
      final repo = ref.read(seasonLbRepositoryProvider);
      final g = ref.read(gameControllerProvider);
      final nickname = ref.read(sharedPreferencesProvider).getString(_nicknameKey) ?? '';
      if (g.seasonXp > 0) {
        if (nickname.isEmpty) {
          state = const SeasonLbNeedsNickname();
          return;
        }
        await repo.submit(nickname, seasonIdFor(ref.read(clockProvider)()), g.seasonXp);
      }
      state = SeasonLbLoaded(await repo.top(), repo.myUserId);
    } catch (e) {
      developer.log('$e', name: 'SeasonLeaderboard');
      state = const SeasonLbError();
    }
  }

  Future<void> submitNickname(String nickname) async {
    await ref.read(sharedPreferencesProvider).setString(_nicknameKey, nickname);
    await refresh();
  }
}

final seasonLbControllerProvider = NotifierProvider<SeasonLbController, SeasonLbState>(SeasonLbController.new);

/// Thưởng cuối mùa chưa/đã nhận của mình. Mọi lỗi (mạng, chưa liên kết, server chưa có SQL) bị nuốt: thưởng chỉ là
/// phần thêm.
class SeasonRewardsController extends Notifier<List<SeasonEndReward>> {
  /// Tải khi trang Thẻ Mùa mở lần đầu xem thưởng (provider tự huỷ khi đóng trang → mở lại thì tải lại).
  @override
  List<SeasonEndReward> build() {
    Future.microtask(refresh);
    return const [];
  }

  Future<void> refresh() async {
    try {
      state = await ref.read(seasonLbRepositoryProvider).rewardStatus();
    } catch (e) {
      developer.log('season_reward_status: $e', name: 'SeasonRewards');
    }
  }

  bool _claiming = false;

  /// Nhận: server xác nhận TRƯỚC rồi mới cộng 💎 cục bộ (không bao giờ được 💎 ảo). Top 3 → nhớ "Quán quân mùa".
  /// Trả số 💎, hoặc ném lỗi server cho UI báo.
  Future<int> claim(SeasonEndReward r) async {
    if (_claiming) return 0;
    _claiming = true;
    try {
      final gems = await ref.read(seasonLbRepositoryProvider).claimReward(r.season);
      ref.read(gameControllerProvider.notifier).grantLeaderboardRewardGems(gems);
      if (r.rank <= seasonChampionMaxRank) {
        await ref.read(sharedPreferencesProvider).setBool(seasonChampionPrefsKey, true);
        ref.invalidate(seasonChampionProvider);
      }
      await refresh();
      return gems;
    } finally {
      _claiming = false;
    }
  }
}

final seasonRewardsControllerProvider =
    NotifierProvider.autoDispose<SeasonRewardsController, List<SeasonEndReward>>(SeasonRewardsController.new);

/// Đã từng nhận thưởng top 3 mùa chưa (mở danh hiệu "Quán quân mùa"); lưu máy.
const seasonChampionPrefsKey = 'season_champion';
final seasonChampionProvider =
    Provider<bool>((ref) => ref.watch(sharedPreferencesProvider).getBool(seasonChampionPrefsKey) ?? false);
