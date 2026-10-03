import 'package:boba_empire/core/wheel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tổng trọng số = 100 (mỗi ô là phần trăm)', () {
    final total = wheelPrizes.fold<int>(0, (a, p) => a + p.weight);
    expect(total, 100);
  });

  test('spinWheel: điểm giữa mỗi khoảng rơi đúng ô theo trọng số tích lũy', () {
    // Khoảng tích lũy (%): [0,20)->0 [20,38)->1 [38,52)->2 [52,64)->3 [64,70)->4(rương)
    //                      [70,78)->5 [78,88)->6 [88,96)->7 [96,100)->8
    // Dùng điểm GIỮA mỗi khoảng để tránh nhập nhằng số thực ở đúng ranh giới.
    expect(spinWheel(0.10), 0);
    expect(spinWheel(0.29), 1);
    expect(spinWheel(0.45), 2);
    expect(spinWheel(0.58), 3);
    expect(spinWheel(0.67), 4);
    expect(spinWheel(0.74), 5);
    expect(spinWheel(0.83), 6);
    expect(spinWheel(0.92), 7);
    expect(spinWheel(0.98), 8);
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

  test('9 ô, có đúng 1 ô rương phụ kiện trọng số 6; các ô hiếm giữ nguyên trọng số', () {
    expect(wheelPrizes.length, 9);
    final chests = wheelPrizes.where((p) => p.kind == WheelKind.chest).toList();
    expect(chests.length, 1);
    expect(chests.single.weight, 6);
    // Ô hiếm KHÔNG bị đụng: 2h=12, x2=8, 25💎=10, 6h=8, jackpot=4.
    int w(WheelKind k, int amount) => wheelPrizes
        .firstWhere((p) => p.kind == k && p.amount == amount)
        .weight;
    expect(w(WheelKind.coins, 2 * 3600), 12);
    expect(w(WheelKind.x2, 0), 8);
    expect(w(WheelKind.gems, 25), 10);
    expect(w(WheelKind.coins, 6 * 3600), 8);
    expect(w(WheelKind.gems, 100), 4);
  });
}
