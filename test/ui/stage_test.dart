import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, GameState seed) async {
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
  testWidgets('giai đoạn 1 chỉ hiện Trà đen; mở khóa → hiện topping GĐ2',
      (tester) async {
    await _pump(tester, GameState.newGame(nowMillis: 0)..money = 2000);

    // Giai đoạn 1.
    expect(find.textContaining('Xe đẩy vỉa hè'), findsOneWidget);
    expect(find.text('Trà đen'), findsOneWidget);
    expect(find.text('Trân châu'), findsNothing);

    // Mở khóa giai đoạn 2 (đủ 2000 Xu).
    await tester.tap(find.byKey(const Key('unlock-stage')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kiosk cửa hàng nhỏ'), findsOneWidget);
    expect(find.text('Trân châu'), findsOneWidget);
    expect(find.text('0 Xu'), findsOneWidget); // tiền đã bị trừ

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('thiếu tiền: nút mở khóa bị mờ', (tester) async {
    await _pump(tester, GameState.newGame(nowMillis: 0)..money = 100);

    final btn = tester.widget<FilledButton>(
      find.byKey(const Key('unlock-stage')),
    );
    expect(btn.onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
