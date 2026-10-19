import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

int _active = 0;

/// Đợt hạt emoji bung ra từ giữa widget [anchor] (rồi rơi xuống mờ dần) + nhãn nổi lên ("+5 💎", "+1"). Dùng cho
/// khoảnh khắc nhận thưởng/thu tiền/đánh boss. Hữu hạn (~0.9s), không chặn chạm, tự gỡ; tối đa 8 đợt cùng lúc;
/// tắt khi giảm chuyển động/test.
void showRewardBurst(
  BuildContext anchor, {
  List<String> emojis = const ['✨'],
  String? label,
  int count = 10,
}) {
  if (reduceMotion || _active >= 8 || !anchor.mounted) return;
  final box = anchor.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return;
  final center = box.localToGlobal(box.size.center(Offset.zero));
  final overlay = Overlay.maybeOf(anchor, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Burst(
      center: center,
      emojis: emojis,
      label: label,
      count: count,
      onDone: () {
        entry.remove();
        _active--;
      },
    ),
  );
  _active++;
  overlay.insert(entry);
}

class _Burst extends StatefulWidget {
  const _Burst({required this.center, required this.emojis, required this.label, required this.count, required this.onDone});
  final Offset center;
  final List<String> emojis;
  final String? label;
  final int count;
  final VoidCallback onDone;

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    })
    ..forward();
  late final math.Random _r = math.Random(widget.center.dx.toInt() * 31 + widget.center.dy.toInt());

  late final List<({double angle, double speed, String emoji, double size})> _p = [
    for (var i = 0; i < widget.count; i++)
      (
        angle: -math.pi / 2 + (_r.nextDouble() - 0.5) * math.pi * 1.3,
        speed: 70 + _r.nextDouble() * 70,
        emoji: widget.emojis[i % widget.emojis.length],
        size: 14 + _r.nextDouble() * 8,
      ),
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final fade = (1 - ((_c.value - 0.55) / 0.45).clamp(0.0, 1.0));
          return Stack(
            children: [
              for (final p in _p)
                Positioned(
                  left: widget.center.dx + math.cos(p.angle) * p.speed * t - 10,
                  // trọng lực: bay lên rồi rơi xuống
                  top: widget.center.dy + math.sin(p.angle) * p.speed * t + 140 * _c.value * _c.value - 10,
                  child: Opacity(opacity: fade, child: Text(p.emoji, style: TextStyle(fontSize: p.size, decoration: TextDecoration.none))),
                ),
              if (widget.label != null)
                Positioned(
                  left: widget.center.dx - 80,
                  width: 160,
                  top: widget.center.dy - 24 - 46 * t,
                  child: Opacity(
                    opacity: fade,
                    child: Text(
                      widget.label!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFB300),
                        decoration: TextDecoration.none,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
