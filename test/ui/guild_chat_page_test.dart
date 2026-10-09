// Chat hội: gửi/hiện tin, tin ghim, xoá & ghim theo quyền, lỗi giữ nguyên chữ, không tràn.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

/// chatPost chờ [gate] — giả lập mạng chậm để rời trang giữa chừng.
class _SlowChat extends FakeGuildRepository {
  _SlowChat({super.mine});
  final gate = Completer<void>();
  @override
  Future<void> chatPost(String body) async {
    await gate.future;
    return super.chatPost(body);
  }
}

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

GuildMessage _msg(int id, String body, {String user = 'other', String nick = 'Bob'}) =>
    GuildMessage(id: id, userId: user, nickname: nick, body: body);

/// [owner] true → người chơi (id 'me') là chủ hội.
Future<(ProviderContainer, FakeGuildRepository)> _open(
  WidgetTester tester, {
  bool owner = true,
  String locale = 'vi',
  Size size = const Size(360, 800),
  void Function(FakeGuildRepository)? seed,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now),
      nowMillis: _now);
  final repo = FakeGuildRepository(mine: fakeGuild(ownerId: owner ? 'me' : 'boss'));
  seed?.call(repo);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
  ]);
  _live.add(c);
  await c.read(guildControllerProvider.notifier).refresh();
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const GuildChatPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo);
}

final _live = <ProviderContainer>[];

/// Huỷ cây rồi huỷ container TRƯỚC khi test kết thúc (timer của game controller).
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

void main() {
  testWidgets('màn Hội: biểu tượng chat chỉ hiện khi đang ở hội và mở được chat', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final inGuild in [false, true]) {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
          GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now),
          nowMillis: _now);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
        guildRepositoryProvider
            .overrideWithValue(FakeGuildRepository(mine: inGuild ? fakeGuild() : null)),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GuildPage(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-chat-button')), inGuild ? findsOneWidget : findsNothing);
      if (inGuild) {
        await tester.tap(find.byKey(const Key('guild-chat-button')));
        await tester.pumpAndSettle();
        expect(find.byType(GuildChatPage), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    }
  });

  testWidgets('trống: hiện lời mời nhắn tin', (tester) async {
    await _open(tester);
    expect(find.textContaining('Chưa có tin nào'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('gửi tin: hiện trong danh sách và ô nhập được xoá', (tester) async {
    final (_, repo) = await _open(tester);
    await tester.enterText(find.byKey(const Key('guild-chat-input')), '  chào cả nhà ');
    await tester.tap(find.byKey(const Key('guild-chat-send')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages.single.body, 'chào cả nhà');
    expect(find.text('chào cả nhà'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('guild-chat-input'))).controller!.text, '');
    await _end(tester);
  });

  testWidgets('rời trang khi tin đang gửi (mạng chậm): không crash khi server trả lời muộn',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now),
        nowMillis: _now);
    final repo = _SlowChat(mine: fakeGuild());
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => _now),
      guildRepositoryProvider.overrideWithValue(repo),
    ]);
    _live.add(c);
    await c.read(guildControllerProvider.notifier).refresh();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GuildChatPage(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('guild-chat-input')), 'chậm');
    await tester.tap(find.byKey(const Key('guild-chat-send')));
    await tester.pump();
    // Nút khoá khi đang gửi → bấm lần nữa không gửi đôi.
    await tester.tap(find.byKey(const Key('guild-chat-send')), warnIfMissed: false);
    await tester.pump();
    await tester.pumpWidget(const SizedBox()); // rời trang
    repo.gate.complete();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(repo.chatMessages.length, 1, reason: 'không gửi đôi');
    await _end(tester);
  });

  testWidgets('tin rỗng không gọi server', (tester) async {
    final (_, repo) = await _open(tester);
    await tester.enterText(find.byKey(const Key('guild-chat-input')), '   ');
    await tester.tap(find.byKey(const Key('guild-chat-send')));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c == 'chatPost'), isEmpty);
    await _end(tester);
  });

  testWidgets('server từ chối (gửi nhanh quá): báo lỗi và GIỮ chữ để sửa', (tester) async {
    final (_, repo) = await _open(tester);
    repo.failures['chatPost'] = const GuildException(GuildFailure.chatRateLimited);
    await tester.enterText(find.byKey(const Key('guild-chat-input')), 'nhanh quá');
    await tester.tap(find.byKey(const Key('guild-chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn gửi quá nhanh, chờ vài giây nhé.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('guild-chat-input'))).controller!.text,
        'nhanh quá');
    await _end(tester);
  });

  testWidgets('tin ghim hiện ở trên cùng; tin của mình căn phải, của người khác kèm tên',
      (tester) async {
    await _open(tester, seed: (r) {
      r.chatMessages.addAll([
        _msg(3, 'của tôi', user: 'me', nick: 'Alice'),
        _msg(2, 'thông báo tuần', user: 'boss', nick: 'Sếp'),
        _msg(1, 'xin chào', nick: 'Bob'),
      ]);
      r.chatPinnedId = 2;
    });
    expect(find.byKey(const Key('guild-chat-pinned')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('guild-chat-pinned')), matching: find.text('thông báo tuần')),
        findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Alice'), findsNothing, reason: 'tin của mình không lặp tên');
    final mine = tester.getRect(find.byKey(const Key('guild-chat-msg-3')));
    final other = tester.getRect(find.byKey(const Key('guild-chat-msg-1')));
    expect(mine.right, greaterThan(other.right), reason: 'tin của mình lệch phải');
    await _end(tester);
  });

  testWidgets('chủ hội: nhấn giữ tin người khác → ghim, rồi bỏ ghim', (tester) async {
    final (_, repo) = await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'xin chào')));
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guild-chat-pin')));
    await tester.pumpAndSettle();
    expect(repo.chatPinnedId, 1);
    expect(find.byKey(const Key('guild-chat-pinned')), findsOneWidget);

    await tester.longPress(find.byKey(const Key('guild-chat-pinned')));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ ghim'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guild-chat-pin')));
    await tester.pumpAndSettle();
    expect(repo.chatPinnedId, isNull);
    await _end(tester);
  });

  testWidgets('chủ hội xoá được tin người khác', (tester) async {
    final (_, repo) = await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'spam')));
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guild-chat-delete')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages, isEmpty);
    await _end(tester);
  });

  testWidgets('thành viên thường: không có menu trên tin người khác; xoá được tin của mình, không có Ghim',
      (tester) async {
    final (_, repo) = await _open(tester, owner: false, seed: (r) {
      r.chatMessages.addAll([_msg(2, 'của tôi', user: 'me', nick: 'Alice'), _msg(1, 'người khác')]);
    });
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guild-chat-delete')), findsNothing);

    await tester.longPress(find.byKey(const Key('guild-chat-msg-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guild-chat-pin')), findsNothing, reason: 'chỉ chủ hội ghim');
    await tester.tap(find.byKey(const Key('guild-chat-delete')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages.map((m) => m.id), [1]);
    await _end(tester);
  });

  testWidgets('lỗi mạng khi tải: hiện nút thử lại', (tester) async {
    await _open(tester, seed: (r) => r.failures['chat'] = const GuildException(GuildFailure.network));
    expect(find.byType(TextButton), findsOneWidget);
    await _end(tester);
  });

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$locale] 320px: tên + tin rất dài và ghim không tràn', (tester) async {
      await _open(tester, locale: locale, size: const Size(320, 640), seed: (r) {
        final long = 'W' * 20;
        r.chatMessages.addAll([
          _msg(3, 'x' * 200, user: 'me', nick: 'Alice'),
          _msg(2, 'dòng dài ' * 25, nick: long),
          _msg(1, 'ghim ' * 40, user: 'boss', nick: long),
        ]);
        r.chatPinnedId = 1;
      });
      expect(tester.takeException(), isNull);
      await _end(tester);
    });
  }
}
