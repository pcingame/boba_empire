/// Hiệu ứng "sang chảnh" chung cho mọi thứ VIP: quầng vàng nhịp thở + (tuỳ chọn) vệt sáng quét ngang.
/// Chạy chung [AmbientTicker] nên chi phí không nhân theo số widget. Theo [EffectsQuality]:
/// Vừa/Cao = quầng + vệt quét, Thấp = quầng tĩnh, Tắt/giảm chuyển động = giữ nguyên [child] (0 timer).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ambient_ticker.dart';
import 'effects_quality.dart';
import 'motion.dart' show reduceMotion;
import 'reward_burst.dart';

const _gold = Color(0xFFFFC107);

class VipShine extends StatefulWidget {
  const VipShine({
    super.key,
    required this.child,
    this.radius = 12,
    this.circle = false,
    this.sweep = true,
    this.phase = 0,
  });

  final Widget child;
  final double radius;

  /// Quầng tròn (xe VIP) thay vì bo góc.
  final bool circle;

  /// Vệt sáng quét ngang qua [child]. Dùng ShaderMask (saveLayer) nên chỉ bật cho widget nhỏ.
  final bool sweep;

  /// Lệch pha (giây) để các cụm không nhấp nháy đồng loạt.
  final double phase;

  @override
  State<VipShine> createState() => _VipShineState();
}

class _VipShineState extends State<VipShine> {
  VoidCallback? _unsub;
  late double _t = widget.phase;

  @override
  void initState() {
    super.initState();
    if (!reduceMotion) {
      _unsub = AmbientTicker.instance.subscribe((dt) {
        if (mounted) setState(() => _t += dt);
      });
    }
  }

  @override
  void dispose() {
    _unsub?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return widget.child;
    final q = EffectsController.instance.quality.value;
    final animated = q == EffectsQuality.medium || q == EffectsQuality.high;
    final pulse = animated ? 0.5 + 0.5 * math.sin(_t * 2.4) : 0.5;

    Widget child = widget.child;
    if (animated && widget.sweep) {
      // Chu kỳ 3s: vệt sáng quét trong 0.9s đầu, nghỉ phần còn lại.
      final p = ((_t % 3.0) / 0.9).clamp(0.0, 1.0);
      child = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0x00FFFFFF),
            Color(0xB3FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [(p - 0.25).clamp(0.0, 1.0), p, (p + 0.25).clamp(0.0, 1.0)],
        ).createShader(r),
        child: child,
      );
    }
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.circle
              ? null
              : BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.25 + 0.35 * pulse),
              blurRadius: 8 + 8 * pulse,
              spreadRadius: 0.5 + 2 * pulse,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Pháo hoa VIP (👑 ✨ 💎 🪙) bung từ giữa [anchor]; số hạt theo mức hiệu ứng.
void showVipBurst(BuildContext anchor, {String? label}) {
  final count = switch (EffectsController.instance.quality.value) {
    EffectsQuality.high => 16,
    EffectsQuality.medium => 10,
    _ => 5,
  };
  showRewardBurst(
    anchor,
    emojis: const ['👑', '✨', '💎', '🪙'],
    label: label,
    count: count,
  );
}
