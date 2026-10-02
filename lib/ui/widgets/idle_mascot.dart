import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Nhân vật "sống" (Lottie + nhún nhẹ) chạy ở 30 khung/giây bằng [Timer] thay vì
/// ticker vsync 60Hz.
///
/// Vì sao: một animation lặp vô hạn trên ticker ép Flutter nộp khung MỖI vsync,
/// và mỗi khung GPU phải vẽ lại toàn bộ màn chính (~8ms trên Android tầm trung) —
/// tức ~50% GPU liên tục, kể cả khi người chơi chỉ nhìn. Ở 30Hz tải GPU/pin giảm
/// một nửa; chuyển động của một con cốc 72dp gần như không khác mắt thường. Không
/// có ticker nào chạy → khi [animate] = false màn chính HOÀN TOÀN yên (0 khung).
///
/// Thiếu file Lottie thì về [emoji] (giống `Mascot`).
class IdleMascot extends StatefulWidget {
  const IdleMascot({
    super.key,
    required this.asset,
    required this.emoji,
    this.size = 72,
    this.animate = true,
  });

  final String asset;
  final String emoji;
  final double size;

  /// false (test / người dùng bật "giảm chuyển động"): đứng yên ở khung đầu.
  final bool animate;

  @override
  State<IdleMascot> createState() => _IdleMascotState();
}

class _IdleMascotState extends State<IdleMascot>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _stepMs = 33; // ~30Hz
  static const _bobSeconds = 1.4; // chu kỳ nhún (đi + về)
  static const _bobPixels = 7.0;

  // KHÔNG forward()/repeat(): controller không có ticker chạy → không ép khung vsync.
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _timer;
  double _t = 0; // giây
  double _loopSeconds = 2.4; // cập nhật theo độ dài thật của file Lottie

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(IdleMascot old) {
    super.didUpdateWidget(old);
    if (widget.animate != old.animate) {
      widget.animate ? _start() : _stop();
    }
  }

  void _start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: _stepMs), (_) {
      _t += _stepMs / 1000.0;
      _c.value = (_t % _loopSeconds) / _loopSeconds;
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  // Ra nền thì dừng hẳn (không đốt pin vô ích); quay lại thì chạy tiếp.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.animate) return;
    state == AppLifecycleState.resumed ? _start() : _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lottie = Lottie.asset(
      widget.asset,
      controller: _c,
      fit: BoxFit.contain,
      onLoaded: (composition) =>
          _loopSeconds = composition.duration.inMilliseconds / 1000.0,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.size * 0.7)),
      ),
    );
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // Tam giác 0→1→0 theo chu kỳ nhún, làm mượt bằng easeInOut.
          final u = (_t / _bobSeconds) % 2;
          final bob = Curves.easeInOut.transform(u <= 1 ? u : 2 - u);
          return Transform.translate(
            offset: Offset(0, -_bobPixels * bob),
            child: child,
          );
        },
        child: lottie,
      ),
    );
  }
}
