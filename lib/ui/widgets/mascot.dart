import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Test bật cờ này để tắt animation lặp (ticker lặp làm pumpAndSettle treo).
/// App thật luôn để false. Xem test/flutter_test_config.dart.
bool debugDisableMascotAnimation = false;

/// Hiển thị animation Lottie nếu asset tồn tại, ngược lại về [emoji] fallback.
///
/// Nhờ [Lottie.asset]'s errorBuilder, widget vẫn chạy bình thường khi CHƯA có
/// file: chỉ cần thả `.json` vào `assets/anim/` (đã khai báo trong pubspec) rồi
/// hot restart là animation tự thay emoji — không phải sửa code.
///
/// Muốn thêm nhân vật khác (mèo, khách VIP...): dùng lại widget này với asset
/// và emoji tương ứng.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    required this.asset,
    required this.emoji,
    this.size = 96,
  });

  /// Đường dẫn asset, ví dụ 'assets/anim/cup.json'.
  final String asset;

  /// Emoji dùng khi chưa có file animation.
  final String emoji;

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        asset,
        fit: BoxFit.contain,
        animate: !debugDisableMascotAnimation,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.7)),
        ),
      ),
    );
  }
}
