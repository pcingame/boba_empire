/// Khách đứng quầy vẽ bằng CODE (không cần file Lottie/ảnh): nhân vật chibi tròn dễ thương. Mỗi [seed] cho một
/// diện mạo riêng (da, tóc, áo, kính), nét mặt đổi theo [CustomerMood], thở + chớp mắt khi chờ. Tắt chuyển động
/// (giảm chuyển động của máy / chất lượng hiệu ứng "tắt" / test) thì đứng yên, không có animation lặp.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Tâm trạng của khách.
enum CustomerMood { waiting, delighted, pleased, upset }

/// Diện mạo suy ra từ [seed] — thuần (test được), cùng seed luôn ra cùng một người.
class ChibiLook {
  const ChibiLook({
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.hairStyle,
    required this.glasses,
  });

  final Color skin;
  final Color hair;
  final Color shirt;

  /// 0 mái ngố · 1 búi tóc · 2 hai bím · 3 tóc ngắn rẽ ngôi · 4 tóc bob dài.
  final int hairStyle;
  final bool glasses;

  static const _skins = [Color(0xFFFFE0C2), Color(0xFFF7C9A0), Color(0xFFE8B088), Color(0xFFC98F66), Color(0xFF9C6A48)];
  static const _hairs = [
    Color(0xFF2B1B14),
    Color(0xFF4A2C1B),
    Color(0xFF7A4B28),
    Color(0xFFB87333),
    Color(0xFFD9A441),
    Color(0xFF3B3B4F),
    Color(0xFFB04A6B),
  ];
  static const _shirts = [
    Color(0xFFF28B82),
    Color(0xFF7BB6E8),
    Color(0xFF8FD694),
    Color(0xFFFFD166),
    Color(0xFFB39DDB),
    Color(0xFFFFAB91),
    Color(0xFF80CBC4),
  ];

  static const hairStyleCount = 5;

  factory ChibiLook.fromSeed(int seed) {
    // Trộn bit để các đặc điểm không đổi cùng nhịp khi seed tăng dần (seed thường là id món + chỉ số đơn).
    final m = (seed.abs() * 2654435761 + 40503) & 0xFFFFFFFF;
    int pick(int shift, int n) => ((m >> shift) ^ (m >> (shift + 7))) % n;
    return ChibiLook(
      skin: _skins[pick(0, _skins.length)],
      hair: _hairs[pick(3, _hairs.length)],
      shirt: _shirts[pick(5, _shirts.length)],
      hairStyle: pick(9, hairStyleCount),
      glasses: pick(13, 4) == 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ChibiLook &&
      other.skin == skin &&
      other.hair == hair &&
      other.shirt == shirt &&
      other.hairStyle == hairStyle &&
      other.glasses == glasses;

  @override
  int get hashCode => Object.hash(skin, hair, shirt, hairStyle, glasses);
}

/// Nhân vật chibi vuông [size]×[size]. [impatient] (khách sốt ruột ở Giờ cao điểm) chỉ có tác dụng khi đang chờ.
class ChibiCustomer extends StatefulWidget {
  const ChibiCustomer({
    super.key,
    required this.seed,
    required this.mood,
    this.impatient = false,
    this.size = 64,
  });

  final int seed;
  final CustomerMood mood;
  final bool impatient;
  final double size;

  @override
  State<ChibiCustomer> createState() => _ChibiCustomerState();
}

class _ChibiCustomerState extends State<ChibiCustomer> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    // Chu kỳ 4 giây: thở (sin) + một lần chớp mắt. Không tạo controller khi tắt chuyển động ⇒ không lặp khung hình.
    if (!reduceMotion) {
      _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = ChibiLook.fromSeed(widget.seed);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const Key('chibi-customer'),
          size: Size.square(widget.size),
          painter: ChibiPainter(
            look: look,
            mood: widget.mood,
            impatient: widget.impatient,
            phase: _c,
          ),
        ),
      ),
    );
  }
}

/// Vẽ chibi. [phase] ∈ [0,1) (null = đứng yên, mắt mở). Công khai để test vẽ ra ảnh.
class ChibiPainter extends CustomPainter {
  ChibiPainter({required this.look, required this.mood, this.impatient = false, Animation<double>? phase})
      : _phase = phase,
        super(repaint: phase);

  final ChibiLook look;
  final CustomerMood mood;
  final bool impatient;
  final Animation<double>? _phase;

  /// Hiện tại của chu kỳ 0..1 (0 khi đứng yên).
  double get phase => _phase?.value ?? 0;

  static const _ink = Color(0xFF3A2A25);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final t = phase;
    final sad = mood == CustomerMood.upset;
    final happy = mood == CustomerMood.delighted || mood == CustomerMood.pleased;
    final nervous = impatient && mood == CustomerMood.waiting;

    // Thở: đầu/thân nhấp nhô nhẹ; sốt ruột thì nhanh hơn + nghiêng đầu.
    final bob = _phase == null ? 0.0 : math.sin(2 * math.pi * t * (nervous ? 4 : 1)) * s * 0.012;
    final tilt = _phase != null && nervous ? math.sin(2 * math.pi * t * 4) * 0.05 : 0.0;
    // Chớp mắt: ~8% cuối chu kỳ, mắt khép dần rồi mở (không chớp khi đang cười/buồn).
    final blink = _phase == null ? 1.0 : _eyeOpen(t);

    final cx = s / 2;
    final r = s * 0.31; // bán kính đầu — to so với thân cho đúng chất chibi
    final cy = s * 0.44 + bob;

    // Thân (áo) — chỉ lộ nửa trên, phần dưới bị cắt bởi mép khung.
    final body = RRect.fromLTRBR(cx - s * 0.27, s * 0.74 + bob, cx + s * 0.27, s * 1.1, Radius.circular(s * 0.16));
    canvas.drawRRect(body, Paint()..color = look.shirt);
    canvas.drawRRect(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..color = _ink.withValues(alpha: 0.35));
    // Cổ áo nhỏ.
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, s * 0.745 + bob), width: s * 0.18, height: s * 0.1), 0, math.pi,
        false, Paint()..color = look.skin);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tilt);
    canvas.translate(-cx, -cy);

    _hairBack(canvas, cx, cy, r, s);

    // Đầu.
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = look.skin);
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..color = _ink.withValues(alpha: 0.4));

    // Má hồng (đậm hơn khi vui).
    final blush = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: happy ? 0.65 : 0.35);
    canvas.drawCircle(Offset(cx - r * 0.62, cy + r * 0.32), r * 0.17, blush);
    canvas.drawCircle(Offset(cx + r * 0.62, cy + r * 0.32), r * 0.17, blush);

    _eyes(canvas, cx, cy, r, s, happy: happy, nervous: nervous, open: blink);
    _mouth(canvas, cx, cy, r, s, nervous: nervous);
    _hairFront(canvas, cx, cy, r, s);
    if (look.glasses) _glasses(canvas, cx, cy, r, s);

    // Giọt mồ hôi khi sốt ruột; giọt nước mắt khi buồn.
    if (nervous) _drop(canvas, Offset(cx + r * 0.95, cy - r * 0.35), r * 0.16, const Color(0xFF81D4FA));
    if (sad) _drop(canvas, Offset(cx - r * 0.5, cy + r * 0.34), r * 0.13, const Color(0xFF81D4FA));

    canvas.restore();
  }

  /// Độ mở mắt 0..1 theo pha: mở gần suốt chu kỳ, khép nhanh một lần.
  static double _eyeOpen(double t) {
    const start = 0.88, len = 0.08;
    if (t < start || t > start + len) return 1;
    final u = (t - start) / len; // 0..1
    return (u - 0.5).abs() * 2; // 1 → 0 → 1
  }

  void _hairBack(Canvas c, double cx, double cy, double r, double s) {
    final p = Paint()..color = look.hair;
    switch (look.hairStyle) {
      case 1: // búi tóc trên đỉnh
        c.drawCircle(Offset(cx, cy - r * 1.08), r * 0.34, p);
        c.drawCircle(Offset(cx, cy), r * 1.05, p);
      case 2: // hai bím hai bên
        c.drawCircle(Offset(cx - r * 1.0, cy + r * 0.45), r * 0.3, p);
        c.drawCircle(Offset(cx + r * 1.0, cy + r * 0.45), r * 0.3, p);
        c.drawCircle(Offset(cx, cy), r * 1.05, p);
      case 4: // bob dài che hai bên má
        c.drawRRect(RRect.fromLTRBR(cx - r * 1.12, cy - r * 0.6, cx + r * 1.12, cy + r * 1.05, Radius.circular(r * 0.7)), p);
      default:
        c.drawCircle(Offset(cx, cy), r * 1.05, p);
    }
  }

  void _hairFront(Canvas c, double cx, double cy, double r, double s) {
    final p = Paint()..color = look.hair;
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.01)));
    // Mảng tóc phủ phần trên đầu, mép dưới lượn sóng thành các "chỏm".
    final fringeBottom = cy - r * 0.38;
    c.drawRect(Rect.fromLTRB(cx - r * 1.2, cy - r * 1.2, cx + r * 1.2, fringeBottom), p);
    switch (look.hairStyle) {
      case 3: // rẽ ngôi lệch: một bên dài xuống
        c.drawOval(Rect.fromCenter(center: Offset(cx - r * 0.5, fringeBottom), width: r * 1.5, height: r * 0.75), p);
        c.drawCircle(Offset(cx + r * 0.62, fringeBottom - r * 0.02), r * 0.3, p);
      default: // mái ngố: 3 chỏm
        for (final dx in [-0.62, 0.0, 0.62]) {
          c.drawCircle(Offset(cx + r * dx, fringeBottom), r * 0.34, p);
        }
    }
    c.restore();
  }

  void _eyes(Canvas c, double cx, double cy, double r, double s,
      {required bool happy, required bool nervous, required double open}) {
    final ex = r * 0.42;
    final ey = cy + r * 0.1;
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final x = cx + side * ex;
      if (happy) {
        // Mắt cười ^ ^
        c.drawArc(Rect.fromCenter(center: Offset(x, ey + r * 0.05), width: r * 0.34, height: r * 0.3), math.pi, math.pi, false, line);
      } else {
        // Mắt tròn to có điểm sáng; chớp mắt thì dẹt lại. Sốt ruột: nhìn sang bên.
        final look = nervous ? side * r * 0.04 + r * 0.05 : 0.0;
        final h = r * 0.34 * open.clamp(0.08, 1.0);
        c.drawOval(Rect.fromCenter(center: Offset(x + look, ey), width: r * 0.26, height: h), ink);
        if (open > 0.5) {
          c.drawCircle(Offset(x + look - r * 0.04, ey - h * 0.22), r * 0.05, Paint()..color = Colors.white);
        }
      }
      // Cố ý KHÔNG vẽ lông mày: mái tóc phủ tới sát mắt (kiểu chibi), mày bị che hoặc lòi ra thành nét lạ.
    }
  }

  void _mouth(Canvas c, double cx, double cy, double r, double s, {required bool nervous}) {
    final my = cy + r * 0.52;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case CustomerMood.delighted: // miệng há to cười, có lưỡi
        final mouth = Path()
          ..moveTo(cx - r * 0.3, my - r * 0.04)
          ..quadraticBezierTo(cx, my + r * 0.5, cx + r * 0.3, my - r * 0.04)
          ..close();
        c.drawPath(mouth, Paint()..color = const Color(0xFF8E2C3B));
        c.drawArc(Rect.fromCenter(center: Offset(cx, my + r * 0.17), width: r * 0.28, height: r * 0.2), math.pi, math.pi, false,
            Paint()..color = const Color(0xFFFF8A9B));
        c.drawPath(mouth, line..strokeWidth = s * 0.025);
      case CustomerMood.pleased: // cười mỉm rộng
        c.drawArc(Rect.fromCenter(center: Offset(cx, my - r * 0.05), width: r * 0.62, height: r * 0.4), 0.15 * math.pi,
            0.7 * math.pi, false, line);
      case CustomerMood.upset: // mếu
        c.drawArc(Rect.fromCenter(center: Offset(cx, my + r * 0.16), width: r * 0.44, height: r * 0.3), 1.15 * math.pi,
            0.7 * math.pi, false, line);
      case CustomerMood.waiting:
        if (nervous) {
          // Mím miệng lượn sóng.
          final w = Path()..moveTo(cx - r * 0.2, my);
          w.quadraticBezierTo(cx - r * 0.1, my - r * 0.1, cx, my);
          w.quadraticBezierTo(cx + r * 0.1, my + r * 0.1, cx + r * 0.2, my);
          c.drawPath(w, line);
        } else {
          c.drawArc(Rect.fromCenter(center: Offset(cx, my - r * 0.03), width: r * 0.36, height: r * 0.26), 0.15 * math.pi,
              0.7 * math.pi, false, line);
        }
    }
  }

  void _glasses(Canvas c, double cx, double cy, double r, double s) {
    final p = Paint()
      ..color = _ink.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03;
    final ey = cy + r * 0.1;
    c.drawCircle(Offset(cx - r * 0.42, ey), r * 0.27, p);
    c.drawCircle(Offset(cx + r * 0.42, ey), r * 0.27, p);
    c.drawLine(Offset(cx - r * 0.15, ey), Offset(cx + r * 0.15, ey), p);
  }

  void _drop(Canvas c, Offset o, double rad, Color color) {
    final p = Path()
      ..moveTo(o.dx, o.dy - rad * 1.6)
      ..quadraticBezierTo(o.dx + rad * 1.3, o.dy + rad * 0.2, o.dx, o.dy + rad)
      ..quadraticBezierTo(o.dx - rad * 1.3, o.dy + rad * 0.2, o.dx, o.dy - rad * 1.6);
    c.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(ChibiPainter old) => old.look != look || old.mood != mood || old.impatient != impatient || old._phase != _phase;
}
