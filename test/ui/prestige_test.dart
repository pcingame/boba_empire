import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bơm app với một save có sẵn (để điều khiển lifetimeEarnings, money...).
Future<void> _pumpWithSave(WidgetTester tester, GameState seed) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ),
  );
}

void main() {
  testWidgets('chưa đủ lifetime: nút nhượng quyền bị mờ', (tester) async {
    await _pumpWithSave(
      tester,
      GameState.newGame(nowMillis: 0)..lifetimeEarnings = 100, // -> 0 sao
    );

    await tester.tap(find.byKey(const Key('prestige-button')));
    await tester.pumpAndSettle();

    expect(find.text('Chưa đủ'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('prestige-confirm')),
    );
    expect(confirm.onPressed, isNull); // disabled

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đủ điều kiện: nhượng quyền nhận sao và reset tiền',
      (tester) async {
    await _pumpWithSave(
      tester,
      GameState.newGame(nowMillis: 0)
        ..money = 500
        ..levels['tra_den'] = 3
        ..lifetimeEarnings = 1000000, // 0.05*sqrt(1e6)=50 sao
    );

    expect(find.text('500 Xu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('prestige-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('+50 ⭐'), findsWidgets);

    await tester.tap(find.byKey(const Key('prestige-confirm')));
    await tester.pumpAndSettle();

    // Dialog đóng, tiền reset về 0, số Sao trên AppBar thành 50.
    expect(find.text('0 Xu'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.textContaining('Nhượng quyền thành công'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
