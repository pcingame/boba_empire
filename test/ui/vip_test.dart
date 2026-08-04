import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('VIP hiện; chạm → nhận Kim Cương, VIP biến mất, hiện snackbar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      nowMillis: 0,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => 0),
        ],
        child: const BobaEmpireApp(),
      ),
    );

    // Ban đầu: chưa có VIP, Kim Cương = 0.
    expect(find.byKey(const Key('vip-customer')), findsNothing);
    expect(find.text('💎 0'), findsOneWidget);

    // Ép VIP xuất hiện.
    final element = tester.element(find.byType(HomePage));
    final container = ProviderScope.containerOf(element);
    container.read(gameControllerProvider.notifier).debugSpawnVip();
    await tester.pump();
    expect(find.byKey(const Key('vip-customer')), findsOneWidget);

    // Chạm VIP → nhận thưởng.
    await tester.tap(find.byKey(const Key('vip-customer')));
    await tester.pump();

    expect(find.byKey(const Key('vip-customer')), findsNothing);
    expect(find.text('💎 0'), findsNothing); // Kim Cương đã tăng
    expect(find.textContaining('Khách VIP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
