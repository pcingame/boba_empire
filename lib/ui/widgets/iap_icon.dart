import 'package:flutter/material.dart';

import '../../iap/iap_products.dart';

/// Biểu tượng của một gói IAP ở cửa hàng 💎: ô bo tròn nền dải màu + emoji lớn. Vẽ bằng
/// code (không file ảnh) nên nhẹ và đổi màu/emoji ở một chỗ.
class IapIcon extends StatelessWidget {
  const IapIcon({
    super.key,
    required this.product,
    this.size = 46,
    this.firstBonus = false,
  });

  final IapProduct product;

  /// Gói 💎 chưa mua lần nào: hiện nhãn đỏ "x2" (thưởng mua lần đầu).
  final bool firstBonus;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = iapArt(product);
    return Container(
      key: Key('iap-icon-${product.id}'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: art.colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(art.emoji, style: TextStyle(fontSize: size * 0.55)),
          if (firstBonus)
            Positioned(
              right: -size * 0.1,
              top: -size * 0.1,
              child: Container(
                key: const Key('iap-first-bonus'),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x2',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (art.badge != null)
            Positioned(
              right: -size * 0.04,
              bottom: -size * 0.02,
              child: Text(
                art.badge!,
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 3, color: Colors.black87)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IapArt {
  const IapArt(this.emoji, this.colors, {this.badge});
  final String emoji;
  final List<Color> colors;

  /// Chữ nhỏ ở góc dưới phải (vd "×2").
  final String? badge;
}

/// Hình của từng gói: gói 💎 tăng dần theo giá trị (viên ngọc → túi → quà → vương miện →
/// cúp), các gói khác theo công dụng.
IapArt iapArt(IapProduct p) => switch (p) {
      IapProduct.gemsSmall =>
        const IapArt('💎', [Color(0xFF81D4FA), Color(0xFF4FC3F7)]),
      IapProduct.gemsMedium =>
        const IapArt('💰', [Color(0xFFA5D6A7), Color(0xFF66BB6A)]),
      IapProduct.gemsLarge =>
        const IapArt('🎁', [Color(0xFFF48FB1), Color(0xFFEC407A)]),
      IapProduct.gemsHuge =>
        const IapArt('👑', [Color(0xFFCE93D8), Color(0xFF8E24AA)]),
      IapProduct.gemsMega =>
        const IapArt('🏆', [Color(0xFFFFE082), Color(0xFFFF8F00)]),
      IapProduct.removeAds =>
        const IapArt('🚫', [Color(0xFFEF9A9A), Color(0xFFE53935)]),
      IapProduct.doubleIncome =>
        const IapArt('🪙', [Color(0xFFFFE082), Color(0xFFFFB300)], badge: '×2'),
      IapProduct.piggyBreak =>
        const IapArt('🐷', [Color(0xFFF8BBD0), Color(0xFFF06292)]),
      IapProduct.vip30 =>
        const IapArt('🎫', [Color(0xFFB39DDB), Color(0xFF5E35B1)]),
      IapProduct.starterPack =>
        const IapArt('🚀', [Color(0xFF90CAF9), Color(0xFF1E88E5)]),
      IapProduct.coldStorage =>
        const IapArt('❄️', [Color(0xFFB3E5FC), Color(0xFF0288D1)]),
      IapProduct.comboNoAdsX2 =>
        const IapArt('🚫', [Color(0xFFFFCC80), Color(0xFFE64A19)], badge: '×2'),
    };
