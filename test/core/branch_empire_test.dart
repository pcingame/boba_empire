// Chi nhánh làm trục vòng chơi chính: tổng cấp → thu nhập quán chính; Nhượng quyền không reset chi nhánh.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/branches.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _s() => GameState.newGame(nowMillis: 1000)
  ..levels[Balance.generators.first.id] = 30;

double _income(GameState s) => effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar);

void main() {
  test('hệ số: 1 khi chưa mở; +0.5%/cấp; tối đa +85%', () {
    expect(branchIncomeMultiplier({}), 1);
    expect(branchIncomeMultiplier({'saigon': 4, 'tokyo': 6}), closeTo(1.05, 1e-12));
    expect(branchIncomeMultiplier({for (final c in branchCities) c.id: 10}), closeTo(1.85, 1e-12));
  });

  test('thu nhập quán chính nhân theo tổng cấp chi nhánh', () {
    final a = _s();
    final b = _s()..branchLevels.addAll({'saigon': 10, 'tokyo': 10});
    expect(_income(b), closeTo(_income(a) * 1.10, _income(a) * 1e-9));
  });

  test('Nhượng quyền giữ nguyên cấp chi nhánh và thời điểm tích', () {
    final s = _s()
      ..branchLevels['saigon'] = 7
      ..branchSince['saigon'] = 5000
      ..lifetimeEarnings = 1e12;
    expect(prestige(s), greaterThan(0));
    expect(s.branchLevels['saigon'], 7);
    expect(s.branchSince['saigon'], 5000);
  });
}
