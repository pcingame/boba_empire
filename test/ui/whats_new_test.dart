/// Hộp "Có gì mới": chỉ hiện đúng một lần cho người vừa cập nhật lên 1.0.8;
/// cài mới và bản khác không hiện.
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/whats_new.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/home_page.dart' show debugAutoShowStory, debugAutoShowTutorial;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, SharedPreferences)> _launch(
  WidgetTester tester, {
  required String version,
  String? seen,
  bool hasSave = true,
}) async {
  SharedPreferences.setMockInitialValues({
    whatsNewSeenKey: ?seen,
  });
  final prefs = await SharedPreferences.getInstance();
  if (hasSave) {
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
  }
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
    appVersionProvider.overrideWithValue(() async => version),
  ]);
  await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
  await tester.pumpAndSettle();
  return (c, prefs);
}

void main() {
  group('shouldShowWhatsNew', () {
    test('cập nhật từ bản có ghi nhận / chưa ghi nhận nhưng có save → hiện', () {
      expect(shouldShowWhatsNew(seen: '1.0.5', current: '1.0.8', hasSave: true),
          isTrue);
      expect(shouldShowWhatsNew(seen: null, current: '1.0.8', hasSave: true),
          isTrue);
    });
    test('cài mới (không save), đã xem, hoặc bản khác → không hiện', () {
      expect(shouldShowWhatsNew(seen: null, current: '1.0.8', hasSave: false),
          isFalse);
      expect(shouldShowWhatsNew(seen: '1.0.8', current: '1.0.8', hasSave: true),
          isFalse);
      expect(shouldShowWhatsNew(seen: '1.0.8', current: '1.0.8', hasSave: true),
          isFalse);
    });
  });

  testWidgets('vừa cập nhật lên 1.0.8: hiện hộp, ghi nhớ, mở bộ sưu tập từ nút',
      (tester) async {
    final (c, prefs) = await _launch(tester, version: '1.0.8', seen: '1.0.5');
    expect(find.byKey(const Key('whats-new')), findsOneWidget);
    expect(prefs.getString(whatsNewSeenKey), '1.0.8');
    await tester.tap(find.byKey(const Key('whats-new-open')));
    await tester.pumpAndSettle();
    expect(find.byType(AccessoryInventoryPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('người dùng bản 1.0.5 chưa từng ghi nhận (seen=null, có save) → hiện',
      (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.8');
    expect(find.byKey(const Key('whats-new')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đã xem 1.0.8 rồi → không hiện lại', (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.8', seen: '1.0.8');
    expect(find.byKey(const Key('whats-new')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('cài mới (chưa có save): không hiện, nhưng vẫn ghi nhớ phiên bản',
      (tester) async {
    final (c, prefs) = await _launch(tester, version: '1.0.8', hasSave: false);
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(prefs.getString(whatsNewSeenKey), '1.0.8');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('bản khác 1.0.8 (chưa có nội dung): không hiện', (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.8', seen: '1.0.8');
    expect(find.byKey(const Key('whats-new')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('không lấy được phiên bản (nền tảng lỗi): không crash, không hiện',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(GameState.newGame(nowMillis: 0), nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      appVersionProvider.overrideWithValue(() async => throw 'no plugin'),
    ]);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('cài mới: hướng dẫn lần đầu hiện, đóng xong KHÔNG hiện "Có gì mới" (dù tutorial đã lưu ván)',
      (tester) async {
    final savedTutorial = debugAutoShowTutorial;
    debugAutoShowTutorial = true;
    addTearDown(() => debugAutoShowTutorial = savedTutorial);
    final (c, prefs) = await _launch(tester, version: '1.0.8', hasSave: false);
    expect(find.byKey(const Key('how-to-play-close')), findsOneWidget,
        reason: 'người mới thấy hướng dẫn');
    expect(find.byKey(const Key('whats-new')), findsNothing);
    await tester.tap(find.byKey(const Key('how-to-play-close')));
    await tester.pumpAndSettle();
    // markTutorialSeen() đã lưu ván → trước bản sửa, đây bị nhầm là "người vừa cập nhật".
    expect(prefs.containsKey(GameStorage.saveKey), isTrue);
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(prefs.getString(whatsNewSeenKey), '1.0.8');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đang chờ cutscene cốt truyện: nhường cutscene, CHƯA ghi nhớ → lần mở sau mới hiện',
      (tester) async {
    debugAutoShowStory = true;
    addTearDown(() => debugAutoShowStory = false);
    SharedPreferences.setMockInitialValues({whatsNewSeenKey: '1.0.5'});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..storyChapter = 5
          ..stage = 5,
        nowMillis: 0);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
      appVersionProvider.overrideWithValue(() async => '1.0.8'),
    ]);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('story-choice-0')), findsOneWidget);
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(prefs.getString(whatsNewSeenKey), '1.0.5',
        reason: 'chưa hiện thì chưa ghi nhớ');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
