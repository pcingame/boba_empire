import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ambient_ticker.dart';
import 'effects_quality.dart';
import 'motion.dart' show reduceMotion;

/// Kiểu hạt trang trí trên cảnh quán. Mỗi giai đoạn một kiểu (xem [ambienceFor]).
enum AmbienceKind {
  /// Bụi sáng ấm lơ lửng bay lên chậm (kiosk, trong nhà).
  motes(0xFFFFE2A8, rise: 0.035, sway: 0.02, size: 2.2, max: 14),

  /// Lá rơi nhẹ (ngoài trời: xe đẩy, nông trại).
  leaves(0xFF8DBB6B, rise: -0.05, sway: 0.06, size: 4.0, max: 8),

  /// Hơi nước bốc lên, nở dần và mờ đi (cafe, lò nướng, nhà máy).
  steam(0xFFFFFFFF, rise: 0.07, sway: 0.03, size: 6.0, max: 8, grow: true),

  /// Đốm vàng lấp lánh bay lên (khối kinh doanh, tài chính).
  gold(0xFFFFD54F, rise: 0.05, sway: 0.025, size: 2.6, max: 16, twinkle: true),

  /// Mảnh dữ liệu xanh bay lên nhanh (đế chế công nghệ).
  tech(0xFF4DD0E1, rise: 0.09, sway: 0.01, size: 2.4, max: 16, square: true),

  /// Sao nhấp nháy đứng yên (các giai đoạn cuối, vũ trụ).
  stars(0xFFEDE7FF, rise: 0, sway: 0, size: 2.4, max: 24, twinkle: true);

  const AmbienceKind(
    this.color, {
    required this.rise,
    required this.sway,
    required this.size,
    required this.max,
    this.grow = false,
    this.twinkle = false,
    this.square = false,
  });

  final int color;

  /// Tốc độ dọc (phần chiều cao mỗi giây; dương = bay lên, âm = rơi).
  final double rise;

  /// Biên độ lắc ngang (phần chiều rộng).
  final double sway;

  /// Kích thước hạt (dp).
  final double size;

  /// Trần số hạt của kiểu này (còn bị chặn thêm bởi ngân sách của mức chất lượng).
  final int max;
  final bool grow;
  final bool twinkle;
  final bool square;
}

/// Kiểu hạt của giai đoạn [stage] (1..18; ngoài khoảng thì dùng giai đoạn gần nhất).
AmbienceKind ambienceFor(int stage) {
  final s = stage.clamp(1, 18);
  if (s == 1 || s == 10) return AmbienceKind.leaves;
  if (s == 2) return AmbienceKind.motes;
  if (s <= 5) return AmbienceKind.steam;
  if (s <= 9) return AmbienceKind.gold;
  if (s == 11) return AmbienceKind.tech;
  if (s == 12) return AmbienceKind.gold;
  return AmbienceKind.stars;
}

/// Một hạt tại thời điểm [t] giây. Toàn bộ là hàm của (i, t) — không giữ trạng thái, nên vẽ lại
/// rẻ và test được. x, y trong [0,1] của khung; [alpha] trong [0,1]; [radius] theo dp.
class Particle {
  const Particle(this.x, this.y, this.alpha, this.radius);
  final double x, y, alpha, radius;
}

double _hash(int i, int salt) {
  final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

Particle particleAt(AmbienceKind k, int i, double t) {
  final phase = _hash(i, 1);
  final baseX = _hash(i, 2);
  final speed = 0.6 + _hash(i, 3) * 0.8; // 0.6..1.4 lần tốc độ chuẩn
  final size = k.size * (0.7 + _hash(i, 4) * 0.6);
  // Tiến độ vòng đời 0..1 (hạt bay hết khung thì xuất hiện lại từ phía bên kia).
  final p = k.rise == 0 ? 0.0 : (phase + t * k.rise.abs() * speed) % 1.0;
  final y = k.rise >= 0 ? 1.0 - p : p;
  final x = (baseX + k.sway * math.sin(t * (0.6 + _hash(i, 5)) + phase * 6.283)) % 1.0;
  double alpha;
  if (k.rise == 0) {
    alpha = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * (0.8 + _hash(i, 6) * 1.6) + phase * 6.283));
    return Particle(x, _hash(i, 7) * 0.7, alpha * 0.9, size);
  }
  alpha = math.sin(math.pi * p); // hiện dần rồi tan dần
  if (k.twinkle) alpha *= 0.55 + 0.45 * math.sin(t * 5 + phase * 6.283);
  if (k.grow) alpha *= 0.5;
  return Particle(x, y, alpha.clamp(0.0, 1.0), k.grow ? size * (0.6 + p * 1.4) : size);
}

/// Lớp hạt phủ lên cảnh quán (đặt NGAY TRÊN ảnh nền, dưới vùng chạm). Chạy bằng [AmbientTicker]
/// nên theo mức chất lượng: số hạt = ngân sách của mức, Tắt hoặc "giảm chuyển động" = không dựng gì
/// (0 khung). Bị hộp thoại/trang khác phủ lên thì tạm dừng cập nhật.
class StageAmbience extends StatefulWidget {
  const StageAmbience({super.key, required this.stage});

  final int stage;

  @override
  State<StageAmbience> createState() => _StageAmbienceState();
}

class _StageAmbienceState extends State<StageAmbience> {
  final _time = ValueNotifier<double>(0);
  VoidCallback? _unsub;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    EffectsController.instance.quality.addListener(_onQuality);
    _sync();
  }

  void _onQuality() {
    if (mounted) setState(_sync);
  }

  bool get _active => !reduceMotion && EffectsController.instance.quality.value.particleBudget > 0;

  void _sync() {
    if (_active) {
      _unsub ??= AmbientTicker.instance.subscribe((dt) {
        if (!_covered) _time.value += dt;
      });
    } else {
      _unsub?.call();
      _unsub = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    _covered = route != null && !route.isCurrent;
  }

  @override
  void dispose() {
    EffectsController.instance.quality.removeListener(_onQuality);
    _unsub?.call();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    final kind = ambienceFor(widget.stage);
    final count = math.min(kind.max, EffectsController.instance.quality.value.particleBudget);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const Key('stage-ambience'),
          size: Size.infinite,
          painter: _AmbiencePainter(_time, kind, count, dark ? 0.85 : 1.0),
        ),
      ),
    );
  }
}

class _AmbiencePainter extends CustomPainter {
  _AmbiencePainter(this.time, this.kind, this.count, this.strength) : super(repaint: time);

  final ValueNotifier<double> time;
  final AmbienceKind kind;
  final int count;
  final double strength;
  final _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Color(kind.color);
    for (var i = 0; i < count; i++) {
      final p = particleAt(kind, i, time.value);
      if (p.alpha <= 0.01) continue;
      _paint.color = base.withValues(alpha: p.alpha * strength * (kind.grow ? 0.5 : 0.85));
      final c = Offset(p.x * size.width, p.y * size.height);
      if (kind.square) {
        canvas.drawRect(Rect.fromCenter(center: c, width: p.radius * 1.6, height: p.radius * 1.6), _paint);
      } else if (kind == AmbienceKind.leaves) {
        canvas.drawOval(Rect.fromCenter(center: c, width: p.radius * 2.2, height: p.radius * 1.2), _paint);
      } else {
        canvas.drawCircle(c, p.radius, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(_AmbiencePainter old) =>
      old.kind != kind || old.count != count || old.strength != strength;
}
