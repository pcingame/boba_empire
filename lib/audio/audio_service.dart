/// Trừu tượng hoá âm thanh hiệu ứng (SFX).
///
/// Tầng UI chỉ phụ thuộc interface này nên test/chạy được mà không cần asset
/// hay plugin. Mặc định là [SilentAudioService] (không phát gì); `main()`
/// override bằng bản thật dựa trên flame_audio (xem flame_audio_service.dart) —
/// đúng như cách [adServiceProvider] đổi sang Admob thật.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cờ tắt tiếng toàn cục (giống [debugDisableMascotAnimation]). Cài đặt bật/tắt
/// qua [soundOnProvider]; bản thật kiểm cờ này trước khi phát.
bool audioMuted = false;

/// Các hiệu ứng âm thanh trong game. Giá trị = tên file trong `assets/audio/`.
enum Sfx {
  tap('tap.wav'),
  buy('buy.wav'),
  unlock('unlock.wav'),
  prestige('prestige.wav'),
  vip('vip.wav'),
  reward('reward.wav');

  const Sfx(this.file);
  final String file;
}

abstract interface class AudioService {
  /// Phát một SFX (fire-and-forget). Không được ném lỗi.
  void play(Sfx sfx);
}

/// Gộp các lần phát CÙNG một SFX quá gần nhau (click/mua dồn dập) để tránh tiếng
/// chồng thành ồn và giảm tải. Thuần logic (không plugin) nên test được.
class SfxGate {
  SfxGate({required this.minGapMs});

  /// Khoảng cách tối thiểu (ms) giữa 2 lần phát cùng một SFX.
  final int minGapMs;
  final Map<Sfx, int> _lastMs = {};

  /// Cho phép phát [sfx] tại thời điểm [nowMs] không? Nếu có thì ghi lại mốc.
  bool allow(Sfx sfx, int nowMs) {
    if (nowMs - (_lastMs[sfx] ?? (nowMs - minGapMs)) < minGapMs) return false;
    _lastMs[sfx] = nowMs;
    return true;
  }
}

/// Không phát gì — an toàn ở test và làm mặc định khi chưa gắn bản thật.
class SilentAudioService implements AudioService {
  const SilentAudioService();

  @override
  void play(Sfx sfx) {}
}

/// Mặc định im lặng; override trong `main()` bằng FlameAudioService.
final audioServiceProvider =
    Provider<AudioService>((ref) => const SilentAudioService());
