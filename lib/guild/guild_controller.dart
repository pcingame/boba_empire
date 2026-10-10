/// Điều phối UI Hội: tải trạng thái (đang ở hội nào / danh sách hội công khai),
/// báo điểm tuần lên server, và các hành động (tạo/vào/rời/kick/nhận thưởng).
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../core/guild.dart';
import '../core/guild_shop.dart';
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
  bool get isOfficer => guild.members
      .any((m) => m.userId == myUserId && m.role == GuildRole.officer);

  /// Chủ hội hoặc phó hội: duyệt đơn, xoá tin.
  bool get canModerate => isOwner || isOfficer;

  /// Chủ kick mọi người khác; phó hội chỉ kick thành viên thường.
  bool canKick(GuildMemberInfo m) {
    if (m.userId == myUserId) return false;
    if (isOwner) return true;
    return isOfficer && m.role == GuildRole.member;
  }
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
      // Đồng bộ phần chạy ở tầng game: buff hội, cờ "đang ở hội", và khôi phục phụ
      // kiện hội đã đổi (mất save/đổi máy vẫn lấy lại được từ server).
      final game = ref.read(gameControllerProvider.notifier);
      game.setGuildJoined(my != null);
      game.applyGuildBuff(my?.buffSeconds ?? 0);
      if (my != null) game.grantGuildItems(my.ownedItems);
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

  Future<GuildOutcome> setOfficer(String userId, {required bool on}) =>
      _act(() => _repo.setOfficer(userId, on: on));

  Future<GuildOutcome> transferOwner(String userId) =>
      _act(() => _repo.transferOwner(userId));

  Future<GuildOutcome> report(String guildId, String reason) async {
    try {
      await _repo.report(guildId, reason);
      return const GuildOutcome();
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    }
  }

  int _lastBuffSyncMs = 0;

  /// Áp buff hội lúc mở app/quay lại mà KHÔNG cần mở màn Hội: chỉ hỏi server khi
  /// biết mình đang ở hội, và cách nhau ≥ 10 phút. Mọi lỗi (mất mạng) bị nuốt — buff
  /// cũ giữ nguyên tới hạn đã lưu.
  Future<void> syncBuff() async {
    final game = ref.read(gameControllerProvider);
    if (!game.guildJoined) return;
    final now = ref.read(clockProvider)();
    if (_lastBuffSyncMs != 0 && now - _lastBuffSyncMs < 10 * 60 * 1000) return;
    _lastBuffSyncMs = now;
    try {
      final secs = await _repo.buffSeconds();
      ref.read(gameControllerProvider.notifier).applyGuildBuff(secs);
    } catch (e) {
      developer.log('syncBuff: $e', name: 'Guild');
    }
  }

  /// Nạp [gems] 💎 lấy Xu Hội: kiểm đủ 💎 và còn hạn mức ngày TRƯỚC, trừ 💎 SAU khi
  /// server ghi nhận.
  Future<GuildOutcome> donate(int gems) async {
    final s = state;
    final doneToday = s is GuildMine ? s.guild.donatedToday : 0;
    if (gems <= 0) return const GuildOutcome(failure: GuildFailure.invalidInput);
    if (ref.read(gameControllerProvider).gems < gems) {
      return const GuildOutcome(failure: GuildFailure.notEnoughGems);
    }
    if (doneToday + gems > guildDonateDailyCap) {
      return const GuildOutcome(failure: GuildFailure.dailyLimit);
    }
    final out = await _act(() => _repo.donate(gems));
    if (out.ok) {
      ref.read(gameControllerProvider.notifier).chargeGuildDonation(gems);
    }
    return out;
  }

  /// Nhận thưởng nhiệm vụ hội tuần [index] (0-based) → Xu Hội cộng ở server.
  Future<GuildOutcome> claimFund() => _act(_repo.claimFund);

  Future<GuildOutcome> claimQuest(int index) async {
    if (index < 0 || index >= guildQuests.length) {
      return const GuildOutcome(failure: GuildFailure.invalidInput);
    }
    try {
      // Báo điểm mới nhất để server thấy đóng góp hiện tại của mình.
      if (_score > 0) await _repo.submitScore(_score);
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    }
    return _act(() => _repo.claimQuest(index + 1));
  }

  /// Đổi Xu Hội lấy phụ kiện hội: server trừ ví TRƯỚC, rồi mới cấp cục bộ.
  Future<GuildOutcome> buyItem(String itemId) async {
    final out = await _act(() => _repo.buyItem(itemId));
    if (out.ok) {
      ref.read(gameControllerProvider.notifier).grantGuildItems([itemId]);
    }
    return out;
  }

  /// Chat hội: không đụng trạng thái hội nên không refresh().
  Future<GuildOutcome> _chatAct(Future<void> Function() action) async {
    try {
      await action();
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    } catch (_) {
      return const GuildOutcome(failure: GuildFailure.network);
    }
    return const GuildOutcome();
  }

  Future<GuildOutcome> chatPost(String body) => _chatAct(() => _repo.chatPost(body));
  Future<GuildOutcome> chatDelete(int id) => _chatAct(() => _repo.chatDelete(id));
  Future<GuildOutcome> chatReport(int id) => _chatAct(() => _repo.chatReport(id));
  Future<GuildOutcome> chatPin(int? id) => _chatAct(() => _repo.chatPin(id));

  /// Mua buff thu nhập cho cả hội; buff áp ngay qua refresh (server báo giây còn lại).
  Future<GuildOutcome> buyBuff() => _act(_repo.buyBuff);

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
