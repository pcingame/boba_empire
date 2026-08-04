/// Các công thức kinh tế — HÀM THUẦN, không mutate gì, không phụ thuộc thời gian.
///
/// Đây là mục 5 ("công thức đóng"): thu nhập là hàm tuyến tính theo thời gian,
/// nên ta chỉ cần tính `thu_nhập_mỗi_giây` ở đây, còn việc nhân với dt để cộng
/// tiền nằm ở [simulation.dart]. Online và offline dùng chung các hàm này.
library;

import 'dart:math';

import 'balance.dart';
import 'models.dart';

/// Giá để nâng nguồn thu từ [currentLevel] lên cấp kế tiếp.
///
/// chi_phí = base * growth^level  (đúng công thức trong GDD).
double nextLevelCost(GeneratorConfig config, int currentLevel) =>
    config.baseCost * pow(config.costGrowth, currentLevel).toDouble();

/// Tổng giá để mua liền [count] cấp bắt đầu từ [fromLevel] (chuỗi cấp số nhân).
///
/// Dùng cho nút "mua x10 / mua tối đa" — tính một lần thay vì cộng dồn.
double bulkCost(GeneratorConfig config, int fromLevel, int count) {
  if (count <= 0) return 0;
  final g = config.costGrowth;
  final first = config.baseCost * pow(g, fromLevel).toDouble();
  if (g == 1) return first * count;
  return first * (pow(g, count).toDouble() - 1) / (g - 1);
}

/// Hệ số nhân thu nhập vĩnh viễn từ prestige: 1 + sao * bonus.
double prestigeMultiplier(int stars, double bonusPerStar) =>
    1 + stars * bonusPerStar;

/// Hệ số nhân thu nhập vĩnh viễn từ vật phẩm Kim Cương "Tăng thu nhập".
double permanentMultiplier(int gemBoostLevel) =>
    1 + gemBoostLevel * Balance.gemBoostPerLevel;

/// Giá (Kim Cương) để nâng vật phẩm "Tăng thu nhập" lên cấp kế tiếp.
int gemBoostCost(int currentLevel) =>
    (Balance.gemBoostBaseCost * pow(Balance.gemCostGrowth, currentLevel))
        .ceil();

/// Giá (Kim Cương) để nâng vật phẩm "Kho lạnh offline" lên cấp kế tiếp.
int offlineCapCost(int currentLevel) =>
    (Balance.offlineCapBaseCost * pow(Balance.gemCostGrowth, currentLevel))
        .ceil();

/// Trần thời gian offline (giây) sau khi tính cấp "Kho lạnh offline".
int offlineCapSeconds(int offlineCapLevel) =>
    Balance.maxOfflineSeconds +
    offlineCapLevel * Balance.offlineCapPerLevelSeconds;

/// Thu nhập tự động mỗi giây, CHƯA tính bonus prestige.
double baseIncomePerSecond(GameState state, List<GeneratorConfig> configs) {
  var total = 0.0;
  for (final config in configs) {
    final level = state.levels[config.id] ?? 0;
    total += config.incomePerLevelPerSecond * level;
  }
  return total;
}

/// Thu nhập tự động mỗi giây, ĐÃ tính bonus prestige và [boostMultiplier]
/// (Mưa vàng ×3). Boost mặc định 1.0 nên tính offline không bị dính boost.
double effectiveIncomePerSecond(
  GameState state,
  List<GeneratorConfig> configs, {
  required double bonusPerStar,
  double boostMultiplier = 1.0,
}) =>
    baseIncomePerSecond(state, configs) *
    prestigeMultiplier(state.prestigeStars, bonusPerStar) *
    permanentMultiplier(state.gemBoostLevel) *
    boostMultiplier;

/// Số Sao nhượng quyền tương ứng với tổng thu nhập cả đời.
///
/// Mô hình tích lũy kiểu "angel investor": Sao = floor(k * sqrt(lifetime)).
/// Vì [GameState.lifetimeEarnings] không reset khi prestige, giá trị này chỉ
/// tăng dần; phần chênh lệch là số Sao nhận được ở lần prestige kế tiếp.
int starsForLifetimeEarnings(double lifetimeEarnings, double k) {
  if (lifetimeEarnings <= 0) return 0;
  return (k * sqrt(lifetimeEarnings)).floor();
}
