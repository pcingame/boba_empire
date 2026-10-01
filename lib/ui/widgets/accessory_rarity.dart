import 'package:flutter/material.dart';

import '../../core/accessories.dart';

/// Màu quy ước theo độ hiếm (xám/xanh/tím/vàng) — cố định, không lấy từ
/// theme, giống cách hầu hết game sưu tập dùng màu hiếm cố định xuyên suốt
/// light/dark mode để người chơi quét nhanh bằng mắt không cần đọc chữ. Dùng
/// chung giữa Kho phụ kiện và Chợ Phụ kiện — cùng 1 hệ thống trực quan.
Color rarityColor(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => const Color(0xFF9E9E9E),
      AccessoryRarity.rare => const Color(0xFF42A5F5),
      AccessoryRarity.epic => const Color(0xFFAB47BC),
      AccessoryRarity.legendary => const Color(0xFFFFA726),
    };

/// Chip nhỏ nền màu độ hiếm, chữ trắng — cùng kiểu đã dùng ở ô Kho phụ kiện.
class RarityChip extends StatelessWidget {
  const RarityChip({super.key, required this.rarity, required this.label});
  final AccessoryRarity rarity;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: rarityColor(rarity),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}
