/// Trang trí quán: 20 món thuộc 4 chủ đề đặt vào 8 ô (1 bảng hiệu · 2 tường · 2 quầy · 3 sàn). Mỗi món đặt +0.5% thu
/// nhập; đặt ≥3 món cùng chủ đề +2%, đủ 5 món +6% (thay vì +2%). Món thường mua bằng Xu, món hiếm (bảng hiệu, tranh tường)
/// bằng 💎. Giữ qua Nhượng quyền/Kỷ Nguyên. Số liệu ước lượng, chưa playtest.
library;

import 'dart:math';

enum DecorSlotKind { sign, wall, counter, floor }

/// Ô trên cảnh: khoá lưu là `<kind>#<chỉ số>`; số ô mỗi loại ở [decorSlotCount].
const Map<DecorSlotKind, int> decorSlotCount = {
  DecorSlotKind.sign: 1,
  DecorSlotKind.wall: 2,
  DecorSlotKind.counter: 2,
  DecorSlotKind.floor: 3,
};

/// Tất cả khoá ô theo thứ tự cố định.
final List<String> decorSlotKeys = [
  for (final k in DecorSlotKind.values)
    for (var i = 0; i < decorSlotCount[k]!; i++) '${k.name}#$i',
];

DecorSlotKind? decorSlotKind(String key) {
  final parts = key.split('#');
  if (parts.length != 2) return null;
  final kind = DecorSlotKind.values.where((k) => k.name == parts[0]).firstOrNull;
  final idx = int.tryParse(parts[1]);
  if (kind == null || idx == null || idx < 0 || idx >= decorSlotCount[kind]!) return null;
  return kind;
}

class DecorItem {
  const DecorItem(this.id, this.theme, this.kind, this.emoji, {this.gems = 0});
  final String id;
  final int theme;
  final DecorSlotKind kind;
  final String emoji;

  /// >0: món hiếm mua bằng 💎; 0: mua bằng Xu.
  final int gems;
}

const int decorThemeCount = 4;
const List<String> decorThemeEmoji = ['🎞️', '⛩️', '🌴', '🔮'];
const int decorThemeSize = 5;

const List<DecorItem> decorItems = [
  // 0 · Cổ điển
  DecorItem('retro_sign', 0, DecorSlotKind.sign, '🪧', gems: 120),
  DecorItem('retro_wall', 0, DecorSlotKind.wall, '🖼️', gems: 80),
  DecorItem('retro_counter', 0, DecorSlotKind.counter, '☕'),
  DecorItem('retro_floor1', 0, DecorSlotKind.floor, '🪑'),
  DecorItem('retro_floor2', 0, DecorSlotKind.floor, '🕰️'),
  // 1 · Zen Nhật
  DecorItem('zen_sign', 1, DecorSlotKind.sign, '⛩️', gems: 120),
  DecorItem('zen_wall', 1, DecorSlotKind.wall, '🎏', gems: 80),
  DecorItem('zen_counter', 1, DecorSlotKind.counter, '🍵'),
  DecorItem('zen_floor1', 1, DecorSlotKind.floor, '🎋'),
  DecorItem('zen_floor2', 1, DecorSlotKind.floor, '🪨'),
  // 2 · Nhiệt đới
  DecorItem('tropic_sign', 2, DecorSlotKind.sign, '🌴', gems: 120),
  DecorItem('tropic_wall', 2, DecorSlotKind.wall, '🦜', gems: 80),
  DecorItem('tropic_counter', 2, DecorSlotKind.counter, '🍍'),
  DecorItem('tropic_floor1', 2, DecorSlotKind.floor, '🪴'),
  DecorItem('tropic_floor2', 2, DecorSlotKind.floor, '🌺'),
  // 3 · Neon tương lai
  DecorItem('neon_sign', 3, DecorSlotKind.sign, '💡', gems: 120),
  DecorItem('neon_wall', 3, DecorSlotKind.wall, '🌌', gems: 80),
  DecorItem('neon_counter', 3, DecorSlotKind.counter, '🤖'),
  DecorItem('neon_floor1', 3, DecorSlotKind.floor, '🛸'),
  DecorItem('neon_floor2', 3, DecorSlotKind.floor, '🔮'),
];

final Map<String, DecorItem> _byId = {for (final d in decorItems) d.id: d};

DecorItem? decorById(String id) => _byId[id];

const double decorPerItem = 0.005;
const double decorSet3Bonus = 0.02;
const double decorSet5Bonus = 0.06;

/// Số món đã đặt thuộc chủ đề [theme].
int decorThemeCountPlaced(Map<String, String> placed, int theme) =>
    placed.values.where((id) => _byId[id]?.theme == theme).length;

/// Thưởng bộ của chủ đề: ≥5 món +6%, ≥3 món +2%.
double decorSetBonus(int placedInTheme) =>
    placedInTheme >= decorThemeSize ? decorSet5Bonus : (placedInTheme >= 3 ? decorSet3Bonus : 0);

/// Hệ số nhân thu nhập từ các món đang đặt (id không hợp lệ bị bỏ qua).
double decorIncomeMultiplier(Map<String, String> placed) {
  var bonus = 0.0;
  for (final id in placed.values) {
    if (_byId.containsKey(id)) bonus += decorPerItem;
  }
  for (var t = 0; t < decorThemeCount; t++) {
    bonus += decorSetBonus(decorThemeCountPlaced(placed, t));
  }
  return 1 + bonus;
}

/// Chủ đề đủ bộ (5 món đã đặt) — dùng cho hiệu ứng rực sáng.
Set<int> decorCompleteThemes(Map<String, String> placed) =>
    {for (var t = 0; t < decorThemeCount; t++) if (decorThemeCountPlaced(placed, t) >= decorThemeSize) t};

/// Xu mua món thường: 30 phút thu nhập (sàn 5000).
double decorXuCost(double income) => max(5000.0, (income.isFinite ? income : 0.0) * 1800);

/// Món [id] có đặt được vào ô [slotKey] không.
bool decorFits(String slotKey, String id) {
  final kind = decorSlotKind(slotKey);
  final item = _byId[id];
  return kind != null && item != null && item.kind == kind;
}

/// Làm sạch bộ đặt đọc từ save: bỏ ô lạ, món lạ, sai loại, món chưa sở hữu, trùng một món đặt hai ô.
Map<String, String> decorSanitizePlaced(Object? raw, Set<String> owned) {
  final out = <String, String>{};
  if (raw is! Map) return out;
  final used = <String>{};
  for (final slot in decorSlotKeys) {
    final id = raw[slot];
    if (id is String && owned.contains(id) && decorFits(slot, id) && used.add(id)) out[slot] = id;
  }
  return out;
}
