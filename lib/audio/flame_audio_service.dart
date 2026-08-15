/// Bản AudioService thật dùng flame_audio. Chỉ `main()` import file này để giữ
/// phụ thuộc plugin ở rìa (tầng UI/test chỉ biết [AudioService]).
library;

import 'package:flame_audio/flame_audio.dart';

import 'audio_service.dart';

class FlameAudioService implements AudioService {
  FlameAudioService();

  /// Nạp trước các file để lần phát đầu không giật. Thiếu file thì bỏ qua —
  /// âm thanh chỉ trang trí, không được làm sập game (giống hiệu ứng Lottie).
  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll([for (final s in Sfx.values) s.file]);
    } catch (_) {
      // Chưa thả file .mp3 vào assets/audio/ — kệ, play() sẽ tự bỏ qua.
    }
  }

  @override
  void play(Sfx sfx) {
    if (audioMuted) return;
    _safePlay(sfx.file);
  }

  Future<void> _safePlay(String file) async {
    try {
      await FlameAudio.play(file);
    } catch (_) {
      // Thiếu asset / không có plugin — bỏ qua.
    }
  }
}
