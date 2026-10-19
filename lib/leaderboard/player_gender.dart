/// Giới tính hồ sơ (tuỳ chọn): lưu máy, đẩy lên server để người khác thấy ở hồ sơ công khai.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';

/// Giá trị khớp whitelist `player_gender_schema.sql`.
enum PlayerGender {
  male('♂'),
  female('♀'),
  other('⚧');

  const PlayerGender(this.symbol);
  final String symbol;
}

PlayerGender? playerGenderById(String id) {
  for (final g in PlayerGender.values) {
    if (g.name == id) return g;
  }
  return null;
}

const _prefsKey = 'profile_gender';

class SelectedGender extends Notifier<PlayerGender?> {
  @override
  PlayerGender? build() => playerGenderById(ref.read(sharedPreferencesProvider).getString(_prefsKey) ?? '');

  /// Chọn ([g] null = bỏ). Lưu máy trước; đẩy server là phần thêm nên lỗi (mạng, chưa liên kết) bị nuốt.
  Future<void> select(PlayerGender? g) async {
    state = g;
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, g?.name ?? '');
    try {
      await Supabase.instance.client.rpc('set_player_gender', params: {'p_gender': g?.name ?? ''});
    } catch (_) {}
  }
}

final selectedGenderProvider = NotifierProvider<SelectedGender, PlayerGender?>(SelectedGender.new);

/// Giới tính công khai của [nickname]; lỗi/chưa có SQL → null (không làm hỏng hồ sơ).
final playerGenderProvider = FutureProvider.autoDispose.family<PlayerGender?, String>((ref, nickname) async {
  try {
    final r = await Supabase.instance.client.rpc('player_gender', params: {'p_nickname': nickname});
    return r is String ? playerGenderById(r) : null;
  } catch (_) {
    return null;
  }
});
