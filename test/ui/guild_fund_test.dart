// Quỹ hội tuần: hằng số/mục tiêu theo số người, parse, thẻ trong cửa hàng hội
// (hiện/ẩn, nút nhận đúng điều kiện, lỗi, không tràn ở 320px).
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
  GuildFund fund, {
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
  final repo = FakeGuildRepository(mine: fakeGuild(fund: fund, wallet: wallet));
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

Finder _k(String k) => find.byKey(Key(k));
FilledButton _claim(WidgetTester t) => t.widget<FilledButton>(_k('guild-fund-claim'));

void main() {
  group('mục tiêu quỹ', () {
    test('tối thiểu 500; 100 💎/người; khớp bảng giá trị', () {
      expect(guildFundTarget(0), 500);
      expect(guildFundTarget(1), 500);
      expect(guildFundTarget(5), 500);
      expect(guildFundTarget(6), 600);
      expect(guildFundTarget(30), 3000);
      expect(guildFundTarget(guildMaxMembers), guildFundPerMember * guildMaxMembers);
    });

    test('mục tiêu đầy hội ≥ trần quyên góp ngày của 1 người (không ai gánh 1 mình trong 1 ngày)',
        () {
      expect(guildFundTarget(guildMaxMembers), greaterThan(guildDonateDailyCap));
    });

    test('GuildFund.fromJson: null/server cũ → không có quỹ; có dữ liệu → đọc đúng', () {
      expect(GuildFund.fromJson(null).available, isFalse);
      final f = GuildFund.fromJson({'progress': 505, 'target': 500, 'mine': 50, 'claimed': false});
      expect((f.progress, f.target, f.mine, f.claimed), (505, 500, 50, false));
      expect(f.available, isTrue);
      expect(f.reached, isTrue);
      expect(const GuildFund(progress: 499, target: 500).reached, isFalse);
      expect(const GuildFund().reached, isFalse, reason: 'không có quỹ ≠ đạt');
    });

    test('MyGuild.fromJson đọc fund; thiếu fund → mặc định', () {
      Map<String, dynamic> base() => {
            'guild': {'id': 'g', 'name': 'N', 'tag': 'T', 'emoji': 'e', 'owner_id': 'a'},
            'total': 0,
            'claimed': [],
            'members': [],
          };
      expect(MyGuild.fromJson(base()).fund.available, isFalse);
      final j = base()..['fund'] = {'progress': 1, 'target': 500, 'mine': 2, 'claimed': true};
      expect(MyGuild.fromJson(j).fund.claimed, isTrue);
    });

    test('lỗi RPC → failure đúng', () {
      expect(guildFailureFromMessage('goal not reached'), GuildFailure.fundNotReached);
      expect(guildFailureFromMessage('fund donation too low'), GuildFailure.fundDonationLow);
      expect(guildFailureFromMessage('Could not find the function public.guild_claim_fund'),
          GuildFailure.network);
    });
  });

  group('thẻ quỹ hội', () {
    testWidgets('server cũ (không có quỹ): ẩn thẻ', (tester) async {
      await _open(tester, const GuildFund());
      expect(_k('guild-fund-card'), findsNothing);
      await _end(tester);
    });

    testWidgets('chưa đạt: hiện tiến độ, phần của mình, nút khoá', (tester) async {
      await _open(tester, const GuildFund(progress: 250, target: 500, mine: 40));
      expect(find.text('250 / 500 💎'), findsOneWidget);
      expect(find.text('Bạn đã góp 40 💎'), findsOneWidget);
      expect(tester.widget<LinearProgressIndicator>(_k('guild-fund-bar')).value, 0.5);
      expect(_claim(tester).onPressed, isNull);
      expect(find.text('Nhận $guildFundReward Xu Hội'), findsOneWidget);
      await _end(tester);
    });

    testWidgets('đạt + đã góp đủ + chưa nhận: nút bật; nhận → ví +thưởng, nút thành "Đã nhận"',
        (tester) async {
      final repo = await _open(
          tester, const GuildFund(progress: 600, target: 500, mine: guildFundMinDonation),
          wallet: 100);
      expect(_claim(tester).onPressed, isNotNull);
      await tester.tap(_k('guild-fund-claim'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('claimFund'));
      expect(repo.mine!.wallet, 100 + guildFundReward);
      expect(find.text('Đã nhận $guildFundReward Xu Hội từ quỹ hội!'), findsOneWidget);
      expect(_claim(tester).onPressed, isNull);
      expect(find.text('Đã nhận'), findsWidgets);
      await _end(tester);
    });

    testWidgets('đạt nhưng mình góp chưa đủ mức tối thiểu: nút khoá', (tester) async {
      await _open(tester,
          const GuildFund(progress: 600, target: 500, mine: guildFundMinDonation - 1));
      expect(_claim(tester).onPressed, isNull);
      await _end(tester);
    });

    testWidgets('đã nhận rồi: nút khoá', (tester) async {
      await _open(tester,
          const GuildFund(progress: 600, target: 500, mine: 99, claimed: true));
      expect(_claim(tester).onPressed, isNull);
      await _end(tester);
    });

    testWidgets('tiến độ vượt mục tiêu: thanh kẹp ở 100%, không văng', (tester) async {
      await _open(tester, const GuildFund(progress: 99999, target: 500, mine: 50));
      expect(tester.widget<LinearProgressIndicator>(_k('guild-fund-bar')).value, 1.0);
      await _end(tester);
    });

    testWidgets('server từ chối: báo đúng thông điệp, thẻ không đổi', (tester) async {
      final repo = await _open(
          tester, const GuildFund(progress: 600, target: 500, mine: 50));
      repo.failures['claimFund'] = const GuildException(GuildFailure.fundNotReached);
      await tester.tap(_k('guild-fund-claim'));
      await tester.pumpAndSettle();
      expect(find.text('Quỹ hội chưa đạt mục tiêu.'), findsOneWidget);
      expect(_claim(tester).onPressed, isNotNull);
      repo.failures['claimFund'] = const GuildException(GuildFailure.fundDonationLow);
      await tester.tap(_k('guild-fund-claim'));
      await tester.pumpAndSettle();
      expect(find.textContaining('góp ít nhất $guildFundMinDonation'), findsWidgets);
      await _end(tester);
    });

    for (final l in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
      testWidgets('[$l] 320px: số rất lớn trong thẻ quỹ không tràn', (tester) async {
        await _open(tester,
            const GuildFund(progress: 9999999999, target: 9999999999, mine: 999999999),
            locale: l, size: const Size(320, 640));
        expect(tester.takeException(), isNull);
        await _end(tester);
      });
    }
  });
}
