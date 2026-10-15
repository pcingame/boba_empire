/// Hình ảnh của trò "Pha theo đơn": màu nguyên liệu, ly nhiều lớp (rót dâng lên, đậy nắp + lắc), khách đứng quầy
/// với bong bóng đơn và nét mặt đổi theo kết quả. Chỉ vẽ + animation; luật chơi nằm ở core/recipe_orders.dart.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart' show reduceMotion;
import 'recipe_motion.dart' show ShakeOnTrigger;

/// Màu một lớp nguyên liệu trong ly (nhận theo từ khoá trong tên, từ khoá cụ thể trước — cùng khuôn
/// `ingredientEmoji`). Không khớp thì sinh màu ổn định từ tên: cùng nguyên liệu luôn cùng màu.
Color ingredientColor(String name) {
  final n = name.toLowerCase();
  const table = <(String, int)>[
    ('hoa hồng', 0xFFF4A6C0),
    ('việt quất', 0xFF5B4B9A),
    ('dưa hấu', 0xFFF06D7D),
    ('kiwi', 0xFF9BC53D),
    ('nho', 0xFF7B4B94),
    ('dâu', 0xFFF27A8D),
    ('chuối', 0xFFF7E27A),
    ('đào', 0xFFF9B48A),
    ('cam', 0xFFF5A03A),
    ('tắc', 0xFFF5B83A),
    ('chanh', 0xFFE6EE7A),
    ('xoài', 0xFFF9C13C),
    ('dứa', 0xFFF4DE5A),
    ('matcha', 0xFF7DAA4F),
    ('lục trà', 0xFFB7C77A),
    ('hồng trà', 0xFFB5651D),
    ('ô long', 0xFFC58A3E),
    ('trà thái', 0xFFE8742A),
    ('trà ', 0xFFC9964B),
    ('cold brew', 0xFF4A3322),
    ('cà phê', 0xFF4A3322),
    ('espresso', 0xFF3B2A1C),
    ('cacao', 0xFF6B4226),
    ('chocolate', 0xFF5A3825),
    ('caramel', 0xFFC8832E),
    ('đường đen', 0xFF4E3524),
    ('mật ong', 0xFFE5A823),
    ('đường', 0xFFF1E3C0),
    ('sữa hạnh nhân', 0xFFF1E4D3),
    ('sữa', 0xFFFAF3E6),
    ('kem', 0xFFFFFBF2),
    ('nước cốt dừa', 0xFFFFFAF0),
    ('khoai môn', 0xFFB79BD1),
    ('trân châu', 0xFF2B1B14),
    ('thạch', 0xFF86D0C4),
    ('soda', 0xFFCBEFF5),
    ('tonic', 0xFFD8F1F5),
    ('nước nóng', 0xFFE7F3F7),
    ('đá', 0xFFDFF3FB),
  ];
  for (final (k, c) in table) {
    if (n.contains(k)) return Color(c);
  }
  final h = (name.hashCode.abs() % 360).toDouble();
  return HSVColor.fromAHSV(1, h, 0.45, 0.85).toColor();
}

/// Nguyên liệu dạng topping (hạt/viên): khi cho vào ly thì RƠI từng viên chứ không rót.
bool isTopping(String name) {
  final n = name.toLowerCase();
  return const ['trân châu', 'thạch', 'pudding', 'oreo', 'đậu đỏ'].any(n.contains);
}

/// Một lớp trong ly: màu + tỉ lệ chiều cao (0..1 so với cả ly; tổng vượt 1 thì co lại cho vừa).
class CupLayer {
  const CupLayer(this.color, this.fraction);
  final Color color;
  final double fraction;
}

/// Ly nhiều lớp. Lớp mới dâng lên mượt; [lidded] thả nắp xuống; [shaking] lắc ly (sau khi đậy nắp).
class OrderCup extends StatefulWidget {
  const OrderCup({
    super.key,
    required this.layers,
    this.width = 84,
    this.height = 112,
    this.lidded = false,
    this.shaking = false,
    this.marks = const [],
    this.target,
    this.dropBurst = 0,
    this.dropColor = const Color(0xFF2B1B14),
  });

  final List<CupLayer> layers;
  final double width;
  final double height;
  final bool lidded;
  final bool shaking;

  /// Vạch chia trên thành ly (tỉ lệ 0..1 so với phần chứa nước) — bậc có gợi ý thì hiện.
  final List<double> marks;

  /// Vạch mốc ĐÚNG (tỉ lệ 0..1) — chỉ bậc Mới / khi đã xem công thức mẫu.
  final double? target;

  /// Tăng lên mỗi lần có topping thả vào: viên rơi xuống mặt nước (màu [dropColor]).
  final int dropBurst;
  final Color dropColor;

  @override
  State<OrderCup> createState() => _OrderCupState();
}

class _OrderCupState extends State<OrderCup> with TickerProviderStateMixin {
  late final AnimationController _fill =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1);
  late final AnimationController _lid = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final AnimationController _drop = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  List<double> _from = const [];
  List<double> _to = const [];

  @override
  void initState() {
    super.initState();
    _to = _fractions(widget.layers);
    _from = _to;
    if (widget.lidded) _lid.value = 1;
  }

  /// Chiều cao từng lớp sau khi co lại cho tổng ≤ 1.
  static List<double> _fractions(List<CupLayer> l) {
    final sum = l.fold<double>(0, (a, x) => a + x.fraction);
    final k = sum > 1 ? 1 / sum : 1.0;
    return [for (final x in l) x.fraction * k];
  }

  List<double> get _shown {
    final t = Curves.easeOut.transform(_fill.value);
    final n = math.max(_from.length, _to.length);
    return [
      for (var i = 0; i < n; i++)
        (i < _from.length ? _from[i] : 0.0) + ((i < _to.length ? _to[i] : 0.0) - (i < _from.length ? _from[i] : 0.0)) * t,
    ];
  }

  @override
  void didUpdateWidget(OrderCup old) {
    super.didUpdateWidget(old);
    final next = _fractions(widget.layers);
    if (!_same(next, _to)) {
      _from = _shown;
      _to = next;
      reduceMotion ? _fill.value = 1 : _fill.forward(from: 0);
    }
    if (widget.dropBurst > old.dropBurst && !reduceMotion) _drop.forward(from: 0);
    if (widget.lidded != old.lidded) {
      if (reduceMotion) {
        _lid.value = widget.lidded ? 1 : 0;
      } else {
        widget.lidded ? _lid.forward(from: 0) : _lid.value = 0;
      }
    }
    if (widget.shaking && !old.shaking && !reduceMotion) _shake.repeat();
    if (!widget.shaking && old.shaking) {
      _shake.stop();
      _shake.value = 0;
    }
  }

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 1e-9) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _fill.dispose();
    _lid.dispose();
    _shake.dispose();
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return AnimatedBuilder(
      animation: Listenable.merge([_fill, _lid, _shake, _drop]),
      builder: (context, _) {
        final angle = widget.shaking ? math.sin(_shake.value * math.pi * 2 * 3) * 0.14 : 0.0;
        final dy = widget.shaking ? -math.sin(_shake.value * math.pi * 2 * 3).abs() * 5 : 0.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: CustomPaint(
              key: const Key('order-cup-paint'),
              size: Size(widget.width, widget.height),
              painter: _CupPainter(
                layers: widget.layers,
                fractions: _shown,
                lid: Curves.bounceOut.transform(_lid.value),
                outline: outline,
                marks: widget.marks,
                target: widget.target,
                drop: _drop.isAnimating ? _drop.value : 0,
                dropColor: widget.dropColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CupPainter extends CustomPainter {
  _CupPainter({
    required this.layers,
    required this.fractions,
    required this.lid,
    required this.outline,
    this.marks = const [],
    this.target,
    this.drop = 0,
    this.dropColor = Colors.black,
  });

  final List<double> marks;
  final double? target;
  final double drop;
  final Color dropColor;

  final List<CupLayer> layers;
  final List<double> fractions;
  final double lid;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final top = h * 0.14; // chừa chỗ cho nắp
    final bottom = h;
    // Ly hình thang: miệng rộng, đáy hẹp.
    final body = Path()
      ..moveTo(w * 0.06, top)
      ..lineTo(w * 0.94, top)
      ..lineTo(w * 0.80, bottom - 4)
      ..quadraticBezierTo(w * 0.78, bottom, w * 0.70, bottom)
      ..lineTo(w * 0.30, bottom)
      ..quadraticBezierTo(w * 0.22, bottom, w * 0.20, bottom - 4)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: 0.55));
    canvas.save();
    canvas.clipPath(body);
    var y = bottom;
    final inner = bottom - top;
    for (var i = 0; i < fractions.length && i < layers.length; i++) {
      final lh = fractions[i] * inner;
      if (lh <= 0.2) continue;
      canvas.drawRect(Rect.fromLTRB(0, y - lh, w, y), Paint()..color = layers[i].color);
      y -= lh;
    }
    // Topping rơi: vài viên rơi từ trên miệng ly xuống mặt nước, lệch nhịp nhau, chạm là mờ dần.
    if (drop > 0) {
      for (var k = 0; k < 7; k++) {
        final start = k * 0.07;
        final t = ((drop - start) / 0.5).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        final cx = w * (0.28 + 0.44 * ((k * 37) % 7) / 6);
        final cy = (top - 6) + (y - (top - 6)) * Curves.easeIn.transform(t);
        canvas.drawCircle(Offset(cx, cy), 4.5, Paint()..color = dropColor);
        canvas.drawCircle(Offset(cx - 1.4, cy - 1.4), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
    }
    canvas.restore();
    // Vạch chia + vạch mốc đúng (vẽ trên thành ly bên trái).
    final mp = Paint()..color = outline.withValues(alpha: 0.55)..strokeWidth = 1.5;
    for (final m in marks) {
      final my = bottom - m.clamp(0.0, 1.0) * inner;
      canvas.drawLine(Offset(w * 0.17 + (1 - m) * w * 0.02, my), Offset(w * 0.17 + 9, my), mp);
    }
    final tg = target;
    if (tg != null) {
      final ty = bottom - tg.clamp(0.0, 1.0) * inner;
      final tp = Paint()..color = Colors.green.shade600..strokeWidth = 2.5;
      for (var x = w * 0.12; x < w * 0.88; x += 9) {
        canvas.drawLine(Offset(x, ty), Offset(math.min(x + 5, w * 0.88), ty), tp);
      }
    }
    // Viền + vệt sáng.
    canvas.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = outline.withValues(alpha: 0.7));
    canvas.drawLine(Offset(w * 0.24, top + 8), Offset(w * 0.32, bottom - 14),
        Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 3..strokeCap = StrokeCap.round);
    if (lid > 0) {
      // Nắp thả từ trên xuống miệng ly + ống hút.
      final lidTop = top - 10 - (1 - lid) * h * 0.5;
      canvas.drawLine(Offset(w * 0.58, lidTop - 2), Offset(w * 0.66, lidTop - h * 0.16),
          Paint()..color = Colors.pink.shade300..strokeWidth = 4..strokeCap = StrokeCap.round);
      final lidRect = RRect.fromLTRBR(w * 0.02, lidTop, w * 0.98, lidTop + 12, const Radius.circular(6));
      canvas.drawRRect(lidRect, Paint()..color = Colors.grey.shade300);
      canvas.drawRRect(lidRect, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outline.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(_CupPainter old) =>
      old.lid != lid ||
      old.fractions != fractions ||
      old.layers != layers ||
      old.outline != outline ||
      old.marks != marks ||
      old.target != target ||
      old.drop != drop;
}

/// Tâm trạng của khách.
enum CustomerMood { waiting, delighted, pleased, upset }

const _faces = {
  CustomerMood.waiting: '🙂',
  CustomerMood.delighted: '😍',
  CustomerMood.pleased: '😊',
  CustomerMood.upset: '😕',
};

const _avatars = ['🧑', '👩', '👨', '👧', '🧒', '👵', '👴', '🧕', '👱‍♀️', '🧔'];

/// Khách đứng quầy: avatar + nét mặt (đổi theo [mood], nảy khi vui / lắc khi buồn) và bong bóng nói đơn.
/// [seed] chọn avatar ổn định cho từng đơn.
class OrderCustomer extends StatelessWidget {
  const OrderCustomer({super.key, required this.seed, required this.mood, required this.child, this.upsetCount = 0});

  final int seed;
  final CustomerMood mood;

  /// Nội dung bong bóng (lời gọi món).
  final Widget child;

  /// Tăng mỗi khi khách buồn — kích hoạt lắc.
  final int upsetCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = _avatars[seed.abs() % _avatars.length];
    final happy = mood == CustomerMood.delighted || mood == CustomerMood.pleased;
    Widget head = Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
      child: Text(avatar, style: const TextStyle(fontSize: 30)),
    );
    // Nét mặt ở góc, bật lên (scale) mỗi lần đổi.
    head = Stack(clipBehavior: Clip.none, children: [
      head,
      Positioned(
        right: -6,
        bottom: -6,
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
          child: Container(
            key: ValueKey(mood),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
            child: Text(_faces[mood]!, key: const Key('order-customer-face'), style: const TextStyle(fontSize: 20)),
          ),
        ),
      ),
    ]);
    // Vui thì nảy một nhịp; buồn thì lắc.
    head = TweenAnimationBuilder<double>(
      key: ValueKey(happy),
      tween: Tween(begin: happy && !reduceMotion ? 0.0 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      child: ShakeOnTrigger(trigger: upsetCount, child: head),
    );
    // Vào quầy: trượt từ trái.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) =>
          Opacity(opacity: t, child: Transform.translate(offset: Offset(-40 * (1 - t), 0), child: child)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        head,
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: child,
          ),
        ),
      ]),
    );
  }
}
