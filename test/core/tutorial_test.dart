import 'package:boba_empire/core/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

TutorialStep _s({bool seen = false, int level = 0, bool afford = false}) =>
    tutorialStepFor(seen: seen, firstLevel: level, canAffordFirst: afford);

void main() {
  test('đã xem/bỏ qua → không hiện, bất kể trạng thái', () {
    for (final level in [0, 1, 50]) {
      for (final afford in [false, true]) {
        expect(_s(seen: true, level: level, afford: afford), TutorialStep.none);
      }
    }
  });

  test('chưa mua gì: chưa đủ tiền → chạm cốc; đủ tiền → chỉ nút mua', () {
    expect(_s(afford: false), TutorialStep.tap);
    expect(_s(afford: true), TutorialStep.buy);
  });

  test('đã mua nguồn thu đầu → giải thích, dù còn đủ tiền mua tiếp', () {
    expect(_s(level: 1), TutorialStep.explain);
    expect(_s(level: 1, afford: true), TutorialStep.explain);
    expect(_s(level: 37), TutorialStep.explain);
  });

  test('chuỗi bước đi một chiều khi chơi: tap → buy → explain → none', () {
    final seen = <TutorialStep>[
      _s(afford: false),
      _s(afford: true),
      _s(level: 1),
      _s(level: 1, seen: true),
    ];
    expect(seen, [
      TutorialStep.tap,
      TutorialStep.buy,
      TutorialStep.explain,
      TutorialStep.none,
    ]);
  });
}
