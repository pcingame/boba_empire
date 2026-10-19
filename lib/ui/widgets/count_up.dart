import 'package:flutter/material.dart';

import 'motion.dart';

/// Số chạy mượt tới giá trị mới (đổi liên tục vẫn mượt: mỗi lần chạy từ giá trị đang hiện). [builder] dựng chuỗi
/// từ số đang chạy (vd định dạng 1.2K). Tắt khi giảm chuyển động / test (hiện thẳng).
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.builder,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });
  final double value;
  final String Function(double v) builder;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion || !value.isFinite) return Text(builder(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(builder(v), style: style),
    );
  }
}
