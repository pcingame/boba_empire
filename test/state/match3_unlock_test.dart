// Hồi quy: qua màn 1 lúc thu nhập/giây còn 0 (người chơi mới, chưa mua nguồn
// thu nào) thì màn 2 vẫn phải mở khoá ngay.
import 'package:boba_empire/core/match3_levels.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('thu nhập/giây = 0 vẫn có thưởng Xu (không phải 0 trơn)', () {
    final s = GameState.newGame(nowMillis: 0);
    final (cash, _) = applyMatch3Result(s, 1, 1, incomePerSecond: 0);
    expect(s.m3Stars.first, 1);
    expect(cash, greaterThan(0), reason: 'phải có mức sàn cho người chơi mới');
  });

  test('qua màn 1 -> snapshot cập nhật sao -> màn 2 mở khoá', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);

    final controller = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider).incomePerSecond, 0,
        reason: 'ván mới: chưa có thu nhập');

    controller.grantMatch3Result(1, 1);

    final snap = container.read(gameControllerProvider);
    expect(starsOf(snap.m3Stars, 1), 1, reason: 'snapshot phải thấy sao mới');
    expect(levelUnlocked(snap.m3Stars, 2), isTrue);
    container.dispose();
  });

  test('sao được lưu xuống đĩa (mở lại app không mất)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = GameStorage(prefs);
    await storage.save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    container.read(gameControllerProvider.notifier).grantMatch3Result(1, 2);
    await Future<void>.delayed(Duration.zero); // saveNow() chạy bất đồng bộ
    container.dispose();

    expect(starsOf(storage.load()!.m3Stars, 1), 2);
  });
}
