/// Điều phối UI Bảng xếp hạng: hỏi tên lần đầu → nộp điểm hiện tại → tải
/// top + hạng của mình.
///
/// Giống ArenaController/CloudSaveController — không đụng trực tiếp
/// `GameState`, chỉ lấy số liệu qua callback [getLocalStats] do UI gán (xem
/// `leaderboard_page.dart`), giữ tách biệt khỏi `game_controller.dart`.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/analytics_repository.dart';
import '../state/game_providers.dart';
import 'leaderboard_repository.dart';

class LocalStats {
  const LocalStats({
    required this.lifetimeEarnings,
    required this.prestigeStars,
    required this.stage,
  });
  final double lifetimeEarnings;
  final int prestigeStars;
  final int stage;
}

sealed class LeaderboardViewState {
  const LeaderboardViewState();
}

class LeaderboardLoading extends LeaderboardViewState {
  const LeaderboardLoading();
}

/// Chưa từng đặt tên — UI hiện form nhập tên trước khi nộp điểm lần đầu.
class LeaderboardNeedsNickname extends LeaderboardViewState {
  const LeaderboardNeedsNickname();
}

class LeaderboardLoaded extends LeaderboardViewState {
  const LeaderboardLoaded({
    required this.entries,
    required this.myRank,
    required this.myUserId,
  });
  final List<LeaderboardEntry> entries;
  final int? myRank;
  final String? myUserId;
}

class LeaderboardError extends LeaderboardViewState {
  const LeaderboardError(this.message);
  final String message;
}

class LeaderboardController extends Notifier<LeaderboardViewState> {
  LeaderboardRepository? _repo;
  AnalyticsRepository? _analyticsRepo;

  /// UI gán trước khi gọi [refresh]/[submitNickname].
  LocalStats Function()? getLocalStats;

  /// UI gán để nhận Kim Cương thưởng hạng (nếu có) — gọi ĐÚNG 1 LẦN khi vừa
  /// nhận thành công trong [_submitAndLoad], giống cách ArenaController
  /// dùng `onRewardGems` để không đụng trực tiếp GameState.
  void Function(int gems)? onRewardGems;

  @override
  LeaderboardViewState build() => const LeaderboardLoading();

  LeaderboardRepository get _repository => _repo ??= LeaderboardRepository(
        Supabase.instance.client,
        ref.read(sharedPreferencesProvider),
      );

  /// Lazy + tự bắt lỗi giống GameController._analytics — không bao giờ được
  /// phép ảnh hưởng tới việc xem/nộp bảng xếp hạng nếu Supabase có vấn đề.
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

  /// Gọi khi mở màn Bảng xếp hạng. Đã có tên → tự nộp điểm mới nhất rồi
  /// tải danh sách. Chưa có tên → chuyển sang màn hỏi tên trước.
  Future<void> refresh() async {
    state = const LeaderboardLoading();
    unawaited(_analytics?.log('leaderboard_viewed'));
    try {
      final nickname = _repository.cachedNickname;
      if (nickname == null) {
        state = const LeaderboardNeedsNickname();
        return;
      }
      await _submitAndLoad(nickname);
    } catch (e) {
      _fail(e);
    }
  }

  /// Người chơi bấm "Đổi tên" ở màn danh sách — quay lại form nhập tên.
  void changeName() {
    state = const LeaderboardNeedsNickname();
  }

  /// Người chơi vừa đặt tên lần đầu (hoặc đổi tên) — nộp điểm rồi tải lại.
  Future<void> submitNickname(String nickname) async {
    state = const LeaderboardLoading();
    try {
      await _submitAndLoad(nickname);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _submitAndLoad(String nickname) async {
    final stats = getLocalStats?.call();
    if (stats != null) {
      await _repository.submit(
        nickname: nickname,
        lifetimeEarnings: stats.lifetimeEarnings,
        prestigeStars: stats.prestigeStars,
        stage: stats.stage,
      );
    }
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    final entries = await _repository.fetchAroundMe();
    // rank đã tính sẵn ở server cho từng hàng (xem leaderboard_around_me) —
    // lấy lại đúng hàng của mình trong CHÍNH kết quả này, không cần query
    // riêng chỉ để biết hạng.
    final myRank = entries.where((e) => e.userId == myUserId).firstOrNull?.rank;
    state = LeaderboardLoaded(
      entries: entries,
      myRank: myRank,
      myUserId: myUserId,
    );
    // Thử nhận thưởng hạng SAU KHI đã hiện danh sách — server tự kiểm tra
    // điều kiện (hạng đủ cao + qua thời gian chờ), trả 0 nếu chưa đủ, không
    // phải lỗi. Không chặn/làm chậm việc hiện danh sách nếu bước này lỗi.
    try {
      final gems = await _repository.claimReward();
      if (gems > 0) onRewardGems?.call(gems);
    } catch (e) {
      developer.log('nhận thưởng hạng lỗi (bỏ qua): $e', name: 'Leaderboard');
    }
  }

  void _fail(Object error) {
    developer.log('$error', name: 'Leaderboard');
    state = const LeaderboardError('Không tải được bảng xếp hạng, thử lại sau nhé.');
  }
}

final leaderboardControllerProvider =
    NotifierProvider<LeaderboardController, LeaderboardViewState>(
        LeaderboardController.new);
