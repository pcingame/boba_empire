import 'package:flutter/material.dart';

import '../../core/format.dart';

/// Text hiển thị một số lớn (đã format kiểu idle) nhưng chạy mượt tới giá trị
/// mới thay vì nhảy đột ngột.
///
/// Lần dựng đầu hiện NGAY giá trị (không animate) để không làm trễ giá trị khởi
/// tạo; chỉ animate khi [value] đổi. Nếu đổi giữa chừng thì tiếp tục mượt từ
/// giá trị đang hiển thị (đúng cảm giác "đếm đuổi" của game idle).
class AnimatedCount extends StatefulWidget {
  const AnimatedCount(
    this.value, {
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late double _from = widget.value;
  late double _to = widget.value;

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    if (widget.value != _to) {
      _from = _current; // đang hiển thị đâu chạy tiếp từ đó, không giật
      _to = widget.value;
      _controller
        ..stop()
        ..forward(from: 0);
    }
  }

  double get _current =>
      _from + (_to - _from) * Curves.easeOut.transform(_controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Text(
        '${widget.prefix}${formatNumber(_current)}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}
