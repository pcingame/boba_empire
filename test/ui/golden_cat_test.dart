import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quảng cáo giả trả kết quả ngay, khỏi chờ.
class _InstantAds implements AdService {
  const _InstantAds(this.outcome);
  final RewardOutcome outcome;
  @override
  Future<RewardOutcome> showRewardedAd() async => outcome;
}

void main() {
  testWidgets('mèo hiện; chạm + xem QC → mèo biến mất, đồng hồ x3 bật',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          adServiceProvider
              .overrideWithValue(const _InstantAds(RewardOutcome.earned)),
        ],
        child: const BobaEmpireApp(),
      ),
    );

    expect(find.byKey(const Key('golden-cat')), findsNothing);
    expect(find.textContaining('x3'), findsNothing);

    final element = tester.element(find.byType(HomePage));
    final container = ProviderScope.containerOf(element);
    container.read(gameControllerProvider.notifier).debugSpawnCat();
    await tester.pump();
    expect(find.byKey(const Key('golden-cat')), findsOneWidget);

    await tester.tap(find.byKey(const Key('golden-cat')));
    await tester.pumpAndSettle(); // đợi Future quảng cáo hoàn tất
    expect(find.byKey(const Key('golden-cat')), findsNothing);
    expect(find.textContaining('x3'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
