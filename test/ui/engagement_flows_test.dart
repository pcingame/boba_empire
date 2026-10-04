import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/ui/accessory_pack_dialog.dart';
import 'package:boba_empire/ui/home_page.dart' show debugAutoShowDaily;
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Luồng UI thật (qua BobaEmpireApp) của: cứu streak, QC nhượng quyền, QC thêm
/// phụ kiện, ô trưng bày VIP. QC giả để điều khiển earned/dismissed.
class _Ads implements AdService {
  _Ads(this.outcome);
  RewardOutcome outcome;
  int shown = 0;
  @override
  Future<RewardOutcome> showRewardedAd() async {
    shown++;
    return outcome;
  }
}

const _day = 24 * 60 * 60 * 1000;

Future<ProviderContainer> _pump(WidgetTester tester, GameState seed, _Ads ads,
    {required int now}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: now);
  late ProviderContainer container;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
      adServiceProvider.overrideWithValue(ads),
    ],
    child: Consumer(builder: (c, ref, _) {
      container = ProviderScope.containerOf(c);
      return const BobaEmpireApp();
    }),
  ));
  await tester.pumpAndSettle();
  return container;
}

/// Chuỗi 5 ngày, nhận lần cuối ngày 100, hôm nay ngày 102 → lỡ đúng 1 ngày.
GameState _streakSave(int now, {double gems = 100}) =>
    GameState.newGame(nowMillis: now)
      ..tutorialSeen = true
      ..dailyStreak = 5
      ..lastDailyDay = 100
      ..gems = gems;

void main() {
  final now = 102 * _day + 1000;

  group('cứu streak (dialog điểm danh thật)', () {
    setUp(() => debugAutoShowDaily = true);
    tearDown(() => debugAutoShowDaily = false);
    testWidgets('trả 💎: giữ chuỗi → 6, trừ 20💎', (tester) async {
      final c = await _pump(tester, _streakSave(now), _Ads(RewardOutcome.earned),
          now: now);
      expect(find.byKey(const Key('daily-restore-gems')), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily-restore-gems')));
      await tester.pumpAndSettle();
      expect(find.text('Chuỗi 6 ngày 🔥'), findsOneWidget);
      final gems = c.read(gameControllerProvider).gems;
      expect(gems, 100 - streakRestoreGems + dailyGemsForStreak(6));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('xem QC xong: giữ chuỗi, KHÔNG trừ 💎', (tester) async {
      final ads = _Ads(RewardOutcome.earned);
      final c = await _pump(tester, _streakSave(now, gems: 0), ads, now: now);
      await tester.tap(find.byKey(const Key('daily-restore-ad')));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(find.text('Chuỗi 6 ngày 🔥'), findsOneWidget);
      expect(c.read(gameControllerProvider).gems, dailyGemsForStreak(6).toDouble());
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đóng QC sớm: chưa nhận gì, vẫn còn 3 lựa chọn', (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      final c = await _pump(tester, _streakSave(now, gems: 0), ads, now: now);
      await tester.tap(find.byKey(const Key('daily-restore-ad')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('daily-restore-ad')), findsOneWidget);
      expect(c.read(gameControllerProvider).dailyAvailable, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('thiếu 💎: nút trả 💎 bị mờ', (tester) async {
      await _pump(tester, _streakSave(now, gems: 5), _Ads(RewardOutcome.earned),
          now: now);
      final b = tester.widget<FilledButton>(
          find.byKey(const Key('daily-restore-gems')));
      expect(b.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"Bỏ qua": chuỗi reset về 1', (tester) async {
      await _pump(tester, _streakSave(now), _Ads(RewardOutcome.earned), now: now);
      await tester.tap(find.byKey(const Key('daily-claim')));
      await tester.pumpAndSettle();
      expect(find.text('Chuỗi 1 ngày 🔥'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('lỡ 2 ngày: không có lựa chọn cứu, nhận thường', (tester) async {
      final seed = _streakSave(now)..lastDailyDay = 99;
      await _pump(tester, seed, _Ads(RewardOutcome.earned), now: now);
      expect(find.byKey(const Key('daily-restore-gems')), findsNothing);
      expect(find.byKey(const Key('daily-claim')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('nhượng quyền + QC', () {
    GameState seed(int now) => GameState.newGame(nowMillis: now)
      ..tutorialSeen = true
      ..lastDailyDay = now ~/ _day // bỏ qua popup điểm danh
      ..stage = 3
      ..lifetimeEarnings = 1e12
      ..levels['tra_den'] = 50;

    testWidgets('xem QC: nhượng quyền + có Xu khởi đầu', (tester) async {
      final ads = _Ads(RewardOutcome.earned);
      final c = await _pump(tester, seed(now), ads, now: now);
      await tester.tap(find.byKey(const Key('prestige-button')));
      await tester.pumpAndSettle();
      final income = c.read(gameControllerProvider).incomePerSecond;
      await tester.tap(find.byKey(const Key('prestige-ad')));
      await tester.pumpAndSettle();
      final s = c.read(gameControllerProvider);
      expect(ads.shown, 1);
      expect(s.prestigeStars, greaterThan(0));
      expect(s.money, greaterThan(income * 500)); // ≈ 600s thu nhập cũ
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đóng QC sớm: KHÔNG nhượng quyền, dialog còn mở', (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      final c = await _pump(tester, seed(now), ads, now: now);
      await tester.tap(find.byKey(const Key('prestige-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prestige-ad')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).prestigeStars, 0);
      expect(find.byKey(const Key('prestige-confirm')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('VIP ô trưng bày', () {
    testWidgets('không VIP: tối đa 3; VIP: 4', (tester) async {
      for (final vip in [false, true]) {
        final s = GameState.newGame(nowMillis: now)
          ..tutorialSeen = true
          ..lastDailyDay = now ~/ _day
          ..vipUntilMillis = vip ? now + _day : 0
          ..ownedAccessories.addAll(accessories.take(5).map((a) => a.id));
        final c = await _pump(tester, s, _Ads(RewardOutcome.earned), now: now);
        final ctrl = c.read(gameControllerProvider.notifier);
        final results = [
          for (final a in accessories.take(5)) ctrl.toggleEquippedAccessory(a.id)
        ];
        expect(results.where((r) => r).length, vip ? 4 : 3);
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('QC thêm phụ kiện (dialog nhiệm vụ ngày thật)', () {
    GameState seed(int now, {required bool bonusClaimed}) =>
        GameState.newGame(nowMillis: now)
          ..tutorialSeen = true
          ..lastDailyDay = now ~/ _day
          ..dailyQuestDay = now ~/ _day
          ..dailyBonusClaimed = bonusClaimed;

    testWidgets('chưa nhận thưởng cả bộ: không có nút QC', (tester) async {
      await _pump(tester, seed(now, bonusClaimed: false),
          _Ads(RewardOutcome.earned),
          now: now);
      await tester.tap(find.byKey(const Key('daily-quests-chip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accessory-ad-drop')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đã nhận: xem QC → hiện món vừa rớt, nút biến mất (1 lần/ngày)',
        (tester) async {
      final ads = _Ads(RewardOutcome.earned);
      final c = await _pump(tester, seed(now, bonusClaimed: true), ads, now: now);
      await tester.tap(find.byKey(const Key('daily-quests-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accessory-ad-drop')));
      await tester.pumpAndSettle();
      expect(ads.shown, 1);
      expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
      expect(find.byKey(const Key('accessory-ad-drop')), findsNothing);
      expect(c.read(gameControllerProvider).ownedAccessories.length, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đóng QC sớm: không rớt, nút còn để thử lại', (tester) async {
      final ads = _Ads(RewardOutcome.dismissed);
      final c = await _pump(tester, seed(now, bonusClaimed: true), ads, now: now);
      await tester.tap(find.byKey(const Key('daily-quests-chip')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('accessory-ad-drop')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).ownedAccessories, isEmpty);
      expect(find.byKey(const Key('accessory-ad-drop')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  // Dialog mới/sửa không tràn ở mọi ngôn ngữ, màn hẹp 320dp (RenderFlex → test fail).
  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] 320dp: dialog cứu streak / nhượng quyền / nhiệm vụ không tràn',
        (tester) async {
      tester.platformDispatcher.localesTestValue = [Locale(locale)];
      debugAutoShowDaily = true;
      addTearDown(() => debugAutoShowDaily = false);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final seed = _streakSave(now)
        ..stage = 3
        ..lifetimeEarnings = 1e12
        ..dailyQuestDay = now ~/ _day
        ..dailyBonusClaimed = true;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(seed, nowMillis: now);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
          adServiceProvider.overrideWithValue(_Ads(RewardOutcome.earned)),
        ],
        child: const BobaEmpireApp(),
      ));
      await tester.pumpAndSettle(); // dialog cứu streak
      expect(find.byKey(const Key('daily-restore-gems')), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily-claim'))); // bỏ qua
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('daily-close')).evaluate().isEmpty
          ? find.byType(FilledButton).last
          : find.byKey(const Key('daily-close')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prestige-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('prestige-ad')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] 320dp: dialog nhiệm vụ (nút QC phụ kiện) + Kho phụ kiện không tràn',
        (tester) async {
      tester.platformDispatcher.localesTestValue = [Locale(locale)];
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final seed = GameState.newGame(nowMillis: now)
        ..tutorialSeen = true
        ..lastDailyDay = now ~/ _day
        ..dailyQuestDay = now ~/ _day
        ..dailyBonusClaimed = true;
      final c = await _pump(tester, seed, _Ads(RewardOutcome.earned), now: now);
      await tester.tap(find.byKey(const Key('daily-quests-chip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accessory-ad-drop')), findsOneWidget);
      await tester.tap(find.byKey(const Key('accessory-ad-drop'))); // + reveal
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).ownedAccessories.length, 1);
      await tester.pumpWidget(const SizedBox());
    });
  }

  group('vòng quay phụ kiện (UI thật)', () {
    Future<(ProviderContainer, _Ads)> open(WidgetTester tester,
        {double gems = 200, RewardOutcome o = RewardOutcome.earned, Size? size}) async {
      final ads = _Ads(o);
      final seed = GameState.newGame(nowMillis: now)
        ..tutorialSeen = true
        ..lastDailyDay = now ~/ _day
        ..gems = gems;
      final c = await _pump(tester, seed, ads, now: now);
      showAccessoryPacks(tester.element(find.byType(Scaffold).first));
      await tester.pumpAndSettle();
      return (c, ads);
    }

    testWidgets('quay bằng 💎 → hiện món, trừ 30 (hoàn 2 nếu trùng)',
        (tester) async {
      final (c, _) = await open(tester);
      await tester.tap(find.byKey(const Key('accessory-wheel-gems')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
      expect(c.read(gameControllerProvider).ownedAccessories.length, 1);
      expect(c.read(gameControllerProvider).gems, 170);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('quay xem QC → hiện món; số lượt còn giảm 1', (tester) async {
      final (c, ads) = await open(tester, gems: 0);
      await tester.tap(find.byKey(const Key('accessory-wheel-ad')));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(ads.shown, 1);
      expect(find.byKey(const Key('accessory-reveal')), findsOneWidget);
      expect(c.read(gameControllerProvider).accessoryAdSpinsLeft, 9);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('đóng QC sớm: không quay, không rớt', (tester) async {
      final (c, _) = await open(tester, gems: 0, o: RewardOutcome.dismissed);
      await tester.tap(find.byKey(const Key('accessory-wheel-ad')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('accessory-reveal')), findsNothing);
      expect(c.read(gameControllerProvider).ownedAccessories, isEmpty);
      expect(c.read(gameControllerProvider).accessoryAdSpinsLeft, 10);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('thiếu 💎: nút 30 💎 mờ', (tester) async {
      await open(tester, gems: 29);
      final b = tester
          .widget<FilledButton>(find.byKey(const Key('accessory-wheel-gems')));
      expect(b.onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
