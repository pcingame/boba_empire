import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mức chất lượng hiệu ứng động: MỌI animation trang trí đọc mức này thay vì tự quyết.
/// Thứ tự tăng dần theo chất lượng (index dùng để lưu và để "hạ một mức").
enum EffectsQuality {
  off,
  low,
  medium,
  high;

  /// Chu kỳ ticker chung (ms); 0 = không có ticker nào chạy (màn hoàn toàn yên).
  int get tickMs => switch (this) { off => 0, low => 66, medium => 33, high => 33 };

  /// Số hạt trang trí tối đa cùng lúc trên một cảnh.
  int get particleBudget => switch (this) { off => 0, low => 6, medium => 14, high => 24 };

  EffectsQuality? get lower => index == 0 ? null : EffectsQuality.values[index - 1];
}

/// Lựa chọn của người chơi ở Cài đặt; [auto] = theo mức tự đo.
enum EffectsPref {
  auto,
  high,
  medium,
  low,
  off;

  EffectsQuality? get fixed => switch (this) {
        auto => null,
        high => EffectsQuality.high,
        medium => EffectsQuality.medium,
        low => EffectsQuality.low,
        off => EffectsQuality.off,
      };
}

/// Đánh giá khung hình để biết máy có đuối không (thuần, test được). Bỏ [warmup] khung đầu
/// (nạp tài nguyên) và khung dài bất thường (quay lại từ nền); mỗi [window] khung mà tỉ lệ khung
/// chậm vượt [slowRatio] thì báo nên hạ một mức.
class FrameTuner {
  FrameTuner({
    this.warmup = 180,
    this.window = 120,
    this.slowMs = 20.0,
    this.hitchMs = 250.0,
    this.slowRatio = 0.15,
  });

  final int warmup;
  final int window;
  final double slowMs;
  final double hitchMs;
  final double slowRatio;
  int _seen = 0, _n = 0, _slow = 0;

  /// Nhận thời gian một khung (ms, dựng + raster). true = nên hạ mức.
  bool add(double ms) {
    if (ms >= hitchMs) return false;
    if (_seen < warmup) {
      _seen++;
      return false;
    }
    _n++;
    if (ms > slowMs) _slow++;
    if (_n < window) return false;
    final drop = _slow / _n > slowRatio;
    _n = 0;
    _slow = 0;
    return drop;
  }

  void reset() => _seen = _n = _slow = 0;
}

/// Mức chất lượng hiện hành + lưu lựa chọn + tự hạ khi máy đuối. Singleton vì widget trang trí
/// (không phải widget Riverpod) cũng cần đọc.
///
/// Điểm xuất phát do `detectDeviceTier` (RAM/đời máy) cung cấp; không đọc được thì iOS=cao,
/// Android=vừa. Sau đó CHỈ hạ theo đo thực tế, không bao giờ tự nâng.
class EffectsController {
  EffectsController._();
  static final instance = EffectsController._();

  static const prefKey = 'fx_pref';
  static const autoKey = 'fx_auto';

  /// Mức đang hiệu lực (đã gồm lựa chọn người chơi); lắng nghe để đổi theo.
  final ValueNotifier<EffectsQuality> quality = ValueNotifier(EffectsQuality.medium);

  /// Báo mỗi lần tự hạ (từ → xuống) — nối analytics.
  void Function(EffectsQuality from, EffectsQuality to)? onAutoDrop;

  SharedPreferences? _prefs;
  EffectsPref _pref = EffectsPref.auto;
  EffectsQuality _auto = EffectsQuality.medium;
  final FrameTuner _tuner = FrameTuner();
  bool _listening = false;

  EffectsPref get pref => _pref;
  EffectsQuality get autoLevel => _auto;

  /// Đọc cài đặt đã lưu và (trên máy thật) bắt đầu theo dõi khung hình.
  void init(SharedPreferences prefs, {EffectsQuality? platformStart, bool listenFrames = true}) {
    _prefs = prefs;
    final start = platformStart ?? _platformStart();
    _pref = _readEnum(EffectsPref.values, prefs.getInt(prefKey)) ?? EffectsPref.auto;
    // Mức đã tự hạ từ trước vẫn được giữ; cấu hình máy chỉ có thể kéo xuống thêm, không nâng lên.
    final stored = _readEnum(EffectsQuality.values, prefs.getInt(autoKey));
    _auto = stored == null || stored.index > start.index ? start : stored;
    _apply();
    if (listenFrames && !_listening) {
      _listening = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
  }

  static EffectsQuality _platformStart() {
    if (kIsWeb) return EffectsQuality.medium;
    return Platform.isIOS ? EffectsQuality.high : EffectsQuality.medium;
  }

  static T? _readEnum<T>(List<T> values, int? i) =>
      i != null && i >= 0 && i < values.length ? values[i] : null;

  Future<void> setPref(EffectsPref p) async {
    _pref = p;
    _tuner.reset();
    _apply();
    await _prefs?.setInt(prefKey, p.index);
  }

  void _apply() => quality.value = _pref.fixed ?? _auto;

  void _onTimings(List<FrameTiming> timings) {
    if (_pref != EffectsPref.auto) return;
    for (final t in timings) {
      if (_tuner.add(t.totalSpan.inMicroseconds / 1000.0)) {
        dropAuto();
        return;
      }
    }
  }

  /// Hạ mức tự động một bậc (không xuống Tắt — Tắt là quyền của người chơi).
  @visibleForTesting
  void dropAuto() {
    final lower = _auto.lower;
    if (lower == null || lower == EffectsQuality.off) return;
    final from = _auto;
    _auto = lower;
    _prefs?.setInt(autoKey, lower.index);
    _apply();
    onAutoDrop?.call(from, lower);
  }

  /// Chỉ cho test: đưa về trạng thái ban đầu.
  @visibleForTesting
  void debugReset() {
    _prefs = null;
    _pref = EffectsPref.auto;
    _auto = EffectsQuality.medium;
    _tuner.reset();
    onAutoDrop = null;
    quality.value = EffectsQuality.medium;
  }
}

/// Đang ở mức Tắt (người chơi chọn, hoặc "Tự động" không có gì để chạy).
bool get effectsOff => EffectsController.instance.quality.value == EffectsQuality.off;
