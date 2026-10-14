import 'package:flutter/material.dart';

import 'one_shot_lottie.dart';

/// Phát hiệu ứng nhỏ ([asset]) ngay trên [child] mỗi lần [value] TĂNG (không phát ở lần dựng đầu,
/// không phát khi giảm). Mức chất lượng, trần đồng thời và "giảm chuyển động" do [playEffect] lo.
/// [minGapMs] gộp các lần tăng dồn dập (vd nhận nhiều phần thưởng liền nhau).
class EffectOnIncrease extends StatefulWidget {
  const EffectOnIncrease({
    super.key,
    required this.value,
    required this.asset,
    required this.child,
    this.size = 90,
    this.minGapMs = 700,
  });

  final num value;
  final String asset;
  final Widget child;
  final double size;
  final int minGapMs;

  @override
  State<EffectOnIncrease> createState() => _EffectOnIncreaseState();
}

class _EffectOnIncreaseState extends State<EffectOnIncrease> {
  DateTime? _last;

  @override
  void didUpdateWidget(EffectOnIncrease old) {
    super.didUpdateWidget(old);
    if (widget.value <= old.value) return;
    final now = DateTime.now();
    if (_last != null && now.difference(_last!).inMilliseconds < widget.minGapMs) return;
    _last = now;
    // Sau khung này mới có kích thước/vị trí mới của child.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playEffect(context, widget.asset,
          size: widget.size, center: effectCenterOf(context), heavy: false);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
