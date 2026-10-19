/// Bảng xếp hạng Chi nhánh — xếp theo tổng cấp mọi chi nhánh (RPC `branch_leaderboard_top`, nộp qua
/// `submit_branch_levels`; supabase/branch_leaderboard_schema.sql). Dùng chung biệt danh `leaderboard_nickname`.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/branches.dart';
import '../state/game_providers.dart';

class BranchLbEntry {
  const BranchLbEntry(this.userId, this.nickname, this.totalLevels, this.opened, this.rank);
  factory BranchLbEntry.fromRow(Map<String, dynamic> r) => BranchLbEntry(r['user_id'] as String,
      r['nickname'] as String, (r['total_levels'] as num).toInt(), (r['opened'] as num).toInt(), (r['rank'] as num).toInt());
  final String userId;
  final String nickname;
  final int totalLevels;
  final int opened;
  final int rank;
}

/// Tách để test thay bằng bản giả.
abstract class BranchLbRepository {
  Future<void> submit(String nickname, int totalLevels, int opened);
  Future<List<BranchLbEntry>> top();
  String? get myUserId;
}

class SupabaseBranchLbRepository implements BranchLbRepository {
  SupabaseClient get _c => Supabase.instance.client;
  @override
  Future<void> submit(String nickname, int totalLevels, int opened) async {
    final u = _c.auth.currentUser;
    if (u == null || u.isAnonymous) return; // chỉ tài khoản đã liên kết email
    await _c.rpc('submit_branch_levels',
        params: {'p_nickname': nickname, 'p_total': totalLevels, 'p_opened': opened});
  }

  @override
  Future<List<BranchLbEntry>> top() async {
    final rows = await _c.rpc('branch_leaderboard_top', params: {'p_limit': 50}) as List;
    return [for (final r in rows) BranchLbEntry.fromRow(r as Map<String, dynamic>)];
  }

  @override
  String? get myUserId => _c.auth.currentUser?.id;
}

final branchLbRepositoryProvider = Provider<BranchLbRepository>((_) => SupabaseBranchLbRepository());

sealed class BranchLbState {
  const BranchLbState();
}

class BranchLbLoading extends BranchLbState {
  const BranchLbLoading();
}

class BranchLbNeedsNickname extends BranchLbState {
  const BranchLbNeedsNickname();
}

class BranchLbError extends BranchLbState {
  const BranchLbError();
}

class BranchLbLoaded extends BranchLbState {
  const BranchLbLoaded(this.entries, this.myUserId);
  final List<BranchLbEntry> entries;
  final String? myUserId;
}

class BranchLbController extends Notifier<BranchLbState> {
  static const _nicknameKey = 'leaderboard_nickname';

  @override
  BranchLbState build() => const BranchLbLoading();

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const BranchLbLoading();
    try {
      final repo = ref.read(branchLbRepositoryProvider);
      final levels = ref.read(gameControllerProvider).branchLevels;
      final total = branchTotalLevels(levels);
      final nickname = ref.read(sharedPreferencesProvider).getString(_nicknameKey) ?? '';
      if (total > 0) {
        if (nickname.isEmpty) {
          state = const BranchLbNeedsNickname();
          return;
        }
        await repo.submit(nickname, total, branchCities.where((c) => branchLevel(levels, c.id) > 0).length);
      }
      state = BranchLbLoaded(await repo.top(), repo.myUserId);
    } catch (e) {
      developer.log('$e', name: 'BranchLeaderboard');
      state = const BranchLbError();
    }
  }

  Future<void> submitNickname(String nickname) async {
    await ref.read(sharedPreferencesProvider).setString(_nicknameKey, nickname);
    await refresh();
  }
}

final branchLbControllerProvider = NotifierProvider<BranchLbController, BranchLbState>(BranchLbController.new);
