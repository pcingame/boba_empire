/// Điều phối UI Bảng xếp hạng Sự kiện: nộp điểm của mình (nếu > 0 và đã đặt
/// tên) rồi tải top. Cùng khuôn `m3_leaderboard_controller.dart`.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';
import 'event_leaderboard_repository.dart';

sealed class EventLeaderboardViewState {
  const EventLeaderboardViewState();
}

class EventLeaderboardLoading extends EventLeaderboardViewState {
  const EventLeaderboardLoading();
}

class EventLeaderboardNeedsNickname extends EventLeaderboardViewState {
  const EventLeaderboardNeedsNickname();
}

class EventLeaderboardLoaded extends EventLeaderboardViewState {
  const EventLeaderboardLoaded({
    required this.entries,
    required this.myUserId,
    required this.myScore,
  });
  final List<EventLeaderboardEntry> entries;
  final String? myUserId;

  /// Điểm của chính người xem — 0 nghĩa là chưa tham gia.
  final int myScore;
}

class EventLeaderboardError extends EventLeaderboardViewState {
  const EventLeaderboardError();
}

class EventLeaderboardController extends Notifier<EventLeaderboardViewState> {
  EventLeaderboardRepository? _repo;

  /// UI gán trước khi gọi [refresh] — (id dịp, điểm của mình).
  (String festivalId, int score) Function()? getMyProgress;

  @override
  EventLeaderboardViewState build() => const EventLeaderboardLoading();

  EventLeaderboardRepository get _repository =>
      _repo ??= EventLeaderboardRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );

  Future<void> refresh({bool silent = false}) => _run(silent: silent);

  Future<void> submitNickname(String nickname) => _run(nickname: nickname);

  Future<void> _run({bool silent = false, String? nickname}) async {
    if (!silent) state = const EventLeaderboardLoading();
    try {
      final (festivalId, score) = getMyProgress?.call() ?? ('', 0);
      if (festivalId.isEmpty) {
        state = const EventLeaderboardError();
        return;
      }
      if (score > 0) {
        final name = nickname ?? _repository.cachedNickname;
        if (name == null) {
          state = const EventLeaderboardNeedsNickname();
          return;
        }
        await _repository.submit(
            festivalId: festivalId, nickname: name, score: score);
      }
      final entries = await _repository.fetchTop(festivalId);
      state = EventLeaderboardLoaded(
        entries: entries,
        myUserId: Supabase.instance.client.auth.currentUser?.id,
        myScore: score,
      );
    } catch (e) {
      developer.log('$e', name: 'EventLeaderboard');
      state = const EventLeaderboardError();
    }
  }
}

final eventLeaderboardControllerProvider =
    NotifierProvider<EventLeaderboardController, EventLeaderboardViewState>(
        EventLeaderboardController.new);
