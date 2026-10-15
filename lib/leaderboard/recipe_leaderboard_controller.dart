/// Điều phối UI Bảng xếp hạng Thợ pha chế: nộp/cập nhật số món đã từng đạt Thạo (nếu có món và đã đặt
/// tên) rồi tải top. Cùng khuôn `accessory_leaderboard_controller.dart`.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/analytics_repository.dart';
import '../state/game_providers.dart';
import 'recipe_leaderboard_repository.dart';

sealed class RecipeLeaderboardViewState {
  const RecipeLeaderboardViewState();
}

class RecipeLeaderboardLoading extends RecipeLeaderboardViewState {
  const RecipeLeaderboardLoading();
}

/// Có món Thạo để nộp nhưng chưa từng đặt tên ở bảng xếp hạng nào.
class RecipeLeaderboardNeedsNickname extends RecipeLeaderboardViewState {
  const RecipeLeaderboardNeedsNickname();
}

class RecipeLeaderboardLoaded extends RecipeLeaderboardViewState {
  const RecipeLeaderboardLoaded({required this.entries, required this.myUserId, required this.myMastered});
  final List<RecipeLeaderboardEntry> entries;
  final String? myUserId;

  /// Số món đã từng Thạo của chính người xem — 0 nghĩa là chưa có món nào.
  final int myMastered;
}

class RecipeLeaderboardError extends RecipeLeaderboardViewState {
  const RecipeLeaderboardError();
}

class RecipeLeaderboardController extends Notifier<RecipeLeaderboardViewState> {
  RecipeLeaderboardRepository? _repo;
  AnalyticsRepository? _analyticsRepo;

  /// UI gán trước khi gọi [refresh] — trả về số món đã từng đạt Thạo.
  int Function()? getMyMastered;

  @override
  RecipeLeaderboardViewState build() => const RecipeLeaderboardLoading();

  /// Bảng mà bộ điều phối này phục vụ — [RecipeOrderLeaderboardController] đổi sang bảng Pha theo đơn.
  RecipeBoard get board => RecipeBoard.quiz;

  RecipeLeaderboardRepository get _repository => _repo ??=
      RecipeLeaderboardRepository(Supabase.instance.client, ref.read(sharedPreferencesProvider), board);

  /// Lazy + tự nuốt lỗi: analytics không bao giờ được cản việc xem bảng.
  AnalyticsRepository? get _analytics {
    if (_analyticsRepo != null) return _analyticsRepo;
    try {
      return _analyticsRepo =
          AnalyticsRepository(Supabase.instance.client, ref.read(sharedPreferencesProvider));
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const RecipeLeaderboardLoading();
    unawaited(_analytics?.log(switch (board) {
      RecipeBoard.quiz => 'recipe_leaderboard_viewed',
      RecipeBoard.orders => 'recipe_order_leaderboard_viewed',
      RecipeBoard.daily => 'recipe_daily_leaderboard_viewed',
    }));
    try {
      final mastered = getMyMastered?.call() ?? 0;
      if (mastered > 0) {
        final nickname = _repository.cachedNickname;
        if (nickname == null) {
          state = const RecipeLeaderboardNeedsNickname();
          return;
        }
        await _repository.submit(nickname: nickname, mastered: mastered);
      }
      await _loadTop(mastered);
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi vừa đặt tên lần đầu.
  Future<void> submitNickname(String nickname) async {
    state = const RecipeLeaderboardLoading();
    try {
      final mastered = getMyMastered?.call() ?? 0;
      if (mastered > 0) await _repository.submit(nickname: nickname, mastered: mastered);
      await _loadTop(mastered);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadTop(int myMastered) async {
    final entries = await _repository.fetchTop();
    state = RecipeLeaderboardLoaded(
      entries: entries,
      myUserId: Supabase.instance.client.auth.currentUser?.id,
      myMastered: myMastered,
    );
  }

  void _fail(Object error) {
    developer.log('$error', name: 'RecipeLeaderboard');
    state = const RecipeLeaderboardError();
  }
}

class RecipeOrderLeaderboardController extends RecipeLeaderboardController {
  @override
  RecipeBoard get board => RecipeBoard.orders;
}

class RecipeDailyLeaderboardController extends RecipeLeaderboardController {
  @override
  RecipeBoard get board => RecipeBoard.daily;
}

final recipeDailyLeaderboardControllerProvider =
    NotifierProvider<RecipeDailyLeaderboardController, RecipeLeaderboardViewState>(RecipeDailyLeaderboardController.new);

final recipeOrderLeaderboardControllerProvider =
    NotifierProvider<RecipeOrderLeaderboardController, RecipeLeaderboardViewState>(
        RecipeOrderLeaderboardController.new);

final recipeLeaderboardControllerProvider =
    NotifierProvider<RecipeLeaderboardController, RecipeLeaderboardViewState>(RecipeLeaderboardController.new);
