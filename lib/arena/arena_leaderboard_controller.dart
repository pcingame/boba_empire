/// Điều phối UI "Bảng xếp hạng PK": hỏi tên lần đầu (nếu chưa có) → tải
/// thắng/thua đã gộp từ mọi trận Đấu Trường.
///
/// Giống LeaderboardController nhưng KHÔNG có bước "nộp điểm" — thắng/thua
/// tính thẳng từ arena_matches ở server, không có số nào client tự báo (xem
/// arena_leaderboard_repository.dart).
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';
import 'arena_leaderboard_repository.dart';

sealed class ArenaLeaderboardViewState {
  const ArenaLeaderboardViewState();
}

class ArenaLeaderboardLoading extends ArenaLeaderboardViewState {
  const ArenaLeaderboardLoading();
}

/// Chưa từng đặt tên — UI hiện form nhập tên trước khi hiện danh sách.
class ArenaLeaderboardNeedsNickname extends ArenaLeaderboardViewState {
  const ArenaLeaderboardNeedsNickname();
}

class ArenaLeaderboardLoaded extends ArenaLeaderboardViewState {
  const ArenaLeaderboardLoaded({
    required this.entries,
    required this.myRank,
    required this.myUserId,
  });
  final List<ArenaLeaderboardEntry> entries;
  final int? myRank;
  final String? myUserId;
}

class ArenaLeaderboardError extends ArenaLeaderboardViewState {
  const ArenaLeaderboardError(this.message);
  final String message;
}

class ArenaLeaderboardController extends Notifier<ArenaLeaderboardViewState> {
  ArenaLeaderboardRepository? _repo;

  @override
  ArenaLeaderboardViewState build() => const ArenaLeaderboardLoading();

  ArenaLeaderboardRepository get _repository => _repo ??= ArenaLeaderboardRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );

  /// Gọi khi mở màn Bảng xếp hạng PK. Đã có tên → tải thẳng danh sách. Chưa
  /// có tên → chuyển sang màn hỏi tên trước.
  Future<void> refresh() async {
    state = const ArenaLeaderboardLoading();
    try {
      final nickname = _repository.cachedNickname;
      if (nickname == null) {
        state = const ArenaLeaderboardNeedsNickname();
        return;
      }
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi bấm "Đổi tên" ở màn danh sách — quay lại form nhập tên.
  void changeName() {
    state = const ArenaLeaderboardNeedsNickname();
  }

  /// Người chơi vừa đặt tên lần đầu (hoặc đổi tên) — đăng ký rồi tải lại.
  Future<void> submitNickname(String nickname) async {
    state = const ArenaLeaderboardLoading();
    try {
      await _repository.setNickname(nickname);
      await _load();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _load() async {
    final myUserId = await _repository.ensureSignedIn();
    final entries = await _repository.fetchAroundMe();
    // rank đã tính sẵn ở server cho từng hàng (xem
    // arena_leaderboard_around_me) — lấy lại đúng hàng của mình trong CHÍNH
    // kết quả này, null nếu bạn chưa có trận nào (không nằm trong đó).
    final myRank = entries.where((e) => e.userId == myUserId).firstOrNull?.rank;
    state = ArenaLeaderboardLoaded(
      entries: entries,
      myRank: myRank,
      myUserId: myUserId,
    );
  }

  void _fail(Object error) {
    developer.log('$error', name: 'ArenaLeaderboard');
    state =
        const ArenaLeaderboardError('Không tải được bảng xếp hạng, thử lại sau nhé.');
  }
}

final arenaLeaderboardControllerProvider =
    NotifierProvider<ArenaLeaderboardController, ArenaLeaderboardViewState>(
        ArenaLeaderboardController.new);
