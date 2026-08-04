/// Nơi DUY NHẤT được phép mutate [GameState].
///
/// Các hàm ở đây gọi công thức thuần trong [economy.dart] rồi áp kết quả lên
/// trạng thái: tick thời gian thực, chạm ly, mua nâng cấp, tính tiền offline,
/// và prestige.
library;

import 'dart:math';

import 'balance.dart';
import 'economy.dart';
import 'models.dart';

/// Kết quả một lần chạm ly. [boostMultiplier] là hệ số Mưa vàng đang có.
double tap(GameState state, {double boostMultiplier = 1.0}) {
  final gain = state.tapValue *
      prestigeMultiplier(state.prestigeStars, Balance.bonusPerStar) *
      permanentMultiplier(state.gemBoostLevel) *
      boostMultiplier;
  _credit(state, gain);
  return gain;
}

/// Cộng thu nhập tự động cho khoảng thời gian [dt] giây (dùng khi app đang mở).
void tick(
  GameState state,
  double dt, {
  List<GeneratorConfig> configs = Balance.generators,
  double boostMultiplier = 1.0,
}) {
  if (dt <= 0) return;
  final income = effectiveIncomePerSecond(
        state,
        configs,
        bonusPerStar: Balance.bonusPerStar,
        boostMultiplier: boostMultiplier,
      ) *
      dt;
  _credit(state, income);
}

/// Nâng một nguồn thu lên 1 cấp nếu đủ tiền và đã mở khóa giai đoạn. Trả về
/// true nếu mua thành công.
bool buyUpgrade(
  GameState state,
  String generatorId, {
  List<GeneratorConfig> configs = Balance.generators,
}) {
  final config = configs.firstWhere((c) => c.id == generatorId);
  if (config.stage > state.stage) return false; // chưa mở khóa
  final level = state.levels[generatorId] ?? 0;
  final cost = nextLevelCost(config, level);
  if (state.money < cost) return false;
  state.money -= cost;
  state.levels[generatorId] = level + 1;
  return true;
}

/// Mở khóa giai đoạn kế tiếp bằng tiền. Trả về true nếu đủ tiền và còn giai
/// đoạn để mở.
bool unlockNextStage(GameState state) {
  final next = Balance.nextStageConfig(state.stage);
  if (next == null) return false;
  if (state.money < next.unlockCost) return false;
  state.money -= next.unlockCost;
  state.stage = next.stage;
  return true;
}

/// Mua/nâng vật phẩm "Tăng thu nhập" bằng Kim Cương. True nếu đủ gems.
bool buyGemBoost(GameState state) {
  final cost = gemBoostCost(state.gemBoostLevel);
  if (state.gems < cost) return false;
  state.gems -= cost;
  state.gemBoostLevel += 1;
  return true;
}

/// Mua/nâng vật phẩm "Kho lạnh offline" bằng Kim Cương. True nếu đủ gems.
bool buyOfflineCap(GameState state) {
  final cost = offlineCapCost(state.offlineCapLevel);
  if (state.gems < cost) return false;
  state.gems -= cost;
  state.offlineCapLevel += 1;
  return true;
}

/// Tính tiền kiếm được lúc offline khi mở lại app.
///
/// - Chống lùi giờ (mục 8): nếu [nowMillis] < lastSeen thì coi như 0 và chỉ
///   cập nhật mốc thời gian.
/// - Cap theo [Balance.maxOfflineSeconds].
///
/// Trả về số Xu vừa cộng (để UI hiện popup "Bạn kiếm được X khi vắng mặt").
double applyOfflineEarnings(
  GameState state,
  int nowMillis, {
  List<GeneratorConfig> configs = Balance.generators,
  int maxOfflineSeconds = Balance.maxOfflineSeconds,
}) {
  final elapsedMs = nowMillis - state.lastSeenMillis;
  state.lastSeenMillis = nowMillis;
  if (elapsedMs <= 0) return 0; // đồng hồ bị lùi hoặc không đổi
  final elapsedSec = min(elapsedMs / 1000.0, maxOfflineSeconds.toDouble());
  final earned = effectiveIncomePerSecond(
        state,
        configs,
        bonusPerStar: Balance.bonusPerStar,
      ) *
      elapsedSec;
  _credit(state, earned);
  return earned;
}

/// Số Sao sẽ NHẬN THÊM nếu prestige ngay bây giờ (để UI xem trước, không mutate).
int prestigeStarsAvailable(GameState state) {
  final total =
      starsForLifetimeEarnings(state.lifetimeEarnings, Balance.prestigeK);
  return max(0, total - state.prestigeStars);
}

/// Thực hiện Nhượng quyền: nhận Sao, reset ván (tiền + cấp) nhưng GIỮ
/// lifetimeEarnings và Sao. Trả về số Sao vừa nhận (0 nếu chưa đủ).
int prestige(GameState state) {
  final gained = prestigeStarsAvailable(state);
  if (gained <= 0) return 0;
  state.prestigeStars += gained;
  state.money = 0;
  state.levels.clear();
  // lifetimeEarnings KHÔNG reset — đó là nền tảng của mô hình Sao tích lũy.
  return gained;
}

/// Cộng thẳng [amount] Xu (phần thưởng quảng cáo, quà tặng...).
void grantBonus(GameState state, double amount) {
  if (amount <= 0) return;
  _credit(state, amount);
}

/// Cộng [amount] Xu và ghi nhận vào tổng thu nhập cả đời.
void _credit(GameState state, double amount) {
  state.money += amount;
  state.lifetimeEarnings += amount;
}
