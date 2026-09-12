/// Điều phối UI Bảng xếp hạng tốc độ hoàn thành cốt truyện: nộp mốc hoàn
/// thành (nếu có và chưa nộp) rồi tải top danh sách.
///
/// Khác LeaderboardController: không có state "cần đặt tên" chặn cả việc
/// XEM — ai cũng xem được top danh sách ngay cả khi bản thân chưa hoàn
/// thành cốt truyện (không có gì để nộp thì bỏ qua bước nộp, tải thẳng
/// danh sách). "Cần đặt tên" chỉ xảy ra khi ĐÃ hoàn thành nhưng chưa từng
/// đặt tên ở đâu (kể cả Bảng xếp hạng chính — dùng chung 1 tên).
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';
import 'story_speedrun_repository.dart';

sealed class StorySpeedrunViewState {
  const StorySpeedrunViewState();
}

class StorySpeedrunLoading extends StorySpeedrunViewState {
  const StorySpeedrunLoading();
}

/// Đã hoàn thành cốt truyện nhưng chưa từng đặt tên — cần đặt tên trước khi
/// nộp mốc lên bảng xếp hạng.
class StorySpeedrunNeedsNickname extends StorySpeedrunViewState {
  const StorySpeedrunNeedsNickname();
}

class StorySpeedrunLoaded extends StorySpeedrunViewState {
  const StorySpeedrunLoaded({
    required this.entries,
    required this.myUserId,
    required this.hasCompleted,
  });
  final List<StorySpeedrunEntry> entries;
  final String? myUserId;

  /// Bản thân người xem đã hoàn thành 18 chương chưa (để hiện banner nhắc
  /// nếu chưa, thay vì âm thầm chỉ hiện danh sách).
  final bool hasCompleted;
}

class StorySpeedrunError extends StorySpeedrunViewState {
  const StorySpeedrunError(this.message);
  final String message;
}

class StorySpeedrunController extends Notifier<StorySpeedrunViewState> {
  StorySpeedrunRepository? _repo;

  /// UI gán trước khi gọi [refresh]/[submitNickname] — trả về số giây hoàn
  /// thành (null nếu chưa hoàn thành cốt truyện).
  int? Function()? getMyCompleteSeconds;

  @override
  StorySpeedrunViewState build() => const StorySpeedrunLoading();

  StorySpeedrunRepository get _repository => _repo ??= StorySpeedrunRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );

  Future<void> refresh() async {
    state = const StorySpeedrunLoading();
    try {
      final completeSeconds = getMyCompleteSeconds?.call();
      if (completeSeconds != null) {
        final nickname = _repository.cachedNickname;
        if (nickname == null) {
          state = const StorySpeedrunNeedsNickname();
          return;
        }
        await _repository.submitCompletion(
          nickname: nickname,
          completeSeconds: completeSeconds,
        );
      }
      await _loadTop(hasCompleted: completeSeconds != null);
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi vừa đặt tên lần đầu (đã hoàn thành, chưa từng đặt tên).
  Future<void> submitNickname(String nickname) async {
    state = const StorySpeedrunLoading();
    try {
      final completeSeconds = getMyCompleteSeconds?.call();
      if (completeSeconds != null) {
        await _repository.submitCompletion(
          nickname: nickname,
          completeSeconds: completeSeconds,
        );
      }
      await _loadTop(hasCompleted: completeSeconds != null);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadTop({required bool hasCompleted}) async {
    final entries = await _repository.fetchTop();
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    state = StorySpeedrunLoaded(
      entries: entries,
      myUserId: myUserId,
      hasCompleted: hasCompleted,
    );
  }

  void _fail(Object error) {
    developer.log('$error', name: 'StorySpeedrun');
    state =
        const StorySpeedrunError('Không tải được bảng xếp hạng, thử lại sau nhé.');
  }
}

final storySpeedrunControllerProvider =
    NotifierProvider<StorySpeedrunController, StorySpeedrunViewState>(
        StorySpeedrunController.new);
