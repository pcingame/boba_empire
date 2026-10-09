// Cửa hàng hội + BXH hội 3 tab + phụ kiện hội trong Kho + dòng chuỗi/buff ở màn Hội.
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
import 'package:boba_empire/ui/accessory_inventory_page.dart';
import 'package:boba_empire/ui/guild_leaderboard_page.dart';
import 'package:boba_empire/ui/guild_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../guild/fake_guild_repository.dart';

final _now = DateTime.utc(2026, 10, 8).millisecondsSinceEpoch;

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

final _live = <ProviderContainer>[];

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (final c in _live) {
    c.dispose();
  }
  _live.clear();
}

void gTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      await _teardown(tester);
    }
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeGuildRepository repo, {
  String locale = 'vi',
  Widget home = const GuildPage(),
  double gems = 5000,
  double score = 0,
  Size size = const Size(360, 800),
  GameState? seed,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      seed ??
          (GameState.newGame(nowMillis: _now)
            ..gems = gems
            ..guildWeek = guildWeekIndex(_now)
            ..guildWeekScore = score),
      nowMillis: _now);
  final List<Override> overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => _now),
    guildRepositoryProvider.overrideWithValue(repo),
    flairCacheProvider.overrideWith(_Flair.new),
  ];
  final c = ProviderContainer(overrides: overrides);
  _live.add(c);
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
  return c;
}

/// Mở màn Hội rồi vào cửa hàng.
Future<ProviderContainer> _openShop(WidgetTester tester, FakeGuildRepository repo,
    {double gems = 5000, String locale = 'vi', Size size = const Size(360, 800)}) async {
  final c = await _pump(tester, repo, gems: gems, locale: locale, size: size);
  await tester.dragUntilVisible(find.byKey(const Key('guild-shop-button')),
      find.byType(ListView), const Offset(0, -150));
  await tester.tap(find.byKey(const Key('guild-shop-button')));
  await tester.pumpAndSettle();
  return c;
}

FilledButton _btn(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.byKey(Key(key)));

Future<void> _scrollTo(WidgetTester tester, String key) async {
  await tester.dragUntilVisible(
      find.byKey(Key(key)), find.byType(ListView), const Offset(0, -150));
  // dragUntilVisible dừng khi widget đã được dựng (vùng đệm cuộn), chưa chắc đã nằm trong màn.
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('màn Hội: chuỗi, buff, nút cửa hàng', () {
    gTest('hiện chuỗi tuần và buff còn lại khi có; ẩn khi không', (tester) async {
      await _pump(
          tester, FakeGuildRepository(mine: fakeGuild(streak: 3, buffSeconds: 5400)));
      expect(find.text('🔥 3 tuần liên tiếp đủ 3 mốc'), findsOneWidget);
      expect(find.textContaining('Buff hội +10%'), findsOneWidget);
      await _teardown(tester);
      await _pump(tester, FakeGuildRepository(mine: fakeGuild()));
      expect(find.byKey(const Key('guild-streak')), findsNothing);
      expect(find.byKey(const Key('guild-buff-line')), findsNothing);
    });

    gTest('nút cửa hàng hiện số Xu Hội và mở được trang cửa hàng', (tester) async {
      await _openShop(tester, FakeGuildRepository(mine: fakeGuild(wallet: 1234)));
      expect(find.byKey(const Key('guild-wallet')), findsOneWidget);
      expect(find.text('Xu Hội: 1234'), findsOneWidget);
    });
  });

  group('cửa hàng: nạp 💎', () {
    gTest('nút nạp chỉ bật khi đủ 💎 VÀ còn hạn mức ngày', (tester) async {
      await _openShop(tester, FakeGuildRepository(mine: fakeGuild()), gems: 60);
      expect(_btn(tester, 'guild-donate-10').onPressed, isNotNull);
      expect(_btn(tester, 'guild-donate-50').onPressed, isNotNull);
      expect(_btn(tester, 'guild-donate-100').onPressed, isNull, reason: '60 < 100 💎');
      expect(_btn(tester, 'guild-donate-500').onPressed, isNull);
      await _teardown(tester);

      await _openShop(
          tester, FakeGuildRepository(mine: fakeGuild(donatedToday: 995)),
          gems: 5000);
      for (final n in guildDonateChoices) {
        expect(_btn(tester, 'guild-donate-$n').onPressed, isNull,
            reason: 'còn 5 💎 hạn mức → mọi nút ≥ 10 đều khoá ($n)');
      }
    });

    gTest('nạp: trừ 💎, cộng ví, cập nhật "Hôm nay: x/1000", báo thành công', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild());
      final c = await _openShop(tester, repo, gems: 500);
      await tester.tap(find.byKey(const Key('guild-donate-50')));
      await tester.pumpAndSettle();
      expect(c.read(gameControllerProvider).gems, 450);
      expect(find.text('Xu Hội: 50'), findsOneWidget);
      expect(find.textContaining('Hôm nay: 50/1000'), findsOneWidget);
      expect(find.text('Đã nạp, nhận +50 Xu Hội'), findsOneWidget);
    });

    gTest('nạp lỗi (server báo hết hạn mức): thông báo đúng, không mất 💎', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild())
        ..failures['donate'] = const GuildException(GuildFailure.dailyLimit);
      final c = await _openShop(tester, repo, gems: 500);
      await tester.tap(find.byKey(const Key('guild-donate-10')));
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay bạn đã nạp tối đa 1000 💎.'), findsOneWidget);
      expect(c.read(gameControllerProvider).gems, 500);
    });
  });

  group('cửa hàng: nhiệm vụ tuần', () {
    gTest('nút nhận chỉ bật khi đủ điểm cá nhân; đã nhận hiện "Đã nhận"', (tester) async {
      final g = fakeGuild(questsClaimed: [1], members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 6000),
        GuildMemberInfo(userId: 'u2', nickname: 'Bob', points: 100),
      ]);
      await _openShop(tester, FakeGuildRepository(mine: g));
      await _scrollTo(tester, 'guild-quest-0');
      expect(find.text('Đã nhận'), findsOneWidget, reason: 'bậc 1 đã nhận');
      expect(_btn(tester, 'guild-quest-0').onPressed, isNull);
      expect(_btn(tester, 'guild-quest-1').onPressed, isNotNull, reason: '6000 ≥ 5000');
      expect(_btn(tester, 'guild-quest-2').onPressed, isNull, reason: '6000 < 20000');
    });

    gTest('nhận nhiệm vụ: ví tăng đúng thưởng, nút chuyển thành "Đã nhận"', (tester) async {
      final g = fakeGuild(members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 1500),
      ]);
      final repo = FakeGuildRepository(mine: g);
      await _openShop(tester, repo);
      await _scrollTo(tester, 'guild-quest-0');
      await tester.tap(find.byKey(const Key('guild-quest-0')));
      await tester.pumpAndSettle();
      expect(find.text('Nhận +${guildQuests[0].reward} Xu Hội'), findsOneWidget);
      expect(_btn(tester, 'guild-quest-0').onPressed, isNull);
      await _scrollTo(tester, 'guild-wallet').catchError((_) {});
      expect((repo.mine as MyGuild).wallet, guildQuests[0].reward);
    });
  });

  group('cửa hàng: phụ kiện và buff', () {
    gTest('mua phụ kiện: bật khi đủ Xu; mua xong hiện "Đã có" + cấp vào Kho', (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild(wallet: 600));
      final c = await _openShop(tester, repo);
      await _scrollTo(tester, 'guild-buy-guild_flag');
      expect(_btn(tester, 'guild-buy-guild_flag').onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('guild-buy-guild_flag')));
      await tester.pumpAndSettle();
      expect(find.text('Đã đổi! Phụ kiện nằm trong Kho.'), findsOneWidget);
      expect(c.read(gameControllerProvider).ownedLimited, ['guild_flag']);
      expect(_btn(tester, 'guild-buy-guild_flag').onPressed, isNull);
      expect(find.text('Đã có'), findsOneWidget);
      await _scrollTo(tester, 'guild-buy-guild_castle');
      expect(_btn(tester, 'guild-buy-guild_castle').onPressed, isNull, reason: '100 < 1500');
    });

    gTest('món đã có (khôi phục từ server) hiện "Đã có" và khoá', (tester) async {
      await _openShop(tester,
          FakeGuildRepository(mine: fakeGuild(wallet: 9999, ownedItems: ['guild_dragon'])));
      await _scrollTo(tester, 'guild-buy-guild_dragon');
      expect(_btn(tester, 'guild-buy-guild_dragon').onPressed, isNull);
    });

    gTest('mua buff: bật khi đủ Xu; mua xong hiện thời gian còn lại và bật buff cho game',
        (tester) async {
      final repo = FakeGuildRepository(mine: fakeGuild(wallet: 1000));
      final c = await _openShop(tester, repo);
      await _scrollTo(tester, 'guild-buy-buff');
      expect(find.byKey(const Key('guild-buff-left')), findsNothing);
      await tester.tap(find.byKey(const Key('guild-buy-buff')));
      await tester.pumpAndSettle();
      expect(find.text('Đã kích hoạt buff cho cả hội!'), findsOneWidget);
      await _scrollTo(tester, 'guild-buy-buff');
      expect(find.byKey(const Key('guild-buff-left')), findsOneWidget);
      expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
    });

    gTest('thiếu Xu → khoá nút mua buff; server báo "tối đa" → thông báo đúng', (tester) async {
      await _openShop(tester, FakeGuildRepository(mine: fakeGuild(wallet: 100)));
      await _scrollTo(tester, 'guild-buy-buff');
      expect(_btn(tester, 'guild-buy-buff').onPressed, isNull);
      await _teardown(tester);

      final repo = FakeGuildRepository(mine: fakeGuild(wallet: 5000))
        ..failures['buyBuff'] = const GuildException(GuildFailure.buffMaxed);
      await _openShop(tester, repo);
      await _scrollTo(tester, 'guild-buy-buff');
      await tester.tap(find.byKey(const Key('guild-buy-buff')));
      await tester.pumpAndSettle();
      expect(find.text('Buff của hội đã đạt mức tối đa, hãy chờ bớt.'), findsOneWidget);
    });
  });

  group('BXH hội 3 tab', () {
    const total = [
      GuildSummary(id: 'a', name: 'Alpha', tag: 'AL', emoji: '🐉',
          memberCount: 3, weekTotal: 900, rank: 1),
    ];
    const avg = [
      GuildSummary(id: 'b', name: 'Beta', tag: 'BE', emoji: '🧋',
          memberCount: 6, weekTotal: 60000, rank: 1, avgPoints: 10000),
    ];
    const streak = [
      GuildSummary(id: 'c', name: 'Gamma', tag: 'GA', emoji: '🔥',
          memberCount: 9, weekTotal: 5, rank: 1, streak: 4),
    ];

    gTest('mỗi tab hiện đúng chỉ số của nó và ghi chú', (tester) async {
      final repo = FakeGuildRepository()
        ..board = total
        ..boardAvg = avg
        ..boardStreak = streak;
      await _pump(tester, repo, home: const GuildLeaderboardPage());
      expect(find.text('900 điểm'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-lb-tab-avg')));
      await tester.pumpAndSettle();
      expect(find.text('10000/người'), findsOneWidget);
      expect(find.text('Chỉ tính hội từ 5 thành viên trở lên'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-lb-tab-streak')));
      await tester.pumpAndSettle();
      expect(find.text('4 tuần'), findsOneWidget);
      expect(find.text('Số tuần liên tiếp cả hội đạt đủ 3 mốc'), findsOneWidget);
    });

    gTest('tab rỗng hiện lời riêng của tab đó', (tester) async {
      await _pump(tester, FakeGuildRepository(), home: const GuildLeaderboardPage());
      expect(find.text('Tuần này chưa hội nào có điểm.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-lb-tab-avg')));
      await tester.pumpAndSettle();
      expect(find.text('Chưa hội nào đủ điều kiện xếp hạng trung bình.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-lb-tab-streak')));
      await tester.pumpAndSettle();
      expect(find.text('Chưa hội nào có chuỗi tuần.'), findsOneWidget);
    });

    gTest('một tab lỗi mạng không làm hỏng tab khác; thử lại được', (tester) async {
      final repo = FakeGuildRepository()
        ..board = total
        ..failures['leaderboardAvg'] = const GuildException(GuildFailure.network);
      await _pump(tester, repo, home: const GuildLeaderboardPage());
      expect(find.text('900 điểm'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guild-lb-tab-avg')));
      await tester.pumpAndSettle();
      expect(find.text('Không kết nối được, thử lại sau nhé.'), findsOneWidget);
      repo.boardAvg = avg;
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('10000/người'), findsOneWidget);
    });

    gTest('số rất lớn và tên rất dài không gây tràn ở màn 320px', (tester) async {
      final repo = FakeGuildRepository()
        ..board = const [
          GuildSummary(id: 'a', name: 'TênHộiDàiDằngDặcKhôngCóKhoảngTrắngNào', tag: 'ABCD',
              emoji: '🐉', memberCount: 30, weekTotal: 999999999, rank: 1),
        ];
      await _pump(tester, repo, home: const GuildLeaderboardPage(), size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });

  gTest('Kho: có mục phụ kiện hội; món đã đổi mở khoá, món chưa có thì khoá', (tester) async {
    final seed = GameState.newGame(nowMillis: _now)..ownedLimited.add('guild_flag');
    await _pump(tester, FakeGuildRepository(),
        home: const AccessoryInventoryPage(), size: const Size(400, 12800), seed: seed);
    expect(find.byKey(const Key('inventory-guild-section')), findsOneWidget);
    expect(find.text('Phụ kiện độc quyền của hội'), findsOneWidget);
    expect(find.text('Cờ hội'), findsOneWidget, reason: 'món sở hữu hiện tên');
    for (final a in guildAccessories) {
      // Món chưa có hiện "???" nên tên không lộ; món đã có hiện tên.
      if (a.id != 'guild_flag') expect(find.text(a.emoji), findsNothing);
    }
  });

  for (final locale in ['vi', 'en', 'pt', 'es', 'id', 'th', 'ko']) {
    gTest('[$locale] cửa hàng hội không tràn trên 320px (số lớn, mọi mục)', (tester) async {
      final g = fakeGuild(
        wallet: 99999999,
        donatedToday: 995,
        buffSeconds: 90000,
        streak: 12,
        members: const [
          GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 99999999),
        ],
      );
      await _openShop(tester, FakeGuildRepository(mine: g),
          gems: 99999999, locale: locale, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await tester.dragUntilVisible(find.byKey(const Key('guild-buy-buff')),
          find.byType(ListView), const Offset(0, -150));
      expect(tester.takeException(), isNull);
    });
  }
}
