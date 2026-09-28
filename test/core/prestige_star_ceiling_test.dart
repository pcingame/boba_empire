// Sao nhượng quyền KHÔNG được có trần int64.
//
// Bug thật, đo trên dữ liệu người chơi ngày 2026-09-29: 77/1184 người có
// `prestige_stars` đúng bằng 9223372036854775807 (= 2^63−1). Nguyên nhân:
// Sao = (k·√lifetime).floor(), mà `.floor()` trên double lớn hơn int64 KHÔNG
// ném lỗi — nó KẸP im lặng ở int64max. Hậu quả dây chuyền:
//   total (kẹp) − prestigeStars (kẹp) = 0  → prestigeStarsAvailable = 0
//   → Nhượng quyền vĩnh viễn không cho Sao nào, hệ số thu nhập đóng băng.
// Với lifetime cuối tuyến đo được (1,15e68) thì Sao thật là ~2e32 — lệch 14
// bậc so với con số bị kẹp.
import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

const int _int64Max = 9223372036854775807;

/// Lifetime nhỏ nhất làm k·√lifetime vượt int64 với k mặc định (~2,13e41).
double get _ceilingLifetime => pow(_int64Max / Balance.prestigeK, 2).toDouble();

void main() {
  group('Sao không còn trần int64', () {
    test('lifetime cuối tuyến cho Sao vượt xa int64max', () {
      // 1,15e68 = save thật lớn nhất trên bảng xếp hạng ngày 2026-09-29.
      final stars = starsForLifetimeEarnings(1.15e68, Balance.prestigeK);
      expect(stars.isFinite, isTrue);
      expect(stars, greaterThan(_int64Max.toDouble()));
      // Đúng công thức, không phải một con số kẹp nào đó.
      expect(stars, closeTo(Balance.prestigeK * sqrt(1.15e68), stars * 1e-12));
    });

    test('Sao vẫn TĂNG khi lifetime tăng ở vùng quá trần int64', () {
      final a = starsForLifetimeEarnings(
        _ceilingLifetime * 4,
        Balance.prestigeK,
      );
      final b = starsForLifetimeEarnings(
        _ceilingLifetime * 9,
        Balance.prestigeK,
      );
      // Kẹp trần thì a == b == int64max; đúng thì b/a = √(9/4) = 1,5.
      expect(b / a, closeTo(1.5, 1e-9));
    });

    test('người chơi quá trần vẫn nhận được Sao khi Nhượng quyền', () {
      final s = GameState.newGame(nowMillis: 0)
        ..lifetimeEarnings = 1e50
        ..prestigeStars = 0;
      final available = prestigeStarsAvailable(s);
      expect(available, greaterThan(_int64Max.toDouble()));
      final gained = prestige(s);
      expect(gained, available);
      expect(s.prestigeStars, available);
      // Và lần sau vẫn tiếp tục tích được, không đứng yên.
      s.lifetimeEarnings = 4e50;
      expect(prestigeStarsAvailable(s), greaterThan(0.0));
    });

    test('save cũ bị kẹp trần tự lành ở lần Nhượng quyền kế tiếp', () {
      // Đúng hình dạng 77 save thật: Sao lưu bằng int64max, lifetime thì to hơn
      // nhiều so với mức sinh ra con số đó.
      final json = (GameState.newGame(
        nowMillis: 0,
      )..lifetimeEarnings = 1e50).toJson()..['prestigeStars'] = _int64Max;
      final s = GameState.fromJson(json);
      expect(s.prestigeStars, _int64Max.toDouble());
      // Trước khi sửa: available = 0 (cả hai vế đều kẹp) → kẹt vĩnh viễn.
      final available = prestigeStarsAvailable(s);
      expect(available, greaterThan(0.0));
      prestige(s);
      expect(
        s.prestigeStars,
        starsForLifetimeEarnings(1e50, Balance.prestigeK),
      );
    });

    test('hệ số thu nhập không đóng băng theo Sao bị kẹp', () {
      final lo = prestigeMultiplier(
        starsForLifetimeEarnings(_ceilingLifetime * 4, Balance.prestigeK),
        Balance.bonusPerStar,
      );
      final hi = prestigeMultiplier(
        starsForLifetimeEarnings(_ceilingLifetime * 9, Balance.prestigeK),
        Balance.bonusPerStar,
      );
      expect(hi, greaterThan(lo));
      expect(hi.isFinite, isTrue);
    });

    test('giá perk Kho Sao không kẹp trần ở cấp cao', () {
      // baseCost·2^level: từ cấp ~60 là vượt int64. Sao hết trần nên cấp này
      // với tới được, giá kẹp = mua mãi không hết Sao.
      final c60 = prestigeShopCost(Balance.prestigeIncomeBaseCost, 60);
      final c70 = prestigeShopCost(Balance.prestigeIncomeBaseCost, 70);
      expect(c70 / c60, closeTo(1024, 1e-9));
      expect(c70, greaterThan(_int64Max.toDouble()));
    });
  });
}
