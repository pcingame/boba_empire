/// Chữ một dòng: vừa khung thì hiện bình thường; dài quá thì tự chạy qua lại
/// để đọc hết (thay cho dấu "…"). Dừng hẳn khi bị hộp thoại/trang khác phủ lên
/// (không đốt khung hình vô ích — cùng lý do với idle_mascot.dart) hoặc khi
/// người dùng tắt animation (khi đó rơi về "…").
library;

import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  /// Tốc độ chạy (px/giây).
  static const _pixelsPerSecond = 35.0;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final CurvedAnimation _t = CurvedAnimation(
    parent: _c,
    // Đứng yên 20% đầu/cuối mỗi chiều để kịp đọc.
    curve: const Interval(0.2, 0.8, curve: Curves.linear),
  );
  bool _covered = false;
  double _overflow = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _covered = route != null && !route.isCurrent;
    _sync();
  }

  @override
  void didUpdateWidget(MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.style != widget.style) _sync();
  }

  void _sync() {
    final animate =
        _overflow > 0 &&
        !_covered &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (!animate) {
      _c.stop();
      return;
    }
    if (_c.isAnimating) return;
    _c.duration = Duration(
      milliseconds: (_overflow / MarqueeText._pixelsPerSecond * 1000 / 0.6)
          .round(),
    );
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final overflow = painter.width - constraints.maxWidth;
        final lineHeight = painter.height;
        painter.dispose();
        final newOverflow = overflow > 0.5 ? overflow : 0.0;
        if (newOverflow != _overflow) {
          _overflow = newOverflow;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _sync();
          });
        }
        final noAnimation =
            MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (_overflow == 0 || noAnimation) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return ClipRect(
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, child) => Transform.translate(
              offset: Offset(-_overflow * _t.value, 0),
              child: child,
            ),
            // Cao đúng 1 dòng: OverflowBox mặc định phình theo ràng buộc cha, mà cha
            // (Column…) có thể không giới hạn chiều cao → "infinite size".
            child: SizedBox(
              height: lineHeight,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
