import 'dart:io';
import 'dart:ui' as ui;

import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/ui/invite_dialog.dart' show shareTextProvider;
import 'package:boba_empire/ui/web_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nút "xem / chia sẻ bảng xếp hạng trên web": địa chỉ đúng từng bảng, khớp các tab thật của web.
void main() {
  test('id tab web (site.js BOARDS) khớp đúng WebBoard, và site.js đọc tham số ?board=', () {
    final js = File('docs/assets/site.js').readAsStringSync();
    final block = js.substring(js.indexOf('var BOARDS = ['), js.indexOf('var cache = {}'));
    final ids = RegExp(r"id: '(\w+)'").allMatches(block).map((m) => m.group(1)!).toList();
    expect(ids.toSet(), {for (final b in WebBoard.values) b.name});
    expect(js, contains("get('board')"));
    expect(js, contains('wanted'));
    // Mục #board có thật trong trang chủ để liên kết cuộn tới.
    expect(File('docs/index.html').readAsStringSync(), contains('id="board"'));
  });

  test('webBoardUrl: tham số trước dấu #, đúng tên tab', () {
    expect(webBoardUrl(WebBoard.vip), 'https://bobaempiregame.com/?board=vip#board');
    for (final b in WebBoard.values) {
      final u = Uri.parse(webBoardUrl(b));
      expect(u.queryParameters['board'], b.name);
      expect(u.fragment, 'board');
      expect(u.host, 'bobaempiregame.com');
    }
  });

  test('mỗi màn bảng xếp hạng dùng đúng WebBoardActions của bảng mình', () {
    const pages = {
      'lib/ui/leaderboard_page.dart': 'income',
      'lib/ui/m3_leaderboard_page.dart': 'pearls',
      'lib/ui/accessory_leaderboard_page.dart': 'collection',
      'lib/ui/story_speedrun_page.dart': 'speed',
      'lib/ui/guild_leaderboard_page.dart': 'guild',
      'lib/ui/vip_leaderboard_page.dart': 'vip',
    };
    pages.forEach((file, board) {
      expect(File(file).readAsStringSync(), contains('WebBoardActions(WebBoard.$board)'),
          reason: file);
    });
    // Bảng không có trên web (Đấu Trường, sự kiện) KHÔNG có nút này.
    for (final f in ['lib/ui/arena_leaderboard_page.dart', 'lib/ui/event_leaderboard_page.dart']) {
      expect(File(f).readAsStringSync().contains('WebBoardActions'), isFalse, reason: f);
    }
  });

  Future<(ProviderContainer, List<Uri>, List<String>)> pump(
    WidgetTester tester,
    WebBoard board, {
    String locale = 'en',
    Size size = const Size(400, 800),
    bool openOk = true,
  }) async {
    final opened = <Uri>[];
    final shared = <String>[];
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final c = ProviderContainer(overrides: [
      urlOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return openOk;
      }),
      shareTextProvider.overrideWithValue((text, origin) async => shared.add(text)),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: ui.Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(appBar: AppBar(title: const Text('t'), actions: [WebBoardActions(board)])),
      ),
    ));
    return (c, opened, shared);
  }

  testWidgets('bấm "mở trên web": mở đúng địa chỉ tab của bảng đó', (tester) async {
    for (final b in WebBoard.values) {
      final (c, opened, _) = await pump(tester, b);
      await tester.tap(find.byKey(const Key('web-board-open')));
      await tester.pump();
      expect(opened, [Uri.parse(webBoardUrl(b))], reason: b.name);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('bấm "chia sẻ": chia sẻ câu kèm đúng địa chỉ bảng đó', (tester) async {
    final (c, _, shared) = await pump(tester, WebBoard.guild);
    await tester.tap(find.byKey(const Key('web-board-share')));
    await tester.pump();
    expect(shared, ['Check out the Boba Empire leaderboard: ${webBoardUrl(WebBoard.guild)}']);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('không mở được: báo lỗi bằng snackbar', (tester) async {
    final (c, opened, _) = await pump(tester, WebBoard.income, openOk: false);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const ui.Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          appBar: AppBar(actions: const [WebBoardActions(WebBoard.income)]),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('web-board-open')));
    await tester.pumpAndSettle();
    expect(opened, isNotEmpty);
    expect(find.textContaining("Couldn't open the website"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
    testWidgets('không tràn ở 320px và có chú thích ($lang)', (tester) async {
      final (c, _, shared) = await pump(tester, WebBoard.vip, locale: lang, size: const Size(320, 640));
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.byTooltip(RegExp(r'.+')), findsWidgets);
      await tester.tap(find.byKey(const Key('web-board-share')));
      await tester.pump();
      expect(shared.single, contains('?board=vip#board'), reason: lang);
      expect(shared.single.contains('{url}'), isFalse, reason: lang);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
}
