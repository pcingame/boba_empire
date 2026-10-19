/// Hộp "Có gì mới": chỉ hiện đúng một lần cho người vừa cập nhật lên 1.0.12;
/// cài mới và bản khác không hiện.
library;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/whats_new.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/whats_new_dialog.dart';
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
      expect(shouldShowWhatsNew(seen: '1.0.5', current: '1.0.12', hasSave: true),
          isTrue);
      expect(shouldShowWhatsNew(seen: null, current: '1.0.12', hasSave: true),
          isTrue);
    });
    test('cài mới (không save), đã xem, hoặc bản khác → không hiện', () {
      expect(shouldShowWhatsNew(seen: null, current: '1.0.12', hasSave: false),
          isFalse);
      expect(shouldShowWhatsNew(seen: '1.0.12', current: '1.0.12', hasSave: true),
          isFalse);
      expect(shouldShowWhatsNew(seen: '1.0.12', current: '1.0.12', hasSave: true),
          isFalse);
    });
  });

  testWidgets('vừa cập nhật lên 1.0.12: hiện hộp, ghi nhớ, mở hộp Trò chơi từ nút',
      (tester) async {
    final (c, prefs) = await _launch(tester, version: '1.0.12', seen: '1.0.5');
    expect(find.byKey(const Key('whats-new')), findsOneWidget);
    expect(prefs.getString(whatsNewSeenKey), '1.0.12');
    await tester.tap(find.byKey(const Key('whats-new-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('games-orders')), findsOneWidget, reason: 'nút "Chơi thử" mở hộp Trò chơi');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('người dùng bản 1.0.5 chưa từng ghi nhận (seen=null, có save) → hiện',
      (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.12');
    expect(find.byKey(const Key('whats-new')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('đã xem 1.0.12 rồi → không hiện lại', (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.12', seen: '1.0.12');
    expect(find.byKey(const Key('whats-new')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('cài mới (chưa có save): không hiện, nhưng vẫn ghi nhớ phiên bản',
      (tester) async {
    final (c, prefs) = await _launch(tester, version: '1.0.12', hasSave: false);
    expect(find.byKey(const Key('whats-new')), findsNothing);
    expect(prefs.getString(whatsNewSeenKey), '1.0.12');
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('bản khác 1.0.12 (chưa có nội dung): không hiện', (tester) async {
    final (c, _) = await _launch(tester, version: '1.0.12', seen: '1.0.12');
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

  testWidgets(
      'cài mới: hướng dẫn tương tác hiện, KHÔNG hiện "Có gì mới" dù hướng dẫn xong sẽ lưu ván',
      (tester) async {
    final savedTutorial = debugAutoShowTutorial;
    debugAutoShowTutorial = true;
    addTearDown(() => debugAutoShowTutorial = savedTutorial);
    final (c, prefs) = await _launch(tester, version: '1.0.12', hasSave: false);
    expect(find.byKey(const Key('ftue-bubble')), findsOneWidget,
        reason: 'người mới thấy hướng dẫn tương tác');
    expect(find.byKey(const Key('whats-new')), findsNothing);
    // Phiên bản được ghi nhớ NGAY (dù chưa hiện gì) → lần mở sau người mới không bị
    // nhầm là "vừa cập nhật" khi ván đã được lưu.
    expect(prefs.getString(whatsNewSeenKey), '1.0.12');
    await tester.tap(find.byKey(const Key('ftue-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('whats-new')), findsNothing);
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
      appVersionProvider.overrideWithValue(() async => '1.0.12'),
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

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('hộp Có gì mới 1.0.12 không tràn ở 320px, đủ chuỗi ($lang)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
                onPressed: () => showWhatsNew(c, '1.0.12'), child: const Text('open')),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('whats-new')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.textContaining(RegExp(r'\{[a-z]+\}')), findsNothing, reason: lang);
      // Đủ 5 gạch đầu dòng của 1.0.12 (mỗi dòng một biểu tượng).
      for (final e in ['👥', '🐺', '🌏', '📈', '✨']) {
        expect(find.textContaining(e), findsOneWidget, reason: '$lang $e');
      }
      // Và không còn nội dung của 1.0.9 (VIP / Hội / nhiệm vụ tuần).
      for (final e in ['👑', '🛡️', '📋']) {
        expect(find.textContaining(e), findsNothing, reason: '$lang $e');
      }
    });
  }
}
