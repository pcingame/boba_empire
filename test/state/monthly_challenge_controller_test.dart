import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/monthly_challenge.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mở app chụp mốc tháng; làm đủ 3 mục → nhận → rương rớt phụ kiện ≥ Sử thi, mở một lần', () async {
    final now = DateTime.utc(2026, 10, 15, 12).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Đã có mốc tháng này (tạo bằng roll) rồi mới tăng bộ đếm, như người chơi đang chơi giữa tháng.
    final seed = GameState.newGame(nowMillis: now)..gems = 0;
    rollMonthlyChallenge(seed, now);
    seed.tapCount += 3000;
    seed.buyCount += 1000;
    seed.ownedAccessories.addAll(['x1', 'x2', 'x3', 'x4']);
    await GameStorage(prefs).save(seed, nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    var snap = c.read(gameControllerProvider);
    expect(snap.monthly.every((m) => m.done && !m.claimed), isTrue);
    expect(snap.dailyClaimableCount, 3);

    expect(ctrl.claimMonthlyChestReward(), 0); // chưa nhận đủ
    for (final k in MonthlyKind.values) {
      expect(ctrl.claimMonthlyReward(k), monthlyQuestRewardGems);
    }
    snap = c.read(gameControllerProvider);
    expect(snap.monthlyChestAvailable, isTrue);
    expect(snap.dailyClaimableCount, 1);
    final before = snap.gems;
    expect(ctrl.claimMonthlyChestReward(), monthlyChestGems);
    final drop = ctrl.lastAccessoryDrop as AccessoryDrop?;
    expect(drop, isNotNull);
    expect(drop!.accessory.rarity.index, greaterThanOrEqualTo(AccessoryRarity.epic.index));
    snap = c.read(gameControllerProvider);
    expect(snap.gems, greaterThanOrEqualTo(before + monthlyChestGems));
    expect(snap.monthlyChestClaimed, isTrue);
    expect(snap.dailyClaimableCount, 0);
    expect(ctrl.claimMonthlyChestReward(), 0);
  });
}
