import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'effects_quality.dart';
import 'motion.dart' show reduceMotion;

/// Gộp bớt hiệu ứng khi bị gọi liên tục quá nhanh (chạm liên tục kiểu idle/
/// clicker) — [playEffect] dựng MỚI 1 OverlayEntry + AnimationController +
/// render Lottie MỖI LẦN gọi; không giới hạn thì gọi càng nhanh, hiệu ứng
/// càng chồng lên nhau càng nhiều, tự nó gây giật khung hình (không phải do
/// 1 hiệu ứng đơn lẻ nặng). Cùng nguyên lý với `SfxGate`
/// (lib/audio/audio_service.dart) nhưng tách riêng — chỉ 1 chỗ cần gộp
/// (hiệu ứng đồng xu khi chạm), không phải 1 họ nhiều loại như SfxGate với
/// enum Sfx, nên không cần tổng quát hoá.
class TapEffectGate {
  TapEffectGate({required this.minGapMs});

  /// Khoảng cách tối thiểu (ms) giữa 2 lần cho phép phát hiệu ứng.
  final int minGapMs;
  int? _lastMs;

  /// Cho phép phát hiệu ứng tại thời điểm [nowMs] không? Nếu có thì ghi lại
  /// mốc, giống [SfxGate.allow]. Lần gọi đầu tiên LUÔN được phép — [_lastMs]
  /// null (chưa từng phát) chứ không mặc định 0, tránh bị chặn nhầm khi
  /// [nowMs] nhỏ (VD test bơm đồng hồ bắt đầu từ 0).
  bool allow(int nowMs) {
    final last = _lastMs;
    if (last != null && nowMs - last < minGapMs) return false;
    _lastMs = nowMs;
    return true;
  }
}

/// Số hiệu ứng một-lần đang sống (mọi nơi gọi [playEffect] dùng chung một trần).
int _liveEffects = 0;

/// Chỉ cho test: gỡ cây giữa lúc còn hiệu ứng sống làm bộ đếm kẹt, ảnh hưởng test sau.
@visibleForTesting
void debugResetLiveEffects() => _liveEffects = 0;

int _maxLiveEffects(EffectsQuality q) => switch (q) {
      EffectsQuality.off => 0,
      EffectsQuality.low => 2,
      EffectsQuality.medium => 3,
      EffectsQuality.high => 5,
    };

/// Tâm (toạ độ toàn cục) của widget có [context] — để phát hiệu ứng đúng chỗ vừa bấm. Null nếu chưa
/// có kích thước.
Offset? effectCenterOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// Phát một hiệu ứng Lottie MỘT LẦN ở lớp overlay rồi tự gỡ.
///
/// Theo mức chất lượng ([EffectsController]): Tắt / giảm chuyển động = không phát; Thấp bỏ hiệu ứng
/// [heavy] (pháo giấy, pháo hoa… nhiều lớp); và mọi mức đều có trần số hiệu ứng sống cùng lúc để các
/// lần gọi dồn dập không chồng lên nhau gây giật. Mặc định [heavy] = true (an toàn cho nơi gọi cũ);
/// hiệu ứng nhỏ (tia sáng, xu bay…) truyền `heavy: false`.
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
  // Phát nhanh hơn (>1) cho hiệu ứng dài nhưng chỉ là trang trí — ngắn hơn thì
  // ít bản chồng nhau cùng lúc hơn.
  double speed = 1.0,
  // Gọi đúng MỘT lần khi hiệu ứng kết thúc/bị gỡ — để chỗ gọi đếm số hiệu ứng
  // đang sống và giới hạn đồng thời.
  VoidCallback? onFinished,
  bool heavy = true,
}) {
  final quality = EffectsController.instance.quality.value;
  if (reduceMotion || (heavy && quality == EffectsQuality.low)) {
    onFinished?.call(); // không phát: vẫn "kết thúc" để chỗ gọi đếm đúng
    return;
  }
  if (_liveEffects >= _maxLiveEffects(quality)) {
    onFinished?.call();
    return;
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onFinished?.call();
    return;
  }
  _liveEffects++;

  OverlayEntry? entry;
  var removed = false;
  void dismiss() {
    if (removed) return;
    removed = true;
    _liveEffects--;
    entry?.remove();
    entry?.dispose();
    onFinished?.call();
  }

  entry = OverlayEntry(
    builder: (_) {
      final effect = _OneShotLottie(
          asset: asset, size: size, speed: speed, onDone: dismiss);
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
    required this.speed,
    required this.onDone,
  });

  final String asset;
  final double size;
  final double speed;
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
        // Chỉ là trang trí: vẽ 30 khung/giây thay vì 60 (file gốc 60fps, nhiều lớp)
        // — nửa chi phí vẽ mỗi khung mà mắt gần như không nhận ra.
        frameRate: const FrameRate(30),
        onLoaded: (composition) {
          _controller
            ..duration = composition.duration * (1 / widget.speed)
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
