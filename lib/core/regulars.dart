/// Khách quen: 12 người quen ghé quán, mỗi ngày 4 người "ghé". Phục vụ (tốn Xu) bằng cách chọn 1 trong 3 đồ uống:
/// đúng món họ thích +2 điểm thân thiết, sai +1 (và lộ món họ thích). Đủ điểm thì lên cấp (tối đa 5): +💎 và
/// +[regularIncomePerLevel] thu nhập mỗi cấp. Giữ qua Nhượng quyền. Số liệu ước lượng, chưa playtest.
library;

import 'dart:math';

const int regularCount = 12;
const int regularVisitsPerDay = 4;
const int regularMaxLevel = 5;
const double regularIncomePerLevel = 0.005;
const List<int> regularLevelPoints = [3, 8, 15, 25, 40];
const List<String> regularDrinks = ['🧋', '🍵', '🥤', '🧃', '☕', '🍹'];
const List<String> regularNames = [
  'Mai', 'Tuấn', 'Lan', 'Hùng', 'Yuki', 'Minho', 'Sofia', 'Ana', 'Pim', 'Rizky', 'Chloé', 'Kenji',
];

/// Món yêu thích của khách [i] (cố định).
int regularFavorite(int i) => (i * 5 + 2) % regularDrinks.length;

int regularPoints(Map<String, int> pts, int i) => (pts['$i'] ?? 0).clamp(0, 1 << 20);

int regularLevelOf(int points) {
  var lv = 0;
  for (final need in regularLevelPoints) {
    if (points >= need) lv++;
  }
  return lv;
}

int regularLevel(Map<String, int> pts, int i) => regularLevelOf(regularPoints(pts, i));

/// Bộ khách ghé ngày [day] — xác định theo ngày.
List<int> regularsVisiting(int day) {
  final ids = List.generate(regularCount, (i) => i)..shuffle(Random(day * 2654435761 ^ 0x5bd1e995));
  return ids.take(regularVisitsPerDay).toList()..sort();
}

/// 3 đồ uống để chọn cho khách [i] hôm [day]: luôn có món họ thích, 2 món còn lại xác định theo ngày.
List<int> regularOptions(int i, int day) {
  final fav = regularFavorite(i);
  final others = [for (var d = 0; d < regularDrinks.length; d++) if (d != fav) d]
    ..shuffle(Random(day * 31 + i));
  return ([fav, others[0], others[1]]..shuffle(Random(day * 17 + i * 7)));
}

/// Hệ số nhân thu nhập từ tổng cấp mọi khách quen.
double regularIncomeMultiplier(Map<String, int> pts) {
  var total = 0;
  for (var i = 0; i < regularCount; i++) {
    total += regularLevel(pts, i);
  }
  return 1 + total * regularIncomePerLevel;
}

/// 💎 thưởng khi lên tới cấp [level].
int regularLevelGems(int level) => 20 * level;

/// Xu để phục vụ một lần: 5 phút thu nhập (sàn 500).
double regularServeCost(double income) => max(500.0, (income.isFinite ? income : 0) * 300);

/// Điểm nhận được khi chọn [drink] cho khách [i].
int regularPointsFor(int i, int drink) => drink == regularFavorite(i) ? 2 : 1;
