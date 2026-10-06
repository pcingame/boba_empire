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
    expect(find.byKey(const Key('milestone-claim-10')), findsOneWidget); // mốc 10
    expect(find.text('+20 🪙'), findsOneWidget);
    expect(find.byKey(const Key('collection-title')), findsNothing);
    c.dispose();
    await tester.pumpWidget(const SizedBox());

    seed.collectionMilestonesClaimed.add(10);
    c = await _pump(tester, seed);
    expect(find.byKey(const Key('milestone-claim-10')), findsNothing);
    expect(find.text('✓'), findsOneWidget);
    expect(find.text('Danh hiệu: Người sưu tầm'), findsOneWidget);
    c.dispose();
  });

  testWidgets('dải mốc cuộn ngang: MỘT hàng, thẻ rộng đều, không tràn (360px, chữ 1.3x)',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await _pump(tester, GameState.newGame(nowMillis: 0));
    final cells = collectionMilestones
        .map((m) => tester.getRect(find.byKey(Key('milestone-${m.count}'))))
        .toList();
    expect(cells.map((r) => r.top).toSet().length, 1, reason: 'cùng một hàng');
    expect(cells.map((r) => r.width.round()).toSet().length, 1,
        reason: 'rộng đều');
    expect(cells.first.left, lessThan(24), reason: 'chưa nhận gì → mốc đầu ở mép trái');
    expect(tester.takeException(), isNull);
    c.dispose();
  });

  testWidgets('tự cuộn tới mốc kế tiếp chưa nhận và đưa vào trong khung nhìn',
      (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Đã nhận 4 mốc đầu (10/25/40/50), đủ 160 món → mốc kế là 80 (thứ 5).
    final seed = GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(accessories.take(160).map((a) => a.id))
      ..collectionMilestonesClaimed.addAll([10, 25, 40, 50]);
    final c = await _pump(tester, seed);
    final strip = tester.getRect(find.byType(SingleChildScrollView).first);
    final next = tester.getRect(find.byKey(const Key('milestone-claim-80')));
    expect(next.left, greaterThanOrEqualTo(strip.left - 0.5));
    expect(next.right, lessThanOrEqualTo(strip.right + 0.5));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('tiêu đề Kho không bị cắt "…" dù 3 nút bên phải + chữ to (320px, 1.3x)',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await _pump(tester, GameState.newGame(nowMillis: 0));
    final title = find.descendant(
        of: find.byType(AppBar), matching: find.byType(FittedBox));
    expect(title, findsOneWidget);
    final text = tester.widget<Text>(
        find.descendant(of: title, matching: find.byType(Text)));
    // Text bên trong FittedBox luôn được layout đủ rộng → không bao giờ ellipsis.
    final box = tester.getRect(title);
    final share = tester.getRect(find.byKey(const Key('collection-share')));
    expect(box.right, lessThanOrEqualTo(share.left + 0.5),
        reason: 'tiêu đề không đè lên nút chia sẻ');
    expect(text.maxLines, 1);
    expect(tester.takeException(), isNull);
    c.dispose();
  });
}
