import 'package:flutter/material.dart';

import 'mascot.dart' show debugDisableMascotAnimation;

/// Có nên tắt animation trang trí không: khi test HOẶC khi người dùng bật "giảm
/// chuyển động" ở hệ điều hành (accessibility). Mọi widget trong file này tôn trọng nó.
bool get reduceMotion =>
    debugDisableMascotAnimation ||
    WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
        .disableAnimations;

/// Nhấp nhẹ (phóng 1 → [peak] → 1, ~220ms) mỗi lần [value] TĂNG — phản hồi "mua
/// được rồi" cho ô nâng cấp. Chỉ ô thay đổi mới chạy animation; hữu hạn nên không
/// ép vẽ khung khi đứng yên.
class PulseOnIncrease extends StatefulWidget {
  const PulseOnIncrease({
    super.key,
    required this.value,
    required this.child,
    this.peak = 1.03,
  });

  final num value;
  final Widget child;
  final double peak;

  @override
  State<PulseOnIncrease> createState() => _PulseOnIncreaseState();
}

class _PulseOnIncreaseState extends State<PulseOnIncrease>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didUpdateWidget(PulseOnIncrease old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value && !reduceMotion) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: widget.peak)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: widget.peak, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 60,
        ),
      ]).animate(_c),
      child: widget.child,
    );
  }
}

/// Gây chú ý một lần khi widget XUẤT HIỆN: nhịp phóng-thu lặp [cycles] lần rồi
/// dừng hẳn (không lặp vô hạn — vô hạn sẽ ép vẽ 60 khung/giây mãi).
class PulseOnMount extends StatefulWidget {
  const PulseOnMount({
    super.key,
    required this.child,
    this.cycles = 2,
    this.peak = 1.08,
  });

  final Widget child;
  final int cycles;
  final double peak;

  @override
  State<PulseOnMount> createState() => _PulseOnMountState();
}

class _PulseOnMountState extends State<PulseOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  var _done = 0;

  @override
  void initState() {
    super.initState();
    if (!reduceMotion) {
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed && ++_done < widget.cycles) {
          _c.forward(from: 0);
        }
      });
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: widget.peak)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween(begin: widget.peak, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50,
        ),
      ]).animate(_c),
      child: widget.child,
    );
  }
}

/// Hiện dần + trượt nhẹ từ dưới lên khi LẦN ĐẦU được dựng — cho listing mới xuất
/// hiện. [enabled] = false (hoặc giảm chuyển động) thì hiện ngay, không animation.
class AppearIn extends StatelessWidget {
  const AppearIn({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // LUÔN giữ TweenAnimationBuilder trong cây (chỉ đổi thời lượng) — đổi cấu trúc
    // giữa chừng sẽ dựng lại con và cắt animation.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: enabled && !reduceMotion ? 0.0 : 1.0, end: 1.0),
      duration: enabled && !reduceMotion
          ? const Duration(milliseconds: 320)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// "Bật" ra (phóng 0 → 1 kiểu nảy nhẹ, ~280ms) khi xuất hiện — cho chấm đỏ/huy hiệu.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: child,
    );
  }
}
