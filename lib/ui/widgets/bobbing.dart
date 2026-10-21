/// Nhún nhẹ lên xuống + nghiêng chút (linh vật, món đấu giá). Chạy chung [AmbientTicker]; giảm chuyển động/Tắt = đứng yên.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ambient_ticker.dart';
import 'motion.dart' show reduceMotion;

class Bobbing extends StatefulWidget {
  const Bobbing({super.key, required this.child, this.amplitude = 6, this.period = 2.4});

  final Widget child;

  /// Biên độ nhún (px).
  final double amplitude;

  /// Chu kỳ (giây).
  final double period;

  @override
  State<Bobbing> createState() => _BobbingState();
}

class _BobbingState extends State<Bobbing> {
  VoidCallback? _unsub;
  double _t = 0;

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
    if (_unsub == null) return widget.child;
    final a = 2 * math.pi * _t / widget.period;
    return Transform.translate(
      offset: Offset(0, math.sin(a) * widget.amplitude),
      child: Transform.rotate(angle: math.sin(a * 0.5) * 0.05, child: widget.child),
    );
  }
}
