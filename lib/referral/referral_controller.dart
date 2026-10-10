/// Điều phối UI "Mời bạn": tải trạng thái, nhập mã, nhận thưởng, báo giai đoạn. 💎 được cộng
/// cục bộ CHỈ SAU khi server xác nhận (app tắt giữa chừng thì mất lượt thưởng, không được 💎 ảo).
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';
import 'referral_repository.dart';

/// Tách khỏi controller để test thay bản giả.
final referralRepositoryProvider = Provider<ReferralRepository>(
  (ref) => SupabaseReferralRepository(Supabase.instance.client),
);

sealed class ReferralViewState {
  const ReferralViewState();
}

class ReferralLoading extends ReferralViewState {
  const ReferralLoading();
}

class ReferralLoaded extends ReferralViewState {
  const ReferralLoaded(this.status);
  final ReferralStatus status;
}

class ReferralError extends ReferralViewState {
  const ReferralError(this.failure);
  final ReferralFailure failure;
}

/// Kết quả một hành động: [failure] null = thành công, [gems] là 💎 vừa nhận.
class ReferralOutcome {
  const ReferralOutcome({this.failure, this.gems = 0});
  final ReferralFailure? failure;
  final int gems;
  bool get ok => failure == null;
}

class ReferralController extends Notifier<ReferralViewState> {
  ReferralRepository get _repo => ref.read(referralRepositoryProvider);

  @override
  ReferralViewState build() => const ReferralLoading();

  Future<ReferralOutcome> _run(Future<int> Function() action) async {
    try {
      final gems = await action();
      return ReferralOutcome(gems: gems);
    } on ReferralException catch (e) {
      return ReferralOutcome(failure: e.failure);
    } catch (e) {
      developer.log('$e', name: 'Referral');
      return const ReferralOutcome(failure: ReferralFailure.network);
    }
  }

  Future<void> load() async {
    state = const ReferralLoading();
    try {
      state = ReferralLoaded(await _repo.status());
    } on ReferralException catch (e) {
      state = ReferralError(e.failure);
    } catch (e) {
      developer.log('$e', name: 'Referral');
      state = const ReferralError(ReferralFailure.network);
    }
  }

  /// Nhập mã của người mời: server ghi nhận TRƯỚC, rồi mới cộng 💎. Xong thì báo luôn giai đoạn
  /// hiện tại (bạn có thể đã vượt giai đoạn 3 từ trước khi nhập mã).
  Future<ReferralOutcome> redeem(String code) async {
    final out = await _run(() => _repo.redeem(code));
    if (!out.ok) return out;
    final game = ref.read(gameControllerProvider.notifier);
    game.grantReferralGems(out.gems);
    game.markReferralRedeemed();
    await reportStageIfNeeded();
    await load();
    return out;
  }

  /// Người mời nhận thưởng cho mọi bạn đã đạt giai đoạn.
  Future<ReferralOutcome> claim() async {
    final out = await _run(_repo.claim);
    if (out.ok) {
      ref.read(gameControllerProvider.notifier).grantReferralGems(out.gems);
      await load();
    }
    return out;
  }

  /// Người được mời: báo một lần khi đạt giai đoạn đủ cao (cờ cục bộ chặn gọi lặp). Lỗi nuốt im
  /// lặng — lần mở app sau thử lại.
  Future<void> reportStageIfNeeded() async {
    final s = ref.read(gameControllerProvider);
    if (!s.referralRedeemed || s.referralStageSent || s.stage < referralStageNeeded) {
      return;
    }
    try {
      await _repo.reportStage(s.stage);
      ref.read(gameControllerProvider.notifier).markReferralStageSent();
    } catch (_) {}
  }
}

final referralControllerProvider =
    NotifierProvider<ReferralController, ReferralViewState>(
  ReferralController.new,
);
