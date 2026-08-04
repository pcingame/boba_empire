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
  testWidgets('mở shop, mua bằng gems → cấp tăng, gems giảm', (tester) async {
    await _pump(tester, GameState.newGame(nowMillis: 0)..gems = 5);

    // Header hiện 💎 5.
    expect(find.text('💎 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cửa Hàng'), findsOneWidget);
    expect(find.text('5 💎'), findsOneWidget); // giá cấp 0 của Tăng thu nhập

    await tester.tap(find.byKey(const Key('gem-buy-Tăng thu nhập')));
    await tester.pumpAndSettle();

    // Sau khi mua: vật phẩm lên Lv.1 và tiêu đề shop cập nhật "có 0".
    expect(find.textContaining('Lv.1'), findsOneWidget);
    expect(find.textContaining('có 0'), findsOneWidget);

    // Đóng shop, header về 💎 0.
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('💎 0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('không đủ gems: nút mua bị mờ', (tester) async {
    await _pump(tester, GameState.newGame(nowMillis: 0)); // 0 gems

    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await tester.pumpAndSettle();

    final buyBtn = tester.widget<FilledButton>(
      find.byKey(const Key('gem-buy-Tăng thu nhập')),
    );
    expect(buyBtn.onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
