import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// milestoneStep=25, milestoneFactor=2 → mỗi 25 cấp thu nhập nguồn ×2.
const _g = GeneratorConfig(
  id: 'x',
  name: 'X',
  baseCost: 10,
  costGrowth: 1.15,
  incomePerLevelPerSecond: 10,
);

void main() {
  test('trong cùng một mốc: phần tăng = income/cấp (không đổi)', () {
    expect(marginalIncomePerSecond(_g, 0), 10); // 0→1
    expect(marginalIncomePerSecond(_g, 5), 10); // 5→6
    expect(marginalIncomePerSecond(_g, 23), 10); // 23→24
  });

  test('cấp chạm mốc (24→25): phần tăng nhảy vọt do ×2 cả nguồn', () {
    // mult(24)=×1, mult(25)=×2 → 10*(25*2 - 24*1) = 260.
    expect(marginalIncomePerSecond(_g, 24), 260);
  });

  test('ngay sau mốc (25→26): phần tăng = income/cấp × hệ số mốc hiện tại', () {
    // Cả hai cấp đều ×2 → 10*(26*2 - 25*2) = 20.
    expect(marginalIncomePerSecond(_g, 25), 20);
  });

  test('mốc thứ hai (49→50): ×2→×4, nhảy lớn hơn', () {
    // mult(49)=×2, mult(50)=×4 → 10*(50*4 - 49*2) = 1020.
    expect(marginalIncomePerSecond(_g, 49), 1020);
  });

  test('luôn dương với income/cấp dương', () {
    for (var lvl = 0; lvl < 120; lvl++) {
      expect(marginalIncomePerSecond(_g, lvl), greaterThan(0));
    }
  });
}
