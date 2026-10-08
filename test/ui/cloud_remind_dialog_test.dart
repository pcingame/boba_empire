// Lời nhắc liên kết email trên màn hình chính + hộp thoại.
import 'dart:ui' as ui;

import 'package:boba_empire/core/cloud_remind.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/whats_new.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/cloud_remind_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  required bool linked,
  int opens = 2,
  int count = 0,
  int last = 0,
  String? whatsNewSeen,
  String version = 'no-plugin',
}) async {
  SharedPreferences.setMockInitialValues({
    whatsNewSeenKey: ?whatsNewSeen,
    cloudRemindOpensKey: opens,
    cloudRemindCountKey: count,
    if (last > 0) cloudRemindLastKey: last,
  });
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..tutorialSeen = true,
      nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 100 * 86400000),
    cloudLinkedProvider.overrideWithValue(linked),
    cloudSaveControllerProvider.overrideWith(_FakeCloud.new),
    // Không có plugin trong test: PackageInfo sẽ treo chuỗi popup mở app.
    appVersionProvider.overrideWithValue(
        version == 'no-plugin' ? () async => throw 'no plugin' : () async => version),
  ]);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return c;
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
}

void main() {
  testWidgets('"Có gì mới" đang hiện: lời nhắc nhường chỗ, KHÔNG tốn lượt nhắc',
      (tester) async {
    final c = await _pumpHome(tester,
        linked: false, whatsNewSeen: '0.0.1', version: whatsNewVersion);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new')), findsOneWidget);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    // Đóng "Có gì mới" xong lời nhắc cũng KHÔNG nhảy ra nối tiếp (lần mở này
    // nhường hẳn) và không tốn lượt nhắc.
    await tester.tap(find.text('Để sau')); // nút "Để sau" của hộp thoại Có gì mới
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    expect(c.read(sharedPreferencesProvider).getInt(cloudRemindCountKey), 0);
    await _end(tester, c);
  });

  testWidgets('chưa liên kết + đủ 3 lần mở: hiện lời nhắc', (tester) async {
    final c = await _pumpHome(tester, linked: false);
    expect(find.byKey(const Key('cloud-remind-link')), findsOneWidget);
    expect(find.text('Bảo vệ tiến độ của bạn'), findsOneWidget);
    await _end(tester, c);
  });

  testWidgets('đã liên kết: KHÔNG nhắc', (tester) async {
    final c = await _pumpHome(tester, linked: true);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('mới mở lần 1-2 (người chơi mới): KHÔNG nhắc', (tester) async {
    final c = await _pumpHome(tester, linked: false, opens: 0);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('vừa nhắc hôm qua: chưa nhắc lại', (tester) async {
    final c = await _pumpHome(tester,
        linked: false, opens: 9, count: 1, last: 99 * 86400000);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('đã nhắc đủ 5 lần: thôi hẳn', (tester) async {
    final c = await _pumpHome(tester,
        linked: false, opens: 50, count: 5, last: 1);
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    await _end(tester, c);
  });

  testWidgets('"Để sau" đóng hộp thoại, không mở màn liên kết', (tester) async {
    final c = await _pumpHome(tester, linked: false);
    await tester.tap(find.byKey(const Key('cloud-remind-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    expect(find.text('Đồng bộ đám mây'), findsNothing);
    await _end(tester, c);
  });

  testWidgets('"Liên kết ngay" mở hộp thoại Đồng bộ đám mây', (tester) async {
    final c = await _pumpHome(tester, linked: false);
    await tester.tap(find.byKey(const Key('cloud-remind-link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cloud-remind-link')), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'hộp thoại liên kết');
    await _end(tester, c);
  });

  testWidgets('lần nhắc được ghi nhận: mở lại ngay (cùng prefs) thì không nhắc nữa',
      (tester) async {
    final c = await _pumpHome(tester, linked: false);
    final prefs = c.read(sharedPreferencesProvider);
    expect(prefs.getInt(cloudRemindCountKey), 1);
    expect(prefs.getInt(cloudRemindOpensKey), 3);
    await _end(tester, c);
  });

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] hộp thoại nhắc không tràn trên 320px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        locale: ui.Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
            builder: (ctx) => TextButton(
                onPressed: () => showCloudRemindDialog(ctx),
                child: const Text('open'))),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('cloud-remind-link')), findsOneWidget);
    });
  }
}
