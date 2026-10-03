import 'package:boba_empire/core/market_fee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cuối tuần (thứ 7/CN UTC) miễn phí, biên chính xác', () {
    expect(marketFeeFree(DateTime.utc(2026, 10, 2, 23, 59, 59)), isFalse); // T6
    expect(marketFeeFree(DateTime.utc(2026, 10, 3, 0, 0, 0)), isTrue); // T7
    expect(marketFeeFree(DateTime.utc(2026, 10, 4, 23, 59, 59)), isTrue); // CN
    expect(marketFeeFree(DateTime.utc(2026, 10, 5, 0, 0, 0)), isFalse); // T2
  });

  test('phí ngày thường: 1%, làm tròn lên, tối thiểu 1, không vượt giá', () {
    final weekday = DateTime.utc(2026, 10, 7);
    expect(marketFee(1, weekday), 1);
    expect(marketFee(99, weekday), 1);
    expect(marketFee(100, weekday), 1);
    expect(marketFee(101, weekday), 2);
    expect(marketFee(100000, weekday), 1000);
  });

  test('cuối tuần: phí 0 mọi mức giá', () {
    final sat = DateTime.utc(2026, 10, 3, 12);
    for (final p in [1, 101, 100000]) {
      expect(marketFee(p, sat), 0);
    }
  });
}
