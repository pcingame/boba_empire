/// Bản AudioService thật dùng flame_audio. Chỉ `main()` import file này để giữ
/// phụ thuộc plugin ở rìa (tầng UI/test chỉ biết [AudioService]).
library;

import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'audio_service.dart';

class FlameAudioService implements AudioService {
  FlameAudioService();

  /// Mỗi SFX một [AudioPool] tái dùng sẵn player → click/mua dồn dập không phải
  /// tạo/huỷ player liên tục (nguồn gây lag) và lần phát đầu không giật.
  final Map<Sfx, AudioPool> _pools = {};

  /// Gộp burst click cùng loại (>16 lần/giây) → tránh tiếng chồng thành ồn.
  final SfxGate _gate = SfxGate(minGapMs: 60);

  /// Số player tối đa mỗi SFX: tiếng bắn nhanh (tap/buy) cần vài player để chồng
  /// lớp mượt; tiếng dài/ít lặp thì ít.
  int _maxPlayers(Sfx s) => switch (s) {
    Sfx.tap || Sfx.buy => 4,
    _ => 2,
  };

  /// Tạo trước pool cho mọi SFX. Thiếu file thì bỏ qua — âm thanh chỉ trang trí,
  /// không được làm sập game (giống hiệu ứng Lottie).
  Future<void> preload() async {
    for (final s in Sfx.values) {
      try {
        _pools[s] = await FlameAudio.createPool(
          s.file,
          maxPlayers: _maxPlayers(s),
        );
      } catch (_) {
        // Chưa thả file vào assets/audio/ hoặc không có plugin — kệ, play() no-op.
      }
    }
  }

  @override
  void play(Sfx sfx) {
    if (audioMuted) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    if (!_gate.allow(sfx, DateTime.now().millisecondsSinceEpoch)) return;
    unawaited(_safeStart(pool));
  }

  Future<void> _safeStart(AudioPool pool) async {
    try {
      await pool.start();
    } catch (_) {
      // Lỗi phát (thiếu asset lúc runtime…) — bỏ qua.
    }
  }
}
