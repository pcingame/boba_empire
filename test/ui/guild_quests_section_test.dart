// Mục "Nhiệm vụ Hội" trên màn Hội: nhiệm vụ chung + nhiệm vụ cá nhân + quỹ hội, tiến độ và nút nhận ngay tại đây
// (cùng điều kiện với Cửa hàng Hội); không trùng khoá với trang cửa hàng; ẩn nhiệm vụ chung/quỹ khi server cũ.
import 'dart:ui' as ui;

import 'package:boba_empire/core/guild.dart';
import 'package:boba_empire/core/guild_shop.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/l10n/app_localizations.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;
final _live = <ProviderContainer>[];

GuildMemberInfo _m(String id, String nick, int pts) =>
    GuildMemberInfo(userId: id, nickname: nick, points: pts);

Future<FakeGuildRepository> _open(
  WidgetTester tester,
  MyGuild guild, {
  String locale = 'vi',
  Size size = const Size(360, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(GameState.newGame(nowMillis: _now)..guildWeek = guildWeekIndex(_now), nowMillis: _now);
  final repo = FakeGuildRepository(mine: guild);
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
      home: const GuildPage(),
    ),
  ));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

Finder _k(String k) => find.byKey(Key(k));
FilledButton _btn(WidgetTester t, String k) => t.widget<FilledButton>(_k(k));

Future<void> _show(WidgetTester tester, String key) async {
  await tester.dragUntilVisible(_k(key), find.byType(ListView), const Offset(0, -200));
  await tester.ensureVisible(_k(key));
  await tester.pumpAndSettle();
}

MyGuild _guild({
  int myPoints = 0,
  List<int> questsClaimed = const [],
  bool team = true,
  bool teamClaimed = false,
  GuildFund fund = const GuildFund(progress: 100, target: 500, mine: 0),
  List<GuildMemberInfo>? others,
}) =>
    fakeGuild(
      teamAvailable: team,
      teamClaimed: teamClaimed,
      fund: fund,
      questsClaimed: questsClaimed,
      members: [_m('me', 'Alice', myPoints), ...(others ?? [_m('u2', 'Bob', 0), _m('u3', 'Cy', 0)])],
    );

void main() {
  testWidgets('có đủ: tiêu đề, nhiệm vụ chung, 3 nhiệm vụ cá nhân, quỹ hội', (tester) async {
    await _open(tester, _guild());
    await _show(tester, 'gq-header');
    expect(find.text('📋 Nhiệm vụ Hội'), findsOneWidget);
    for (final k in ['gq-team-tile', 'gq-quest-tile-0', 'gq-quest-tile-1', 'gq-quest-tile-2', 'gq-fund-tile']) {
      await _show(tester, k);
      expect(_k(k), findsOneWidget, reason: k);
    }
    await _end(tester);
  });

  testWidgets('tiến độ cá nhân: nút chỉ bật khi đủ điểm; đạt mốc 1 nhưng chưa mốc 2', (tester) async {
    await _open(tester, _guild(myPoints: guildQuests[0].need));
    await _show(tester, 'gq-quest-0');
    expect(_btn(tester, 'gq-quest-0').onPressed, isNotNull);
    expect(_btn(tester, 'gq-quest-1').onPressed, isNull);
    expect(_btn(tester, 'gq-quest-2').onPressed, isNull);
    expect(find.textContaining('(${guildQuests[0].need}/${guildQuests[0].need})'), findsOneWidget);
    await _end(tester);
  });

  testWidgets('nhận nhiệm vụ cá nhân: gọi server đúng bậc, cộng ví, nút thành "Đã nhận", báo kết quả', (tester) async {
    final repo = await _open(tester, _guild(myPoints: guildQuests[1].need));
    await _show(tester, 'gq-quest-1');
    await tester.tap(_k('gq-quest-1'));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('claimQuest'));
    expect(repo.mine!.questsClaimed, contains(2));
    expect(find.text('Nhận +${guildQuests[1].reward} Xu Hội'), findsOneWidget, reason: 'snackbar kết quả');
    await _show(tester, 'gq-quest-1');
    expect(_btn(tester, 'gq-quest-1').onPressed, isNull);
    await _end(tester);
  });

  testWidgets('đã nhận từ trước: nút khoá, ghi "Đã nhận"', (tester) async {
    await _open(tester, _guild(myPoints: guildQuests[0].need, questsClaimed: const [1]));
    await _show(tester, 'gq-quest-0');
    expect(_btn(tester, 'gq-quest-0').onPressed, isNull);
    expect(find.descendant(of: _k('gq-quest-0'), matching: find.text('Đã nhận')), findsOneWidget);
    await _end(tester);
  });

  group('nhiệm vụ chung', () {
    testWidgets('chưa đủ người → khoá; hiện "x / y người"', (tester) async {
      await _open(tester, _guild(myPoints: guildTeamMinPoints));
      await _show(tester, 'gq-team');
      expect(_btn(tester, 'gq-team').onPressed, isNull);
      expect(find.text('1 / 2 người đã đạt'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('đủ người + mình đạt → nhận được, cộng Xu Hội', (tester) async {
      final repo = await _open(
          tester, _guild(myPoints: guildTeamMinPoints, others: [_m('u2', 'Bob', guildTeamMinPoints), _m('u3', 'Cy', 0)]));
      await _show(tester, 'gq-team');
      expect(_btn(tester, 'gq-team').onPressed, isNotNull);
      await tester.tap(_k('gq-team'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('claimTeam'));
      expect(find.text('Đã nhận $guildTeamReward Xu Hội từ nhiệm vụ chung!'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('đủ người nhưng mình chưa đạt điểm → khoá', (tester) async {
      await _open(tester, _guild(myPoints: 10, others: [_m('u2', 'Bob', guildTeamMinPoints), _m('u3', 'Cy', guildTeamMinPoints)]));
      await _show(tester, 'gq-team');
      expect(_btn(tester, 'gq-team').onPressed, isNull);
      await _end(tester);
    });

    testWidgets('server cũ (chưa có nhiệm vụ chung) → không hiện thẻ', (tester) async {
      await _open(tester, _guild(team: false));
      await _show(tester, 'gq-quest-0');
      expect(_k('gq-team-tile'), findsNothing);
      await _end(tester);
    });
  });

  group('quỹ hội', () {
    testWidgets('chưa đạt mục tiêu: nút dẫn tới Cửa hàng Hội để góp 💎 (không phải nhận)', (tester) async {
      final repo = await _open(tester, _guild());
      await _show(tester, 'gq-fund');
      expect(_btn(tester, 'gq-fund').onPressed, isNotNull);
      expect(find.descendant(of: _k('gq-fund'), matching: find.text('Cửa hàng hội')), findsOneWidget);
      await tester.tap(_k('gq-fund'));
      await tester.pumpAndSettle();
      expect(find.text('Cửa hàng hội'), findsWidgets, reason: 'đã mở trang cửa hàng');
      expect(repo.calls, isNot(contains('claimFund')));
      await _end(tester);
    });

    testWidgets('đạt mục tiêu + mình góp đủ → nhận được', (tester) async {
      final repo = await _open(
          tester, _guild(fund: GuildFund(progress: 600, target: 500, mine: guildFundMinDonation)));
      await _show(tester, 'gq-fund');
      expect(find.descendant(of: _k('gq-fund'), matching: find.text('Nhận $guildFundReward Xu Hội')), findsOneWidget);
      await tester.tap(_k('gq-fund'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('claimFund'));
      expect(find.text('Đã nhận $guildFundReward Xu Hội từ quỹ hội!'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('đạt mục tiêu nhưng mình góp chưa đủ → khoá (không thể nhận, không còn gì để góp)', (tester) async {
      await _open(tester, _guild(fund: GuildFund(progress: 600, target: 500, mine: guildFundMinDonation - 1)));
      await _show(tester, 'gq-fund');
      expect(_btn(tester, 'gq-fund').onPressed, isNull);
      await _end(tester);
    });

    testWidgets('đã nhận: khoá, "Đã nhận"; server cũ (không có quỹ) → không hiện thẻ', (tester) async {
      await _open(tester, _guild(fund: GuildFund(progress: 600, target: 500, mine: 50, claimed: true)));
      await _show(tester, 'gq-fund');
      expect(_btn(tester, 'gq-fund').onPressed, isNull);
      await _end(tester);
      await _open(tester, _guild(fund: const GuildFund()));
      await _show(tester, 'gq-quest-0');
      expect(_k('gq-fund-tile'), findsNothing);
      await _end(tester);
    });
  });

  testWidgets('lỗi server khi nhận: báo lỗi, không đổi trạng thái', (tester) async {
    final repo = await _open(tester, _guild(myPoints: guildQuests[0].need));
    repo.failures['claimQuest'] = const GuildException(GuildFailure.network);
    await _show(tester, 'gq-quest-0');
    await tester.tap(_k('gq-quest-0'));
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được, thử lại sau nhé.'), findsOneWidget);
    expect(repo.mine!.questsClaimed, isEmpty);
    await _end(tester);
  });

  for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    testWidgets('[$l] 320px: nhiệm vụ chung + cá nhân + quỹ số lớn không tràn', (tester) async {
      final errors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => errors.add(d.toString());
      addTearDown(() => FlutterError.onError = prev);
      await _open(
          tester,
          _guild(
              myPoints: 99999999,
              fund: GuildFund(progress: 999999999, target: 999999999, mine: 999999999),
              others: [for (var i = 0; i < 20; i++) _m('u$i', 'Người $i', 123456)]),
          locale: l,
          size: const Size(320, 640));
      for (final k in ['gq-team', 'gq-quest-0', 'gq-quest-2', 'gq-fund']) {
        await _show(tester, k);
      }
      FlutterError.onError = prev;
      expect(errors, isEmpty, reason: errors.join('\n'));
      await _end(tester);
    });
  }
}
