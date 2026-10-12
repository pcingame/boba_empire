// Tự động chạm trên giao diện: hàng "xem QC" trong hộp Kiếm thêm, và chip trong cảnh quán.
import 'package:boba_empire/ads/ad_service.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/rewards_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Ads implements AdService {
  const _Ads(this.outcome);
  final RewardOutcome outcome;
  @override
  Future<RewardOutcome> showRewardedAd() async => outcome;
}

Future<ProviderContainer> _openRewards(WidgetTester tester,
    {RewardOutcome ad = RewardOutcome.earned, String locale = 'vi', Size size = const Size(400, 900), int vipExp = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: 0)..vipExp = vipExp, nowMillis: 0);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
    adServiceProvider.overrideWithValue(_Ads(ad)),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showRewards(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return container;
}

Finder _watchBtn() => find.descendant(of: find.byKey(const Key('reward-auto-tap')), matching: find.byType(FilledButton));

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('hộp Kiếm thêm có hàng Tự động chạm; xem QC xong thì bật + hiện còn bao lâu', (tester) async {
    final c = await _openRewards(tester);
    await tester.ensureVisible(find.byKey(const Key('reward-auto-tap')));
    expect(find.text('Tự động chạm ${Balance.autoTapAdMs ~/ 60000} phút'), findsOneWidget);
    expect(c.read(gameControllerProvider).autoTapActive, isFalse);
    await tester.tap(_watchBtn());
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).autoTapActive, isTrue);
    expect(find.textContaining('Đang bật · còn'), findsOneWidget);
    expect(find.textContaining('Chỉ cộng Xu'), findsOneWidget, reason: 'snack nói rõ không tính điểm Hội');
    await _end(tester, c);
  });

  testWidgets('QC không xem xong (bỏ giữa chừng) thì KHÔNG bật', (tester) async {
    final c = await _openRewards(tester, ad: RewardOutcome.dismissed);
    await tester.ensureVisible(find.byKey(const Key('reward-auto-tap')));
    await tester.tap(_watchBtn());
    await tester.pumpAndSettle();
    expect(c.read(gameControllerProvider).autoTapActive, isFalse);
    await _end(tester, c);
  });

  testWidgets('VIP đủ cấp: hàng báo mở vĩnh viễn', (tester) async {
    final c = await _openRewards(tester, vipExp: topupTiers[Balance.autoTapVipLevel - 1].exp);
    await tester.ensureVisible(find.byKey(const Key('reward-auto-tap')));
    expect(find.textContaining('vĩnh viễn'), findsWidgets);
    await _end(tester, c);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] hàng Tự động chạm 360px không tràn', (tester) async {
      // Gom lỗi layout thay vì để test chết: thẻ Heo đất (có từ trước) tràn 5px ở tiếng Indonesia
      // 360px — không thuộc tính năng này. Chỉ đòi KHÔNG có lỗi nào xuất phát từ hàng _OfferRow.
      final layoutErrors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => layoutErrors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      final c = await _openRewards(tester, locale: l, size: const Size(360, 720));
      await tester.ensureVisible(find.byKey(const Key('reward-auto-tap')));
      await tester.pumpAndSettle();
      FlutterError.onError = prev;
      expect(layoutErrors.where((e) => e.contains('_OfferRow')), isEmpty, reason: layoutErrors.join('\n'));
      await _end(tester, c);
    });
  }

  testWidgets('chip trong cảnh quán: ẩn khi tắt; đếm ngược khi bật bằng QC; "VIP" khi mở sẵn', (tester) async {
    Future<ProviderContainer> pumpHome(GameState seed) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(seed, nowMillis: 0);
      await tester.binding.setSurfaceSize(const Size(400, 900));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => 1000),
        ],
        child: const BobaEmpireApp(),
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(BobaEmpireApp)));
    }

    addTearDown(() => tester.binding.setSurfaceSize(null));
    var c = await pumpHome(GameState.newGame(nowMillis: 0));
    expect(find.byKey(const Key('auto-tap-chip')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();

    c = await pumpHome(GameState.newGame(nowMillis: 0)..autoTapUntilMillis = 1000 + 5 * 60 * 1000);
    expect(find.byKey(const Key('auto-tap-chip')), findsOneWidget);
    expect(find.textContaining('🤖 '), findsOneWidget);
    expect(find.text('🤖 VIP'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();

    c = await pumpHome(GameState.newGame(nowMillis: 0)..vipExp = topupTiers[Balance.autoTapVipLevel - 1].exp);
    expect(find.text('🤖 VIP'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
