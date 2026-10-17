/// "Món của ngày": mỗi ngày (UTC) MỘT phụ kiện cụ thể mua thẳng bằng 💎, một lần/ngày. Độ hiếm xoay theo
/// ngày trong tuần; món được chọn là món CHƯA CÓ đầu tiên theo thứ tự trộn cố định của ngày (nên người chơi
/// luôn nhắm được món còn thiếu mà không phụ thuộc may rủi). Giá là ước lượng chưa playtest — cố ý đắt hơn gói
/// ngẫu nhiên cùng độ hiếm vì đây là mua đích danh.
library;

import 'accessories.dart';

/// Độ hiếm theo `dayIndex % 7` (huyền thoại mỗi tuần một ngày).
const List<AccessoryRarity> dailyItemRarityCycle = [
  AccessoryRarity.rare,
  AccessoryRarity.common,
  AccessoryRarity.epic,
  AccessoryRarity.common,
  AccessoryRarity.rare,
  AccessoryRarity.epic,
  AccessoryRarity.legendary,
];

/// Giá (💎) theo độ hiếm.
int dailyItemPrice(AccessoryRarity r) => switch (r) {
      AccessoryRarity.common => 40,
      AccessoryRarity.rare => 120,
      AccessoryRarity.epic => 350,
      AccessoryRarity.legendary => 900,
    };

/// Băm FNV-1a ổn định (không dùng `hashCode`/`Random` vì không đảm bảo giữa các phiên bản Dart).
int _fnv(int day, String id) {
  var h = 0x811c9dc5 ^ day;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// Món của ngày [dayIndex] cho người đang sở hữu [owned]: món chưa có đầu tiên theo thứ tự trộn của ngày; nếu đã
/// có hết cả độ hiếm đó thì lấy món đầu tiên (mua sẽ ra bản dư).
Accessory dailyItemFor(int dayIndex, Set<String> owned) {
  final rarity = dailyItemRarityCycle[dayIndex % dailyItemRarityCycle.length];
  final pool = [for (final a in accessories) if (a.rarity == rarity) a]
    ..sort((a, b) {
      final c = _fnv(dayIndex, a.id).compareTo(_fnv(dayIndex, b.id));
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return pool.firstWhere((a) => !owned.contains(a.id), orElse: () => pool.first);
}
