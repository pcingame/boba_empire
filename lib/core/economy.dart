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

/// Số cấp NHIỀU NHẤT có thể mua liền từ [fromLevel] với [money] Xu (giá đã nhân
/// [costMult] từ perk "Mua sỉ"). Đảo công thức chuỗi cấp số nhân.
int maxAffordableLevels(
  GeneratorConfig config,
  int fromLevel,
  double money,
  double costMult,
) {
  if (money <= 0) return 0;
  final g = config.costGrowth;
  final first = config.baseCost * pow(g, fromLevel).toDouble() * costMult;
  if (money < first) return 0;
  if (g == 1) return (money / first).floor();
  // money ≥ first · (gⁿ − 1)/(g − 1)  ⇒  n ≤ log_g(1 + money·(g−1)/first)
  var n = (log(1 + money * (g - 1) / first) / log(g)).floor();
  // Chỉnh sai số dấu phẩy động ở biên bằng cách đối chiếu lại tổng chính xác.
  if (bulkCost(config, fromLevel, n + 1) * costMult <= money) n += 1;
  while (n > 0 && bulkCost(config, fromLevel, n) * costMult > money) {
    n -= 1;
  }
  return n;
}

/// Thu nhập/giây TĂNG THÊM khi nâng một nguồn thu từ [fromLevel] lên
/// [fromLevel]+[count] (đã tính mốc nhân bội, CHƯA nhân hệ số toàn cục).
double bulkIncomeGain(GeneratorConfig config, int fromLevel, int count) {
  if (count <= 0) return 0;
  final to = fromLevel + count;
  return config.incomePerLevelPerSecond *
      (to * generatorMilestoneMultiplier(to) -
          fromLevel * generatorMilestoneMultiplier(fromLevel));
}

/// Hệ số nhân thu nhập vĩnh viễn từ prestige: 1 + sao * bonus.
double prestigeMultiplier(int stars, double bonusPerStar) =>
    1 + stars * bonusPerStar;

/// Hệ số nhân thu nhập vĩnh viễn từ vật phẩm Kim Cương "Tăng thu nhập".
double permanentMultiplier(int gemBoostLevel) =>
    1 + gemBoostLevel * Balance.gemBoostPerLevel;

/// Giá (Sao) nâng một perk kho prestige từ [level] lên cấp kế: base * 2^level.
int prestigeShopCost(int baseCost, int level) => baseCost * (1 << level);

/// Tổng Sao đã tiêu cho một perk đạt [level] (tổng cấp số nhân, growth 2).
int _prestigeSpentFor(int baseCost, int level) => baseCost * ((1 << level) - 1);

/// Tổng Sao đã tiêu trong kho prestige (mọi perk).
int prestigeStarsSpent(GameState s) =>
    _prestigeSpentFor(Balance.prestigeIncomeBaseCost, s.prestigeIncomeLevel) +
    _prestigeSpentFor(Balance.prestigeTapBaseCost, s.prestigeTapLevel) +
    _prestigeSpentFor(
        Balance.prestigeOfflineBaseCost, s.prestigeOfflineLevel) +
    _prestigeSpentFor(
        Balance.prestigeStartCashBaseCost, s.prestigeStartCashLevel) +
    _prestigeSpentFor(
        Balance.prestigeKeepStageBaseCost, s.prestigeKeepStageLevel) +
    _prestigeSpentFor(
        Balance.prestigeDiscountBaseCost, s.prestigeDiscountLevel);

/// Số Sao còn có thể tiêu (tổng Sao trừ đã tiêu). KHÔNG đụng số Sao dùng cho
/// passive/accounting prestige → tiêu rồi prestige cũng không lấy lại được.
int prestigeStarsSpendable(GameState s) =>
    s.prestigeStars - prestigeStarsSpent(s);

/// Hệ số nhân thu nhập từ perk "Siêu thu nhập".
double prestigeIncomeMultiplier(int level) =>
    1 + level * Balance.prestigeIncomePerLevel;

/// Hệ số nhân giá trị chạm từ perk "Siêu chạm".
double prestigeTapMultiplier(int level) =>
    1 + level * Balance.prestigeTapPerLevel;

/// Hệ số nhân thu nhập offline từ perk "Siêu offline".
double prestigeOfflineMultiplier(int level) =>
    1 + level * Balance.prestigeOfflinePerLevel;

/// Xu nhận ngay sau Nhượng quyền từ perk "Vốn khởi nghiệp" (cấp 0 → 0).
double startCashAfterPrestige(int level) =>
    level <= 0 ? 0 : 50 * pow(25, level).toDouble();

/// Giai đoạn giữ lại sau Nhượng quyền: `1 + cấp perk "Giữ giai đoạn"`, kẹp
/// trong [1, stageHiện tại].
int keptStageAfterPrestige(int currentStage, int keepStageLevel) =>
    (1 + keepStageLevel).clamp(1, currentStage);

/// Hệ số nhân giá nâng cấp nguồn thu từ perk "Mua sỉ" (≤ 1, sàn floor).
double upgradeCostMultiplier(int discountLevel) {
  final m = 1 - discountLevel * Balance.prestigeDiscountPerLevel;
  return m < Balance.prestigeDiscountFloor ? Balance.prestigeDiscountFloor : m;
}

/// Giá (Kim Cương) để nâng vật phẩm "Tăng thu nhập" lên cấp kế tiếp.
int gemBoostCost(int currentLevel) =>
    (Balance.gemBoostBaseCost * pow(Balance.gemCostGrowth, currentLevel))
        .ceil();

/// Giá (Kim Cương) để nâng vật phẩm "Kho lạnh offline" lên cấp kế tiếp.
int offlineCapCost(int currentLevel) =>
    (Balance.offlineCapBaseCost * pow(Balance.gemCostGrowth, currentLevel))
        .ceil();

/// Giá 💎 để "mở giai đoạn tức thì" khi đang ở [currentStage] (mở sang
/// currentStage+1). Trả về giá phần tử cuối nếu vượt bảng.
int instantStageGemCost(int currentStage) {
  final i = (currentStage - 1).clamp(0, Balance.instantStageGemCost.length - 1);
  return Balance.instantStageGemCost[i];
}

/// Trần thời gian offline (giây) sau khi tính cấp "Kho lạnh offline".
int offlineCapSeconds(int offlineCapLevel) =>
    Balance.maxOfflineSeconds +
    offlineCapLevel * Balance.offlineCapPerLevelSeconds;

/// Hệ số nhân thu nhập của MỘT nguồn thu theo mốc cấp: cứ mỗi
/// [Balance.milestoneStep] cấp lại ×[Balance.milestoneFactor] (25→×2, 50→×4...).
/// Cấp 0..24 = ×1, nên không đổi cân bằng ở giai đoạn đầu.
double generatorMilestoneMultiplier(int level) =>
    pow(Balance.milestoneFactor, level ~/ Balance.milestoneStep).toDouble();

/// Số cấp còn thiếu để chạm mốc nhân bội kế tiếp (1..milestoneStep).
int levelsToNextMilestone(int level) =>
    Balance.milestoneStep - (level % Balance.milestoneStep);

/// Tổng số "mốc vàng" mọi nguồn thu đã vượt — chỉ tính từ mốc thứ
/// ([Balance.milestoneGlobalFreeTiers]+1) trở lên. Mỗi mốc vàng cộng
/// [Balance.milestoneGlobalBonus] vào hệ số thu nhập toàn cục.
int globalMilestoneTiers(
  GameState state, [
  List<GeneratorConfig> configs = Balance.generators,
]) {
  var n = 0;
  for (final config in configs) {
    final tiers = (state.levels[config.id] ?? 0) ~/ Balance.milestoneStep;
    final counted = tiers - Balance.milestoneGlobalFreeTiers;
    if (counted > 0) n += counted;
  }
  return n;
}

/// Hệ số thu nhập TOÀN CỤC từ "mốc vàng" (xem [globalMilestoneTiers]).
double globalMilestoneMultiplier(
  GameState state, [
  List<GeneratorConfig> configs = Balance.generators,
]) =>
    1 + globalMilestoneTiers(state, configs) * Balance.milestoneGlobalBonus;

/// Thu nhập/giây TĂNG THÊM khi nâng một nguồn thu từ [level] lên [level]+1,
/// CHƯA nhân hệ số toàn cục (prestige/gem/x2). Có tính mốc nhân bội, nên cấp
/// chạm mốc cho phần tăng lớn hơn hẳn.
double marginalIncomePerSecond(GeneratorConfig config, int level) =>
    config.incomePerLevelPerSecond *
    ((level + 1) * generatorMilestoneMultiplier(level + 1) -
        level * generatorMilestoneMultiplier(level));

/// Thu nhập tự động mỗi giây, CHƯA tính bonus prestige. Đã gồm mốc nhân bội
/// riêng của từng nguồn thu.
double baseIncomePerSecond(GameState state, List<GeneratorConfig> configs) {
  var total = 0.0;
  for (final config in configs) {
    final level = state.levels[config.id] ?? 0;
    total += config.incomePerLevelPerSecond *
        level *
        generatorMilestoneMultiplier(level);
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
    globalMilestoneMultiplier(state, configs) *
    prestigeMultiplier(state.prestigeStars, bonusPerStar) *
    permanentMultiplier(state.gemBoostLevel) *
    prestigeIncomeMultiplier(state.prestigeIncomeLevel) *
    (state.doubleIncomeOwned ? 2.0 : 1.0) *
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
