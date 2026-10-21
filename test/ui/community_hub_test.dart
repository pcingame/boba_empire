// Hộp Cộng đồng gộp Hội + Bạn bè; Thành tựu là tab của hộp Nhiệm vụ & Quà.
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/community_hub_dialog.dart';
import 'package:boba_empire/ui/daily_hub_dialog.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Cloud extends CloudSaveController {
  _Cloud(this._linked);
  final bool _linked;
  @override
  CloudSaveViewState build() => _linked ? const CloudSaveLinked('a@b.c') : const CloudSaveUnlinked();
}

Future<void> _open(WidgetTester tester, {required bool linked}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ProviderScope(
    overrides: [cloudSaveControllerProvider.overrideWith(() => _Cloud(linked))],
    child: MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) =>
            TextButton(key: const Key('open'), onPressed: () => showCommunityHub(context), child: const Text('x')),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('có đủ Hội và Bạn bè', (tester) async {
    await _open(tester, linked: false);
    expect(find.byKey(const Key('community-guild')), findsOneWidget);
    expect(find.byKey(const Key('community-friends')), findsOneWidget);
  });

  testWidgets('chưa liên kết email: Hội và Bạn bè đều bị chặn bởi cổng', (tester) async {
    for (final key in ['community-guild', 'community-friends']) {
      await _open(tester, linked: false);
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('online-gate-dialog')), findsOneWidget, reason: key);
      expect(find.byType(GuildPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('đã liên kết: bấm Hội mở trang Hội, không hiện cổng', (tester) async {
    await _open(tester, linked: true);
    await tester.tap(find.byKey(const Key('community-guild')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('online-gate-dialog')), findsNothing);
    expect(find.byType(GuildPage), findsOneWidget);
  });

  testWidgets('tab Thành tựu trong hộp Nhiệm vụ & Quà: có danh sách và xoá chấm đỏ thành tựu mới', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DailyHubDialog(initialTab: DailyHubTab.achievements)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hub-tab-achievements')), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(c.read(gameControllerProvider).newAchievements, isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose(); // phải gỡ trước khi test kết thúc: bộ đếm nhịp của game còn Timer
  });
}
