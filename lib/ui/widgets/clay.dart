import 'package:flutter/material.dart';

/// Thẻ "đất sét" (claymorphism): bo tròn dày, bóng kép (bóng tối dưới + highlight
/// sáng trên) tạo cảm giác mềm, phồng — phong cách casual game.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 20,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final base = color ?? theme.colorScheme.surface;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.05 : 0.75),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Chip "đất sét" nhỏ gọn — dùng cho số Kim Cương/Xu ở đầu trang.
class ClayChip extends StatelessWidget {
  const ClayChip({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
