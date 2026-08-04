import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InstantAds implements AdService {
  const _InstantAds(this.outcome);
  final RewardOutcome outcome;
  @override
  Future<RewardOutcome> showRewardedAd() async => outcome;
}

/// Bơm app với save có tiền offline: tra_den cấp 2 (1 Xu/s), lưu ở t=0, mở ở
/// t=60s → offline 60 Xu.
Future<void> _pumpWithOffline(WidgetTester tester, AdService ads) async {
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
        clockProvider.overrideWithValue(() => 60000),
        adServiceProvider.overrideWithValue(ads),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle(); // đợi postFrame mở popup
}

void main() {
  testWidgets('popup offline hiện số tiền và nút nhân đôi', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned));

    expect(find.textContaining('Bạn kiếm được 60 Xu'), findsOneWidget);
    expect(find.byKey(const Key('offline-double')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('xem QC nhân đôi: tiền offline thành gấp đôi', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned));

    // Trước khi nhân đôi: đã nhận 60 (offline) → money hiển thị 60 Xu.
    await tester.tap(find.byKey(const Key('offline-double')));
    await tester.pumpAndSettle();

    // Sau nhân đôi: 60 + 60 = 120 Xu, popup đã đóng.
    expect(find.byKey(const Key('offline-double')), findsNothing);
    expect(find.text('120 Xu'), findsOneWidget);
    expect(find.textContaining('Nhân đôi'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bấm Nhận: không nhân đôi, giữ nguyên tiền', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.dismissed));

    await tester.tap(find.text('Nhận'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline-double')), findsNothing);
    expect(find.text('60 Xu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
