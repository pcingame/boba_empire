// Màn gom mọi bảng xếp hạng: đủ 9 dòng, chưa liên kết → bị cổng chặn, đã liên kết → mở đúng trang; Cài đặt gom mạng xã hội.
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/compete_hub_dialog.dart';
import 'package:boba_empire/ui/leaderboard_page.dart';
import 'package:boba_empire/ui/leaderboards_hub_page.dart';
import 'package:boba_empire/ui/vip_leaderboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Linked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveLinked('a@b.c');
}

class _Unlinked extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

Future<ProviderContainer> _open(WidgetTester tester, {required bool linked, String locale = 'vi', Size size = const Size(400, 900)}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 1000),
    cloudSaveControllerProvider.overrideWith(linked ? _Linked.new : _Unlinked.new),
  ]);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LeaderboardsHubPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('liệt kê đủ 9 bảng', (tester) async {
    final c = await _open(tester, linked: true);
    for (final id in ['income', 'pearls', 'collection', 'recipes', 'vip', 'speedrun', 'arena', 'season', 'branches']) {
      expect(find.byKey(Key('lbh-$id')), findsOneWidget, reason: id);
    }
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('chưa liên kết: mọi dòng bị cổng chặn', (tester) async {
    final c = await _open(tester, linked: false);
    for (final id in ['income', 'vip', 'season']) {
      await tester.tap(find.byKey(Key('lbh-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget, reason: id);
      await tester.tap(find.byKey(const Key('online-gate-cancel')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(LeaderboardPage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đã liên kết: bấm VIP mở trang BXH VIP, không hiện cổng', (tester) async {
    final c = await _open(tester, linked: true);
    await tester.tap(find.byKey(const Key('lbh-vip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
    expect(find.byType(VipLeaderboardPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final loc in ['vi', 'en', 'es', 'id', 'ko', 'pt', 'th']) {
    testWidgets('[$loc] 320px chữ to: không tràn', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await _open(tester, linked: true, locale: loc, size: const Size(320, 700));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  testWidgets('hub Thi đấu: một mục Bảng xếp hạng mở màn gom', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      cloudSaveControllerProvider.overrideWith(_Linked.new),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Builder(builder: (ctx) => TextButton(onPressed: () => showCompeteHub(ctx), child: const Text('open')))),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('compete-leaderboards')));
    await tester.pumpAndSettle();
    expect(find.byType(LeaderboardsHubPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
