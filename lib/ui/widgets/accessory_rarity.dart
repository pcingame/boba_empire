import 'package:flutter/material.dart';

import '../../core/accessories.dart';

/// Màu quy ước theo độ hiếm (xám/xanh/tím/vàng), tông pastel — cố định, không
/// lấy từ theme, giống cách hầu hết game sưu tập dùng màu hiếm cố định xuyên
/// suốt light/dark mode để người chơi quét nhanh bằng mắt không cần đọc chữ.
/// Chữ đặt lên màu này phải dùng [rarityOnColor] (chữ trắng chỉ đạt 1.5–2.4:1
/// trên nền pastel). Dùng chung giữa Kho phụ kiện và Chợ Phụ kiện.
Color rarityColor(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => const Color(0xFFB0BEC5),
      AccessoryRarity.rare => const Color(0xFF90CAF9),
      AccessoryRarity.epic => const Color(0xFFCE93D8),
      AccessoryRarity.legendary => const Color(0xFFFFCC80),
    };

/// Chữ/icon đặt trên [rarityColor] — nâu tối, 5.7–9.3:1 trên cả 4 màu.
const rarityOnColor = Color(0xFF3B2A1A);

/// Chip nhỏ nền màu độ hiếm, chữ tối — cùng kiểu đã dùng ở ô Kho phụ kiện.
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
                color: rarityOnColor,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}
