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

class FlairCache extends Notifier<Map<String, String>> {
  final _pending = <String>{};
  Timer? _timer;

  @override
  Map<String, String> build() {
    ref.onDispose(() => _timer?.cancel());
    return const {};
  }

  /// Xếp [userId] vào hàng đợi nếu chưa biết; gọi trong build() là an toàn.
  void ensure(String userId) {
    if (state.containsKey(userId) || !_pending.add(userId)) return;
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
      }
    } catch (_) {
      // Không có mạng/Supabase: hiện như chưa có huy hiệu, không thử lại ồ ạt.
    }
    ref.read(vipLevelProvider.notifier).merge(vips);
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
    if (emoji == null) {
      Future.microtask(() {
        // Widget có thể đã bị gỡ trước khi microtask chạy → ref đã dispose.
        if (context.mounted) {
          ref.read(flairCacheProvider.notifier).ensure(userId);
        }
      });
    }
    final vip = ref.watch(vipLevelProvider.select((m) => m[userId])) ?? 0;
    final hasEmoji = emoji != null && emoji.isNotEmpty;
    if (!hasEmoji && vip <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vip > 0) VipTag(level: vip, key: const Key('vip-badge')),
          if (vip > 0 && hasEmoji) const SizedBox(width: 3),
          if (hasEmoji) Text(emoji, key: const Key('flair-badge')),
        ],
      ),
    );
  }
}

/// Nhãn "VIP n" nhỏ, màu vàng — dùng ở bảng xếp hạng/Hội và màn Mốc nạp.
class VipTag extends StatelessWidget {
  const VipTag({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFE0A868),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'VIP $level',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF24160A),
            height: 1.2,
          ),
        ),
      );
}
