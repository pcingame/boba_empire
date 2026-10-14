import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart' show reduceMotion;

/// Lắc ngang (~360ms, tắt dần) mỗi lần [trigger] TĂNG — báo "chưa đúng" cho lựa chọn sai. Hữu hạn nên
/// không ép vẽ khung khi đứng yên; tôn trọng [reduceMotion] (Tắt hiệu ứng / giảm chuyển động / test).
class ShakeOnTrigger extends StatefulWidget {
  const ShakeOnTrigger({super.key, required this.trigger, required this.child, this.distance = 8});

  final int trigger;
  final Widget child;

  /// Biên độ lắc tối đa (dp).
  final double distance;

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 360));

  @override
  void didUpdateWidget(ShakeOnTrigger old) {
    super.didUpdateWidget(old);
    if (widget.trigger > old.trigger && !reduceMotion) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // 3 chu kỳ sin, biên độ giảm dần về 0 khi kết thúc.
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * widget.distance * (1 - t);
        return Transform.translate(key: const Key('shake-transform'), offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Số nguyên đếm lên tới [value] (lần dựng đầu chạy từ 0) rồi dừng; tắt hiệu ứng thì hiện luôn giá trị cuối.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder, this.duration = const Duration(milliseconds: 700)});

  final int value;
  final Widget Function(BuildContext context, int current) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? value.toDouble() : 0, end: value.toDouble()),
      duration: reduceMotion ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}

/// Thanh tiến độ chạy mượt tới [value] (0..1); lần dựng đầu hiện ngay (không chạy từ 0 mỗi lần mở màn).
class SmoothBar extends StatelessWidget {
  const SmoothBar({super.key, required this.value, this.minHeight = 10, this.radius = 6});

  final double value;
  final double minHeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: value, end: value),
        // `begin == end` ở lần dựng đầu → hiện ngay; khi `value` đổi Tween tự chạy từ giá trị đang hiển thị.
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: minHeight),
      ),
    );
  }
}
