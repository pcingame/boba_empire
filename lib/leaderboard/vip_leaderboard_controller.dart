/// Điều phối UI Bảng xếp hạng VIP: nộp EXP của mình (nếu đã có cấp VIP và đã đặt biệt
/// danh) rồi tải top. Cùng khuôn accessory_leaderboard_controller.dart.
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/topup.dart';
import '../state/game_providers.dart';
import 'flair.dart';
import 'vip_leaderboard_repository.dart';

sealed class VipLeaderboardViewState {
  const VipLeaderboardViewState();
}

class VipLeaderboardLoading extends VipLeaderboardViewState {
  const VipLeaderboardLoading();
}

/// Có cấp VIP để nộp nhưng chưa từng đặt biệt danh ở bảng xếp hạng nào.
class VipLeaderboardNeedsNickname extends VipLeaderboardViewState {
  const VipLeaderboardNeedsNickname();
}

class VipLeaderboardLoaded extends VipLeaderboardViewState {
  const VipLeaderboardLoaded({
    required this.entries,
    required this.myUserId,
    required this.myVipExp,
  });
  final List<VipLeaderboardEntry> entries;
  final String? myUserId;

  /// EXP của chính người xem; dưới bậc đầu nghĩa là chưa có cấp VIP nên chưa lên bảng.
  final int myVipExp;
}

class VipLeaderboardError extends VipLeaderboardViewState {
  const VipLeaderboardError();
}

/// Tách khỏi controller để test thay bằng bản giả.
final vipLeaderboardRepositoryProvider = Provider<VipLeaderboardRepository>(
  (ref) => VipLeaderboardRepository(Supabase.instance.client),
);

class VipLeaderboardController extends Notifier<VipLeaderboardViewState> {
  /// CÙNG key với mọi bảng xếp hạng khác — một biệt danh dùng chung.
  static const _nicknameKey = 'leaderboard_nickname';

  @override
  VipLeaderboardViewState build() => const VipLeaderboardLoading();

  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const VipLeaderboardLoading();
    try {
      final exp = ref.read(gameControllerProvider).vipExp;
      if (topupVipLevel(exp) >= 1) {
        final nickname = ref.read(sharedPreferencesProvider).getString(_nicknameKey);
        if (nickname == null || nickname.isEmpty) {
          state = const VipLeaderboardNeedsNickname();
          return;
        }
        await ref.read(flairCacheProvider.notifier).reportVip(exp);
      }
      final entries = await ref.read(vipLeaderboardRepositoryProvider).fetchTop();
      state = VipLeaderboardLoaded(
        entries: entries,
        myUserId: _myUserId(),
        myVipExp: exp,
      );
    } catch (e) {
      developer.log('$e', name: 'VipLeaderboard');
      state = const VipLeaderboardError();
    }
  }

  /// Người chơi vừa đặt biệt danh lần đầu.
  Future<void> submitNickname(String nickname) async {
    await ref.read(sharedPreferencesProvider).setString(_nicknameKey, nickname);
    await refresh();
  }

  String? _myUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null; // Supabase chưa khởi tạo (test)
    }
  }
}

final vipLeaderboardControllerProvider =
    NotifierProvider<VipLeaderboardController, VipLeaderboardViewState>(
  VipLeaderboardController.new,
);
