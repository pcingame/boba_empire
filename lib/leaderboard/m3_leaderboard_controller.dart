/// Điều phối UI Bảng xếp hạng Trân Châu Rơi: nộp/cập nhật tổng sao của mình
/// (nếu đã có sao và đã đặt tên) rồi tải top.
///
/// Cùng khuôn `story_speedrun_controller.dart`, khác hai điểm: sao TĂNG DẦN nên
/// mỗi lần mở trang là nộp lại, và chưa có sao thì vẫn xem được bảng (chỉ bỏ
/// bước nộp).
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/analytics_repository.dart';
import '../state/game_providers.dart';
import 'm3_leaderboard_repository.dart';

sealed class M3LeaderboardViewState {
  const M3LeaderboardViewState();
}

class M3LeaderboardLoading extends M3LeaderboardViewState {
  const M3LeaderboardLoading();
}

/// Có sao để nộp nhưng chưa từng đặt tên ở bảng xếp hạng nào.
class M3LeaderboardNeedsNickname extends M3LeaderboardViewState {
  const M3LeaderboardNeedsNickname();
}

class M3LeaderboardLoaded extends M3LeaderboardViewState {
  const M3LeaderboardLoaded({
    required this.entries,
    required this.myUserId,
    required this.myStars,
  });
  final List<M3LeaderboardEntry> entries;
  final String? myUserId;

  /// Tổng sao của chính người xem — 0 nghĩa là chưa chơi màn nào.
  final int myStars;
}

class M3LeaderboardError extends M3LeaderboardViewState {
  const M3LeaderboardError(this.message);
  final String message;
}

class M3LeaderboardController extends Notifier<M3LeaderboardViewState> {
  M3LeaderboardRepository? _repo;
  AnalyticsRepository? _analyticsRepo;

  /// UI gán trước khi gọi [refresh] — trả về (tổng sao, số màn đã qua).
  (int stars, int levels) Function()? getMyProgress;

  @override
  M3LeaderboardViewState build() => const M3LeaderboardLoading();

  M3LeaderboardRepository get _repository => _repo ??= M3LeaderboardRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );

  /// Lazy + tự nuốt lỗi: analytics không bao giờ được cản việc xem bảng.
  AnalyticsRepository? get _analytics {
    if (_analyticsRepo != null) return _analyticsRepo;
    try {
      return _analyticsRepo = AnalyticsRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const M3LeaderboardLoading();
    unawaited(_analytics?.log('m3_leaderboard_viewed'));
    try {
      final (stars, levels) = getMyProgress?.call() ?? (0, 0);
      if (stars > 0) {
        final nickname = _repository.cachedNickname;
        if (nickname == null) {
          state = const M3LeaderboardNeedsNickname();
          return;
        }
        await _repository.submit(
          nickname: nickname,
          stars: stars,
          levelsCleared: levels,
        );
      }
      await _loadTop(myStars: stars);
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi vừa đặt tên lần đầu.
  Future<void> submitNickname(String nickname) async {
    state = const M3LeaderboardLoading();
    try {
      final (stars, levels) = getMyProgress?.call() ?? (0, 0);
      if (stars > 0) {
        await _repository.submit(
          nickname: nickname,
          stars: stars,
          levelsCleared: levels,
        );
      }
      await _loadTop(myStars: stars);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadTop({required int myStars}) async {
    final entries = await _repository.fetchTop();
    state = M3LeaderboardLoaded(
      entries: entries,
      myUserId: Supabase.instance.client.auth.currentUser?.id,
      myStars: myStars,
    );
  }

  void _fail(Object error) {
    developer.log('$error', name: 'M3Leaderboard');
    state = const M3LeaderboardError(
        'Không tải được bảng xếp hạng, thử lại sau nhé.');
  }
}

final m3LeaderboardControllerProvider =
    NotifierProvider<M3LeaderboardController, M3LeaderboardViewState>(
        M3LeaderboardController.new);
