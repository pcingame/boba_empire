/// Vòng quay may mắn — bảng phần thưởng + chọn ô theo trọng số. Hàm thuần.
library;

enum WheelKind { coins, gems, x2 }

class WheelPrize {
  const WheelPrize(this.kind, this.amount, this.weight);

  final WheelKind kind;

  /// coins: số GIÂY sản xuất được thưởng; gems: số Kim Cương; x2: không dùng.
  final int amount;

  /// Trọng số xuất hiện (jackpot nhỏ, thưởng thường lớn).
  final int weight;
}

/// 8 ô (thứ tự = vị trí trên vòng quay).
const List<WheelPrize> wheelPrizes = [
  WheelPrize(WheelKind.gems, 5, 22),
  WheelPrize(WheelKind.coins, 30 * 60, 20), // 30 phút thu nhập
  WheelPrize(WheelKind.gems, 15, 16),
  WheelPrize(WheelKind.coins, 2 * 3600, 12), // 2 giờ
  WheelPrize(WheelKind.x2, 0, 8), // x2 thu nhập 24h
  WheelPrize(WheelKind.gems, 25, 10),
  WheelPrize(WheelKind.coins, 6 * 3600, 8), // 6 giờ
  WheelPrize(WheelKind.gems, 100, 4), // JACKPOT
];

/// Chọn ô theo trọng số từ [roll01] trong [0,1). Trả về chỉ số ô.
int spinWheel(double roll01) {
  final total = wheelPrizes.fold<int>(0, (a, p) => a + p.weight);
  var r = roll01 * total;
  for (var i = 0; i < wheelPrizes.length; i++) {
    r -= wheelPrizes[i].weight;
    if (r < 0) return i;
  }
  return wheelPrizes.length - 1;
}
