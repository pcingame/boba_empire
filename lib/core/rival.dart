/// Đối thủ cạnh tranh — "cuộc đua" chạy song song với người chơi.
///
/// HÀM THUẦN: sức ép, thế trận, và KẾT QUẢ một lựa chọn đối phó (không mutate;
/// [game_controller] áp kết quả). "Giây sức ép" chỉ nhích khi có sự kiện đang
/// chờ trả lời và nhảy/giảm theo cách đối phó — KHÔNG cộng theo tổng thời gian
/// chơi, nên không phụ thuộc việc cày lâu/ngắn và dễ tune.
library;

import 'dart:math';

import 'balance.dart';
import 'models.dart';
import 'story.dart';

/// Ba loại sự kiện đối thủ tung ra.
enum RivalEventType { priceWar, poachStaff, smearCampaign }

/// Thế trận hiện tại (để hiện chip ⚔️ ở header).
enum RivalStanding { ahead, even, behind }

/// Sức ép của đối thủ = sqrt(giây sức ép) · k (0 khi đối thủ chưa vào truyện).
double rivalPower(GameState s) => rivalActive(s)
    ? sqrt(max(0, s.rivalPressureSeconds)) * Balance.rivalPowerK
    : 0;

/// Mốc sức ép "hoà" kỳ vọng ở giai đoạn hiện tại.
double rivalExpectedPower(int stage) =>
    Balance.rivalExpectedPower[stage.clamp(1, 6) - 1];

/// Tỉ số sức_ép / kỳ_vọng — 0..~ (dùng cho thanh đo, <1 là đang thắng).
double rivalPowerRatio(GameState s) =>
    rivalPower(s) / rivalExpectedPower(s.stage);

RivalStanding rivalStanding(GameState s) {
  final r = rivalPowerRatio(s);
  if (r < Balance.rivalAheadRatio) return RivalStanding.ahead;
  if (r > Balance.rivalBehindRatio) return RivalStanding.behind;
  return RivalStanding.even;
}

/// Đủ điều kiện "hạ" đối thủ: tới giai đoạn cuối mà vẫn đang dẫn trước.
bool rivalDefeatable(GameState s) =>
    !s.rivalDefeated &&
    s.stage >= 6 &&
    rivalActive(s) &&
    rivalStanding(s) == RivalStanding.ahead;

/// Kết quả (thuần) của một lựa chọn đối phó — [game_controller] áp lên state.
class RivalOutcome {
  const RivalOutcome({
    required this.spendMoney,
    required this.spendGems,
    required this.pressureDelta,
    required this.modifierMult,
    required this.modifierSeconds,
  });

  /// Xu / 💎 phải trả.
  final double spendMoney;
  final int spendGems;

  /// Thay đổi "giây sức ép" (âm = đẩy lùi đối thủ).
  final double pressureDelta;

  /// Hệ số thu nhập/chạm TẠM THỜI sau lựa chọn (1.0 = không có; <1 = debuff khi
  /// phớt lờ; >1 = buff khi phản công mạnh).
  final double modifierMult;
  final int modifierSeconds;

  bool affordableFor(GameState s) =>
      s.money >= spendMoney && s.gems >= spendGems;
}

/// Hai lựa chọn đối phó cho từng loại sự kiện. Option 0 = "chắc tay" (trả bằng %
/// Xu hiện có, đẩy lùi vừa phải). Option 1 = "phản công" (trả 💎, đẩy lùi mạnh +
/// buff ngắn).
List<RivalOutcome> rivalOptions(GameState s, RivalEventType type) {
  double moneyFrac(double f) => s.money * f;
  return switch (type) {
    RivalEventType.priceWar => [
        RivalOutcome(
          spendMoney: moneyFrac(0.10),
          spendGems: 0,
          pressureDelta: -1800,
          modifierMult: 1.0,
          modifierSeconds: 0,
        ),
        const RivalOutcome(
          spendMoney: 0,
          spendGems: 25,
          pressureDelta: -3600,
          modifierMult: 1.15,
          modifierSeconds: 180,
        ),
      ],
    RivalEventType.poachStaff => [
        RivalOutcome(
          spendMoney: moneyFrac(0.15),
          spendGems: 0,
          pressureDelta: -1800,
          modifierMult: 1.0,
          modifierSeconds: 0,
        ),
        const RivalOutcome(
          spendMoney: 0,
          spendGems: 30,
          pressureDelta: -2400,
          modifierMult: 1.15,
          modifierSeconds: 180,
        ),
      ],
    RivalEventType.smearCampaign => [
        RivalOutcome(
          spendMoney: moneyFrac(0.08),
          spendGems: 0,
          pressureDelta: -1500,
          modifierMult: 1.0,
          modifierSeconds: 0,
        ),
        const RivalOutcome(
          spendMoney: 0,
          spendGems: 25,
          pressureDelta: -3000,
          modifierMult: 1.2,
          modifierSeconds: 150,
        ),
      ],
  };
}

/// Kết quả khi PHỚT LỜ một sự kiện: đối thủ lấn tới + debuff tạm.
const RivalOutcome rivalIgnoreOutcome = RivalOutcome(
  spendMoney: 0,
  spendGems: 0,
  pressureDelta: Balance.rivalIgnorePressureSeconds,
  modifierMult: Balance.rivalIgnoreDebuffMult,
  modifierSeconds: Balance.rivalIgnoreDebuffSeconds,
);
