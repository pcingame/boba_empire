// Chat hội: gửi/hiện tin, tin ghim, xoá & ghim theo quyền, lỗi giữ nguyên chữ, không tràn.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_chat_unread.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
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

class _ChatFlair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

class _ChatVips extends VipLevels {
  @override
  Map<String, int> build() => {'vipman': 7, 'plain': 2, 'mid': 5, 'top': 10};
}

GuildMessage _msg(int id, String body, {String user = 'other', String nick = 'Bob'}) =>
    GuildMessage(id: id, userId: user, nickname: nick, body: body);

/// [owner] true → người chơi (id 'me') là chủ hội.
Future<(ProviderContainer, FakeGuildRepository)> _open(
  WidgetTester tester, {
  bool owner = true,
  String locale = 'vi',
  Size size = const Size(360, 800),
  void Function(FakeGuildRepository)? seed,
  List<Override> extra = const [],
  int vipExp = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..vipExp = vipExp
        ..guildWeek = guildWeekIndex(_now),
      nowMillis: _now);
  final repo = FakeGuildRepository(mine: fakeGuild(ownerId: owner ? 'me' : 'boss'));
  seed?.call(repo);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    ...extra,
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
  testWidgets('chat: tin của VIP từ cấp 5 nổi bật (nền + viền theo cấp), cấp thấp thì không',
      (tester) async {
    await _open(
      tester,
      locale: 'en',
      vipExp: topupTiers[7].exp, // mình là VIP 8
      extra: [
        flairCacheProvider.overrideWith(_ChatFlair.new),
        vipLevelProvider.overrideWith(_ChatVips.new),
      ],
      seed: (r) => r.chatMessages.addAll([
        _msg(5, 'của mình', user: 'me', nick: 'Alice'),
        _msg(4, 'top', user: 'top', nick: 'Top'),
        _msg(3, 'mid', user: 'mid', nick: 'Mid'),
        _msg(2, 'vip7', user: 'vipman', nick: 'Tom'),
        _msg(1, 'thường', user: 'plain', nick: 'Pat'),
      ]),
    );
    BoxDecoration deco(int id) => tester
        .widget<Container>(find.byKey(Key('guild-chat-msg-$id')))
        .decoration as BoxDecoration;
    final theme = Theme.of(tester.element(find.byType(GuildChatPage)));

    // Cấp thấp: không viền, màu mặc định.
    expect(deco(1).border, isNull);
    expect(deco(1).color, theme.colorScheme.surfaceContainerHighest);
    // VIP 5 và 7: viền mảnh màu cấp, nền pha khác mặc định, không quầng sáng.
    for (final id in [3, 2]) {
      final d = deco(id);
      expect((d.border as Border).top.width, 1, reason: 'tin $id');
      expect(d.boxShadow, isNull, reason: 'tin $id');
      expect(d.color, isNot(theme.colorScheme.surfaceContainerHighest), reason: 'tin $id');
    }
    expect((deco(3).border as Border).top.color, vipTagColors[4].last);
    expect((deco(2).border as Border).top.color, vipTagColors[6].last);
    // VIP 10 (người khác) và VIP 8 (chính mình): viền dày + quầng sáng.
    for (final id in [4, 5]) {
      expect((deco(id).border as Border).top.width, 2, reason: 'tin $id');
      expect(deco(id).boxShadow, isNotEmpty, reason: 'tin $id');
    }
    expect((deco(5).border as Border).top.color, vipTagColors[7].last); // mình VIP 8
    await _end(tester);
  });

  testWidgets('chat: không tràn ở 320px với tin VIP 10 và tên rất dài (7 ngôn ngữ)',
      (tester) async {
    for (final lang in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      await _open(
        tester,
        locale: lang,
        size: const Size(320, 640),
        extra: [
          flairCacheProvider.overrideWith(_ChatFlair.new),
          vipLevelProvider.overrideWith(_ChatVips.new),
        ],
        seed: (r) => r.chatMessages.add(_msg(1, 'Một tin nhắn khá dài ' * 6,
            user: 'top', nick: 'MộtBiệtDanhRấtRấtDàiNhưThếNày')),
      );
      expect(tester.takeException(), isNull, reason: lang);
      await _end(tester);
    }
  });

  testWidgets('chat: tin của người khác có nhãn VIP cạnh tên; tin của mình không lặp tên',
      (tester) async {
    await _open(
      tester,
      locale: 'en',
      extra: [
        flairCacheProvider.overrideWith(_ChatFlair.new),
        vipLevelProvider.overrideWith(_ChatVips.new),
      ],
      seed: (r) => r.chatMessages.addAll([
        _msg(3, 'xin chào', user: 'vipman', nick: 'Tycoon Tom'),
        _msg(2, 'hi', user: 'plain', nick: 'Pat'),
      ]),
    );
    expect(find.text('Tycoon Tom'), findsOneWidget);
    expect(find.text('VIP 7'), findsOneWidget);
    expect(find.text('VIP 2'), findsOneWidget); // cấp thấp cũng có nhãn
    await _end(tester);
  });

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

  group('chấm "chưa đọc"', () {
    Future<(ProviderContainer, FakeGuildRepository)> openGuild(WidgetTester tester,
        {required int latest, Map<String, Object> prefs = const {}}) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      await GameStorage(sp).save(
          GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now),
          nowMillis: _now);
      final repo = FakeGuildRepository(mine: fakeGuild(chatLatest: latest));
      repo.chatMessages.addAll([for (var i = latest; i >= 1; i--) _msg(i, 'tin $i')]);
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        clockProvider.overrideWithValue(() => _now),
        guildRepositoryProvider.overrideWithValue(repo),
      ]);
      _live.add(c);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GuildPage(),
        ),
      ));
      await tester.pumpAndSettle();
      return (c, repo);
    }

    bool dot(WidgetTester t) =>
        t.widget<Badge>(find.byKey(const Key('guild-chat-unread'))).isLabelVisible;

    testWidgets('có tin mới chưa xem → hiện chấm; mở chat → chấm tắt, và nhớ qua lần mở sau',
        (tester) async {
      final (c, _) = await openGuild(tester, latest: 3);
      expect(dot(tester), isTrue);
      await tester.tap(find.byKey(const Key('guild-chat-button')));
      await tester.pumpAndSettle();
      expect(c.read(guildChatSeenProvider.notifier).seenOf('g1'), 3);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(dot(tester), isFalse);
      final sp = c.read(sharedPreferencesProvider);
      expect(sp.getInt('guild_chat_seen_g1'), 3, reason: 'lưu máy để lần sau không hiện lại');
      await _end(tester);
    });

    testWidgets('đã xem tới tin mới nhất (lưu từ trước) → không chấm; không có tin nào → không chấm',
        (tester) async {
      await openGuild(tester, latest: 5, prefs: {'guild_chat_seen_g1': 5});
      expect(find.byKey(const Key('guild-chat-unread')), findsOneWidget);
      expect(dot(tester), isFalse);
      await _end(tester);
      await openGuild(tester, latest: 0);
      expect(dot(tester), isFalse);
      await _end(tester);
    });

    testWidgets('có tin MỚI HƠN lần xem cuối → lại hiện chấm', (tester) async {
      await openGuild(tester, latest: 7, prefs: {'guild_chat_seen_g1': 5});
      expect(dot(tester), isTrue);
      await _end(tester);
    });

    testWidgets('seen chỉ tăng: danh sách cũ hơn không kéo lùi', (tester) async {
      final (c, _) = await openGuild(tester, latest: 4, prefs: {'guild_chat_seen_g1': 9});
      c.read(guildChatSeenProvider.notifier).markSeen('g1', 2);
      expect(c.read(guildChatSeenProvider.notifier).seenOf('g1'), 9);
      await _end(tester);
    });

    testWidgets('chat của hội khác không ảnh hưởng (khoá theo id hội)', (tester) async {
      await openGuild(tester, latest: 3, prefs: {'guild_chat_seen_gKhac': 99});
      expect(dot(tester), isTrue);
      await _end(tester);
    });
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

  testWidgets('thành viên thường: tin người khác chỉ có Báo cáo (không xoá/ghim); tin của mình có Xoá, không Báo cáo/Ghim',
      (tester) async {
    final (_, repo) = await _open(tester, owner: false, seed: (r) {
      r.chatMessages.addAll([_msg(2, 'của tôi', user: 'me', nick: 'Alice'), _msg(1, 'người khác')]);
    });
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guild-chat-report')), findsOneWidget);
    expect(find.byKey(const Key('guild-chat-delete')), findsNothing);
    expect(find.byKey(const Key('guild-chat-pin')), findsNothing);
    await tester.tapAt(const Offset(5, 5)); // đóng menu
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('guild-chat-msg-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guild-chat-report')), findsNothing, reason: 'không tự báo cáo mình');
    expect(find.byKey(const Key('guild-chat-pin')), findsNothing, reason: 'chỉ chủ hội ghim');
    await tester.tap(find.byKey(const Key('guild-chat-delete')));
    await tester.pumpAndSettle();
    expect(repo.chatMessages.map((m) => m.id), [1]);
    await _end(tester);
  });

  testWidgets('báo cáo tin: gọi server, báo thành công, tin biến mất khỏi danh sách', (tester) async {
    final (_, repo) = await _open(tester, owner: false, seed: (r) => r.chatMessages.add(_msg(1, 'tin xấu')));
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guild-chat-report')));
    await tester.pumpAndSettle();
    expect(repo.reportedIds, [1]);
    expect(find.text('Đã báo cáo tin nhắn. Bạn sẽ không còn thấy tin này.'), findsOneWidget);
    expect(find.byKey(const Key('guild-chat-msg-1')), findsNothing);
    await _end(tester);
  });

  testWidgets('chủ hội cũng báo cáo được tin người khác (menu đủ Báo cáo + Ghim + Xoá)', (tester) async {
    await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'x')));
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    for (final k in ['guild-chat-report', 'guild-chat-pin', 'guild-chat-delete']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    await _end(tester);
  });

  testWidgets('báo cáo lỗi (mạng): thông báo lỗi, không báo thành công', (tester) async {
    final (_, repo) = await _open(tester, owner: false, seed: (r) => r.chatMessages.add(_msg(1, 'x')));
    repo.failures['chatReport'] = const GuildException(GuildFailure.network);
    await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guild-chat-report')));
    await tester.pumpAndSettle();
    expect(find.text('Đã báo cáo tin nhắn. Bạn sẽ không còn thấy tin này.'), findsNothing);
    expect(find.byKey(const Key('guild-chat-msg-1')), findsOneWidget);
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

  group('reaction', () {
    testWidgets('giữ chạm → chọn emoji → chip hiện số 1, đánh dấu của mình; bấm chip → bỏ', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'chào cả nhà')));
      expect(find.byKey(const Key('guild-chat-chip-1-👍')), findsNothing);
      await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
      await tester.pumpAndSettle();
      for (final e in guildReactionEmojis) {
        expect(find.byKey(Key('guild-chat-pick-$e')), findsOneWidget, reason: e);
      }
      await tester.tap(find.byKey(const Key('guild-chat-pick-👍')));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('chatReact'));
      expect(find.text('👍 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-chat-chip-1-👍')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guild-chat-chip-1-👍')), findsNothing);
      await _end(tester);
    });

    testWidgets('chip của người khác: bấm vào cộng thêm của mình (2); số hiện đúng', (tester) async {
      await _open(tester, seed: (r) => r.chatMessages.add(GuildMessage(
          id: 1,
          userId: 'other',
          nickname: 'Bob',
          body: 'hi',
          reactions: const [GuildReaction(emoji: '❤️', count: 1, mine: false)])));
      expect(find.text('❤️ 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-chat-chip-1-❤️')));
      await tester.pumpAndSettle();
      expect(find.text('❤️ 2'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('tin đã bị xoá trong lúc bấm: báo lỗi, không văng', (tester) async {
      final (_, repo) = await _open(tester, seed: (r) => r.chatMessages.add(_msg(1, 'x')));
      repo.failures['chatReact'] = const GuildException(GuildFailure.notFound);
      await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('guild-chat-pick-😂')));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy hội (có thể hội đã đóng).'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _end(tester);
    });

    test('server cũ không có khoá reactions → danh sách rỗng; có thì đọc đúng', () {
      final old = GuildMessage.fromJson({'id': 1, 'user_id': 'u', 'nickname': 'n', 'body': 'b'});
      expect(old.reactions, isEmpty);
      final m = GuildMessage.fromJson({
        'id': 2,
        'user_id': 'u',
        'nickname': 'n',
        'body': 'b',
        'reactions': [
          {'emoji': '😂', 'count': 3, 'mine': true},
          {'emoji': '🎉', 'count': 1, 'mine': false},
        ],
      });
      expect(m.reactions.map((r) => (r.emoji, r.count, r.mine)), [('😂', 3, true), ('🎉', 1, false)]);
    });

    for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
      testWidgets('[$locale] 320px: đủ 6 loại reaction số lớn trên tin dài không tràn', (tester) async {
        await _open(tester, locale: locale, size: const Size(320, 640), seed: (r) {
          r.chatMessages.add(GuildMessage(
            id: 1,
            userId: 'other',
            nickname: 'W' * 20,
            body: 'dòng dài ' * 25,
            reactions: [
              for (final e in guildReactionEmojis) GuildReaction(emoji: e, count: 99999, mine: e == '👍'),
            ],
          ));
        });
        expect(tester.takeException(), isNull);
        await tester.longPress(find.byKey(const Key('guild-chat-msg-1')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'bảng chọn emoji ở 320px');
        await _end(tester);
      });
    }
  });
}
