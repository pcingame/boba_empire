import 'dart:async';

import 'package:flutter/widgets.dart';

import 'effects_quality.dart';

/// Nhịp chung cho mọi animation trang trí chạy theo timer (thay cho mỗi widget một ticker 60Hz).
///
/// - Chu kỳ theo [EffectsQuality.tickMs]: cao/vừa 30Hz, thấp 15Hz, tắt = KHÔNG timer nào.
/// - Không có người nghe, hoặc app ra nền → timer dừng hẳn (0 khung).
/// - Mọi người nghe chung một timer nên chi phí không nhân theo số widget.
class AmbientTicker with WidgetsBindingObserver {
  AmbientTicker._();
  static final instance = AmbientTicker._();

  final _subs = <void Function(double dt)>[];
  Timer? _timer;
  int _timerMs = 0;
  bool _resumed = true;
  bool _hooked = false;

  /// Đăng ký nghe; [cb] nhận số giây của một nhịp (chu kỳ danh định của mức hiện hành). Gọi hàm trả về để huỷ.
  VoidCallback subscribe(void Function(double dt) cb) {
    if (!_hooked) {
      _hooked = true;
      WidgetsBinding.instance.addObserver(this);
      EffectsController.instance.quality.addListener(_sync);
    }
    _subs.add(cb);
    _sync();
    return () {
      _subs.remove(cb);
      _sync();
    };
  }

  /// Đang có timer chạy không (test).
  bool get running => _timer != null;

  void _sync() {
    final ms = EffectsController.instance.quality.value.tickMs;
    final want = _subs.isNotEmpty && _resumed && ms > 0;
    if (!want) {
      _timer?.cancel();
      _timer = null;
      _timerMs = 0;
      return;
    }
    if (_timer != null && _timerMs == ms) return;
    _timer?.cancel();
    _timerMs = ms;
    _timer = Timer.periodic(Duration(milliseconds: ms), (_) => _tick());
  }

  void _tick() {
    // dt danh định (không đo đồng hồ): chuyển động trang trí chỉ chậm nhẹ khi máy trễ nhịp, và
    // không vọt khi vừa tiếp tục sau lúc ra nền.
    final dt = _timerMs / 1000.0;
    for (final cb in List.of(_subs)) {
      cb(dt);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }
}
