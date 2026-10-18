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

/// Tách để test thay bằng bản giả.
abstract class SeasonLbRepository {
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
