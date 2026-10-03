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

/// userId -> emoji ('' = không có huy hiệu / chưa tải được).
final flairCacheProvider = NotifierProvider<FlairCache, Map<String, String>>(
  FlairCache.new,
);

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
    try {
      final rows = await Supabase.instance.client.rpc(
        'accessory_flairs',
        params: {'p_user_ids': ids},
      );
      for (final r in rows as List) {
        final emoji = flairEmoji((r as Map)['accessory_id']);
        if (emoji != null) found[r['user_id'] as String] = emoji;
      }
    } catch (_) {
      // Không có mạng/Supabase: hiện như chưa có huy hiệu, không thử lại ồ ạt.
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
    if (emoji == null) {
      Future.microtask(
        () => ref.read(flairCacheProvider.notifier).ensure(userId),
      );
    }
    if (emoji == null || emoji.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(emoji, key: const Key('flair-badge')),
    );
  }
}
