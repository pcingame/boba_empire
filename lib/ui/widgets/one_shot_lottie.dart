import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Phát một hiệu ứng Lottie MỘT LẦN ở lớp overlay rồi tự gỡ.
///
/// Dùng cho phản hồi tức thời: coin bắn khi chạm, pháo giấy khi mua, pháo hoa
/// khi prestige... Nếu file asset chưa có thì **bỏ qua** (không hiện gì) — hiệu
/// ứng chỉ để trang trí nên không cần fallback.
///
/// Gọi ở bất cứ callback nào có [BuildContext]:
/// ```dart
/// playEffect(context, AnimAssets.confetti);
/// ```
void playEffect(
  BuildContext context,
  String asset, {
  double size = 200,
  Offset? center, // toạ độ toàn cục; null = giữa màn hình
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  OverlayEntry? entry;
  var removed = false;
  void dismiss() {
    if (removed) return;
    removed = true;
    entry?.remove();
  }

  entry = OverlayEntry(
    builder: (_) {
      final effect = _OneShotLottie(asset: asset, size: size, onDone: dismiss);
      // IgnorePointer để hiệu ứng không chặn thao tác của game bên dưới.
      if (center == null) {
        return IgnorePointer(child: Center(child: effect));
      }
      return Positioned(
        left: center.dx - size / 2,
        top: center.dy - size / 2,
        child: IgnorePointer(child: effect),
      );
    },
  );
  overlay.insert(entry);
}

class _OneShotLottie extends StatefulWidget {
  const _OneShotLottie({
    required this.asset,
    required this.size,
    required this.onDone,
  });

  final String asset;
  final double size;
  final VoidCallback onDone;

  @override
  State<_OneShotLottie> createState() => _OneShotLottieState();
}

class _OneShotLottieState extends State<_OneShotLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        widget.asset,
        controller: _controller,
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration
            ..forward().whenComplete(widget.onDone);
        },
        errorBuilder: (_, _, _) {
          // Chưa có file → gỡ ngay sau frame này (không hiện gì).
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onDone());
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
