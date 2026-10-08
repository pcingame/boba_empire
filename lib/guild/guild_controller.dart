/// Điều phối UI Hội: tải trạng thái (đang ở hội nào / danh sách hội công khai),
/// báo điểm tuần lên server, và các hành động (tạo/vào/rời/kick/nhận thưởng).
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../core/guild.dart';
import '../state/game_providers.dart';
import 'guild_repository.dart';

sealed class GuildViewState {
  const GuildViewState();
}

class GuildLoading extends GuildViewState {
  const GuildLoading();
}

/// Chưa ở hội nào: kèm danh sách hội công khai còn chỗ.
class GuildNone extends GuildViewState {
  const GuildNone(this.listing);
  final List<GuildSummary> listing;
}

class GuildMine extends GuildViewState {
  const GuildMine({required this.guild, required this.myUserId});
  final MyGuild guild;
  final String? myUserId;

  bool get isOwner => guild.ownerId == myUserId;
  int get myPoints => guild.pointsOf(myUserId);
}

class GuildError extends GuildViewState {
  const GuildError();
}

/// Kết quả một hành động: [failure] null = thành công.
class GuildOutcome {
  const GuildOutcome({this.failure, this.gems = 0, this.drop});
  final GuildFailure? failure;
  final int gems;
  final AccessoryDrop? drop;
  bool get ok => failure == null;
}

final guildRepositoryProvider = Provider<GuildRepository>(
  (ref) => SupabaseGuildRepository(
    Supabase.instance.client,
    ref.read(sharedPreferencesProvider),
  ),
);

class GuildController extends Notifier<GuildViewState> {
  @override
  GuildViewState build() => const GuildLoading();

  GuildRepository get _repo => ref.read(guildRepositoryProvider);

  int get _score => ref.read(gameControllerProvider).guildScore;

  /// Tải trạng thái. Đang ở hội thì báo điểm tuần trước (chỉ khi > 0) rồi tải lại.
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const GuildLoading();
    try {
      var my = await _repo.myGuild();
      if (my != null && _score > 0) {
        try {
          await _repo.submitScore(_score);
          my = await _repo.myGuild();
        } on GuildException catch (e) {
          // Báo điểm hỏng (vd. mạng chập chờn) không được che mất trạng thái hội.
          developer.log('submitScore: ${e.failure}', name: 'Guild');
        }
      }
      state = my == null
          ? GuildNone(await _repo.list())
          : GuildMine(guild: my, myUserId: _repo.myUserId);
    } catch (e) {
      developer.log('$e', name: 'Guild');
      state = const GuildError();
    }
  }

  Future<GuildOutcome> _act(Future<void> Function() action) async {
    try {
      await action();
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    } catch (_) {
      return const GuildOutcome(failure: GuildFailure.network);
    }
    await refresh(silent: true);
    return const GuildOutcome();
  }

  /// Tạo hội tốn [guildCreateCostGems] 💎: kiểm đủ TRƯỚC, trừ SAU khi server
  /// thành công (server lỗi/app tắt giữa chừng thì không mất 💎).
  Future<GuildOutcome> create({
    required String name,
    required String tag,
    required String emoji,
    required bool requiresApproval,
    required String nickname,
  }) async {
    if (ref.read(gameControllerProvider).gems < guildCreateCostGems) {
      return const GuildOutcome(failure: GuildFailure.notEnoughGems);
    }
    final out = await _act(() => _repo.create(
          name: name.trim(),
          tag: tag.trim(),
          emoji: emoji,
          requiresApproval: requiresApproval,
          nickname: nickname.trim(),
          score: _score,
        ));
    if (out.ok) ref.read(gameControllerProvider.notifier).chargeGuildCreation();
    return out;
  }

  Future<GuildOutcome> join({
    required String guildId,
    required String nickname,
  }) =>
      _act(() => _repo.join(
            guildId: guildId,
            nickname: nickname.trim(),
            score: _score,
          ));

  /// Xin vào hội cần duyệt (chủ hội duyệt mới vào được).
  Future<GuildOutcome> requestJoin({
    required String guildId,
    required String nickname,
  }) =>
      _act(() => _repo.requestJoin(
            guildId: guildId,
            nickname: nickname.trim(),
            score: _score,
          ));

  Future<GuildOutcome> cancelRequest() => _act(_repo.cancelRequest);

  /// Chủ hội duyệt/từ chối yêu cầu của [userId].
  Future<GuildOutcome> respond(String userId, {required bool accept}) =>
      _act(() => _repo.respondRequest(userId, accept: accept));

  Future<GuildOutcome> leave() => _act(_repo.leave);

  Future<GuildOutcome> kick(String userId) => _act(() => _repo.kick(userId));

  Future<GuildOutcome> report(String guildId, String reason) async {
    try {
      await _repo.report(guildId, reason);
      return const GuildOutcome();
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    }
  }

  /// Nhận thưởng mốc [index] (0-based). Server xác nhận TRƯỚC, rồi mới cộng 💎 /
  /// phụ kiện cục bộ — server chặn nhận hai lần trong tuần.
  Future<GuildOutcome> claim(int index) async {
    if (index < 0 || index >= guildMilestones.length) {
      return const GuildOutcome(failure: GuildFailure.notFound);
    }
    try {
      // Báo điểm mới nhất để server thấy đóng góp hiện tại của mình.
      if (_score > 0) await _repo.submitScore(_score);
      await _repo.claimReward(index + 1);
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    }
    final drop =
        ref.read(gameControllerProvider.notifier).grantGuildReward(index);
    await refresh(silent: true);
    return GuildOutcome(gems: guildMilestones[index].gems, drop: drop);
  }
}

final guildControllerProvider =
    NotifierProvider<GuildController, GuildViewState>(GuildController.new);
