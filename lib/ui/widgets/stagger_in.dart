import 'package:flutter/material.dart';

import 'motion.dart';

/// Xuất hiện lần lượt cho dòng bảng xếp hạng/menu: mờ → rõ + trượt nhẹ từ dưới lên, dòng thứ [index] trễ thêm
/// ~45ms (tối đa 12 dòng đầu, các dòng sau hiện ngay để cuộn không bị chậm).
/// Hữu hạn (không ép vẽ khi đứng yên); tôn trọng "giảm chuyển động"/test (hiện thẳng, không animation).
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  static const _dur = 360;
  late final int _delay = (widget.index.clamp(0, 12)) * 45;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _dur + _delay),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(_delay / (_dur + _delay), 1, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    if (!reduceMotion) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 18),
            child: child,
          ),
        );
      },
    );
  }
}
