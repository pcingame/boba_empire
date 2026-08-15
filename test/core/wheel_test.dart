import 'package:boba_empire/core/wheel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tổng trọng số = 100 (mỗi ô là phần trăm)', () {
    final total = wheelPrizes.fold<int>(0, (a, p) => a + p.weight);
    expect(total, 100);
  });

  test('spinWheel: điểm giữa mỗi khoảng rơi đúng ô theo trọng số tích lũy', () {
    // Khoảng tích lũy (%): [0,22)->0 [22,42)->1 [42,58)->2 [58,70)->3
    //                      [70,78)->4 [78,88)->5 [88,96)->6 [96,100)->7
    // Dùng điểm GIỮA mỗi khoảng để tránh nhập nhằng số thực ở đúng ranh giới.
    expect(spinWheel(0.10), 0);
    expect(spinWheel(0.30), 1);
    expect(spinWheel(0.50), 2);
    expect(spinWheel(0.64), 3);
    expect(spinWheel(0.74), 4);
    expect(spinWheel(0.83), 5);
    expect(spinWheel(0.92), 6);
    expect(spinWheel(0.98), 7);
    expect(spinWheel(0.0), 0);
  });

  test('spinWheel: roll=1.0 (biên) vẫn trả ô hợp lệ, không tràn', () {
    expect(spinWheel(1.0), wheelPrizes.length - 1);
  });

  test('jackpot (ô cuối, 100💎) là hiếm nhất', () {
    final jackpot = wheelPrizes.last;
    expect(jackpot.kind, WheelKind.gems);
    expect(jackpot.amount, 100);
    for (var i = 0; i < wheelPrizes.length - 1; i++) {
      expect(jackpot.weight, lessThanOrEqualTo(wheelPrizes[i].weight));
    }
  });
}
