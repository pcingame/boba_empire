import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grantGems cộng Kim Cương; bỏ qua số ≤ 0', () {
    final s = GameState.newGame(nowMillis: 0);
    grantGems(s, 100);
    expect(s.gems, 100);
    grantGems(s, 0);
    grantGems(s, -5);
    expect(s.gems, 100);
  });

  test('setAdsRemoved idempotent', () {
    final s = GameState.newGame(nowMillis: 0);
    expect(s.adsRemoved, false);
    setAdsRemoved(s);
    setAdsRemoved(s);
    expect(s.adsRemoved, true);
  });

  test('claimStarterPack trao đúng một lần', () {
    final s = GameState.newGame(nowMillis: 0);
    expect(claimStarterPack(s, 300), true);
    expect(s.gems, 300);
    expect(s.starterPackOwned, true);
    // Lần hai (ví dụ khi restore): không trao thêm.
    expect(claimStarterPack(s, 300), false);
    expect(s.gems, 300);
  });

  test('adsRemoved & starterPackOwned round-trip qua JSON', () {
    final s = GameState.newGame(nowMillis: 0)
      ..adsRemoved = true
      ..starterPackOwned = true;
    final loaded = GameState.fromJson(s.toJson());
    expect(loaded.adsRemoved, true);
    expect(loaded.starterPackOwned, true);
  });

  test('save cũ thiếu 2 trường → mặc định false', () {
    final loaded = GameState.fromJson({
      'money': 0,
      'gems': 0,
      'tapValue': 1,
      'levels': <String, int>{},
      'lifetimeEarnings': 0,
      'prestigeStars': 0,
      'lastSeenMillis': 0,
    });
    expect(loaded.adsRemoved, false);
    expect(loaded.starterPackOwned, false);
  });
}
