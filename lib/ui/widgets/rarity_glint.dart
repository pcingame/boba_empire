/// Hào quang nhẹ cho món Sử thi / Huyền thoại trong Kho: quầng sáng nhấp nháy (Sử thi) hoặc quầng sáng +
/// nhún nhẹ (Huyền thoại). Chạy chung [AmbientTicker] nên chi phí không nhân theo số ô; chỉ bật ở mức hiệu ứng
/// Vừa/Cao và khi không bật giảm chuyển động — còn lại món đứng yên như cũ (0 timer).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessories.dart';
import 'accessory_rarity.dart';
import 'ambient_ticker.dart';
import 'effects_quality.dart';
import 'motion.dart' show reduceMotion;

class RarityGlint extends StatefulWidget {
  const RarityGlint({super.key, required this.rarity, required this.child, this.phase = 0});

  final AccessoryRarity rarity;
  final Widget child;

  /// Lệch pha (giây) để các ô không nhấp nháy đồng loạt.
  final double phase;

  /// Món có hiệu ứng không.
  static bool animates(AccessoryRarity r) => r == AccessoryRarity.epic || r == AccessoryRarity.legendary;

  @override
  State<RarityGlint> createState() => _RarityGlintState();
}

class _RarityGlintState extends State<RarityGlint> {
  VoidCallback? _unsub;
  late double _t = widget.phase;

  bool get _active {
    if (reduceMotion || !RarityGlint.animates(widget.rarity)) return false;
    final q = EffectsController.instance.quality.value;
    return q == EffectsQuality.medium || q == EffectsQuality.high;
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(RarityGlint old) {
    super.didUpdateWidget(old);
    if (old.rarity != widget.rarity) _sync();
  }

  /// Đăng ký/huỷ ticker chung cho khớp độ hiếm + mức hiệu ứng hiện tại.
  void _sync() {
    final want = _active;
    if (want && _unsub == null) {
      _unsub = AmbientTicker.instance.subscribe((dt) {
        if (!mounted) return;
        setState(() => _t += dt);
      });
    } else if (!want && _unsub != null) {
      _unsub!();
      _unsub = null;
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
    final legendary = widget.rarity == AccessoryRarity.legendary;
    // Chu kỳ ~2.4s (Sử thi) / ~3.1s (Huyền thoại): sin 0..1.
    final pulse = 0.5 + 0.5 * math.sin(_t * (legendary ? 2.0 : 2.6));
    final glow = rarityColor(widget.rarity);
    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(0, legendary ? -2.0 * pulse : 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.25 + 0.35 * pulse),
                blurRadius: 10 + 8 * pulse,
                spreadRadius: 1 + 2 * pulse,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
