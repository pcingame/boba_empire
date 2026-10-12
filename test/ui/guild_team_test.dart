// Nhiệm vụ chung "cả hội cùng tham gia": số người cần, thẻ trong cửa hàng hội (hiện/ẩn,
// nút nhận đúng điều kiện, lỗi, không tràn ở 320px).
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/guild_shop.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_shop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;
final _live = <ProviderContainer>[];

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Future<FakeGuildRepository> _open(
  WidgetTester tester,
  List<GuildMemberInfo> members, {
  bool available = true,
  bool claimed = false,
  String locale = 'vi',
  Size size = const Size(360, 800),
  int wallet = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      GameState.newGame(nowMillis: _now)
        ..gems = 5000
        ..guildWeek = guildWeekIndex(_now),
      nowMillis: _now);
  final repo = FakeGuildRepository(mine: fakeGuild(
      members: members, teamAvailable: available, teamClaimed: claimed, wallet: wallet));
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
      home: const GuildShopPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

GuildMemberInfo _m(String id, int pts) =>
    GuildMemberInfo(userId: id, nickname: id, points: pts);

Finder _k(String k) => find.byKey(Key(k));
FilledButton _claim(WidgetTester t) => t.widget<FilledButton>(_k('guild-team-claim'));

void main() {
  test('số người cần: nửa hội làm tròn lên, tối thiểu 2, tối đa cả hội', () {
    expect([for (final n in [0, 1, 2, 3, 4, 5, 30]) guildTeamNeed(n)], [0, 1, 2, 2, 2, 3, 15]);
  });

  test('MyGuild: đếm người đạt mức tối thiểu', () {
    final g = fakeGuild(members: [
      _m('me', guildTeamMinPoints),
      _m('a', guildTeamMinPoints - 1),
      _m('b', 5000),
    ]);
    expect((g.teamActive, g.teamNeed, g.teamReached), (2, 2, true));
    expect(fakeGuild(members: [_m('me', 5000), _m('a', 0), _m('b', 0)]).teamReached, isFalse);
  });

  group('thẻ nhiệm vụ chung', () {
    testWidgets('server cũ: ẩn thẻ', (tester) async {
      await _open(tester, [_m('me', 5000)], available: false);
      expect(_k('guild-team-card'), findsNothing);
      await _end(tester);
    });

    testWidgets('chưa đủ người: hiện tiến độ, nút khoá', (tester) async {
      await _open(tester, [_m('me', 2000), _m('a', 10), _m('b', 0)]);
      expect(find.text('1 / 2 người đã đạt'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(_k('guild-team-bar')).value, 0.5);
      expect(_claim(tester).onPressed, isNull);
      await _end(tester);
    });

    testWidgets('đủ người nhưng mình chưa đạt điểm: nút khoá', (tester) async {
      await _open(tester, [_m('me', 10), _m('a', 2000), _m('b', 2000)]);
      expect(_claim(tester).onPressed, isNull);
      await _end(tester);
    });

    testWidgets('đủ người + mình đạt: nhận → ví cộng thưởng, nút "Đã nhận"', (tester) async {
      final repo = await _open(tester, [_m('me', 2000), _m('a', 2000), _m('b', 0)], wallet: 100);
      expect(_claim(tester).onPressed, isNotNull);
      await tester.tap(_k('guild-team-claim'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('claimTeam'));
      expect(repo.mine!.wallet, 100 + guildTeamReward);
      expect(find.text('Đã nhận $guildTeamReward Xu Hội từ nhiệm vụ chung!'), findsOneWidget);
      expect(_claim(tester).onPressed, isNull);
      await _end(tester);
    });

    testWidgets('đã nhận tuần này: nút khoá', (tester) async {
      await _open(tester, [_m('me', 2000), _m('a', 2000)], claimed: true);
      expect(_claim(tester).onPressed, isNull);
      expect(find.text('Đã nhận'), findsWidgets);
      await _end(tester);
    });

    test('lỗi server → GuildFailure đúng, không nhầm với lỗi quỹ', () {
      expect(guildFailureFromMessage('team not reached'), GuildFailure.teamNotReached);
      expect(guildFailureFromMessage('team points too low'), GuildFailure.teamPointsLow);
      expect(guildFailureFromMessage('goal not reached'), GuildFailure.fundNotReached);
    });

    for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
      testWidgets('[$l] 320px: thẻ nhiệm vụ chung không tràn', (tester) async {
        await _open(tester, [for (var i = 0; i < 30; i++) _m(i == 0 ? 'me' : 'u$i', 2000)],
            locale: l, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
        await _end(tester);
      });
    }
  });
}
