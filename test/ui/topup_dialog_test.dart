import 'package:boba_empire/core/topup.dart';
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
