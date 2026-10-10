// Phó hội, chuyển chủ hội, nhật ký hoạt động: quyền hiển thị đúng vai, gọi đúng lệnh,
// báo lỗi, và không tràn ở 320px.
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_activity_page.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

final _live = <ProviderContainer>[];

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

GuildMemberInfo _m(String id, String nick, GuildRole role, {int points = 100}) =>
    GuildMemberInfo(userId: id, nickname: nick, points: points, role: role);

/// Tôi ('me') mang vai [myRole]; có: chủ 'boss' (hoặc tôi), phó 'off', thường 'mem'.
Future<FakeGuildRepository> _open(
  WidgetTester tester, {
  required GuildRole myRole,
  Widget home = const GuildPage(),
  String locale = 'vi',
  Size size = const Size(360, 800),
  List<GuildMemberInfo>? members,
  List<GuildJoinRequest> requests = const [],
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now),
      nowMillis: _now);
  final iAmOwner = myRole == GuildRole.owner;
  final repo = FakeGuildRepository(
    mine: fakeGuild(
      ownerId: iAmOwner ? 'me' : 'boss',
      requests: requests,
      members: members ??
          [
            iAmOwner ? _m('me', 'Alice', GuildRole.owner) : _m('boss', 'Chủ', GuildRole.owner),
            if (!iAmOwner) _m('me', 'Alice', myRole),
            _m('off', 'Phó Hội', GuildRole.officer),
            _m('mem', 'Thường', GuildRole.member),
          ],
    ),
  );
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
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

Finder _k(String k) => find.byKey(Key(k));

void main() {
  group('hiển thị theo vai', () {
    testWidgets('chủ hội: 👑 cạnh chủ, ⭐ cạnh phó; menu quản lý + kick cho MỌI người khác',
        (tester) async {
      await _open(tester, myRole: GuildRole.owner);
      expect(find.text('👑 '), findsOneWidget);
      expect(find.text('⭐ '), findsOneWidget);
      for (final id in ['off', 'mem']) {
        expect(_k('guild-member-menu-$id'), findsOneWidget, reason: id);
        expect(_k('guild-kick-$id'), findsOneWidget, reason: id);
      }
      expect(_k('guild-member-menu-me'), findsNothing);
      expect(_k('guild-kick-me'), findsNothing);
      await _end(tester);
    });

    testWidgets('phó hội: chỉ kick được thành viên thường; không có menu; thấy đơn xin vào',
        (tester) async {
      await _open(tester,
          myRole: GuildRole.officer,
          requests: const [GuildJoinRequest(userId: 'r1', nickname: 'Người Xin')]);
      expect(_k('guild-kick-mem'), findsOneWidget);
      expect(_k('guild-kick-off'), findsNothing, reason: 'không kick phó khác');
      expect(_k('guild-kick-boss'), findsNothing, reason: 'không kick chủ');
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(_k('guild-accept-r1'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('thành viên thường: không kick, không menu, không thấy đơn', (tester) async {
      await _open(tester,
          myRole: GuildRole.member,
          requests: const [GuildJoinRequest(userId: 'r1', nickname: 'Người Xin')]);
      expect(find.byIcon(Icons.person_remove), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(_k('guild-accept-r1'), findsNothing);
      await _end(tester);
    });
  });

  group('căn cột hàng thành viên', () {
    for (final role in GuildRole.values) {
      testWidgets('[${role.name}] điểm các hàng THẲNG CỘT (cùng mép phải) dù hàng có/không có nút',
          (tester) async {
        await _open(tester, myRole: role, members: [
          _m('me', 'Alice', role, points: 5),
          if (role != GuildRole.owner) _m('boss', 'Chủ', GuildRole.owner, points: 12345678),
          if (role != GuildRole.officer) _m('off', 'Phó', GuildRole.officer, points: 7),
          if (role != GuildRole.member) _m('mem', 'Thường', GuildRole.member, points: 987654321),
        ]);
        final rights = [
          for (final e in find.byWidgetPredicate((w) =>
                  w.key is ValueKey<String> &&
                  (w.key as ValueKey<String>).value.startsWith('guild-member-points-'))
              .evaluate())
            tester.getRect(find.byWidget(e.widget)).right,
        ];
        expect(rights.length, greaterThanOrEqualTo(3));
        expect(rights.every((r) => (r - rights.first).abs() < 0.5), isTrue,
            reason: 'mép phải cột điểm lệch: $rights');
        await _end(tester);
      });
    }
  });

  group('chủ hội quản lý', () {
    testWidgets('bổ nhiệm → gọi setOfficer(on:true); phó hội hiện ⭐ sau khi tải lại',
        (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      await tester.tap(_k('guild-member-menu-mem'));
      await tester.pumpAndSettle();
      expect(find.text('Bổ nhiệm phó hội'), findsOneWidget);
      await tester.tap(_k('guild-toggle-officer-mem'));
      await tester.pumpAndSettle();
      expect(repo.roleCalls, ['officer:mem:true']);
      expect(find.text('⭐ '), findsNWidgets(2));
      await _end(tester);
    });

    testWidgets('bãi nhiệm: menu của phó hội ghi "Bãi nhiệm" và gọi on:false', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      await tester.tap(_k('guild-member-menu-off'));
      await tester.pumpAndSettle();
      expect(find.text('Bãi nhiệm phó hội'), findsOneWidget);
      await tester.tap(_k('guild-toggle-officer-off'));
      await tester.pumpAndSettle();
      expect(repo.roleCalls, ['officer:off:false']);
      expect(find.text('⭐ '), findsNothing);
      await _end(tester);
    });

    testWidgets('đủ phó hội → thông báo lỗi đúng, không đổi vai', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      repo.failures['setOfficer'] = const GuildException(GuildFailure.officersFull);
      await tester.tap(_k('guild-member-menu-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-toggle-officer-mem'));
      await tester.pumpAndSettle();
      expect(find.text('Hội đã đủ $guildMaxOfficers phó hội.'), findsOneWidget);
      expect(find.text('⭐ '), findsOneWidget);
      await _end(tester);
    });

    testWidgets('nhường chức: hỏi xác nhận; huỷ thì không gọi; đồng ý thì đổi chủ và mất quyền chủ',
        (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      await tester.tap(_k('guild-member-menu-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-transfer-mem'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Thường'), findsWidgets);
      await tester.tap(find.text(
          find.text('Huỷ').evaluate().isNotEmpty ? 'Huỷ' : 'Hủy'));
      await tester.pumpAndSettle();
      expect(repo.roleCalls, isEmpty);

      await tester.tap(_k('guild-member-menu-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-transfer-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-confirm-ok'));
      await tester.pumpAndSettle();
      expect(repo.roleCalls, ['transfer:mem']);
      expect(repo.mine!.ownerId, 'mem');
      // Tôi không còn là chủ: hết menu quản lý.
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      await _end(tester);
    });

    testWidgets('server từ chối (không đủ quyền) → báo lỗi', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      repo.failures['transferOwner'] = const GuildException(GuildFailure.notAllowed);
      await tester.tap(_k('guild-member-menu-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-transfer-mem'));
      await tester.pumpAndSettle();
      await tester.tap(_k('guild-confirm-ok'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn không đủ quyền với người này.'), findsOneWidget);
      await _end(tester);
    });
  });

  group('chat: phó hội', () {
    testWidgets('xoá được tin người khác nhưng KHÔNG ghim được', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.officer, home: const GuildChatPage());
      repo.chatMessages.add(
          const GuildMessage(id: 1, userId: 'mem', nickname: 'Thường', body: 'spam'));
      // Cần tải lại danh sách sau khi thêm tin.
      final c = _live.single;
      c.invalidate(guildChatProvider);
      await tester.pumpAndSettle();
      await tester.longPress(_k('guild-chat-msg-1'));
      await tester.pumpAndSettle();
      expect(_k('guild-chat-delete'), findsOneWidget);
      expect(_k('guild-chat-report'), findsOneWidget);
      expect(_k('guild-chat-pin'), findsNothing);
      await tester.tap(_k('guild-chat-delete'));
      await tester.pumpAndSettle();
      expect(repo.chatMessages, isEmpty);
      await _end(tester);
    });

    testWidgets('thành viên thường vẫn không xoá được tin người khác', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.member, home: const GuildChatPage());
      repo.chatMessages.add(
          const GuildMessage(id: 1, userId: 'mem2', nickname: 'X', body: 'hi'));
      _live.single.invalidate(guildChatProvider);
      await tester.pumpAndSettle();
      await tester.longPress(_k('guild-chat-msg-1'));
      await tester.pumpAndSettle();
      expect(_k('guild-chat-delete'), findsNothing);
      await _end(tester);
    });
  });

  group('nhật ký hoạt động', () {
    final events = [
      const GuildEvent(kind: GuildEventKind.transferred, actor: 'Chủ', target: 'Alice'),
      const GuildEvent(kind: GuildEventKind.kicked, actor: 'Alice', target: 'Spam'),
      const GuildEvent(kind: GuildEventKind.demoted, actor: 'Alice', target: 'Phó'),
      const GuildEvent(kind: GuildEventKind.promoted, actor: 'Alice', target: 'Phó'),
      const GuildEvent(kind: GuildEventKind.left, actor: 'Rời'),
      const GuildEvent(kind: GuildEventKind.joined, actor: 'Mới'),
    ];

    testWidgets('nút lịch sử ở màn Hội mở nhật ký; mỗi loại sự kiện có câu đúng', (tester) async {
      final repo = await _open(tester, myRole: GuildRole.owner);
      repo.events = events;
      await tester.tap(_k('guild-activity-button'));
      await tester.pumpAndSettle();
      for (final s in [
        'Chủ đã nhường chức chủ hội cho Alice',
        'Alice đã mời Spam ra khỏi hội',
        'Alice đã bãi nhiệm phó hội Phó',
        'Alice đã bổ nhiệm Phó làm phó hội',
        'Rời đã rời hội',
        'Mới đã vào hội',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      await _end(tester);
    });

    testWidgets('trống và lỗi mạng', (tester) async {
      final repo = await _open(tester,
          myRole: GuildRole.member, home: const GuildActivityPage());
      expect(find.text('Chưa có hoạt động nào.'), findsOneWidget);
      repo.failures['activity'] = const GuildException(GuildFailure.network);
      _live.single.invalidate(guildActivityProvider);
      await tester.pumpAndSettle();
      expect(find.byType(TextButton), findsOneWidget);
      await _end(tester);
    });

    testWidgets('nút lịch sử chỉ có khi đang ở hội', (tester) async {
      await _open(tester, myRole: GuildRole.member);
      expect(_k('guild-activity-button'), findsOneWidget);
      await _end(tester);
    });

    for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
      testWidgets('[$l] 320px: tên rất dài trong sự kiện không tràn', (tester) async {
        final repo = await _open(tester,
            myRole: GuildRole.member,
            locale: l,
            size: const Size(320, 640),
            home: const GuildActivityPage());
        final long = 'W' * 20;
        repo.events = [
          for (final k in GuildEventKind.values)
            GuildEvent(kind: k, actor: long, target: long),
        ];
        _live.single.invalidate(guildActivityProvider);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _end(tester);
      });

      testWidgets('[$l] 320px: hàng thành viên có ⭐/👑, tên và điểm rất lớn, menu + kick không tràn',
          (tester) async {
        await _open(tester,
            myRole: GuildRole.owner,
            locale: l,
            size: const Size(320, 800),
            members: [
              _m('me', 'W' * 20, GuildRole.owner, points: 12345678901),
              _m('off', 'W' * 20, GuildRole.officer, points: 12345678901),
              _m('mem', 'W' * 20, GuildRole.member, points: 12345678901),
            ]);
        expect(tester.takeException(), isNull);
        await _end(tester);
      });
    }
  });
}
