// Chi nhánh thành phố: công thức giá/tỉ lệ/tích trần 8 giờ, lưu & nạp save, mở/nâng cấp/thu về qua controller,
// trang (mở khoá theo giai đoạn, nút theo Xu), chấm đỏ, không tràn ở 320px mọi ngôn ngữ.
import 'dart:math' as math;

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/branches.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/branches_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _t0 = 1000000;

Future<(ProviderContainer, GameStorage, SharedPreferences)> _container(
  GameState seed, {
  required int Function() clock,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = GameStorage(prefs);
  await storage.save(seed, nowMillis: _t0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
  return (c, storage, prefs);
}

GameState _rich({int stage = 6, double money = 1e12}) {
  final id = Balance.generators.first.id;
  return GameState.newGame(nowMillis: _t0)
    ..tutorialSeen = true
    ..stage = stage
    ..money = money
    ..levels[id] = 50;
}

void main() {
  group('công thức', () {
    test('tỉ lệ tăng theo cấp và hệ số thành phố; cấp 0 = 0', () {
      final c = branchCityById('tokyo')!;
      expect(branchRate(c, 0), 0);
      expect(branchRate(c, 1), closeTo(branchRatePerLevel * c.rateMult, 1e-12));
      expect(branchRate(c, 10), closeTo(10 * branchRate(c, 1), 1e-12));
    });

    test('giá: theo giờ thu nhập, ×1.4 mỗi cấp, có sàn, không NaN/Infinity', () {
      final c = branchCities[0];
      expect(branchCost(c, 1, 1000), closeTo(1000 * 3600 * 0.5, 1e-6));
      expect(branchCost(c, 2, 1000), closeTo(branchCost(c, 1, 1000) * 1.4, 1e-3));
      expect(branchCost(c, 1, 0), branchCostFloor);
      expect(branchCost(c, 1, double.nan), branchCostFloor);
      expect(branchCost(c, 10, double.infinity).isFinite, isTrue);
      expect(branchCost(branchCityById('moon')!, 1, 1e70).isFinite, isTrue);
    });

    test('17 chi nhánh: id duy nhất, mỗi nơi có landmark + signature + màu riêng, mở từ GĐ2 tới GĐ18', () {
      expect(branchCities.length, 17);
      expect(branchCities.first.minStage, 2);
      expect(branchCities.last.minStage, 18);
      expect(branchCities.map((c) => c.emoji).toSet().length, 17, reason: 'landmark không trùng');
      expect(branchCities.map((c) => c.signature).toSet().length, 17, reason: 'signature không trùng');
      expect(branchCities.map((c) => c.color).toSet().length, 17, reason: 'màu không trùng');
    });

    test('thành phố sau mở khoá muộn hơn, đắt hơn, lời hơn', () {
      for (var i = 1; i < branchCities.length; i++) {
        expect(branchCities[i].minStage, greaterThan(branchCities[i - 1].minStage));
        expect(branchCities[i].costMult, greaterThan(branchCities[i - 1].costMult));
        expect(branchCities[i].rateMult, greaterThan(branchCities[i - 1].rateMult));
      }
      expect(branchCities.map((c) => c.id).toSet().length, branchCities.length);
    });

    test('doanh thu tích theo thời gian và kẹp trần 8 giờ', () {
      final c = branchCities[0];
      final levels = {c.id: 5};
      final since = {c.id: 0};
      final rate = branchRate(c, 5);
      expect(branchPendingIncomeSeconds(levels, since, c, 3600 * 1000), closeTo(3600 * rate, 1e-6));
      final capped = branchPendingIncomeSeconds(levels, since, c, 100 * 3600 * 1000);
      expect(capped, closeTo(branchCapSeconds * rate, 1e-6));
      expect(branchFull(levels, since, c, 9 * 3600 * 1000), isTrue);
      expect(branchFull(levels, since, c, 3600 * 1000), isFalse);
      expect(branchPendingIncomeSeconds({}, {}, c, 99999999), 0, reason: 'chưa mở');
      expect(branchPendingIncomeSeconds(levels, since, c, -5000), 0, reason: 'đồng hồ lùi không âm');
    });

    test('chấm đỏ chỉ khi tích đủ 5 phút thu nhập quán chính', () {
      final c = branchCities[0];
      final levels = {c.id: 10};
      final since = {c.id: 0};
      expect(branchesReady(levels, since, 1000), isFalse);
      expect(branchesReady(levels, since, branchCapSeconds * 1000), isTrue);
    });

    test('chi nhánh kế tiếp có thể mở theo giai đoạn', () {
      expect(nextOpenableBranch({}, 1), isNull);
      expect(nextOpenableBranch({}, 2)!.id, 'saigon');
      expect(nextOpenableBranch({'saigon': 1}, 3)!.id, 'danang');
      expect(nextOpenableBranch({'saigon': 1, 'danang': 1}, 4)!.id, 'hanoi');
    });
  });

  group('lưu / nạp save', () {
    test('khứ hồi giữ cấp và mốc; dữ liệu hỏng bị lọc', () {
      final g = GameState.newGame(nowMillis: _t0)
        ..branchLevels['tokyo'] = 7
        ..branchSince['tokyo'] = 123456;
      final back = GameState.fromJson(g.toJson());
      expect(back.branchLevels['tokyo'], 7);
      expect(back.branchSince['tokyo'], 123456);
      final j = g.toJson();
      j['branchLevels'] = {'a': -3, 'b': double.nan, 'c': 99, 'd': 'x', 'tokyo': 4};
      j['branchSince'] = {'a': -1, 'b': 'x', 'tokyo': 5};
      final dirty = GameState.fromJson(j);
      expect(dirty.branchLevels, {'c': 10, 'tokyo': 4});
      expect(dirty.branchSince, {'tokyo': 5});
    });

    test('save cũ không có trường chi nhánh vẫn nạp được', () {
      final j = GameState.newGame(nowMillis: _t0).toJson()
        ..remove('branchLevels')
        ..remove('branchSince');
      expect(GameState.fromJson(j).branchLevels, isEmpty);
    });
  });

  group('controller', () {
    test('mở chi nhánh: trừ Xu, tặng lễ khai trương, đặt mốc; chưa đủ giai đoạn/Xu thì không', () async {
      var now = _t0;
      final (c, _, _) = await _container(_rich(stage: 6), clock: () => now);
      addTearDown(c.dispose);
      final ctl = c.read(gameControllerProvider.notifier);
      final income = ctl.branchIncome;
      expect(income, greaterThan(0));
      expect(ctl.upgradeBranch('paris'), isNull, reason: 'stage 6 < 12');
      expect(ctl.upgradeBranch('unknown'), isNull);
      final before = c.read(gameControllerProvider).money;
      final cost = branchCost(branchCities[0], 1, income);
      final gala = ctl.upgradeBranch('saigon');
      expect(gala, closeTo(income * branchGalaSeconds, income * 0.01));
      final s = c.read(gameControllerProvider);
      expect(s.branchLevels['saigon'], 1);
      expect(s.branchSince['saigon'], now);
      expect(s.money, closeTo(before - cost + gala!, before * 1e-9 + 1));
    });

    test('thiếu Xu: không đổi gì', () async {
      final (c, _, _) = await _container(_rich(money: 0), clock: () => _t0);
      addTearDown(c.dispose);
      final ctl = c.read(gameControllerProvider.notifier);
      expect(ctl.upgradeBranch('saigon'), isNull);
      expect(c.read(gameControllerProvider).branchLevels, isEmpty);
    });

    test('nâng cấp gom doanh thu cũ trước, tối đa cấp 10 thì dừng', () async {
      var now = _t0;
      final (c, _, _) = await _container(_rich(money: 1e30), clock: () => now);
      addTearDown(c.dispose);
      final ctl = c.read(gameControllerProvider.notifier);
      ctl.upgradeBranch('saigon');
      now += 2 * 3600 * 1000;
      final m0 = c.read(gameControllerProvider).money;
      final cost = branchCost(branchCities[0], 2, ctl.branchIncome);
      final pending = branchPendingIncomeSeconds({'saigon': 1}, {'saigon': 0}, branchCities[0], 2 * 3600 * 1000) * ctl.branchIncome;
      expect(ctl.upgradeBranch('saigon'), 0);
      expect(c.read(gameControllerProvider).money, closeTo(m0 - cost + pending, m0 * 1e-9 + 1));
      expect(c.read(gameControllerProvider).branchSince['saigon'], now, reason: 'mốc đặt lại sau khi gom');
      for (var i = 0; i < 20; i++) {
        ctl.upgradeBranch('saigon');
      }
      expect(c.read(gameControllerProvider).branchLevels['saigon'], branchMaxLevel);
      expect(ctl.upgradeBranch('saigon'), isNull);
    });

    test('thu về: Xu = giây tích × thu nhập (×3 nếu cao điểm), đặt lại mốc, thu lần hai = 0', () async {
      var now = _t0;
      final (c, _, _) = await _container(_rich(money: 1e30), clock: () => now);
      addTearDown(c.dispose);
      final ctl = c.read(gameControllerProvider.notifier);
      ctl.upgradeBranch('saigon');
      for (var i = 0; i < 4; i++) {
        ctl.upgradeBranch('saigon');
      }
      now += 4 * 3600 * 1000;
      final base = branchPendingIncomeSeconds({'saigon': 5}, {'saigon': 0}, branchCities[0], 4 * 3600 * 1000) * ctl.branchIncome;
      final m0 = c.read(gameControllerProvider).money;
      final r = ctl.collectBranches();
      expect(r.xu, anyOf(closeTo(base, base * 1e-9), closeTo(base * branchRushMult, base * 1e-9)));
      expect(r.rushes, r.xu > base * 1.5 ? 1 : 0);
      expect(c.read(gameControllerProvider).money, closeTo(m0 + r.xu, m0 * 1e-9 + 1));
      expect(ctl.collectBranches().xu, 0);
    });

    test('đồng hồ máy chỉnh lùi không tạo Xu âm/NaN', () async {
      var now = _t0;
      final (c, _, _) = await _container(_rich(money: 1e30), clock: () => now);
      addTearDown(c.dispose);
      final ctl = c.read(gameControllerProvider.notifier);
      ctl.upgradeBranch('saigon');
      now -= 10 * 3600 * 1000;
      final r = ctl.collectBranches();
      expect(r.xu, 0);
      expect(c.read(gameControllerProvider).money.isFinite, isTrue);
    });
  });

  group('trang', () {
    Future<ProviderContainer> open(WidgetTester tester, GameState seed,
        {String locale = 'vi', Size size = const Size(400, 900), double scale = 1}) async {
      final (c, _, _) = await _container(seed, clock: () => _t0 + 5 * 3600 * 1000);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BranchesPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> end(WidgetTester tester, ProviderContainer c) async {
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }

    testWidgets('mở khoá theo giai đoạn: stage 2 chỉ Sài Gòn có nút Mở; mở được thì thành cấp 1', (tester) async {
      final c = await open(tester, _rich(stage: 2));
      expect(find.byKey(const Key('branch-act-saigon')), findsOneWidget);
      expect(find.byKey(const Key('branch-act-hanoi')), findsNothing, reason: 'bị khoá');
      expect(find.textContaining('4'), findsWidgets);
      await tester.tap(find.byKey(const Key('branch-act-saigon')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).branchLevels['saigon'], 1);
      expect(find.byType(SnackBar), findsOneWidget, reason: 'thông báo khai trương');
      await end(tester, c);
    });

    testWidgets('thẻ có huy hiệu signature + chấm cấp; đầu trang đếm số chi nhánh đã mở', (tester) async {
      final seed = _rich(stage: 6)
        ..branchLevels['saigon'] = 3
        ..branchSince['saigon'] = _t0;
      final c = await open(tester, seed);
      expect(find.byKey(const Key('branch-sig-saigon')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('branch-sig-saigon')), matching: find.text('☕')), findsOneWidget);
      expect(find.byKey(const Key('branch-pips-saigon')), findsOneWidget);
      expect(find.text('Đã mở 1/17 chi nhánh'), findsOneWidget);
      await end(tester, c);
    });

    testWidgets('nút Thu về mờ khi chưa có gì; có doanh thu thì bấm được', (tester) async {
      final seed = _rich(stage: 6)
        ..branchLevels['saigon'] = 5
        ..branchSince['saigon'] = _t0;
      final c = await open(tester, seed);
      expect(tester.widget<FilledButton>(find.byKey(const Key('branch-collect'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('branch-collect')));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('branch-collect'))).onPressed, isNull);
      await end(tester, c);
    });

    testWidgets('chưa mở chi nhánh nào: nút Thu về mờ', (tester) async {
      final c = await open(tester, _rich(stage: 2));
      expect(tester.widget<FilledButton>(find.byKey(const Key('branch-collect'))).onPressed, isNull);
      await end(tester, c);
    });

    for (final lang in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
      testWidgets('không tràn ở 320px, chữ 1.5×, số khổng lồ ($lang)', (tester) async {
        final id = Balance.generators.first.id;
        final seed = GameState.newGame(nowMillis: _t0)
          ..tutorialSeen = true
          ..stage = 18
          ..money = 1e70
          ..levels[id] = 5000;
        for (final c in branchCities) {
          seed.branchLevels[c.id] = 1 + math.Random(c.id.length).nextInt(10);
          seed.branchSince[c.id] = _t0;
        }
        final c = await open(tester, seed, locale: lang, size: const Size(320, 640), scale: 1.5);
        expect(find.byKey(const Key('branch-collect')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: lang);
        expect(find.textContaining(RegExp(r'\{[a-z]+\}')), findsNothing, reason: lang);
        // Cuộn hết danh sách để dựng cả 17 thẻ, không thẻ nào tràn.
        for (var i = 0; i < 14; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pump();
        }
        expect(tester.takeException(), isNull, reason: '$lang (cuộn)');
        await end(tester, c);
      });
    }
  });
}
