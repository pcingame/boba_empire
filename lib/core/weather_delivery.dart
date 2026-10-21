/// Thời tiết & Giao hàng — hai dịch vụ nhỏ của quán, đều thưởng một lần (không đụng công thức thu nhập).
/// Thời tiết: đổi mỗi [weatherSlotHours] giờ (xác định theo khung giờ UTC); chọn menu hợp thời tiết thì thưởng nhiều.
/// Giao hàng: nhận 1 hợp đồng 1/4/8 giờ, cược Xu; khi xong chốt thắng/thua bằng hạt giống cố định lúc nhận
/// (đóng app/mở lại không đổi kết quả). Số liệu ước lượng, chưa playtest.
library;

import 'dart:math';

const int weatherSlotHours = 3;
const int weatherKinds = 4; // ☀️ nóng · 🌧️ mưa · ❄️ lạnh · ⛅ dịu
const List<String> weatherEmoji = ['☀️', '🌧️', '❄️', '⛅'];

/// Menu chọn (cùng chỉ số với thời tiết hợp): 0 trà đá, 1 trà nóng, 2 sữa nóng, 3 trà trái cây.
const List<String> weatherMenuEmoji = ['🧊', '🍵', '🥛', '🍹'];

int weatherSlot(int nowMillis) => nowMillis ~/ (weatherSlotHours * 3600 * 1000);

int weatherOf(int slot) => Random(slot * 2246822519 ^ 0x9e3779b1).nextInt(weatherKinds);

/// Thời tiết nào thì món nào hợp (hiện tại 1-1).
int weatherBestMenu(int weather) => weather;

/// Giây tới lúc đổi thời tiết.
int weatherSecondsLeft(int nowMillis) {
  const slotMs = weatherSlotHours * 3600 * 1000;
  return ((slotMs - nowMillis % slotMs) / 1000).ceil();
}

/// Giây thu nhập thưởng: chọn đúng [weatherRightSeconds], sai [weatherWrongSeconds].
const int weatherRightSeconds = 600;
const int weatherWrongSeconds = 120;
const double weatherFloor = 500;

double weatherReward(bool right, double income) =>
    max(weatherFloor, (income.isFinite ? income : 0.0) * (right ? weatherRightSeconds : weatherWrongSeconds));

class DeliveryTier {
  const DeliveryTier(this.hours, this.winChance, this.payout);
  final int hours;

  /// Xác suất giao thành công.
  final double winChance;

  /// Thành công nhận lại [payout]× tiền cược (thua mất cược).
  final double payout;
}

const List<DeliveryTier> deliveryTiers = [
  DeliveryTier(1, 0.85, 1.4),
  DeliveryTier(4, 0.75, 2.0),
  DeliveryTier(8, 0.65, 3.0),
];

/// Tiền cược: 10 phút thu nhập × số giờ (sàn 1000).
double deliveryStake(int tier, double income) =>
    max(1000.0, (income.isFinite ? income : 0.0) * 600 * deliveryTiers[tier].hours);

int deliveryDurationMillis(int tier) => deliveryTiers[tier].hours * 3600 * 1000;

/// Kết quả chốt theo hạt giống lúc nhận.
bool deliveryWins(int tier, int seed) => Random(seed).nextDouble() < deliveryTiers[tier].winChance;
