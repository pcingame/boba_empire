/// Boss Thế Giới: mô hình trạng thái, gọi RPC `world_boss_*` (supabase/world_boss_schema.sql) và điều phối
/// (báo sát thương → tải trạng thái → nhận quà). 💎/rương chỉ cấp SAU khi server xác nhận.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ads/ad_service.dart';
import '../core/world_boss.dart';
import '../data/cloud_save_controller.dart';
import '../state/game_providers.dart';

class WorldBossRow {
  const WorldBossRow(this.nickname, this.damage);
  final String nickname;
  final int damage;
}

class WorldBossState {
  const WorldBossState({
    required this.boss,
    required this.hp,
    required this.damage,
    required this.mine,
    required this.rank,
    required this.players,
    required this.endsAtSeconds,
    required this.claimed,
    required this.board,
    this.auto = false,
    this.adLeft = worldBossAdPerDay,
    this.minDamage = worldBossMinDamageToClaim,
    this.daily,
    this.open = true,
    this.startsAtSeconds = 0,
  });

  /// [isDaily]: dùng cho phần `daily` lồng trong trạng thái (boss ngày: mức sát thương tối thiểu riêng).
  factory WorldBossState.fromJson(Map<String, dynamic> j, {bool isDaily = false}) => WorldBossState(
        minDamage: isDaily ? worldBossDayMinDamageToClaim : worldBossMinDamageToClaim,
        daily: !isDaily && j['daily'] is Map
            ? WorldBossState.fromJson(Map<String, dynamic>.from(j['daily'] as Map), isDaily: true)
            : null,
        open: j['open'] != false,
        startsAtSeconds: (j['starts_at'] as num?)?.toInt() ?? 0,
        boss: (((j['boss'] as num?)?.toInt() ?? 0) % worldBossCount).abs(),
        hp: ((j['hp'] as num?)?.toInt() ?? worldBossBaseHp).clamp(1, 1 << 62),
        damage: (j['damage'] as num?)?.toInt() ?? 0,
        mine: (j['mine'] as num?)?.toInt() ?? 0,
        rank: (j['rank'] as num?)?.toInt(),
        players: (j['players'] as num?)?.toInt() ?? 0,
        endsAtSeconds: (j['ends_at'] as num?)?.toInt() ?? 0,
        auto: j['auto'] == true,
        adLeft: ((j['ad_left'] ?? worldBossAdPerDay) as num).toInt().clamp(0, worldBossAdPerDay),
        claimed: {
          for (final e in (j['claimed'] is List ? j['claimed'] as List : const []))
            if (e is num) e.toInt(),
        },
        board: [
          for (final e in (j['board'] is List ? j['board'] as List : const []))
            if (e is Map) WorldBossRow(e['nickname'] as String? ?? '???', (e['damage'] as num?)?.toInt() ?? 0),
        ],
      );

  final int boss;

  /// Boss tuần chỉ đánh được từ 0h UTC Chủ Nhật ([startsAtSeconds]); server cũ không gửi → coi như mở.
  final bool open;
  final int startsAtSeconds;

  /// Đã bật Tự động đánh tuần này.
  final bool auto;

  /// Lượt xem quảng cáo còn lại hôm nay.
  final int adLeft;
  final int hp;

  /// Sát thương tối thiểu của bạn để nhận quà mốc (boss ngày thấp hơn boss tuần).
  final int minDamage;

  /// Boss ngày (null nếu server chưa chạy bản SQL mới).
  final WorldBossState? daily;
  final int damage;
  final int mine;
  final int? rank;
  final int players;
  final int endsAtSeconds;
  final Set<int> claimed;
  final List<WorldBossRow> board;

  int get hpLeft => (hp - damage).clamp(0, hp);
  bool get defeated => damage >= hp;

  /// Mốc [phase] (1-based) đã phá chưa — khớp SQL `tổng×5 ≥ máu×mốc`.
  bool phaseReached(int phase) => damage * worldBossPhases >= hp * phase;

  bool get meetsMinimum => mine >= minDamage;

  bool canClaim(int phase) => phaseReached(phase) && !claimed.contains(phase) && meetsMinimum;

  /// Số mốc nhận được ngay (chấm đỏ).
  int get claimableCount =>
      [for (var p = 1; p <= worldBossPhases; p++) if (canClaim(p)) p].length + (daily?.claimableCount ?? 0);
}

abstract class WorldBossRepository {
  Future<WorldBossState> state();
  Future<void> submit({required int tap, required int off, required int rec});
  Future<({int gems, bool chest})> claim(int phase);

  /// Nhận mốc [phase] của boss NGÀY; trả số 💎 (Xu do app cấp theo [worldBossDayPhaseSeconds]).
  Future<int> claimDay(int phase);

  /// Bật Tự động đánh tuần này. true = vừa bật (trừ 💎), false = đã bật từ trước.
  Future<bool> buyAuto();

  /// Báo đã xem xong một quảng cáo → +[worldBossAdDamage]. Trả số lượt còn lại hôm nay; ném 'ad limit' khi hết.
  Future<int> adStrike();
}

class SupabaseWorldBossRepository implements WorldBossRepository {
  SupabaseClient get _c => Supabase.instance.client;

  @override
  Future<WorldBossState> state() async =>
      WorldBossState.fromJson(Map<String, dynamic>.from(await _c.rpc('world_boss_state') as Map));

  @override
  Future<void> submit({required int tap, required int off, required int rec}) =>
      _c.rpc('world_boss_submit', params: {'p_tap': tap, 'p_off': off, 'p_rec': rec});

  @override
  Future<int> claimDay(int phase) async =>
      (((await _c.rpc('world_boss_day_claim', params: {'p_phase': phase})) as Map)['gems'] as num?)?.toInt() ?? 0;

  @override
  Future<int> adStrike() async => ((await _c.rpc('world_boss_ad_strike')) as num).toInt();

  @override
  Future<bool> buyAuto() async => (await _c.rpc('world_boss_buy_auto')) == true;

  @override
  Future<({int gems, bool chest})> claim(int phase) async {
    final r = await _c.rpc('world_boss_claim', params: {'p_phase': phase}) as Map;
    return (gems: (r['gems'] as num?)?.toInt() ?? 0, chest: r['chest'] == true);
  }
}

final worldBossRepositoryProvider = Provider<WorldBossRepository>((_) => SupabaseWorldBossRepository());

/// Trạng thái trang Boss. Lỗi tải → AsyncError (UI hiện nút thử lại). Báo sát thương trước khi tải.
class WorldBossController extends AsyncNotifier<WorldBossState> {
  WorldBossRepository get _repo => ref.read(worldBossRepositoryProvider);

  Future<WorldBossState> _load() async {
    final t = ref.read(gameControllerProvider.notifier).dungeonProgress();
    try {
      if (t.tap + t.off + t.rec > 0) await _repo.submit(tap: t.tap, off: t.off, rec: t.rec);
    } catch (e) {
      // Báo hỏng (mạng chập chờn, chưa chạy SQL…) không được che trạng thái boss.
      developer.log('world boss submit: $e', name: 'WorldBoss');
    }
    return _repo.state();
  }

  @override
  Future<WorldBossState> build() => _load();

  /// [silent] giữ dữ liệu cũ trên màn trong lúc tải (poll nền).
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = const AsyncLoading<WorldBossState>();
    final next = await AsyncValue.guard(_load);
    if (!ref.mounted) return; // provider autoDispose khi rời màn trong lúc chờ mạng
    state = next;
  }

  /// Xem quảng cáo thưởng rồi +sát thương (người đã gỡ quảng cáo thì bỏ qua bước xem). Trả: null = người chơi đóng
  /// quảng cáo sớm (không thưởng), ngược lại số lượt còn lại hôm nay. Ném khi server từ chối (hết lượt/lỗi mạng).
  Future<int?> adStrike() async {
    final adFree = ref.read(gameControllerProvider).adFree;
    final outcome = adFree ? RewardOutcome.earned : await ref.read(adServiceProvider).showRewardedAd();
    if (outcome != RewardOutcome.earned) return null;
    final left = await _repo.adStrike();
    await refresh(silent: true);
    return left;
  }

  /// Nhận mốc [phase] của boss NGÀY: server OK rồi mới cấp Xu (giây thu nhập) + 💎. Trả (💎, Xu).
  Future<(int, double)> claimDay(int phase) async {
    final gems = await _repo.claimDay(phase);
    final xu = ref
        .read(gameControllerProvider.notifier)
        .grantBossDayReward(gems: gems, seconds: worldBossDayPhaseSeconds[phase - 1]);
    await refresh(silent: true);
    return (gems, xu);
  }

  /// Mua Tự động đánh bằng 💎: server bật TRƯỚC, rồi mới trừ 💎 cục bộ (đã bật từ trước thì không trừ).
  /// Trả false nếu không đủ 💎 (chưa gọi server); ném khi lỗi mạng/server.
  Future<bool> buyAuto() async {
    final ctl = ref.read(gameControllerProvider.notifier);
    if (ref.read(gameControllerProvider).gems < worldBossAutoGems) return false;
    final fresh = await _repo.buyAuto();
    if (fresh) ctl.spendGems(worldBossAutoGems);
    await refresh(silent: true);
    return true;
  }

  /// Nhận mốc [phase]; trả (💎, có rương, món rơi) — server OK TRƯỚC rồi mới cấp cục bộ. Ném khi lỗi.
  Future<int> claim(int phase) async {
    final r = await _repo.claim(phase);
    final ctl = ref.read(gameControllerProvider.notifier);
    ctl.grantDungeonReward(gems: r.gems, chest: r.chest);
    ctl.grantBossDayReward(gems: 0, seconds: worldBossPhaseSeconds[phase - 1]);
    await refresh(silent: true);
    return r.gems;
  }
}

final worldBossControllerProvider =
    AsyncNotifierProvider.autoDispose<WorldBossController, WorldBossState>(WorldBossController.new);

/// Số mốc nhận được ngay (chấm đỏ ở menu Cạnh tranh); 0 nếu chưa liên kết email hoặc lỗi mạng.
final worldBossAlertProvider = FutureProvider<int>((ref) async {
  if (ref.watch(cloudSaveControllerProvider) is! CloudSaveLinked) return 0;
  try {
    return (await ref.read(worldBossRepositoryProvider).state()).claimableCount;
  } catch (_) {
    return 0;
  }
});
