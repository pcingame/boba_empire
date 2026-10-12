// Chat Hội: nhắc tên (@tag) khi gõ + hiển thị, gửi tin/reaction tức thì (và hoàn lại khi lỗi), điền sẵn,
// nhớ lại chat khi mở lại, dừng tải định kỳ khi app chạy nền.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

/// Repo giả có thể giữ chatPost / chatReact / chat lại bằng cổng (Completer) để quan sát trạng thái "đang chờ".
class _Gated extends FakeGuildRepository {
  _Gated({super.mine});
  Completer<void>? postGate;
  Completer<void>? reactGate;
  Completer<void>? chatGate;
  int chatCalls = 0;

  @override
  Future<GuildChat> chat() async {
    chatCalls++;
    final g = chatGate;
    if (g != null) await g.future;
    return super.chat();
  }

  @override
  Future<void> chatPost(String body) async {
    final g = postGate;
    if (g != null) await g.future;
    return super.chatPost(body);
  }

  @override
  Future<void> chatReact(int id, String emoji) async {
    final g = reactGate;
    if (g != null) await g.future;
    return super.chatReact(id, emoji);
  }
}

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;
final _live = <ProviderContainer>[];

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

GuildMessage _msg(int id, String body, {String user = 'u2', String nick = 'Bob'}) =>
    GuildMessage(id: id, userId: user, nickname: nick, body: body);

Future<(ProviderContainer, _Gated)> _open(
  WidgetTester tester, {
  void Function(_Gated)? seed,
  String? prefill,
  Size size = const Size(360, 800),
  String locale = 'vi',
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)..guildWeek = 0, nowMillis: _now);
  // fakeGuild mặc định: me = Alice, u2 = Bob, u3 = Cy.
  final repo = _Gated(mine: fakeGuild());
  seed?.call(repo);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_Flair.new),
  ]);
  _live.add(c);
  await c.read(guildControllerProvider.notifier).refresh();
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      locale: ui.Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: GuildChatPage(prefill: prefill)),
    ),
  ));
  await tester.pumpAndSettle();
  return (c, repo);
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Finder get _input => find.byKey(const Key('guild-chat-input'));
String _text(WidgetTester t) => t.widget<TextField>(_input).controller!.text;

void main() {
  group('gợi ý @tên khi gõ', () {
    testWidgets('gõ "@" → gợi ý thành viên (trừ mình); gõ tiếp thì lọc; không có @ thì ẩn', (tester) async {
      await _open(tester);
      expect(find.byKey(const Key('guild-mention-suggestions')), findsNothing);
      await tester.enterText(_input, '@');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-mention-pick-Bob')), findsOneWidget);
      expect(find.byKey(const Key('guild-mention-pick-Cy')), findsOneWidget);
      expect(find.byKey(const Key('guild-mention-pick-Alice')), findsNothing, reason: 'không gợi ý chính mình');
      await tester.enterText(_input, 'chào @b');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-mention-pick-Bob')), findsOneWidget);
      expect(find.byKey(const Key('guild-mention-pick-Cy')), findsNothing);
      await tester.enterText(_input, 'không nhắc ai');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-mention-suggestions')), findsNothing);
      await _end(tester);
    });

    testWidgets('chạm gợi ý → chèn "@Bob " và ẩn dải gợi ý', (tester) async {
      await _open(tester);
      await tester.enterText(_input, 'ê @b');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-mention-pick-Bob')));
      await tester.pumpAndSettle();
      expect(_text(tester), 'ê @Bob ');
      expect(find.byKey(const Key('guild-mention-suggestions')), findsNothing);
      await _end(tester);
    });

    testWidgets('điền sẵn từ "Nhắc trong chat" (prefill)', (tester) async {
      await _open(tester, prefill: '@Bob ');
      expect(_text(tester), '@Bob ');
      await _end(tester);
    });
  });

  group('hiển thị nhắc tên', () {
    testWidgets('"@Bob" được tô; tin nhắc MÌNH có biểu tượng @ và viền; tin nhắc người khác thì không',
        (tester) async {
      await _open(tester, seed: (r) {
        r.chatMessages.addAll([
          _msg(3, 'ê @alice dậy đi', user: 'u3', nick: 'Cy'), // nhắc mình
          _msg(2, 'gửi @Bob cái này', user: 'u3', nick: 'Cy'), // nhắc người khác
          _msg(1, 'xin chào cả nhà'),
        ]);
      });
      expect(find.byKey(const Key('guild-chat-mention-me-3')), findsOneWidget);
      expect(find.byKey(const Key('guild-chat-mention-me-2')), findsNothing);
      expect(find.byKey(const Key('guild-chat-mention-me-1')), findsNothing);
      expect(find.byKey(const Key('guild-chat-mention-text')), findsNWidgets(2), reason: 'chỉ tin có @ mới dựng rich text');
      final deco = tester.widget<Container>(find.byKey(const Key('guild-chat-msg-3'))).decoration as BoxDecoration;
      expect(deco.border, isNotNull, reason: 'tin nhắc mình có viền nhấn');
      final plain = tester.widget<Container>(find.byKey(const Key('guild-chat-msg-1'))).decoration as BoxDecoration;
      expect(plain.border, isNull);
      await _end(tester);
    });

    testWidgets('tin của chính mình nhắc mình không đánh dấu', (tester) async {
      await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'tự nhắc @Alice', user: 'me', nick: 'Alice')));
      expect(find.byKey(const Key('guild-chat-mention-me-1')), findsNothing);
      await _end(tester);
    });

    testWidgets('"@" không khớp thành viên nào thì giữ nguyên chữ thường', (tester) async {
      await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'liên hệ a@b.com hoặc @ai_do')));
      expect(find.byKey(const Key('guild-chat-mention-text')), findsNothing);
      expect(find.text('liên hệ a@b.com hoặc @ai_do'), findsOneWidget);
      await _end(tester);
    });
  });

  group('gửi tin tức thì', () {
    testWidgets('hiện tin ngay + xoá ô nhập trước khi server trả lời; xong thì thành tin thật', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) => r.postGate = Completer<void>());
      await tester.enterText(_input, 'xin chào nha');
      await tester.tap(find.byKey(const Key('guild-chat-send')));
      await tester.pump();
      expect(find.byKey(const Key('guild-chat-pending-1')), findsOneWidget, reason: 'hiện ngay, chưa chờ server');
      expect(find.text('xin chào nha'), findsOneWidget);
      expect(_text(tester), '', reason: 'ô nhập được xoá ngay');
      expect(tester.widget<IconButton>(find.byKey(const Key('guild-chat-send'))).onPressed, isNull,
          reason: 'khoá nút trong lúc gửi');
      repo.postGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-chat-pending-1')), findsNothing);
      expect(find.text('xin chào nha'), findsOneWidget, reason: 'tin thật thay chỗ tin tạm, không nhân đôi');
      expect(repo.chatMessages.length, 1);
      await _end(tester);
    });

    testWidgets('server từ chối: tin tạm biến mất, chữ trả lại ô nhập, có thông báo', (tester) async {
      await _open(tester, seed: (r) => r.failures['chatPost'] = const GuildException(GuildFailure.chatRateLimited));
      await tester.enterText(_input, 'gửi nhanh quá');
      await tester.tap(find.byKey(const Key('guild-chat-send')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-chat-pending-1')), findsNothing);
      expect(_text(tester), 'gửi nhanh quá');
      expect(find.text('Bạn gửi quá nhanh, chờ vài giây nhé.'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('trong lúc chờ người dùng đã gõ chữ khác thì KHÔNG ghi đè khi lỗi', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) {
        r.postGate = Completer<void>();
        r.failures['chatPost'] = const GuildException(GuildFailure.textBlocked);
      });
      await tester.enterText(_input, 'tin một');
      await tester.tap(find.byKey(const Key('guild-chat-send')));
      await tester.pump();
      await tester.enterText(_input, 'tin hai đang gõ');
      repo.postGate!.complete();
      await tester.pumpAndSettle();
      expect(_text(tester), 'tin hai đang gõ');
      await _end(tester);
    });
  });

  group('reaction tức thì', () {
    testWidgets('chip hiện ngay khi bấm, trước khi server trả lời; xong vẫn còn đúng một chip', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) {
        r.chatMessages.add(_msg(1, 'chào'));
        r.reactGate = Completer<void>();
      });
      await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-chat-pick-👍')));
      await tester.pump();
      expect(find.text('👍 1'), findsOneWidget, reason: 'chip lạc quan');
      repo.reactGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('👍 1'), findsOneWidget);
      expect(repo.calls.where((c) => c == 'chatReact').length, 1);
      await _end(tester);
    });

    testWidgets('server từ chối: chip trở lại như cũ và báo lỗi', (tester) async {
      await _open(tester, seed: (r) {
        r.chatMessages.add(_msg(1, 'chào'));
        r.failures['chatReact'] = const GuildException(GuildFailure.notFound);
      });
      await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-chat-pick-😂')));
      await tester.pumpAndSettle();
      expect(find.text('😂 1'), findsNothing);
      expect(find.text('Không tìm thấy hội (có thể hội đã đóng).'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('bấm đúp nhanh cùng một reaction chỉ gửi MỘT lần', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) {
        r.chatMessages.add(GuildMessage(
            id: 1, userId: 'u2', nickname: 'Bob', body: 'chào',
            reactions: const [GuildReaction(emoji: '👍', count: 1, mine: false)]));
        r.reactGate = Completer<void>();
      });
      await tester.tap(find.byKey(const Key('guild-chat-chip-1-👍')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('guild-chat-chip-1-👍')));
      await tester.pump();
      repo.reactGate!.complete();
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c == 'chatReact').length, 1);
      await _end(tester);
    });
  });

  group('tải chat', () {
    testWidgets('mở lại trang: hiện NGAY bản đã nhớ trong lúc tải mới (không spinner)', (tester) async {
      final (c, repo) = await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'tin cũ đã có')));
      expect(find.text('tin cũ đã có'), findsOneWidget);
      // Rời trang rồi mở lại với mạng chậm.
      await tester.pumpWidget(const SizedBox());
      repo.chatGate = Completer<void>();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: GuildChatPage()),
        ),
      ));
      await tester.pump();
      expect(find.text('tin cũ đã có'), findsOneWidget, reason: 'bản đã nhớ');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      repo.chatGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('tin cũ đã có'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('chạy nền thì dừng tải định kỳ; quay lại thì tải ngay', (tester) async {
      final (_, repo) = await _open(tester);
      final base = repo.chatCalls;
      for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await tester.pump(const Duration(seconds: 50));
      expect(repo.chatCalls, base, reason: 'không tải khi chạy nền');
      for (final st in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await tester.pumpAndSettle();
      expect(repo.chatCalls, greaterThan(base), reason: 'quay lại thì tải ngay');
      final after = repo.chatCalls;
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(repo.chatCalls, greaterThan(after), reason: 'và chạy định kỳ lại');
      await _end(tester);
    });
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] 320px: gợi ý @ + tin nhắc mình + tin tạm không tràn', (tester) async {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      final (_, repo) = await _open(tester, locale: l, size: const Size(320, 640), seed: (r) {
        r.postGate = Completer<void>();
        r.chatMessages.add(_msg(1, '@Alice ${'rất dài ' * 20}', user: 'u3', nick: 'W' * 20));
      });
      await tester.enterText(_input, '@');
      await tester.pumpAndSettle();
      await tester.enterText(_input, 'x' * 150);
      await tester.tap(find.byKey(const Key('guild-chat-send')));
      await tester.pump();
      repo.postGate!.complete();
      await tester.pumpAndSettle();
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      await _end(tester);
    });
  }
}
