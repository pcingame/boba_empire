/// Danh hiệu hồ sơ đang chọn (lưu máy, đẩy lên server để người khác thấy) và tra danh hiệu của người khác.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/titles.dart';
import '../state/game_providers.dart';

const _prefsKey = 'profile_title';

class SelectedTitle extends Notifier<String> {
  @override
  String build() {
    final id = ref.read(sharedPreferencesProvider).getString(_prefsKey) ?? '';
    return playerTitleById(id) == null ? '' : id;
  }

  /// Chọn ([id] rỗng = bỏ). Lưu máy trước; đẩy server là phần thêm nên lỗi (mạng, chưa liên kết) bị nuốt.
  Future<void> select(String id) async {
    state = id;
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, id);
    try {
      await Supabase.instance.client.rpc('set_player_title', params: {'p_id': id});
    } catch (_) {}
  }
}

final selectedTitleProvider = NotifierProvider<SelectedTitle, String>(SelectedTitle.new);

/// Danh hiệu công khai của [nickname]; lỗi/chưa có SQL → '' (không làm hỏng hồ sơ).
final playerTitleProvider = FutureProvider.autoDispose.family<String, String>((ref, nickname) async {
  try {
    final r = await Supabase.instance.client.rpc('player_title', params: {'p_nickname': nickname});
    return r is String && playerTitleById(r) != null ? r : '';
  } catch (_) {
    return '';
  }
});
