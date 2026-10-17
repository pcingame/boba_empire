import 'package:boba_empire/core/format.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/l10n/l10n_ext.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/topup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  _overflowTests();

  testWidgets('câu chữ ráp đúng tham số (gen-l10n sắp tham số theo chữ cái)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * 24 * 60 * 60 * 1000),
    ]);
    container.read(gameControllerProvider.notifier).addVipExp(topupTiers[2].exp); // VIP 3
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showTopupDialog(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // VIP 3: mỗi cấp +2%, hiện +6% (không bị đảo chỗ hai con số).
    expect(find.text('Each VIP level: +2% income (now +6%)'), findsOneWidget);

    // Dòng quyền lợi theo cấp (VIP 1: ngày 10, tuần 70, tháng 300, +2%) — không đảo tham số.
    final perks = find.byKey(const Key('topup-tier-perks-0'), skipOffstage: false);
    expect(tester.widget<Text>(perks).data,
        'Daily +10 💎 · weekly +70 💎 · monthly +300 💎 (with accessory) · +2% income');

    // Hộp Hướng dẫn VIP: 1.00K 💎 đổi 100 EXP, tối đa 20.0K EXP (không đảo cap/gems).
    await tester.tap(find.byKey(const Key('vip-how-to-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('(${formatNumber(vipExpBlockGems.toDouble())} 💎 → $vipExpBlock EXP, up to ${formatNumber(vipExpGemCap.toDouble())} EXP'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('mua EXP liên tiếp: thông báo KHÔNG xếp hàng (chỉ cái mới nhất, hết sau vài giây dù đã thoát màn)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * 24 * 60 * 60 * 1000),
    ]);
    container.read(gameControllerProvider.notifier).grantReferralGems(20000);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(onPressed: () => showTopupDialog(c), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('vip-buy-exp')));
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('vip-buy-exp')));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(SnackBar), findsOneWidget);
    // Thoát màn VIP: thông báo cũ không được còn nối đuôi nhau hiện tiếp.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SnackBar), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  testWidgets('chọn danh hiệu: chỉ hiện từ VIP 5; bấm chip đổi lựa chọn', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * 24 * 60 * 60 * 1000),
    ]);
    final game = container.read(gameControllerProvider.notifier);
    Future<void> open() async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (c) => TextButton(
                onPressed: () => showTopupDialog(c),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    game.addVipExp(topupTiers[3].exp); // VIP 4: chưa đủ cấp 5
    await open();
    expect(find.byKey(const Key('vip-title-auto')), findsNothing);
    await tester.pumpWidget(const SizedBox());

    game.addVipExp(topupTiers[4].exp); // lên VIP 5+
    await open();
    expect(find.byKey(const Key('vip-title-auto')), findsOneWidget);
    expect(find.byKey(const Key('vip-title-5')), findsOneWidget);
    expect(find.byKey(const Key('vip-title-6')), findsNothing); // chưa đạt cấp 6
    await tester.ensureVisible(find.byKey(const Key('vip-title-3')));
    await tester.tap(find.byKey(const Key('vip-title-3')));
    await tester.pump();
    expect(container.read(gameControllerProvider).vipTitleChoice, 3);
    await tester.ensureVisible(find.byKey(const Key('vip-title-0')));
    await tester.tap(find.byKey(const Key('vip-title-0')));
    await tester.pump();
    expect(container.read(gameControllerProvider).vipTitleChoice, 0);
    await tester.ensureVisible(find.byKey(const Key('vip-title-auto')));
    await tester.tap(find.byKey(const Key('vip-title-auto')));
    await tester.pump();
    expect(container.read(gameControllerProvider).vipTitleChoice, -1);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });

  test('banner VIP online: tên người chơi và danh hiệu đúng chỗ', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(vipOnlineText(l10n, nickname: 'Alice', level: 5),
        '👑 Shop Owner Alice just came online!');
    expect(vipOnlineText(lookupAppLocalizations(const Locale('vi')), nickname: 'An', level: 10),
        '👑 Đế vương An vừa online!');
  });

  testWidgets('Mốc nạp: nút Nhận chỉ bật khi đủ điểm, nhận xong hiện Đã nhận',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * 24 * 60 * 60 * 1000),
    ]);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showTopupDialog(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FilledButton claim(int i) =>
        tester.widget<FilledButton>(find.byKey(Key('topup-claim-$i')));
    expect(claim(0).onPressed, isNull); // 0 điểm: chưa đủ

    container.read(gameControllerProvider.notifier).addVipExp(topupTiers[0].exp);
    await tester.pump();
    expect(claim(0).onPressed, isNotNull);
    expect(claim(1).onPressed, isNull);

    await tester.ensureVisible(find.byKey(const Key('topup-claim-0')));
    await tester.tap(find.byKey(const Key('topup-claim-0')));
    await tester.pump();
    expect(find.byKey(const Key('topup-claim-0')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('topup-tier-0')),
            matching: find.text('Claimed')),
        findsOneWidget);
    expect(container.read(gameControllerProvider).gems, topupTiers[0].gems);

    // Mua EXP bằng 💎: thiếu 💎 → nút tắt; đủ → trừ 💎, cộng EXP.
    FilledButton buy() =>
        tester.widget<FilledButton>(find.byKey(const Key('vip-buy-exp')));
    expect(buy().onPressed, isNull);
    container.read(gameControllerProvider.notifier).grantFreeGems();
    await tester.pump();
    // Quà VIP: đã có VIP 1 (500 EXP) → quà ngày nhận được, 1 lần.
    expect(find.byKey(const Key('vip-claim-daily')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('vip-claim-daily')));
    await tester.tap(find.byKey(const Key('vip-claim-daily')));
    await tester.pump();
    expect(find.byKey(const Key('vip-claim-daily')), findsNothing);

    // GameController có Timer.periodic: gỡ cây rồi dispose trước khi test kết thúc.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

/// Màn nhỏ (320px) + ngôn ngữ chữ dài: hộp thoại không được tràn (RenderFlex overflow
/// làm test thất bại), kể cả khi đủ EXP để hiện mọi nút Nhận và EXP rất lớn.
void _overflowCase(String lang) {
  testWidgets('Mốc nạp không tràn ở 320px ($lang)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 100 * 24 * 60 * 60 * 1000),
    ]);
    container.read(gameControllerProvider.notifier).addVipExp(topupTiers.last.exp);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showTopupDialog(c),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    // Hộp "Hướng dẫn VIP" cũng không tràn và đóng được.
    await tester.tap(find.byKey(const Key('vip-how-to-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('vip-how-to-close')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('vip-how-to-close')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('vip-how-to-close')), findsNothing);

    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}

void _overflowTests() {
  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    _overflowCase(lang);
  }
}
