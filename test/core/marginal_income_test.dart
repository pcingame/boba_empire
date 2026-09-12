import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// milestoneStep=50, milestoneFactor=2 → mỗi 50 cấp thu nhập nguồn ×2.
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
    expect(marginalIncomePerSecond(_g, 48), 10); // 48→49
  });

  test('cấp chạm mốc (49→50): phần tăng nhảy vọt do ×2 cả nguồn', () {
    // mult(49)=×1, mult(50)=×2 → 10*(50*2 - 49*1) = 510.
    expect(marginalIncomePerSecond(_g, 49), 510);
  });

  test('ngay sau mốc (50→51): phần tăng = income/cấp × hệ số mốc hiện tại', () {
    // Cả hai cấp đều ×2 → 10*(51*2 - 50*2) = 20.
    expect(marginalIncomePerSecond(_g, 50), 20);
  });

  test('mốc thứ hai (99→100): ×2→×4, nhảy lớn hơn', () {
    // mult(99)=×2, mult(100)=×4 → 10*(100*4 - 99*2) = 2020.
    expect(marginalIncomePerSecond(_g, 99), 2020);
  });

  test('luôn dương với income/cấp dương', () {
    for (var lvl = 0; lvl < 220; lvl++) {
      expect(marginalIncomePerSecond(_g, lvl), greaterThan(0));
    }
  });
}
