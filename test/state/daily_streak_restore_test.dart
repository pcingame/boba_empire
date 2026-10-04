import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 60 * 60 * 1000;

/// Chuỗi 5 ngày, lần nhận cuối ngày 100; hôm nay = ngày 102 (lỡ đúng 1 ngày).
dynamic _ctrl(ProviderContainer c) => c.read(gameControllerProvider.notifier);

Future<ProviderContainer> _open(double gems) async {
  final now = 102 * _day + 1000;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..dailyStreak = 5
        ..lastDailyDay = 100
        ..gems = gems,
      nowMillis: now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('snapshot báo cứu được; trả 💎 → streak 6, trừ đúng giá', () async {
    final c = await _open(100);
    expect(c.read(gameControllerProvider).dailyStreakRestorable, isTrue);
    final r = _ctrl(c).claimDailyReward(restore: true, payGems: true);
    expect(r.streak, 6);
    expect(c.read(gameControllerProvider).gems,
        100 - streakRestoreGems + r.gems);
  });

  test('thiếu 💎 → không trừ, rơi về nhận thường (reset 1)', () async {
    final c = await _open(5);
    final r = _ctrl(c).claimDailyReward(restore: true, payGems: true);
    expect(r.streak, 1);
    expect(c.read(gameControllerProvider).gems, 5 + r.gems);
  });

  test('cứu bằng QC (payGems=false) giữ chuỗi, không trừ 💎', () async {
    final c = await _open(0);
    final r = _ctrl(c).claimDailyReward(restore: true);
    expect(r.streak, 6);
    expect(c.read(gameControllerProvider).gems, r.gems.toDouble());
  });
}
