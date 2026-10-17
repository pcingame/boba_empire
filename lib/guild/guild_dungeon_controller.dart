/// Điều phối Phó bản Hội: báo tổng luỹ kế tuần của máy này, tải trạng thái, chọn vai, nhận thưởng ải.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/guild_dungeon.dart';
import '../state/game_providers.dart';
import 'guild_controller.dart' show GuildOutcome;
import 'guild_dungeon_repository.dart';
import 'guild_repository.dart';

/// [data] null + [loading] false + [failed] false = không ở hội.
class DungeonView {
  const DungeonView({this.data, this.loading = true, this.failed = false});
  final DungeonState? data;
  final bool loading;
  final bool failed;
}

final guildDungeonRepositoryProvider = Provider<GuildDungeonRepository>(
  (ref) => SupabaseGuildDungeonRepository(Supabase.instance.client),
);

class GuildDungeonController extends Notifier<DungeonView> {
  @override
  DungeonView build() => const DungeonView();

  GuildDungeonRepository get _repo => ref.read(guildDungeonRepositoryProvider);

  Future<void> _submit() async {
    final t = ref.read(gameControllerProvider.notifier).dungeonProgress();
    if (t.tap + t.off + t.rec == 0) return;
    await _repo.submit(tap: t.tap, off: t.off, rec: t.rec);
  }

  /// Lần tải thành công gần nhất (epoch ms). Thẻ trên màn Hội và màn chi tiết cùng tự tải khi mở: cửa sổ
  /// ngắn này gộp hai lần thành một (hai RPC thay vì bốn) mà vẫn đủ tươi cho người đang xem.
  int _loadedAtMillis = 0;
  static const _freshMillis = 15000;

  /// Báo luỹ kế (nếu có) rồi tải trạng thái. [silent] giữ dữ liệu cũ trên màn trong lúc tải.
  /// [force] bỏ qua cửa sổ tươi (kéo để làm mới, sau khi đổi vai / nhận thưởng).
  Future<void> refresh({bool silent = false, bool force = false}) async {
    final now = ref.read(clockProvider)();
    if (!force && state.data != null && !state.failed && now - _loadedAtMillis < _freshMillis) return;
    if (!silent) state = DungeonView(data: state.data);
    try {
      try {
        await _submit();
      } on GuildException catch (e) {
        // Báo hỏng (mạng chập chờn…) không được che trạng thái hiện có.
        developer.log('dungeon submit: ${e.failure}', name: 'GuildDungeon');
      }
      state = DungeonView(data: await _repo.state(), loading: false);
      _loadedAtMillis = now;
    } catch (e) {
      developer.log('$e', name: 'GuildDungeon');
      state = DungeonView(data: state.data, loading: false, failed: true);
    }
  }

  Future<GuildOutcome> setRole(DungeonBar role) async {
    try {
      await _repo.setRole(role);
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    } catch (_) {
      return const GuildOutcome(failure: GuildFailure.network);
    }
    await refresh(silent: true, force: true);
    return const GuildOutcome();
  }

  /// Nhận ải [stage] (1-based). Server xác nhận + cộng Xu Hội TRƯỚC, rồi mới cấp 💎/rương cục bộ.
  Future<GuildOutcome> claim(int stage) async {
    try {
      await _submit();
      final r = await _repo.claim(stage);
      final drop = ref
          .read(gameControllerProvider.notifier)
          .grantDungeonReward(gems: r.gems, chest: r.chest);
      await refresh(silent: true, force: true);
      return GuildOutcome(gems: r.gems, coins: r.coins, drop: drop);
    } on GuildException catch (e) {
      return GuildOutcome(failure: e.failure);
    } catch (_) {
      return const GuildOutcome(failure: GuildFailure.network);
    }
  }
}

final guildDungeonControllerProvider =
    NotifierProvider<GuildDungeonController, DungeonView>(GuildDungeonController.new);
