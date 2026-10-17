import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import 'ambient_ticker.dart';
import 'motion.dart' show reduceMotion;

/// Boss Hội "sống": thở/nhún nhẹ khi chờ, rung + loé đỏ + số sát thương bay lên mỗi khi tổng điểm hội
/// TĂNG lúc đang xem, nổi giận (quầng đỏ nhấp nháy, nhún nhanh) khi máu < [rageBelow], và ngã gục khi
/// bị hạ. Thuần Flutter (không cần file Lottie); nhịp idle dùng [AmbientTicker] chung nên tôn trọng mức
/// hiệu ứng và dừng hẳn khi app ra nền / bị trang khác che; hit/ngã là animation hữu hạn.
class BossAvatar extends StatefulWidget {
  const BossAvatar({
    super.key,
    required this.emoji,
    required this.damage,
    required this.hpFraction,
    required this.defeated,
    this.size = 52,
    this.rageBelow = 0.3,
  });

  final String emoji;

  /// Tổng sát thương đã gây (điểm tuần cả hội). Tăng lên = một cú đánh.
  final int damage;

  /// Máu còn lại 0..1 (1 = đầy).
  final double hpFraction;
  final bool defeated;
  final double size;
  final double rageBelow;

  @override
  State<BossAvatar> createState() => _BossAvatarState();
}

class _BossAvatarState extends State<BossAvatar> with TickerProviderStateMixin {
  // Không forward()/repeat(): giá trị do AmbientTicker đặt → không ép khung vsync.
  late final AnimationController _idle = AnimationController(vsync: this);
  late final AnimationController _hit =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _down =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  VoidCallback? _unsub;
  bool _covered = false;
  double _t = 0;
  int _lastDelta = 0;

  bool get _enraged => !widget.defeated && widget.hpFraction < widget.rageBelow;

  @override
  void initState() {
    super.initState();
    // Đã hạ từ trước khi mở trang: nằm sẵn ở trạng thái gục, không diễn lại.
    if (widget.defeated) _down.value = 1;
    if (!reduceMotion) _start();
  }

  void _start() {
    _unsub ??= AmbientTicker.instance.subscribe((dt) {
      if (_covered || widget.defeated) return;
      _t += dt;
      _idle.value = (_t % 100) / 100; // chỉ để báo "đã đổi" cho AnimatedBuilder
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _covered = route != null && !route.isCurrent;
  }

  @override
  void didUpdateWidget(BossAvatar old) {
    super.didUpdateWidget(old);
    if (reduceMotion) return;
    if (!old.defeated && widget.defeated) {
      _hit.value = 0;
      _down.forward(from: 0);
    } else if (widget.damage > old.damage && !widget.defeated) {
      _lastDelta = widget.damage - old.damage;
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _unsub?.call();
    _idle.dispose();
    _hit.dispose();
    _down.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: s,
      height: s,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _hit, _down]),
          builder: (context, _) {
            final h = _hit.value; // 0→1 trong lúc trúng đòn
            final d = Curves.easeIn.transform(_down.value);
            final period = _enraged ? 0.5 : 1.6;
            final u = (_t / period) % 2;
            final bob = widget.defeated || reduceMotion
                ? 0.0
                : Curves.easeInOut.transform(u <= 1 ? u : 2 - u);
            // Rung tắt dần theo thời gian trúng đòn.
            final shake = h == 0 ? 0.0 : math.sin(h * math.pi * 7) * (1 - h) * s * 0.12;
            final flash = h == 0 ? 0.0 : (1 - h);
            final rage = _enraged && !reduceMotion
                ? (0.5 + 0.5 * math.sin(_t * 6)).clamp(0.0, 1.0)
                : 0.0;
            Widget face = Text(widget.emoji, style: TextStyle(fontSize: s * 0.58));
            if (widget.defeated) {
              face = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0, //
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: face,
              );
            }
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(scheme.errorContainer, Colors.red, flash * 0.6 + rage * 0.25),
                    boxShadow: [
                      if (rage > 0)
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.25 + 0.35 * rage),
                          blurRadius: 6 + 8 * rage,
                          spreadRadius: 1 + 2 * rage,
                        ),
                    ],
                  ),
                  child: SizedBox.square(dimension: s),
                ),
                Transform.translate(
                  offset: Offset(shake, -s * 0.06 * bob),
                  child: Transform.rotate(
                    angle: d * 0.9, // ngã nghiêng khi gục
                    child: Transform.scale(
                      scale: (1 + 0.04 * bob + 0.12 * flash) * (1 - 0.18 * d),
                      child: Opacity(opacity: 1 - 0.35 * d, child: face),
                    ),
                  ),
                ),
                if (widget.defeated && _down.value > 0)
                  Positioned(
                    top: -s * 0.1,
                    right: -s * 0.05,
                    child: Opacity(
                      opacity: d,
                      child: Text('💫', style: TextStyle(fontSize: s * 0.34)),
                    ),
                  ),
                if (h > 0 && h < 1 && _lastDelta > 0)
                  Positioned(
                    top: -s * 0.2 - s * 0.5 * h,
                    child: Opacity(
                      opacity: (1 - h * h).clamp(0.0, 1.0),
                      child: Text(
                        '-${formatNumber(_lastDelta.toDouble())}',
                        key: const Key('boss-damage'),
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: math.max(12, s * 0.28),
                          color: Colors.redAccent,
                          shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
