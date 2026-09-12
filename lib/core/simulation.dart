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
      prestigeTapMultiplier(state.prestigeTapLevel) *
      storyChoiceTapMultiplier(state) *
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
  if (level >= Balance.maxGeneratorLevel) return false; // trần cứng an toàn
  final cost = nextLevelCost(config, level) *
      upgradeCostMultiplier(state.prestigeDiscountLevel);
  if (!cost.isFinite || state.money < cost) return false;
  state.money -= cost;
  state.levels[generatorId] = level + 1;
  return true;
}

/// Mua liền [count] cấp một nguồn thu (nút "×10 / MAX"). Trừ tổng chi phí chuỗi
/// (đã tính perk "Mua sỉ"). Trả về số cấp thực mua (0 nếu thiếu tiền / chưa mở
/// khóa / count ≤ 0). Không mua từng phần — thiếu tiền cho trọn [count] thì huỷ.
int buyUpgradeBulk(
  GameState state,
  String generatorId,
  int count, {
  List<GeneratorConfig> configs = Balance.generators,
}) {
  if (count <= 0) return 0;
  final config = configs.firstWhere((c) => c.id == generatorId);
  if (config.stage > state.stage) return 0;
  final level = state.levels[generatorId] ?? 0;
  // Trần cứng an toàn — không mua từng phần cho tới trần, huỷ cả count nếu
  // vượt (khớp "không mua từng phần" của hàm này).
  if (level >= Balance.maxGeneratorLevel ||
      level + count > Balance.maxGeneratorLevel) {
    return 0;
  }
  final cost = bulkCost(config, level, count) *
      upgradeCostMultiplier(state.prestigeDiscountLevel);
  if (!cost.isFinite || state.money < cost) return 0;
  state.money -= cost;
  state.levels[generatorId] = level + count;
  return count;
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

/// Mua/nâng vật phẩm "Tăng thu nhập" bằng Kim Cương. True nếu đủ gems hoặc đã
/// đạt trần cấp (xem Balance.maxGemShopLevel — gemBoostCost() tràn
/// double.infinity ở cấp cao, .ceil() ném lỗi thay vì bão hoà êm).
bool buyGemBoost(GameState state) {
  if (state.gemBoostLevel >= Balance.maxGemShopLevel) return false;
  final cost = gemBoostCost(state.gemBoostLevel);
  if (state.gems < cost) return false;
  state.gems -= cost;
  state.gemBoostLevel += 1;
  return true;
}

/// Nâng perk "Siêu thu nhập" bằng ⭐ Sao (kho prestige). True nếu đủ Sao khả dụng.
bool buyPrestigeIncome(GameState state) {
  final cost =
      prestigeShopCost(Balance.prestigeIncomeBaseCost, state.prestigeIncomeLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeIncomeLevel += 1;
  return true;
}

/// Nâng perk "Siêu chạm" bằng ⭐ Sao. True nếu đủ Sao khả dụng.
bool buyPrestigeTap(GameState state) {
  final cost =
      prestigeShopCost(Balance.prestigeTapBaseCost, state.prestigeTapLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeTapLevel += 1;
  return true;
}

/// Nâng perk "Siêu offline" bằng ⭐ Sao. True nếu đủ Sao khả dụng.
bool buyPrestigeOffline(GameState state) {
  final cost = prestigeShopCost(
      Balance.prestigeOfflineBaseCost, state.prestigeOfflineLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeOfflineLevel += 1;
  return true;
}

/// Nâng perk "Vốn khởi nghiệp" bằng ⭐ Sao. True nếu đủ Sao khả dụng.
bool buyPrestigeStartCash(GameState state) {
  final cost = prestigeShopCost(
      Balance.prestigeStartCashBaseCost, state.prestigeStartCashLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeStartCashLevel += 1;
  return true;
}

/// Nâng perk "Giữ giai đoạn" bằng ⭐ Sao (tối đa
/// [Balance.prestigeKeepStageMaxLevel]). True nếu đủ Sao và chưa tối đa.
bool buyPrestigeKeepStage(GameState state) {
  if (state.prestigeKeepStageLevel >= Balance.prestigeKeepStageMaxLevel) {
    return false;
  }
  final cost = prestigeShopCost(
      Balance.prestigeKeepStageBaseCost, state.prestigeKeepStageLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeKeepStageLevel += 1;
  return true;
}

/// Nâng perk "Mua sỉ" bằng ⭐ Sao. True nếu đủ Sao khả dụng.
bool buyPrestigeDiscount(GameState state) {
  final cost = prestigeShopCost(
      Balance.prestigeDiscountBaseCost, state.prestigeDiscountLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeDiscountLevel += 1;
  return true;
}

/// Mở khoá perk "Tự động mua" bằng ⭐ Sao (tối đa
/// [Balance.prestigeAutoBuyMaxLevel] = 1). True nếu đủ Sao và chưa mở.
bool buyPrestigeAutoBuy(GameState state) {
  if (state.prestigeAutoBuyLevel >= Balance.prestigeAutoBuyMaxLevel) {
    return false;
  }
  final cost = prestigeShopCost(
      Balance.prestigeAutoBuyBaseCost, state.prestigeAutoBuyLevel);
  if (prestigeStarsSpendable(state) < cost) return false;
  state.prestigeAutoBuyLevel += 1;
  return true;
}

/// Tự động mua nguồn "đáng mua nhất" tới khi hết tiền (hoặc chạm [maxBuys] để
/// chặn vòng lặp bệnh lý). Chỉ chạy khi có perk + cờ [GameState.autoBuyEnabled].
/// Trả về số lần mua.
int autoBuyBest(
  GameState state, {
  List<GeneratorConfig> configs = Balance.generators,
  int maxBuys = 200,
}) {
  if (state.prestigeAutoBuyLevel == 0 || !state.autoBuyEnabled) return 0;
  var n = 0;
  while (n < maxBuys) {
    final id = bestBuyGeneratorId(state, configs);
    if (id == null || !buyUpgrade(state, id, configs: configs)) break;
    n++;
  }
  return n;
}

/// Mua/nâng vật phẩm "Kho lạnh offline" bằng Kim Cương. True nếu đủ gems hoặc
/// đã đạt trần cấp (xem Balance.maxGemShopLevel — cùng lý do buyGemBoost).
bool buyOfflineCap(GameState state) {
  if (state.offlineCapLevel >= Balance.maxGemShopLevel) return false;
  final cost = offlineCapCost(state.offlineCapLevel);
  if (state.gems < cost) return false;
  state.gems -= cost;
  state.offlineCapLevel += 1;
  return true;
}

/// "Mở giai đoạn tức thì" bằng 💎 — bỏ qua chi phí Xu. Trả về true nếu còn giai
/// đoạn để mở và đủ 💎.
bool buyInstantStageUnlock(GameState state) {
  final next = Balance.nextStageConfig(state.stage);
  if (next == null) return false;
  final cost = instantStageGemCost(state.stage);
  if (state.gems < cost) return false;
  state.gems -= cost;
  state.stage = next.stage;
  return true;
}

/// "Tua nhanh" bằng 💎: trừ [Balance.gemTimeSkipCost] 💎, cộng ngay
/// [Balance.gemTimeSkipSeconds] giây sản xuất (nhịp cơ bản, không boost). Trả về
/// số Xu vừa cộng (0 nếu thiếu 💎 hoặc chưa có thu nhập).
double buyGemTimeSkip(
  GameState state, {
  List<GeneratorConfig> configs = Balance.generators,
}) {
  if (state.gems < Balance.gemTimeSkipCost) return 0;
  final reward = effectiveIncomePerSecond(
        state,
        configs,
        bonusPerStar: Balance.bonusPerStar,
      ) *
      Balance.gemTimeSkipSeconds;
  if (reward <= 0) return 0;
  state.gems -= Balance.gemTimeSkipCost;
  _credit(state, reward);
  return reward;
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
  // Offline áp: perk "Siêu offline" + VIP ×2 (nếu còn hạn). KHÔNG áp boost tạm
  // (Mưa vàng / x2-24h) — đó là thưởng cho lúc chơi.
  final vipMult = nowMillis < state.vipUntilMillis
      ? Balance.vipIncomeMultiplier
      : 1.0;
  final earned = effectiveIncomePerSecond(
        state,
        configs,
        bonusPerStar: Balance.bonusPerStar,
      ) *
      prestigeOfflineMultiplier(state.prestigeOfflineLevel) *
      vipMult *
      elapsedSec;
  _credit(state, earned);
  fillPiggy(state, elapsedSec); // heo cũng tích cho khoảng vắng (đã cap)
  return earned;
}

/// Tích Kim Cương vào heo đất theo [dtSeconds] thời gian trôi (chơi hoặc vắng),
/// tới trần [Balance.piggyMaxGems]. Gọi mỗi tick và khi tính offline.
void fillPiggy(GameState state, double dtSeconds) {
  if (dtSeconds <= 0) return;
  state.piggyGems = min(
    Balance.piggyMaxGems,
    state.piggyGems + dtSeconds * Balance.piggyGemsPerSecond,
  );
}

/// Số Sao sẽ NHẬN THÊM nếu prestige ngay bây giờ (để UI xem trước, không mutate).
int prestigeStarsAvailable(GameState state) {
  final total =
      starsForLifetimeEarnings(state.lifetimeEarnings, Balance.prestigeK);
  return max(0, total - state.prestigeStars);
}

/// Thực hiện Nhượng quyền: nhận Sao, reset ván (tiền + cấp + giai đoạn) nhưng
/// GIỮ lifetimeEarnings và Sao. Perk kho Sao có thể giữ lại giai đoạn ("Giữ
/// giai đoạn") và cấp vốn khởi đầu ("Vốn khởi nghiệp"). Trả về số Sao vừa nhận
/// (0 nếu chưa đủ).
int prestige(GameState state) {
  final gained = prestigeStarsAvailable(state);
  if (gained <= 0) return 0;
  state.prestigeStars += gained;
  state.levels.clear();
  state.stage =
      keptStageAfterPrestige(state.stage, state.prestigeKeepStageLevel);
  state.money = startCashAfterPrestige(state.prestigeStartCashLevel);
  // lifetimeEarnings KHÔNG reset — đó là nền tảng của mô hình Sao tích lũy.
  // Cốt truyện & đối thủ (storyChapter, storyChoiceA/B, rivalDefeated,
  // rivalPressureSeconds) cũng KHÔNG đụng tới — là tiến trình meta, giữ nguyên.
  return gained;
}

/// Cộng thẳng [amount] Xu (phần thưởng quảng cáo, quà tặng...).
void grantBonus(GameState state, double amount) {
  if (amount <= 0) return;
  _credit(state, amount);
}

/// Cộng thẳng [amount] Kim Cương (mua bằng tiền thật / quà tặng).
void grantGems(GameState state, double amount) {
  if (amount <= 0) return;
  state.gems += amount;
}

/// Bật cờ "Gỡ quảng cáo" (idempotent — khôi phục nhiều lần vẫn đúng).
void setAdsRemoved(GameState state) {
  state.adsRemoved = true;
}

/// Đánh dấu đã xem hướng dẫn (để không tự hiện lại ở các lần mở sau).
void setTutorialSeen(GameState state) {
  state.tutorialSeen = true;
}

/// Trao "Gói khởi động" đúng MỘT lần: cộng gems rồi đánh dấu đã sở hữu. Trả về
/// true nếu vừa trao (false nếu đã sở hữu — chống trao trùng khi restore).
bool claimStarterPack(GameState state, double gems) {
  if (state.starterPackOwned) return false;
  state.gems += gems;
  state.starterPackOwned = true;
  return true;
}

/// Cộng [amount] Xu và ghi nhận vào tổng thu nhập cả đời. (Heo đất tích theo
/// thời gian ở [fillPiggy], không theo Xu.)
void _credit(GameState state, double amount) {
  if (!amount.isFinite) return; // chặn NaN/Infinity (tràn số double) lan vào state
  // Phép cộng tự nó cũng có thể tràn thành Infinity dù amount hữu hạn (money đã
  // gần double.maxFinite) — bỏ qua thay vì để money biến thành Infinity.
  final newMoney = state.money + amount;
  final newLifetime = state.lifetimeEarnings + amount;
  if (newMoney.isFinite) state.money = newMoney;
  if (newLifetime.isFinite) state.lifetimeEarnings = newLifetime;
}
