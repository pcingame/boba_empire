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
/// t=[awayMs] → offline [awayMs]/1000 Xu. Mặc định 120s = đúng ngưỡng bật popup
/// (Balance.offlineDialogMinSeconds).
Future<void> _pumpWithOffline(WidgetTester tester, AdService ads,
    {int awayMs = 120000}) async {
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
        clockProvider.overrideWithValue(() => awayMs),
        adServiceProvider.overrideWithValue(ads),
      ],
      child: const BobaEmpireApp(),
    ),
  );
  await tester.pumpAndSettle(); // đợi postFrame mở popup
}

void main() {
  testWidgets('vắng NGẮN (< 2 phút): KHÔNG bật popup, nhưng Xu vẫn được cộng',
      (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned),
        awayMs: 119000);
    expect(find.byKey(const Key('offline-double')), findsNothing);
    expect(find.textContaining('Bạn kiếm được'), findsNothing);
    expect(find.text('119 Xu'), findsOneWidget, reason: 'tiền vẫn cộng');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đúng ngưỡng 2 phút: bật popup', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned),
        awayMs: 120000);
    expect(find.byKey(const Key('offline-double')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('popup offline hiện số tiền và nút nhân đôi', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned));

    expect(find.textContaining('Bạn kiếm được 120 Xu'), findsOneWidget);
    expect(find.byKey(const Key('offline-double')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('xem QC nhân đôi: tiền offline thành gấp đôi', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.earned));

    // Trước khi nhân đôi: đã nhận 120 (offline) → money hiển thị 120 Xu.
    await tester.tap(find.byKey(const Key('offline-double')));
    await tester.pumpAndSettle();

    // Sau nhân đôi: 120 + 120 = 240 Xu, popup đã đóng.
    expect(find.byKey(const Key('offline-double')), findsNothing);
    expect(find.text('240 Xu'), findsOneWidget);
    expect(find.textContaining('Nhân đôi'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bấm Nhận: không nhân đôi, giữ nguyên tiền', (tester) async {
    await _pumpWithOffline(tester, const _InstantAds(RewardOutcome.dismissed));

    await tester.tap(find.text('Nhận'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline-double')), findsNothing);
    expect(find.text('120 Xu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
