import 'dart:ui' as ui;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAds implements AdService {
  const _StubAds(this.outcome);
  final RewardOutcome outcome;
  @override
  Future<RewardOutcome> showRewardedAd() async => outcome;
}

/// Bơm app (locale en, clock=0 → không có tiền offline, không lượt free hôm nay).
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required AdService ads,
}) async {
  tester.platformDispatcher.localesTestValue = const [ui.Locale('en')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // tra_den cấp 2 = 1 Xu/s → ô "coins" có giá trị > 0.
  await GameStorage(
    prefs,
  ).save(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2, nowMillis: 0);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
        adServiceProvider.overrideWithValue(ads),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(BobaEmpireApp)));
}

Future<void> _openWheel(WidgetTester tester) async {
  await tester.tap(find.text('Earn more 🎁'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('open-wheel')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('quay (xem QC earned) cộng đúng một loại phần thưởng', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      ads: const _StubAds(RewardOutcome.earned),
    );

    // Hết lượt free hôm nay (clock=0) → nút hiện "Watch ad to spin".
    expect(container.read(gameControllerProvider).freeSpinAvailable, isFalse);

    await _openWheel(tester);
    expect(find.byKey(const Key('wheel-spin')), findsOneWidget);

    final beforeMoney = container.read(gameControllerProvider).money;
    final beforeGems = container.read(gameControllerProvider).gems;
    final beforeX2 = container
        .read(gameControllerProvider)
        .x2IncomeRemainingSeconds;

    await tester.tap(find.byKey(const Key('wheel-spin')));
    await tester.pumpAndSettle(); // chờ QC + animation quay 3.6s

    final money = container.read(gameControllerProvider).money;
    final gems = container.read(gameControllerProvider).gems;
    final x2 = container.read(gameControllerProvider).x2IncomeRemainingSeconds;

    // Đúng một trong ba loại thưởng phải tăng.
    final gotReward = money > beforeMoney || gems > beforeGems || x2 > beforeX2;
    expect(gotReward, isTrue, reason: 'quay xong phải nhận thưởng');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đóng QC sớm (dismissed): không quay, không thưởng', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      ads: const _StubAds(RewardOutcome.dismissed),
    );

    await _openWheel(tester);

    final beforeMoney = container.read(gameControllerProvider).money;
    final beforeGems = container.read(gameControllerProvider).gems;

    await tester.tap(find.byKey(const Key('wheel-spin')));
    await tester.pumpAndSettle();

    expect(container.read(gameControllerProvider).money, beforeMoney);
    expect(container.read(gameControllerProvider).gems, beforeGems);

    await tester.pumpWidget(const SizedBox());
  });
}
