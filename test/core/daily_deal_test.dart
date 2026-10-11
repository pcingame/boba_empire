import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/daily_deal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vòng 7 ngày: lặp đúng chu kỳ, có đủ 4 loại ưu đãi, mọi mức giảm hợp lý', () {
    expect(dailyDealCycle.length, 7);
    expect({for (final d in dailyDealCycle) d.kind}, DealKind.values.toSet());
    for (final d in dailyDealCycle) {
      expect(d.discountPercent, inInclusiveRange(10, 70), reason: '${d.kind}');
    }
    for (var day = 0; day < 30; day++) {
      expect(identical(dailyDealFor(day), dailyDealFor(day + 7)), isTrue, reason: 'ngày $day');
    }
    // Không có hai ngày liền nhau cùng một món (đỡ nhàm).
    for (var i = 0; i < 7; i++) {
      expect(dailyDealCycle[i].kind == dailyDealCycle[(i + 1) % 7].kind, isFalse, reason: 'ngày $i');
    }
  });

  test('giá sau giảm = giá gốc × (100 − %), làm tròn, luôn rẻ hơn gốc và ≥ 1', () {
    for (final d in dailyDealCycle) {
      expect(d.price, lessThan(d.baseGems), reason: '${d.kind}');
      expect(d.price, greaterThanOrEqualTo(1));
      expect(d.price, (d.baseGems * (100 - d.discountPercent) / 100).round());
    }
    const skip = DailyDeal(DealKind.timeSkip, 50);
    expect(skip.baseGems, Balance.gemTimeSkipCost);
    expect(skip.price, (Balance.gemTimeSkipCost / 2).round());
    expect(const DailyDeal(DealKind.packBasic, 99).price >= 1, isTrue);
    expect(const DailyDeal(DealKind.packBasic, 100).price, 1); // sàn 1
  });

  test('gói phụ kiện của ưu đãi khớp độ hiếm tối thiểu; tua nhanh không có gói', () {
    expect(const DailyDeal(DealKind.packRare, 40).pack, AccessoryPack.rare);
    expect(const DailyDeal(DealKind.packBasic, 40).pack, AccessoryPack.basic);
    expect(const DailyDeal(DealKind.packEpic, 40).pack, AccessoryPack.epic);
    expect(const DailyDeal(DealKind.timeSkip, 40).pack, isNull);
  });

  test('dealSecondsLeft: đúng 24h lúc nửa đêm UTC, còn 1 giây trước nửa đêm, luôn ≤ 86400', () {
    const day = 24 * 60 * 60 * 1000;
    expect(dealSecondsLeft(5 * day), 86400);
    expect(dealSecondsLeft(5 * day + day - 1000), 1);
    expect(dealSecondsLeft(5 * day + 12 * 3600 * 1000), 12 * 3600);
    for (final ms in [0, 1, 123456789, 5 * day + 1]) {
      expect(dealSecondsLeft(ms), inInclusiveRange(1, 86400));
    }
  });
}
