/// "Ưu đãi hôm nay": mỗi ngày (UTC) một món trong cửa hàng 💎 được giảm giá, mua tối đa MỘT lần
/// mỗi ngày. Xoay vòng theo chỉ số ngày nên mọi người cùng thấy một món. Giá/giảm giá là ước lượng
/// chưa playtest.
library;

import 'accessories.dart';
import 'balance.dart';

enum DealKind { packBasic, packRare, packEpic, timeSkip }

class DailyDeal {
  const DailyDeal(this.kind, this.discountPercent);

  final DealKind kind;

  /// % giảm so với giá gốc của món.
  final int discountPercent;

  /// Giá gốc (💎) của món.
  int get baseGems => switch (kind) {
        DealKind.packBasic => AccessoryPack.basic.baseGems,
        DealKind.packRare => AccessoryPack.rare.baseGems,
        DealKind.packEpic => AccessoryPack.epic.baseGems,
        DealKind.timeSkip => Balance.gemTimeSkipCost,
      };

  /// Giá sau giảm (💎), làm tròn, tối thiểu 1.
  int get price {
    final p = (baseGems * (100 - discountPercent) / 100).round();
    return p < 1 ? 1 : p;
  }

  /// Gói phụ kiện tương ứng (null với "tua nhanh").
  AccessoryPack? get pack => switch (kind) {
        DealKind.packBasic => AccessoryPack.basic,
        DealKind.packRare => AccessoryPack.rare,
        DealKind.packEpic => AccessoryPack.epic,
        DealKind.timeSkip => null,
      };
}

/// Vòng 7 ngày (khớp [dayIndex] % 7). Gói Sử thi giảm ít hơn vì giá trị cao; "tua nhanh" giảm sâu.
const List<DailyDeal> dailyDealCycle = [
  DailyDeal(DealKind.packRare, 40),
  DailyDeal(DealKind.timeSkip, 50),
  DailyDeal(DealKind.packBasic, 50),
  DailyDeal(DealKind.packEpic, 30),
  DailyDeal(DealKind.timeSkip, 50),
  DailyDeal(DealKind.packRare, 40),
  DailyDeal(DealKind.packEpic, 35),
];

/// Ưu đãi của ngày [dayIndex] (chỉ số ngày kể từ epoch UTC, xem `dayIndex` trong daily.dart).
DailyDeal dailyDealFor(int dayIndex) => dailyDealCycle[dayIndex % dailyDealCycle.length];

/// Số giây còn lại tới 00:00 UTC (lúc ưu đãi đổi) tính từ [nowMillis].
int dealSecondsLeft(int nowMillis) {
  const day = 24 * 60 * 60 * 1000;
  return ((day - nowMillis % day) / 1000).ceil();
}
