/// Vòng quay may mắn — bảng phần thưởng + chọn ô theo trọng số. Hàm thuần.
library;

enum WheelKind { coins, gems, x2, chest }

class WheelPrize {
  const WheelPrize(this.kind, this.amount, this.weight);

  final WheelKind kind;

  /// coins: số GIÂY sản xuất được thưởng; gems: số Kim Cương; x2/chest: không dùng.
  final int amount;

  /// Trọng số xuất hiện (jackpot nhỏ, thưởng thường lớn).
  final int weight;
}

/// 9 ô (thứ tự = vị trí trên vòng quay). Tổng trọng số = 100.
///
/// Ô "rương phụ kiện" (2026-10-03, xem PROPOSAL_COLLECTION_SPOTLIGHT.md): thêm nguồn rớt
/// phụ kiện ngoài nhiệm vụ ngày (1 món/ngày → ~270 ngày mới đủ bộ). Trọng số 6 lấy từ
/// các ô thưởng nhỏ (5💎 22→20, 30 phút 20→18, 15💎 16→14) để KHÔNG đụng tỉ lệ các ô
/// hiếm (2h, x2, 25💎, 6h, jackpot).
const List<WheelPrize> wheelPrizes = [
  WheelPrize(WheelKind.gems, 5, 20),
  WheelPrize(WheelKind.coins, 30 * 60, 18), // 30 phút thu nhập
  WheelPrize(WheelKind.gems, 15, 14),
  WheelPrize(WheelKind.coins, 2 * 3600, 12), // 2 giờ
  WheelPrize(WheelKind.chest, 0, 6), // rương phụ kiện
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
