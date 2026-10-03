library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/collection_milestones.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, GameState seed) async {
  await tester.binding.setSurfaceSize(const Size(400, 2800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const MaterialApp(
      locale: Locale('vi'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AccessoryInventoryPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  test('milestonesClaimable / highestClaimed theo số món và cờ đã nhận', () {
    final s = GameState.newGame(nowMillis: 0);
    expect(milestonesClaimable(s), 0);
    s.ownedAccessories.addAll(accessories.take(25).map((a) => a.id));
    expect(milestonesClaimable(s), 2); // 10 và 25
    s.collectionMilestonesClaimed.add(10);
    expect(milestonesClaimable(s), 1);
    expect(highestClaimedMilestone(s)!.count, 10);
    final r = GameState.fromJson(s.toJson());
    expect(r.collectionMilestonesClaimed, [10]);
  });

  testWidgets('Kho: mốc chưa đạt khoá, đạt thì có nút nhận, đã nhận có ✓ + danh hiệu',
      (tester) async {
    final seed = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(accessories.take(12).map((a) => a.id));
    var c = await _pump(tester, seed);
    expect(find.byType(ActionChip), findsOneWidget); // mốc 10
    expect(find.textContaining('Nhận +20'), findsOneWidget);
    expect(find.byKey(const Key('collection-title')), findsNothing);
    c.dispose();
    await tester.pumpWidget(const SizedBox());

    seed.collectionMilestonesClaimed.add(10);
    c = await _pump(tester, seed);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('✓ 10'), findsOneWidget);
    expect(find.text('Danh hiệu: Người sưu tầm'), findsOneWidget);
    c.dispose();
  });
}
