/// Các provider Riverpod cho tầng state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_service.dart';
import '../data/game_storage.dart';
import 'game_controller.dart';
import 'game_snapshot.dart';

/// Bơm instance SharedPreferences đã khởi tạo. Phải override trong `main()`
/// (và trong test) — mặc định ném lỗi để không ai quên.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

/// Nguồn thời gian (epoch ms). Tách ra để test bơm được thời gian cố định.
final clockProvider = Provider<int Function()>(
  (ref) => () => DateTime.now().millisecondsSinceEpoch,
);

final gameStorageProvider = Provider<GameStorage>(
  (ref) => GameStorage(ref.watch(sharedPreferencesProvider)),
);

final gameControllerProvider =
    NotifierProvider<GameController, GameSnapshot>(GameController.new);

/// Bật/tắt âm thanh (SFX), lưu bền qua SharedPreferences. Đồng bộ cờ toàn cục
/// [audioMuted] để tầng phát biết mà im.
final soundOnProvider =
    NotifierProvider<SoundNotifier, bool>(SoundNotifier.new);

class SoundNotifier extends Notifier<bool> {
  static const _key = 'sound_on';

  @override
  bool build() {
    final on = ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;
    audioMuted = !on;
    return on;
  }

  Future<void> toggle() async {
    final on = !state;
    await ref.read(sharedPreferencesProvider).setBool(_key, on);
    audioMuted = !on;
    state = on;
  }
}
