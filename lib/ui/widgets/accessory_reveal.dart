/// Khoảnh khắc "nhận phụ kiện": emoji bật ra giữa màn hình trong vầng sáng màu
/// độ hiếm, tên + nhãn hiện lên rồi tan đi. Chạy ở lớp overlay gốc nên nổi trên
/// cả hộp thoại, không chặn thao tác (IgnorePointer) và tự gỡ sau [_duration].
///
/// Món Sử thi/Huyền thoại có thêm tia lấp lánh bắn ra (Huyền thoại nhiều hơn).
/// Hữu hạn, một lần — không có animation vô hạn. Tôn trọng "giảm chuyển động".
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/accessories.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import 'accessory_rarity.dart';
import 'motion.dart' show reduceMotion;

const _duration = Duration(milliseconds: 2400);

void playAccessoryReveal(BuildContext context, AccessoryDrop drop) {
  if (reduceMotion) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  // Bản dịch tra TRƯỚC khi chèn: overlay dựng lại ngoài cây của context này.
  final l10n = AppLocalizations.of(context)!;
  final name = accessoryName(l10n, drop.accessory.id);
  final rarity = accessoryRarityLabel(l10n, drop.accessory.rarity);
  final badge = drop.isNew ? l10n.marketBadgeNew : null;

  late final OverlayEntry entry;
  var removed = false;
  void dismiss() {
    if (removed) return;
    removed = true;
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    // Material trong suốt: overlay gốc không có Material tổ tiên → Text bị gạch
    // chân vàng (kiểu mặc định khi thiếu DefaultTextStyle của Material).
    builder: (_) => Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
      child: _Reveal(
        accessory: drop.accessory,
        name: name,
        rarityLabel: rarity,
        badge: badge,
        onDone: dismiss,
      ),
    ),
    ),
  );
  overlay.insert(entry);
}

class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.accessory,
    required this.name,
    required this.rarityLabel,
    required this.badge,
    required this.onDone,
  });

  final Accessory accessory;
  final String name;
  final String rarityLabel;
  final String? badge;
  final VoidCallback onDone;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: _duration)
        ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Đoạn [begin, end] của timeline 0..1 → 0..1 (kẹp), nhân [curve].
  double _seg(double t, double begin, double end,
          [Curve curve = Curves.linear]) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(widget.accessory.rarity);
    final sparks = switch (widget.accessory.rarity) {
      AccessoryRarity.legendary => 10,
      AccessoryRarity.epic => 6,
      _ => 0,
    };
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        // Cả khối tan đi ở 15% cuối.
        final fade = 1 - _seg(t, 0.85, 1.0);
        final glow = _seg(t, 0.0, 0.3, Curves.easeOutBack);
        final pop = _seg(t, 0.02, 0.38, Curves.elasticOut);
        final label = _seg(t, 0.28, 0.45, Curves.easeOutCubic);
        final burst = _seg(t, 0.12, 0.7, Curves.easeOutCubic);
        return Opacity(
          opacity: fade,
          child: Center(
            child: SizedBox(
              width: 260,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Vầng sáng: lớn dần, thở nhẹ.
                  Positioned(
                    top: 20,
                    child: Transform.scale(
                      scale: glow * (1 + 0.04 * math.sin(t * 14)),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            color.withValues(alpha: 0.85),
                            color.withValues(alpha: 0.0),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < sparks; i++)
                    Positioned(
                      top: 120,
                      child: Opacity(
                        opacity: (1 - burst).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset.fromDirection(
                            2 * math.pi * i / sparks + 0.3,
                            30 + 90 * burst,
                          ),
                          child: Transform.scale(
                            scale: 0.6 + 0.6 * (i.isEven ? 1 - burst : burst),
                            child: const Text('✨', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      ),
                    ),
                  // Emoji: bật đàn hồi + lắc nhẹ rồi đứng yên.
                  Positioned(
                    top: 52,
                    child: Transform.rotate(
                      angle: -0.25 * (1 - pop),
                      child: Transform.scale(
                        scale: pop,
                        child: Text(
                          widget.accessory.emoji,
                          style: const TextStyle(fontSize: 96),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 190,
                    child: Opacity(
                      opacity: label,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - label)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Text(
                                widget.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RarityChip(
                                    rarity: widget.accessory.rarity,
                                    label: widget.rarityLabel),
                                if (widget.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.badge!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
