/// Thẻ "Bộ trang bị" trong Kho phụ kiện: hiện buff + combo, xác nhận khi tháo, khoá đổi 30 phút,
/// mở khoá bằng QC / thẳng khi đã gỡ QC, và không tràn ở máy nhỏ + chữ to với thẻ đã đầy.
library;

import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/accessory_loadout.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/l10n/app_localizations_vi.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ads implements AdService {
  _Ads(this.outcome);
  final RewardOutcome outcome;
  int shown = 0;
  @override
  Future<RewardOutcome> showRewardedAd() async {
    shown++;
    return outcome;
  }
}

String _id(AccessoryFamily f, AccessoryRarity r, [int skip = 0]) => accessories
    .where((a) => a.rarity == r && accessoryFamilyOf(a.id) == f)
    .elementAt(skip)
    .id;

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<String> owned = const [],
  List<String> equipped = const [],
  int lockUntil = 0,
  bool adsRemoved = false,
  _Ads? ads,
  Locale locale = const Locale('vi'),
  Size size = const Size(400, 12800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final seed = GameState.newGame(nowMillis: 0)
    ..ownedAccessories.addAll(owned)
    ..equippedAccessories.addAll(equipped)
    ..equipLockUntilMillis = lockUntil
    ..adsRemoved = adsRemoved;
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000000),
    adServiceProvider.overrideWithValue(ads ?? _Ads(RewardOutcome.earned)),
  ]);
  // Tự dispose cuối mỗi test (GameController có Timer định kỳ — xem accessory_market_page_test).
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AccessoryInventoryPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

Finder _cell(String id) => find.byKey(Key('accessory-cell-$id'));

Future<void> _tapCell(WidgetTester tester, String id) async {
  await tester.ensureVisible(_cell(id));
  await tester.pumpAndSettle();
  await tester.tap(_cell(id));
  await tester.pumpAndSettle();
}

void main() {
  final tap1 = _id(AccessoryFamily.tap, AccessoryRarity.epic);
  final tap2 = _id(AccessoryFamily.tap, AccessoryRarity.rare);
  final inc1 = _id(AccessoryFamily.income, AccessoryRarity.rare);

  testWidgets('chưa mang gì: thẻ hiện 3 ô trống + gợi ý, không có dòng buff', (tester) async {
    final c = await _pump(tester, owned: [tap1]);
    expect(find.byKey(const Key('loadout-card')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(Key('loadout-slot-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('loadout-slot-3')), findsNothing);
    expect(find.text(AppLocalizationsVi().loadoutEmpty), findsOneWidget);
    expect(find.byKey(const Key('loadout-lock-note')), findsNothing);
    c.dispose();
  });

  testWidgets('VIP có thêm ô thứ 4', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..vipUntilMillis = 1000000 + 86400000, nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 1000000),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccessoryInventoryPage(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loadout-slot-3')), findsOneWidget);
    c.dispose();
  });

  testWidgets('chạm món để mang: dòng buff hiện đúng %, hai món cùng họ có combo ×1.1',
      (tester) async {
    final c = await _pump(tester, owned: [tap1, tap2, inc1]);
    await _tapCell(tester, tap1); // epic = 5 điểm → +10% chạm
    expect(find.text(AppLocalizationsVi().loadoutBuffTap('10')), findsOneWidget);

    await _tapCell(tester, tap2); // + rare 2.5 → 7.5 điểm × 1.1 = 16.5%
    expect(find.text('${AppLocalizationsVi().loadoutBuffTap('16.5')}${AppLocalizationsVi().loadoutComboSuffix('1.1')}'),
        findsOneWidget);

    await _tapCell(tester, inc1); // họ khác: dòng buff riêng, không combo
    expect(find.byKey(const Key('loadout-buff-income')), findsOneWidget);
    expect(find.text(AppLocalizationsVi().loadoutBuffIncome('2.5')), findsOneWidget);
    c.dispose();
  });

  testWidgets('mỗi ô đã có hiện biểu tượng họ; ô chưa có thì không', (tester) async {
    final c = await _pump(tester, owned: [tap1]);
    expect(find.byKey(Key('accessory-family-$tap1')), findsOneWidget);
    expect(find.byKey(Key('accessory-family-$inc1')), findsNothing);
    c.dispose();
  });

  testWidgets('chạm món đang mang: hỏi xác nhận; Huỷ thì giữ nguyên và không khoá', (tester) async {
    final c = await _pump(tester, owned: [tap1], equipped: [tap1]);
    await _tapCell(tester, tap1);
    expect(find.byKey(const Key('loadout-remove-confirm')), findsOneWidget);
    await tester.tap(find.text(AppLocalizationsVi().cancel));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).equippedAccessories, [tap1]);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
    c.dispose();
  });

  testWidgets('xác nhận tháo: món gỡ ra, hiện dòng khoá, bỏ dòng buff', (tester) async {
    final c = await _pump(tester, owned: [tap1], equipped: [tap1]);
    await _tapCell(tester, tap1);
    await tester.tap(find.byKey(const Key('loadout-remove-confirm')));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).equippedAccessories, isEmpty);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 1000000 + 30 * 60000);
    expect(find.byKey(const Key('loadout-lock-note')), findsOneWidget);
    expect(find.text(AppLocalizationsVi().loadoutLockNote(30)), findsOneWidget);
    expect(find.byKey(const Key('loadout-buff-tap')), findsNothing);
    c.dispose();
  });

  testWidgets('đang khoá: chạm món đang mang mở hộp mở khoá, KHÔNG tháo', (tester) async {
    final c = await _pump(tester,
        owned: [tap1, tap2], equipped: [tap1, tap2], lockUntil: 1000000 + 10 * 60000);
    expect(find.text(AppLocalizationsVi().loadoutLockNote(10)), findsOneWidget);
    await _tapCell(tester, tap1);
    expect(find.text(AppLocalizationsVi().loadoutLockedTitle), findsOneWidget);
    expect(find.byKey(const Key('loadout-remove-confirm')), findsNothing);
    await tester.tap(find.text(AppLocalizationsVi().close));
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).equippedAccessories, [tap1, tap2]);
    c.dispose();
  });

  testWidgets('mở khoá bằng QC: xem xong thì khoá về 0', (tester) async {
    final ads = _Ads(RewardOutcome.earned);
    final c = await _pump(tester,
        owned: [tap1], equipped: [tap1], lockUntil: 1000000 + 10 * 60000, ads: ads);
    await _tapCell(tester, tap1);
    await tester.tap(find.byKey(const Key('loadout-unlock-button')));
    await tester.pumpAndSettle();
    expect(ads.shown, 1);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
    expect(find.byKey(const Key('loadout-lock-note')), findsNothing);
    c.dispose();
  });

  testWidgets('QC bị đóng sớm: vẫn khoá', (tester) async {
    final ads = _Ads(RewardOutcome.dismissed);
    final c = await _pump(tester,
        owned: [tap1], equipped: [tap1], lockUntil: 1000000 + 10 * 60000, ads: ads);
    await _tapCell(tester, tap1);
    await tester.tap(find.byKey(const Key('loadout-unlock-button')));
    await tester.pumpAndSettle();
    expect(ads.shown, 1);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 1000000 + 10 * 60000);
    c.dispose();
  });

  testWidgets('đã gỡ quảng cáo: mở khoá thẳng, không gọi QC', (tester) async {
    final ads = _Ads(RewardOutcome.earned);
    final c = await _pump(tester,
        owned: [tap1],
        equipped: [tap1],
        lockUntil: 1000000 + 10 * 60000,
        adsRemoved: true,
        ads: ads);
    await _tapCell(tester, tap1);
    expect(find.text(AppLocalizationsVi().loadoutUnlockFree), findsOneWidget);
    await tester.tap(find.byKey(const Key('loadout-unlock-button')));
    await tester.pumpAndSettle();
    expect(ads.shown, 0);
    expect(c.read(gameControllerProvider).equipLockUntilMillis, 0);
    c.dispose();
  });

  testWidgets('lấp ô trống khi đang khoá vẫn được (nửa sau của một lần thay)', (tester) async {
    final c = await _pump(tester,
        owned: [tap1, inc1], equipped: [tap1], lockUntil: 1000000 + 10 * 60000);
    await _tapCell(tester, inc1);
    expect(c.read(gameControllerProvider).equippedAccessories, [tap1, inc1]);
    c.dispose();
  });

  testWidgets('hết ô: báo đầy, không đổi gì', (tester) async {
    final others = [
      _id(AccessoryFamily.tap, AccessoryRarity.common),
      _id(AccessoryFamily.income, AccessoryRarity.common),
      _id(AccessoryFamily.offline, AccessoryRarity.common),
    ];
    final extra = _id(AccessoryFamily.tap, AccessoryRarity.common, 1);
    final c = await _pump(tester, owned: [...others, extra], equipped: others);
    await _tapCell(tester, extra);
    expect(c.read(gameControllerProvider).equippedAccessories, others);
    expect(find.text(AppLocalizationsVi().accessoryEquipFull(3)), findsOneWidget);
    c.dispose();
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('thẻ đã đầy + đang khoá không tràn ở ${locale.languageCode}, 320px, chữ x1.6',
        (tester) async {
      final owned = [
        _id(AccessoryFamily.tap, AccessoryRarity.legendary),
        _id(AccessoryFamily.tap, AccessoryRarity.legendary, 1),
        _id(AccessoryFamily.income, AccessoryRarity.epic),
        _id(AccessoryFamily.offline, AccessoryRarity.rare),
      ];
      final c = await _pump(tester,
          owned: owned,
          equipped: owned,
          lockUntil: 1000000 + 20 * 60000,
          locale: locale,
          size: const Size(320, 640),
          textScale: 1.6);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('loadout-card')), findsOneWidget);
      c.dispose();
    });
  }
}
