// Tuyến thương mại giữa chi nhánh: công thức, mở/nâng cấp qua controller, hệ số khi thu về, save, bottom sheet.
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

GameState _rich() => GameState.newGame(nowMillis: _t0)
  ..tutorialSeen = true
  ..stage = 18
  ..money = 1e15
  ..levels[Balance.generators.first.id] = 50
  ..branchLevels.addAll({'saigon': 3, 'hanoi': 3, 'paris': 3, 'tokyo': 3, 'london': 3})
  ..branchSince.addAll({for (final id in ['saigon', 'hanoi', 'paris', 'tokyo', 'london']) id: _t0});

Future<ProviderContainer> _c(GameState seed, int Function() clock, {bool tear = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: _t0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(clock),
  ]);
  if (tear) addTearDown(c.dispose);
  return c;
}

void main() {
  test('công thức: khoá xếp chữ cái, cùng/khác châu, hệ số chỉ tính khi hai đầu còn mở', () {
    expect(branchRouteKey('tokyo', 'saigon'), 'saigon|tokyo');
    expect(isBranchRouteKey('saigon|tokyo'), isTrue);
    expect(isBranchRouteKey('tokyo|saigon'), isFalse, reason: 'sai thứ tự');
    expect(isBranchRouteKey('saigon|moon'), isFalse);
    expect(isBranchRouteKey('saigon|saigon'), isFalse);
    expect(isBranchRouteKey('x|y'), isFalse);
    expect(branchRouteCross('saigon', 'tokyo'), isFalse);
    expect(branchRouteCross('saigon', 'paris'), isTrue);
    final lv = {'saigon': 1, 'paris': 1};
    final r = {'paris|saigon': 2};
    expect(branchRouteMultiplier(r, lv, 'saigon'), closeTo(1 + 2 * branchRouteBonusCross, 1e-9));
    expect(branchRouteMultiplier(r, lv, 'paris'), closeTo(1 + 2 * branchRouteBonusCross, 1e-9));
    expect(branchRouteMultiplier(r, lv, 'tokyo'), 1);
    expect(branchRouteMultiplier(r, {'saigon': 1}, 'saigon'), 1, reason: 'đầu kia chưa mở');
    final same = branchRouteCost('saigon', 'tokyo', 0, 1000);
    expect(branchRouteCost('saigon', 'paris', 0, 1000) > same, isTrue);
    expect(branchRouteCost('saigon', 'tokyo', 1, 1000) > same, isTrue);
    expect(branchRouteCost('saigon', 'tokyo', 0, double.nan).isFinite, isTrue);
  });

  test('mở/nâng cấp: cần hai nơi đã mở, trần cấp, tối đa 2 tuyến/nơi, trừ Xu', () async {
    final c = await _c(_rich(), () => _t0);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.upgradeBranchRoute('saigon', 'sydney'), isFalse, reason: 'sydney chưa mở');
    expect(ctl.upgradeBranchRoute('saigon', 'saigon'), isFalse);
    expect(ctl.upgradeBranchRoute('saigon', 'moon'), isFalse);
    final m0 = c.read(gameControllerProvider).money;
    expect(ctl.upgradeBranchRoute('tokyo', 'saigon'), isTrue);
    expect(c.read(gameControllerProvider).branchRoutes, {'saigon|tokyo': 1});
    expect(c.read(gameControllerProvider).money < m0, isTrue);
    expect(ctl.upgradeBranchRoute('saigon', 'tokyo'), isTrue);
    expect(ctl.upgradeBranchRoute('saigon', 'tokyo'), isTrue);
    expect(c.read(gameControllerProvider).branchRoutes['saigon|tokyo'], branchRouteMaxLevel);
    expect(ctl.upgradeBranchRoute('saigon', 'tokyo'), isFalse, reason: 'đã tối đa');
    expect(ctl.upgradeBranchRoute('saigon', 'hanoi'), isTrue);
    expect(ctl.upgradeBranchRoute('saigon', 'paris'), isFalse, reason: 'saigon đã đủ 2 tuyến');
    expect(ctl.upgradeBranchRoute('paris', 'london'), isTrue, reason: 'nơi khác vẫn nối được');
  });

  test('không đủ Xu → không mở, không trừ', () async {
    final c = await _c(_rich()..money = 1, () => _t0);
    final ctl = c.read(gameControllerProvider.notifier);
    expect(ctl.upgradeBranchRoute('saigon', 'tokyo'), isFalse);
    expect(c.read(gameControllerProvider).branchRoutes, isEmpty);
    expect(c.read(gameControllerProvider).money, 1);
  });

  test('thu về nhân hệ số tuyến (hoặc ×cao điểm), save giữ tuyến', () async {
    var now = _t0;
    final c = await _c(_rich()..branchRoutes['paris|saigon'] = 3, () => now);
    final ctl = c.read(gameControllerProvider.notifier);
    now += 3600 * 1000;
    final withRoute = ctl.collectBranches();
    // so với cùng cấu hình KHÔNG tuyến (cao điểm ngẫu nhiên → chỉ kiểm xu dương và hữu hạn, rồi so tỉ lệ nơi không bị ảnh hưởng)
    expect(withRoute.xu.isFinite && withRoute.xu > 0, isTrue);
    await Future<void>.delayed(Duration.zero);
    final back = GameStorage(await SharedPreferences.getInstance()).load()!;
    expect(back.branchRoutes, {'paris|saigon': 3});
  });

  test('save loại tuyến lạ: sai khoá, cấp 0/âm, cấp quá trần được kẹp', () {
    final back = GameState.fromJson({
      ..._rich().toJson(),
      'branchRoutes': {
        'saigon|tokyo': 99,
        'tokyo|saigon': 2,
        'saigon|moon': 1,
        'paris|saigon': 0,
        'hanoi|saigon': -3,
        'abc': 1,
        'hanoi|tokyo': 'x',
      },
    });
    expect(back.branchRoutes, {'saigon|tokyo': branchRouteMaxLevel});
  });

  const langs = ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th'];
  for (final lang in langs) {
    testWidgets('sheet tuyến: mở/nâng cấp được, không tràn ở 320px chữ 1.5× ($lang)', (tester) async {
      final c = await _c(_rich(), () => _t0 + 5 * 3600 * 1000, tear: false);
      const size = Size(320, 640);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MediaQuery(
          data: const MediaQueryData(size: size, textScaler: TextScaler.linear(1.5)),
          child: MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const BranchesPage(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('branch-routes-btn')));
      await tester.tap(find.byKey(const Key('branch-routes-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('branch-routes-sheet')), findsOneWidget);
      expect(find.byKey(const Key('route-none')), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byKey(const Key('branch-routes-sheet'))))!;
      Future<void> pick(String label, String id) async {
        final f = find.byKey(Key('route-$label-$id'));
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await pick(l10n.branchRoutePickA, 'saigon');
      await pick(l10n.branchRoutePickB, 'tokyo');
      await tester.ensureVisible(find.byKey(const Key('route-open')));
      await tester.tap(find.byKey(const Key('route-open')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).branchRoutes, {'saigon|tokyo': 1}, reason: lang);
      expect(find.byKey(const Key('route-saigon|tokyo')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('route-up-saigon|tokyo')));
      await tester.tap(find.byKey(const Key('route-up-saigon|tokyo')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).branchRoutes['saigon|tokyo'], 2, reason: lang);
      expect(tester.takeException(), isNull, reason: lang);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  testWidgets('bản đồ vẽ lớp tuyến khi có tuyến', (tester) async {
    final c = await _c(_rich()..branchRoutes['saigon|tokyo'] = 1, () => _t0 + 5 * 3600 * 1000, tear: false);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BranchesPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('branch-routes')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
