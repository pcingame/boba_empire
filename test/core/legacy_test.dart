import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/economy.dart';
import 'package:boba_empire/core/legacy.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('công thức: giá tăng ×1.6, tổng đã tiêu khớp, hệ số tuyến tính, mở sau Kỷ Nguyên 4', () {
    expect(legacyCost(0), 6);
    expect(legacyCost(1), 10);
    expect(legacyCost(10), greaterThan(legacyCost(9)));
    expect(legacySpent(0), 0);
    expect(legacySpent(3), legacyCost(0) + legacyCost(1) + legacyCost(2));
    expect(legacySpent(10000), legacySpent(legacyMaxLevel), reason: 'kẹp trần');
    expect(legacyCost(legacyMaxLevel), lessThan(1 << 62));
    expect(legacyMultiplier(10), closeTo(1.3, 1e-9));
    expect(legacyMultiplier(-5), 1);
    expect(legacyUnlocked(3), isFalse);
    expect(legacyUnlocked(4), isTrue);
  });

  test('tiêu ⏳ Di sản trừ vào điểm còn dư; tăng thu nhập và chạm; giữ qua Kỷ Nguyên', () {
    final s = GameState.newGame(nowMillis: 0)
      ..ascensionCount = 4
      ..ascensionPointsEarned = 100
      ..levels['tra_den'] = 10;
    final inc0 = baseIncomePerSecond(s, Balance.generators);
    final eff0 = effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar);
    final tap0 = tapGain(s);
    s
      ..legacyIncomeLevel = 5
      ..legacyTapLevel = 2;
    expect(ascensionPointsSpendable(s), 100 - legacySpent(5) - legacySpent(2));
    expect(effectiveIncomePerSecond(s, Balance.generators, bonusPerStar: Balance.bonusPerStar), closeTo(eff0 * 1.15, eff0 * 1e-9));
    expect(tapGain(s), closeTo(tap0 * 1.06, tap0 * 1e-9));
    expect(baseIncomePerSecond(s, Balance.generators), inc0, reason: 'chỉ nhân ở hệ số toàn cục');
    final back = GameState.fromJson(s.toJson()..['legacyTapLevel'] = 9999);
    expect(back.legacyIncomeLevel, 5);
    expect(back.legacyTapLevel, legacyMaxLevel);
    s.lifetimeEarnings = Balance.ascensionMinLifetime * 4;
    ascend(s);
    expect(s.legacyIncomeLevel, 5);
    expect(s.legacyTapLevel, 2);
  });

  test('buyLegacy: khoá khi <4 Kỷ Nguyên, thiếu ⏳, đủ thì mua, mỗi lần giá tăng', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..tutorialSeen = true
          ..ascensionCount = 3
          ..ascensionPointsEarned = 16,
        nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.buyLegacy(tap: false), isFalse, reason: 'chưa mở');
    ctl.debugGame.ascensionCount = 4;
    expect(ctl.buyLegacy(tap: false), isTrue); // 6
    expect(ctl.buyLegacy(tap: true), isTrue); // 6 → còn 4
    expect(c.read(gameControllerProvider).ascensionPointsSpendable, 4);
    expect(ctl.buyLegacy(tap: false), isFalse, reason: 'cấp 2 giá 10 > 4');
    expect(c.read(gameControllerProvider).legacyIncomeLevel, 1);
    expect(c.read(gameControllerProvider).legacyTapLevel, 1);
  });
}
