// Trang Quyền lợi VIP + Thống kê của tôi (thẻ + chia sẻ ảnh/chữ), không tràn 320px / chữ 1.5× / 7 ngôn ngữ.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/stats.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/collection_share_dialog.dart' show shareImageProvider;
import 'package:boba_empire/ui/stats_dialog.dart';
import 'package:boba_empire/ui/vip_perks_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _day = 24 * 3600 * 1000;

Future<ProviderContainer> _open(WidgetTester tester, void Function(BuildContext) show,
    {String lang = 'vi', double scale = 1, Size size = const Size(400, 900), int vipExp = 3000, Future<void> Function(Uint8List, String, Rect?, String)? share}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 5 * _day)
        ..tutorialSeen = true
        ..vipExp = vipExp
        ..tapCount = 12345
        ..buyCount = 678
        ..lifetimeEarnings = 4.5e12
        ..ascensionCount = 2
        ..storyChapter = 30
        ..recipeStreakBest = 9
        ..ownedAccessories.addAll(['dragon'])
        ..firstPlayedMillis = 2 * _day,
      nowMillis: 5 * _day);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 5 * _day),
    if (share != null) shareImageProvider.overrideWithValue(share),
  ]);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(lang),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: Builder(builder: (ctx) => Scaffold(body: TextButton(onPressed: () => show(ctx), child: const Text('go')))),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  test('PlayerStats: ngày chơi tính từ ngày đầu, cấp VIP, phụ kiện, số hữu hạn', () {
    final s = GameState.newGame(nowMillis: 5 * _day)
      ..firstPlayedMillis = 2 * _day
      ..vipExp = 3000
      ..ownedAccessories.add('dragon')
      ..ownedLimited.add('vip_watch')
      ..lifetimeEarnings = double.infinity;
    final st = PlayerStats.from(s, 5 * _day);
    expect(st.daysPlayed, 4);
    expect(st.vipLevel, 3);
    expect(st.items, 2);
    expect(st.lifetime, 0);
    expect(PlayerStats.from(s..firstPlayedMillis = 0, 5 * _day).daysPlayed, 1);
  });

  testWidgets('Quyền lợi VIP: cấp hiện tại được đánh dấu, báo EXP còn thiếu, đủ 10 hàng', (tester) async {
    final c = await _open(tester, showVipPerks);
    // 3000 EXP = VIP 3; cấp kế cần 4800 → còn 1,8K.
    expect(find.byKey(const Key('vip-perks-next')), findsOneWidget);
    expect(find.textContaining('1.8'), findsWidgets);
    for (var l = 1; l <= topupTiers.length; l++) {
      await tester.scrollUntilVisible(find.byKey(Key('vip-perks-row-$l')), 100, scrollable: find.byType(Scrollable).last);
      expect(find.byKey(Key('vip-perks-row-$l')), findsOneWidget);
    }
    await _close(tester, c);
  });

  testWidgets('Quyền lợi VIP: cấp tối đa không còn dòng "còn thiếu"', (tester) async {
    final c = await _open(tester, showVipPerks, vipExp: 999999);
    expect(find.textContaining('👑'), findsOneWidget);
    await _close(tester, c);
  });

  testWidgets('Thống kê: hiện số liệu, chia sẻ ảnh PNG + chữ, chép chữ', (tester) async {
    Uint8List? png;
    String? caption;
    String? name;
    final c = await _open(tester, showStats, share: (bytes, text, origin, fileName) async {
      png = bytes;
      caption = text;
      name = fileName;
    });
    expect(find.text('4'), findsWidgets); // ngày chơi = 4
    expect(find.text('12.35K'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(Icons.ios_share).last);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(caption, contains('4 ngày'));
    expect(name, 'boba_stats.png');
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clip = (call.arguments as Map)['text'] as String;
      return null;
    });
    await tester.tap(find.byKey(const Key('stats-copy')));
    await tester.pump();
    expect(clip, contains('4 ngày'));
    await _close(tester, c);
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px, chữ 1.5× ($lang)', (tester) async {
      const size = Size(320, 640);
      var c = await _open(tester, showVipPerks, lang: lang, scale: 1.5, size: size);
      for (var l = 1; l <= topupTiers.length; l += 3) {
        await tester.scrollUntilVisible(find.byKey(Key('vip-perks-row-$l')), 100, scrollable: find.byType(Scrollable).last);
      }
      expect(tester.takeException(), isNull);
      await _close(tester, c);
      c = await _open(tester, showStats, lang: lang, scale: 1.5, size: size);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  }
}
