import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/widgets/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Số xu cực lớn (FittedBox co hết cỡ) không được dính/đè chip 💎.
void main() {
  for (final vip in [false, true]) {
    for (final w in [360.0, 393.0]) {
      testWidgets('${w.toInt()}dp vip=$vip: số xu cách chip 💎 ≥ 8dp',
          (tester) async {
        tester.view.physicalSize = Size(w * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await GameStorage(prefs).save(
            GameState.newGame(nowMillis: 0)
              ..stage = 3
              ..money = 3.156e40
              ..gems = 2010
              ..vipUntilMillis = vip ? 1 << 50 : 0,
            nowMillis: 0);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(() => 0),
          ],
          child: const BobaEmpireApp(),
        ));
        await tester.pumpAndSettle();
        final coinsRight = tester.getTopRight(find.byType(AnimatedCount)).dx;
        final chipLeft = tester.getTopLeft(find.textContaining('💎').first).dx;
        // chip có padding 10 → mép chip = mép chữ − 10
        expect(chipLeft - 10 - coinsRight, greaterThanOrEqualTo(8));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
