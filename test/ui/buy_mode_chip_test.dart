import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('chip chế độ mua nằm cùng hàng tên giai đoạn và xoay ×1 → ×10 → MAX → ×1',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();

    final chip = find.byKey(const Key('buy-mode-chip'));
    expect(chip, findsOneWidget);
    // Cùng hàng với tên giai đoạn (cùng tâm dọc, không phải hàng riêng bên dưới).
    final nameY = tester.getCenter(find.byKey(const Key('stage-header-name'))).dy;
    expect((tester.getCenter(chip).dy - nameY).abs(), lessThan(12));

    String label() => tester
        .widget<Text>(find.descendant(of: chip, matching: find.byType(Text)))
        .data!;
    expect(label(), '×1');
    for (final expected in ['×10', 'MAX', '×1']) {
      await tester.tap(chip);
      await tester.pump();
      expect(label(), expected);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
