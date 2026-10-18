/// Avatar ảnh của người chơi (supabase/player_avatar_schema.sql): chọn ảnh → nén nhỏ → tải lên bucket công khai
/// 'avatars' → người khác thấy qua `player_avatar(tên)`. Khoá ảnh của mình lưu máy (prefs) để hiện ngay.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/game_providers.dart';

const _prefsKey = 'profile_avatar_key';
const avatarMaxBytes = 100 * 1024; // khớp file_size_limit của bucket
const avatarMaxSide = 256.0;

/// Chọn ảnh từ thư viện, đã thu nhỏ + nén JPEG. null = người dùng huỷ. Tách để test thay bằng bản giả.
typedef AvatarPicker = Future<Uint8List?> Function();

final avatarPickerProvider = Provider<AvatarPicker>((_) => () async {
      final f = await ImagePicker().pickImage(
          source: ImageSource.gallery, maxWidth: avatarMaxSide, maxHeight: avatarMaxSide, imageQuality: 80);
      return f?.readAsBytes();
    });

/// Truy cập server cho avatar; tách để test.
abstract class AvatarRepository {
  /// Cấp khoá mới, tải [bytes] lên, xoá ảnh cũ; trả khoá mới.
  Future<String> upload(Uint8List bytes);
  Future<void> clear();
  Future<String> keyFor(String nickname);
  String urlFor(String key);

  /// Báo cáo ảnh của người tên [nickname]; true nếu ảnh vừa bị tự ẩn do đủ báo cáo.
  Future<bool> report(String nickname);
}

class SupabaseAvatarRepository implements AvatarRepository {
  SupabaseClient get _c => Supabase.instance.client;
  StorageFileApi get _bucket => _c.storage.from('avatars');

  @override
  Future<String> upload(Uint8List bytes) async {
    final r = await _c.rpc('new_avatar_key') as Map;
    final key = r['key'] as String;
    await _bucket.uploadBinary('$key.jpg', bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    final old = r['old'];
    if (old is String) {
      try {
        await _bucket.remove(['$old.jpg']);
      } catch (_) {} // mồ côi vài KB, không đáng làm hỏng lần đổi ảnh
    }
    return key;
  }

  @override
  Future<void> clear() async {
    final old = await _c.rpc('clear_avatar');
    if (old is String) {
      try {
        await _bucket.remove(['$old.jpg']);
      } catch (_) {}
    }
  }

  @override
  Future<String> keyFor(String nickname) async {
    final r = await _c.rpc('player_avatar', params: {'p_nickname': nickname});
    return r is String ? r : '';
  }

  @override
  String urlFor(String key) => _bucket.getPublicUrl('$key.jpg');

  @override
  Future<bool> report(String nickname) async =>
      await _c.rpc('report_avatar', params: {'p_nickname': nickname}) == true;
}

final avatarRepositoryProvider = Provider<AvatarRepository>((_) => SupabaseAvatarRepository());

class AvatarTooBig implements Exception {}

/// Khoá avatar của mình ('' = chưa có).
class MyAvatar extends Notifier<String> {
  @override
  String build() => ref.read(sharedPreferencesProvider).getString(_prefsKey) ?? '';

  /// Chọn + tải ảnh mới. Trả false nếu người dùng huỷ; ném lỗi (mạng, chưa liên kết, ảnh quá lớn) để UI báo.
  Future<bool> change() async {
    final bytes = await ref.read(avatarPickerProvider)();
    if (bytes == null) return false;
    if (bytes.length > avatarMaxBytes) throw AvatarTooBig();
    final key = await ref.read(avatarRepositoryProvider).upload(bytes);
    await _set(key);
    return true;
  }

  Future<void> remove() async {
    await ref.read(avatarRepositoryProvider).clear();
    await _set('');
  }

  Future<void> _set(String key) async {
    state = key;
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, key);
  }
}

final myAvatarProvider = NotifierProvider<MyAvatar, String>(MyAvatar.new);

/// Khoá avatar công khai của [nickname]; lỗi/chưa có SQL → ''.
final playerAvatarProvider = FutureProvider.autoDispose.family<String, String>((ref, nickname) async {
  try {
    return await ref.read(avatarRepositoryProvider).keyFor(nickname);
  } catch (_) {
    return '';
  }
});
