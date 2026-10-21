import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/pet.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('công thức: trần lưu trữ, cấp 0 không có Xu, emoji kẹp cấp', () {
    expect(petPendingSeconds(0, 10 * 3600 * 1000), petStoreHours * 3600);
    expect(petPendingSeconds(5000, 1000), 0);
    expect(petPendingXu(0, 0, 1e9.toInt(), 10), 0);
    expect(petPendingXu(2, 0, 100 * 1000, 10), closeTo(100 * 10 * petRatePerLevel * 2, 1e-9));
    expect(petEmojiOf(99), petEmoji.last);
    expect(petLevelCost(2, double.nan), 2000);
  });

  test('nhận nuôi bằng 💎, nhặt Xu, nâng cấp bằng Xu, lưu/đọc', () async {
    var now = 1000;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..tutorialSeen = true
          ..gems = 30
          ..levels[Balance.generators.first.id] = 10,
        nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    addTearDown(c.dispose);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.collectPet(), 0, reason: 'chưa có linh vật');
    expect(ctl.upgradePet(), isTrue);
    expect(c.read(gameControllerProvider).gems, 30 - petAdoptGems);
    now += 3600 * 1000;
    final money = c.read(gameControllerProvider).money;
    final got = ctl.collectPet();
    expect(got, greaterThan(0));
    expect(c.read(gameControllerProvider).money, closeTo(money + got, got * 1e-6 + 1));
    expect(ctl.collectPet(), 0, reason: 'vừa nhặt');
    expect(ctl.upgradePet(), isFalse, reason: 'thiếu Xu');
    final back = GameState.fromJson(ctl.debugGame.toJson());
    expect(back.petLevel, 1);
  });
}
