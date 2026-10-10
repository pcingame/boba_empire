/// Huy hiệu phụ kiện cạnh tên trên các bảng xếp hạng. Server chỉ trả huy hiệu
/// mà chủ nhân còn sở hữu (RPC `accessory_flairs`); id lạ (bản app cũ hơn)
/// bị bỏ qua. Mỗi hàng chỉ hỏi cache; các id chưa biết được gom thành MỘT
/// lần gọi RPC.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/accessories.dart';
import '../core/topup.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../state/game_providers.dart';

/// userId -> emoji ('' = không có huy hiệu / chưa tải được).
final flairCacheProvider = NotifierProvider<FlairCache, Map<String, String>>(
  FlairCache.new,
);

/// userId -> cấp VIP (>0) lấy từ cùng lần gọi RPC với huy hiệu phụ kiện; người
/// không có cấp VIP không có khoá. Ghi bởi [FlairCache], không có logic riêng.
final vipLevelProvider = NotifierProvider<VipLevels, Map<String, int>>(
  VipLevels.new,
);

class VipLevels extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void merge(Map<String, int> found) => state = {...state, ...found};
}

/// userId -> VIP ≥ cấp 5 đang hiện diện (ping trong 5 phút gần nhất). Ghi bởi
/// [FlairCache] cùng lần gọi RPC; người không có khoá = không online.
final vipOnlineProvider = NotifierProvider<VipOnline, Map<String, bool>>(
  VipOnline.new,
);

class VipOnline extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void merge(Map<String, bool> found) => state = {...state, ...found};
}

class FlairCache extends Notifier<Map<String, String>> {
  /// Hiện diện đổi theo phút nên thông tin đã tải được coi là cũ sau chừng này.
  static const _ttl = Duration(minutes: 2);
  final _fetchedAt = <String, DateTime>{};
  final _pending = <String>{};
  Timer? _timer;

  @override
  Map<String, String> build() {
    ref.onDispose(() => _timer?.cancel());
    return const {};
  }

  /// Xếp [userId] vào hàng đợi nếu chưa biết; gọi trong build() là an toàn.
  void ensure(String userId) {
    // Chưa từng tải (do seed/test) → coi là mới; đã tải mà cũ → tải lại để cập nhật online.
    final at = _fetchedAt[userId];
    final fresh = at == null || DateTime.now().difference(at) < _ttl;
    if ((state.containsKey(userId) && fresh) || !_pending.add(userId)) return;
    _timer ??= Timer(const Duration(milliseconds: 50), _flush);
  }

  /// Quên một người (vd sau khi tự đổi huy hiệu) rồi tải lại.
  void invalidate(String userId) {
    state = {...state}..remove(userId);
    ensure(userId);
  }

  /// Huy hiệu đang hiển thị của chính mình có đúng [emoji] không.
  bool isMine(String emoji) {
    try {
      final id = Supabase.instance.client.auth.currentUser?.id;
      return id != null && state[id] == emoji;
    } catch (_) {
      return false; // Supabase chưa khởi tạo
    }
  }

  /// Báo VIP EXP của chính mình lên server: (1) cấp VIP để hiện huy hiệu cạnh tên ở
  /// các bảng xếp hạng/Hội; (2) nếu đã đặt biệt danh (dùng chung với mọi BXH) thì
  /// cập nhật hàng của mình ở bảng xếp hạng VIP trên web. Server chỉ cho số TĂNG;
  /// nuốt mọi lỗi (mạng/Supabase chưa khởi tạo) vì chỉ là huy hiệu/xếp hạng.
  Future<void> reportVip(int exp) async {
    final level = topupVipLevel(exp);
    if (level <= 0) return;
    try {
      final client = Supabase.instance.client;
      final user =
          client.auth.currentUser ??
          (await client.auth.signInAnonymously()).user;
      await client.rpc('set_vip_level', params: {'p_level': level});
      final nickname = ref
          .read(sharedPreferencesProvider)
          .getString('leaderboard_nickname');
      if (nickname != null && nickname.isNotEmpty) {
        await client.rpc(
          'submit_vip_exp',
          params: {'p_nickname': nickname, 'p_exp': exp},
        );
      }
      if (user != null) invalidate(user.id);
    } catch (_) {}
  }

  /// Đặt (hoặc gỡ với null) huy hiệu của chính mình; true nếu server nhận.
  Future<bool> setMine(String? accessoryId) async {
    try {
      final client = Supabase.instance.client;
      final user =
          client.auth.currentUser ??
          (await client.auth.signInAnonymously()).user;
      await client.rpc(
        'set_accessory_flair',
        params: {'p_accessory_id': accessoryId},
      );
      if (user != null) invalidate(user.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _flush() async {
    _timer = null;
    final ids = _pending.take(100).toList();
    _pending.removeAll(ids);
    final found = <String, String>{};
    final vips = <String, int>{};
    final online = <String, bool>{};
    try {
      final rows = await Supabase.instance.client.rpc(
        'accessory_flairs',
        params: {'p_user_ids': ids},
      );
      for (final r in rows as List) {
        final emoji = flairEmoji((r as Map)['accessory_id']);
        if (emoji != null) found[r['user_id'] as String] = emoji;
        final vip = r['vip_level'];
        if (vip is num && vip > 0) vips[r['user_id'] as String] = vip.toInt();
        if (r['online'] == true) online[r['user_id'] as String] = true;
      }
    } catch (_) {
      // Không có mạng/Supabase: hiện như chưa có huy hiệu, không thử lại ồ ạt.
    }
    ref.read(vipLevelProvider.notifier).merge(vips);
    ref.read(vipOnlineProvider.notifier).merge({
      for (final id in ids) id: online[id] ?? false,
    });
    final now = DateTime.now();
    for (final id in ids) {
      _fetchedAt[id] = now;
    }
    state = {...state, for (final id in ids) id: found[id] ?? ''};
    if (_pending.isNotEmpty) _timer = Timer(Duration.zero, _flush);
  }
}

/// Emoji của phụ kiện [id]; null nếu không phải String hoặc không có trong
/// danh mục (tránh `accessoryById` ném StateError).
String? flairEmoji(Object? id) {
  if (id is! String) return null;
  for (final a in accessories) {
    if (a.id == id) return a.emoji;
  }
  return null;
}

/// Emoji huy hiệu của [userId], hoặc không chiếm chỗ nếu không có.
class FlairBadge extends ConsumerWidget {
  const FlairBadge({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emoji = ref.watch(flairCacheProvider.select((m) => m[userId]));
    // Luôn hỏi cache: chưa có thì xếp hàng tải, có rồi mà cũ (hiện diện đổi theo
    // phút) thì tải lại. ensure() thoát sớm nếu còn mới nên rẻ.
    Future.microtask(() {
      // Widget có thể đã bị gỡ trước khi microtask chạy → ref đã dispose.
      if (context.mounted) {
        ref.read(flairCacheProvider.notifier).ensure(userId);
      }
    });
    final vip = ref.watch(vipLevelProvider.select((m) => m[userId])) ?? 0;
    final online =
        ref.watch(vipOnlineProvider.select((m) => m[userId] ?? false));
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    if (!hasEmoji && vip <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (online) const _OnlineDot(),
          if (vip > 0) VipTag(level: vip, key: const Key('vip-badge')),
          if (vip > 0 && hasEmoji) const SizedBox(width: 3),
          if (hasEmoji) Text(emoji, key: const Key('flair-badge')),
        ],
      ),
    );
  }
}

/// Màu nhãn VIP theo cấp 1..10 (đồng → bạc → vàng → xanh lá → xanh dương → tím → hồng →
/// cam; cấp 9 và 10 là dải màu). Hai màu bằng nhau = màu đặc. Ngoài khoảng thì kẹp.
const List<List<Color>> vipTagColors = [
  [Color(0xFFC08A5A), Color(0xFFC08A5A)], // 1 đồng
  [Color(0xFFB0BEC5), Color(0xFFB0BEC5)], // 2 bạc
  [Color(0xFFE0A868), Color(0xFFE0A868)], // 3 vàng
  [Color(0xFF66BB6A), Color(0xFF66BB6A)], // 4 xanh lá
  [Color(0xFF42A5F5), Color(0xFF42A5F5)], // 5 xanh dương
  [Color(0xFFAB47BC), Color(0xFFAB47BC)], // 6 tím
  [Color(0xFFEC407A), Color(0xFFEC407A)], // 7 hồng
  [Color(0xFFFF7043), Color(0xFFFF7043)], // 8 cam
  [Color(0xFF5E35B1), Color(0xFFD81B60)], // 9 tím → hồng (đậm cho chữ trắng đọc rõ)
  [Color(0xFFFFC107), Color(0xFFF4511E)], // 10 vàng → cam đỏ
];

/// Nhãn "VIP n" nhỏ, màu theo cấp ([vipTagColors]) — dùng ở bảng xếp hạng/Hội và màn
/// Mốc nạp.
class VipTag extends StatelessWidget {
  const VipTag({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final colors = vipTagColors[(level - 1).clamp(0, vipTagColors.length - 1)];
    // Chọn chữ tối hoặc trắng — bên nào tương phản hơn với CẢ HAI đầu dải màu.
    const dark = Color(0xFF24160A);
    double worst(Color fg) => colors
        .map((c) => _contrast(fg, c))
        .reduce((a, b) => a < b ? a : b);
    final fg = worst(dark) >= worst(Colors.white) ? dark : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'VIP $level',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Tỉ lệ tương phản WCAG giữa hai màu.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Chấm xanh "đang online" của VIP ≥ cấp 5.
class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('vip-online-dot'),
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(right: 4),
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D32),
          shape: BoxShape.circle,
        ),
      );
}

/// Dòng danh hiệu (biệt danh cấp VIP) dưới tên người chơi — chỉ từ cấp
/// [vipTitleMinLevel], còn lại không chiếm chỗ.
class VipTitleLine extends ConsumerWidget {
  const VipTitleLine({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(vipLevelProvider.select((m) => m[userId])) ?? 0;
    if (level < vipTitleMinLevel) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      '👑 ${vipName(AppLocalizations.of(context)!, level)}',
      key: const Key('vip-title-line'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        // Cùng cặp màu với danh hiệu top 20 Sưu tập (đủ tương phản sáng/tối).
        color: theme.brightness == Brightness.light
            ? const Color(0xFF9A5B00)
            : const Color(0xFFFFA726),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Khối tên của một hàng bảng xếp hạng: [child] (hàng huy hiệu + tên) và dưới nó là
/// dòng danh hiệu VIP nếu có.
class VipNameBlock extends StatelessWidget {
  const VipNameBlock({super.key, required this.userId, required this.child});
  final String userId;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [child, VipTitleLine(userId: userId)],
      );
}
