/// Nhân viên: 6 tổ trưởng, mỗi người tăng thu nhập của một dải 3 giai đoạn.
/// Thuê bằng 💎 (cấp 0→1), nâng tiếp bằng Xu. Giữ qua Nhượng quyền. Số liệu ước lượng, chưa playtest.
library;

import 'dart:math';

import 'models.dart';

const int staffCount = 6;
const int staffMaxLevel = 20;
const double staffPerLevel = 0.05;
const int _stagesPerStaff = 3;

/// Nhân viên phụ trách giai đoạn [stage] (1..18).
int staffOfStage(int stage) => ((stage - 1) ~/ _stagesPerStaff).clamp(0, staffCount - 1);

int staffLevel(Map<String, int> staff, int i) => (staff['$i'] ?? 0).clamp(0, staffMaxLevel);

/// Hệ số nhân thu nhập của nguồn thu thuộc giai đoạn [stage].
double staffMultiplier(Map<String, int> staff, int stage) =>
    1 + staffLevel(staff, staffOfStage(stage)) * staffPerLevel;

/// Giá 💎 để thuê nhân viên [i].
int staffHireGems(int i) => 50 * (i + 1);

/// Giá Xu nâng nhân viên [i] từ [level] (≥1) lên cấp kế: 8 × giá gốc nguồn thu rẻ nhất dải × 1.4^level.
double staffUpgradeCost(int i, int level, List<GeneratorConfig> configs) {
  final base = configs
      .where((c) => staffOfStage(c.stage) == i)
      .map((c) => c.baseCost)
      .fold<double>(double.infinity, min);
  return (base.isFinite ? base : 100) * 8 * pow(1.4, level).toDouble();
}
