// Danh sách thành viên Hội: thứ tự theo vai, tìm kiếm (chỉ khi đông), bảng thao tác theo quyền, "Nhắc trong chat"
// mở chat với @tên điền sẵn, huy chương, ảnh đại diện, không tràn ở 320px.
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_chat_page.dart';
import 'package:boba_empire/ui/guild_members.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

GuildMemberInfo _m(String id, String nick, GuildRole role, {int points = 0}) =>
    GuildMemberInfo(userId: id, nickname: nick, points: points, role: role);

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;
final _live = <ProviderContainer>[];

Future<void> _open(WidgetTester tester, List<GuildMemberInfo> members,
    {String ownerId = 'boss', String locale = 'vi', Size size = const Size(360, 900)}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now), nowMillis: _now);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(FakeGuildRepository(mine: fakeGuild(ownerId: ownerId, members: members))),
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
      home: const GuildPage(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Finder _k(String k) => find.byKey(Key(k));

Future<void> _scrollTo(WidgetTester tester, Finder f) async {
  await tester.dragUntilVisible(f, find.byType(ListView), const Offset(0, -150));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, String id) async {
  await _scrollTo(tester, _k('guild-member-$id'));
  await tester.tap(_k('guild-member-$id'));
  await tester.pumpAndSettle();
}

List<GuildMemberInfo> _crowd(int n) => [
      _m('boss', 'Chủ', GuildRole.owner, points: 1),
      _m('me', 'Alice', GuildRole.member, points: 2),
      for (var i = 0; i < n - 2; i++) _m('u$i', 'Người $i', GuildRole.member, points: 10 + i),
    ];

void main() {
  group('hàm thuần', () {
    final ms = [
      _m('a', 'An', GuildRole.member, points: 50),
      _m('b', 'Bình', GuildRole.owner, points: 5),
      _m('c', 'Cường', GuildRole.officer, points: 30),
      _m('d', 'Dũng', GuildRole.member, points: 70),
    ];
    test('orderGuildMembers: chủ → phó → thường; trong nhóm giữ thứ tự gốc', () {
      expect(orderGuildMembers(ms).map((m) => m.userId), ['b', 'c', 'a', 'd']);
    });
    test('filterGuildMembers: không phân biệt hoa thường; rỗng thì trả nguyên', () {
      expect(filterGuildMembers(ms, 'ÌN').map((m) => m.userId), ['b']);
      expect(filterGuildMembers(ms, '  ').length, 4);
      expect(filterGuildMembers(ms, 'zzz'), isEmpty);
    });
    test('guildMedalRanks: top 3 theo điểm tuần, bỏ người 0 điểm', () {
      expect(guildMedalRanks(ms), {'d': 0, 'a': 1, 'c': 2});
      expect(guildMedalRanks([_m('x', 'X', GuildRole.member), _m('y', 'Y', GuildRole.member, points: 3)]), {'y': 0});
    });
    test('guildAvatarGlyph: ký tự/emoji đầu, hoa; tên rỗng → ?', () {
      expect(guildAvatarGlyph('bob'), 'B');
      expect(guildAvatarGlyph('🐶áu áu'), '🐶');
      expect(guildAvatarGlyph('  '), '?');
    });
  });

  testWidgets('tiêu đề đếm đủ n/20; hội ≤ 8 người không có ô tìm', (tester) async {
    await _open(tester, _crowd(5));
    await _scrollTo(tester, _k('guild-members-header'));
    expect(find.text('👥 Thành viên (5/$guildBaseMembers)'), findsOneWidget);
    expect(_k('guild-member-search'), findsNothing);
    await _end(tester);
  });

  testWidgets('hội đông: có ô tìm, gõ lọc theo tên, không khớp thì báo', (tester) async {
    await _open(tester, _crowd(12));
    await _scrollTo(tester, _k('guild-member-search'));
    await tester.enterText(_k('guild-member-search'), 'người 3');
    await tester.pumpAndSettle();
    expect(_k('guild-member-u3'), findsOneWidget);
    expect(_k('guild-member-u4'), findsNothing);
    await tester.enterText(_k('guild-member-search'), 'khong-co-ai');
    await tester.pumpAndSettle();
    expect(_k('guild-member-no-match'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('bảng thao tác của người khác: Nhắc trong chat, Tặng 💎, Hồ sơ; của chính mình: chỉ Hồ sơ', (tester) async {
    await _open(tester, _crowd(4));
    await _openSheet(tester, 'u0');
    expect(_k('guild-member-sheet-u0'), findsOneWidget);
    for (final k in ['guild-mention-u0', 'guild-gift-u0', 'guild-profile-u0']) {
      expect(_k(k), findsOneWidget, reason: k);
    }
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await _openSheet(tester, 'me');
    expect(_k('guild-profile-me'), findsOneWidget);
    expect(_k('guild-mention-me'), findsNothing);
    expect(_k('guild-gift-me'), findsNothing);
    await _end(tester);
  });

  testWidgets('"Nhắc trong chat" mở chat với "@tên " điền sẵn', (tester) async {
    await _open(tester, _crowd(4));
    await _openSheet(tester, 'u1');
    await tester.tap(_k('guild-mention-u1'));
    await tester.pumpAndSettle();
    expect(find.byType(GuildChatPage), findsOneWidget);
    final field = tester.widget<TextField>(_k('guild-chat-input'));
    expect(field.controller!.text, '@Người 1 ');
    await _end(tester);
  });

  testWidgets('thứ tự hiển thị: chủ hội đứng đầu dù điểm thấp; vai trò có 👑/⭐', (tester) async {
    await _open(tester, [
      _m('me', 'Alice', GuildRole.member, points: 900),
      _m('off', 'Phó', GuildRole.officer, points: 500),
      _m('boss', 'Chủ', GuildRole.owner, points: 1),
    ]);
    await _scrollTo(tester, _k('guild-member-boss'));
    final y = {
      for (final id in ['boss', 'off', 'me']) id: tester.getTopLeft(_k('guild-member-$id')).dy,
    };
    expect(y['boss']!, lessThan(y['off']!));
    expect(y['off']!, lessThan(y['me']!));
    expect(find.text('👑 '), findsOneWidget);
    expect(find.text('⭐ '), findsOneWidget);
    await _end(tester);
  });

  testWidgets('huy chương chỉ cho top 3 theo ĐIỂM (không theo thứ tự hiển thị)', (tester) async {
    await _open(tester, [
      _m('boss', 'Chủ', GuildRole.owner, points: 1),
      _m('a', 'A', GuildRole.member, points: 900),
      _m('b', 'B', GuildRole.member, points: 500),
      _m('c', 'C', GuildRole.member, points: 400),
      _m('d', 'D', GuildRole.member, points: 300),
      _m('me', 'Alice', GuildRole.member, points: 0),
    ]);
    await _scrollTo(tester, _k('guild-member-me'));
    expect(find.text('🥇 '), findsOneWidget);
    expect(find.text('🥈 '), findsOneWidget);
    expect(find.text('🥉 '), findsOneWidget);
    await _end(tester);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] 320px: 30 thành viên tên dài + bảng thao tác chủ hội không tràn', (tester) async {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      await _open(
          tester,
          [
            _m('me', 'Alice', GuildRole.owner, points: 99999999),
            for (var i = 0; i < 29; i++) _m('u$i', 'Biệt danh rất rất dài số $i', GuildRole.member, points: 123456789 - i),
          ],
          ownerId: 'me',
          locale: l,
          size: const Size(320, 640));
      await _openSheet(tester, 'u5');
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      expect(_k('guild-kick-u5'), findsOneWidget);
      await _end(tester);
    });
  }
}
