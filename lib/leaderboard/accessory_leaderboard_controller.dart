/// Điều phối UI Bảng xếp hạng Sưu tập: nộp/cập nhật số phụ kiện khác nhau
/// đã có (nếu đã có món và đã đặt tên) rồi tải top.
///
/// Cùng khuôn `m3_leaderboard_controller.dart`: số lượng TĂNG DẦN nên mỗi lần
/// mở trang là nộp lại, và chưa có món nào thì vẫn xem được bảng.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/analytics_repository.dart';
import '../state/game_providers.dart';
import 'accessory_leaderboard_repository.dart';

sealed class AccessoryLeaderboardViewState {
  const AccessoryLeaderboardViewState();
}

class AccessoryLeaderboardLoading extends AccessoryLeaderboardViewState {
  const AccessoryLeaderboardLoading();
}

/// Có phụ kiện để nộp nhưng chưa từng đặt tên ở bảng xếp hạng nào.
class AccessoryLeaderboardNeedsNickname extends AccessoryLeaderboardViewState {
  const AccessoryLeaderboardNeedsNickname();
}

class AccessoryLeaderboardLoaded extends AccessoryLeaderboardViewState {
  const AccessoryLeaderboardLoaded({
    required this.entries,
    required this.myUserId,
    required this.myOwnedCount,
  });
  final List<AccessoryLeaderboardEntry> entries;
  final String? myUserId;

  /// Số phụ kiện khác nhau của chính người xem — 0 nghĩa là chưa có món nào.
  final int myOwnedCount;
}

class AccessoryLeaderboardError extends AccessoryLeaderboardViewState {
  const AccessoryLeaderboardError(this.message);
  final String message;
}

class AccessoryLeaderboardController
    extends Notifier<AccessoryLeaderboardViewState> {
  AccessoryLeaderboardRepository? _repo;
  AnalyticsRepository? _analyticsRepo;

  /// UI gán trước khi gọi [refresh] — trả về số phụ kiện khác nhau đang có.
  int Function()? getMyOwnedCount;

  @override
  AccessoryLeaderboardViewState build() => const AccessoryLeaderboardLoading();

  AccessoryLeaderboardRepository get _repository =>
      _repo ??= AccessoryLeaderboardRepository(
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
    if (!silent) state = const AccessoryLeaderboardLoading();
    unawaited(_analytics?.log('accessory_leaderboard_viewed'));
    try {
      final owned = getMyOwnedCount?.call() ?? 0;
      if (owned > 0) {
        final nickname = _repository.cachedNickname;
        if (nickname == null) {
          state = const AccessoryLeaderboardNeedsNickname();
          return;
        }
        await _repository.submit(nickname: nickname, ownedCount: owned);
      }
      await _loadTop(myOwnedCount: owned);
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi vừa đặt tên lần đầu.
  Future<void> submitNickname(String nickname) async {
    state = const AccessoryLeaderboardLoading();
    try {
      final owned = getMyOwnedCount?.call() ?? 0;
      if (owned > 0) {
        await _repository.submit(nickname: nickname, ownedCount: owned);
      }
      await _loadTop(myOwnedCount: owned);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadTop({required int myOwnedCount}) async {
    final entries = await _repository.fetchTop();
    state = AccessoryLeaderboardLoaded(
      entries: entries,
      myUserId: Supabase.instance.client.auth.currentUser?.id,
      myOwnedCount: myOwnedCount,
    );
  }

  void _fail(Object error) {
    developer.log('$error', name: 'AccessoryLeaderboard');
    state = const AccessoryLeaderboardError(
        'Không tải được bảng xếp hạng, thử lại sau nhé.');
  }
}

final accessoryLeaderboardControllerProvider = NotifierProvider<
    AccessoryLeaderboardController,
    AccessoryLeaderboardViewState>(AccessoryLeaderboardController.new);
