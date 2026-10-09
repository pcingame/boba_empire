// QUÉT GIAO DIỆN: chụp mọi màn hình chính ở nhiều trạng thái (người mới, giữa game, số
// cực lớn, tên cực dài, sự kiện lễ hội, hội) để mắt người soát lệch/xấu/trống phụ kiện.
// Không phải ảnh store — chạy bằng dữ liệu GIẢ, không chạm Supabase thật.
//
//   SHOT_DIR=/đường/dẫn/ra flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/qa_sweep_test.dart -d <udid> --dart-define=SHOT_LOCALE=vi
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/cloud_save_controller.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/guild/guild_controller.dart';
import 'package:boba_empire/guild/guild_repository.dart';
import 'package:boba_empire/leaderboard/flair.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/market/market_highlight.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/guild/fake_guild_repository.dart';

const String kLocale = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'vi');

class _Market extends AccessoryMarketController {
  @override
  AccessoryMarketViewState build() {
    final t = DateTime.utc(2026, 10, 1);
    MarketListing l(String id, String item, int price) => MarketListing(
        id: id, sellerId: 's-$id', accessoryId: item, price: price, createdAt: t);
    return AccessoryMarketLoaded(
      listings: [l('1', 'dragon', 1800), l('2', 'cupcake', 25), l('3', 'phoenix', 3200)],
      myListings: const [],
      walletBalance: 540,
      myUserId: 'me',
      recentSales: const [RecentSale(accessoryId: 'galaxy', price: 4100)],
    );
  }

  @override
  Future<void> refresh({bool silent = false}) async {}
}

class _Cloud extends CloudSaveController {
  @override
  CloudSaveViewState build() => const CloudSaveUnlinked();
}

class _Flair extends FlairCache {
  @override
  Map<String, String> build() => {};
}

/// Một ngày thường (thứ 4) để không dính banner cuối tuần.
int _wednesday([int hour = 12]) {
  var d = DateTime.utc(2026, 10, 7, hour);
  return d.millisecondsSinceEpoch;
}

GameState _mid(int now) {
  final s = GameState.newGame(nowMillis: now)
    ..tutorialSeen = true
    ..starterPackClaimed = true
    ..collectionMilestonesClaimed.addAll([10, 25])
    ..ownedAccessories.addAll([
      for (var i = 0; i < accessories.length; i += 3) accessories[i].id,
      'dragon', 'phoenix', 'unicorn',
    ])
    ..ownedLimited.addAll(['bat', 'guild_flag'])
    ..equippedAccessories.addAll(['dragon', 'unicorn', 'phoenix'])
    ..m3HowToSeen = true
    ..stage = 6
    ..money = 4.2e9
    ..gems = 5400
    ..tapValue = 12
    ..lifetimeEarnings = 8.7e15
    ..prestigeStars = 1840
    ..storyChapter = 4
    ..m3Stars.addAll([3, 3, 2, 3, 1, 2])
    ..adsRemoved = true
    ..lastSeenMillis = now
    ..firstPlayedMillis = now
    ..lastDailyDay = now ~/ 86400000;
  for (final g in const ['tra_den', 'tra_sua', 'tran_chau', 'tra_trai_cay']) {
    s.levels[g] = 30;
  }
  return s;
}

GameState _whale(int now) {
  final s = _mid(now)
    ..stage = 12
    ..money = 5.5e77
    ..gems = 987654321
    ..lifetimeEarnings = 1.2e80
    ..prestigeStars = 1.5e20
    ..ascensionCount = 3;
  for (final id in s.levels.keys.toList()) {
    s.levels[id] = 999;
  }
  return s;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, [int frames = 16]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    debugPrint('SHOT $name');
    await binding.takeScreenshot('${kLocale}_$name');
  }

  Future<void> closeDialog(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).first);
    await settle(tester);
  }

  Future<void> dismissBlocking(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      if (find.byType(Dialog).evaluate().isEmpty) return;
      final btn = find.descendant(
          of: find.byType(Dialog), matching: find.byType(TextButton));
      if (btn.evaluate().isEmpty) return;
      await tester.tap(btn.first, warnIfMissed: false);
      await settle(tester);
    }
  }

  Future<ProviderContainer> launch(
    WidgetTester tester,
    GameState seed,
    int now, {
    FakeGuildRepository? guild,
    String version = '1.0.5',
  }) async {
    SharedPreferences.setMockInitialValues(
        {'flutter.app_locale': kLocale, 'flutter.market_intro_seen': true});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(seed, nowMillis: now);
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
      accessoryMarketControllerProvider.overrideWith(_Market.new),
      marketHighlightProvider.overrideWith((ref) async => null),
      cloudSaveControllerProvider.overrideWith(_Cloud.new),
      flairCacheProvider.overrideWith(_Flair.new),
      appVersionProvider.overrideWithValue(() async => version),
      if (guild != null) guildRepositoryProvider.overrideWithValue(guild),
    ]);
    await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    await settle(tester, 24);
    return c;
  }

  Future<void> end(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  }

  testWidgets('quét giao diện — $kLocale', (tester) async {
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;

    final now = _wednesday();
    final repo = FakeGuildRepository(
      listing: const [
        GuildSummary(id: 'a', name: 'Trà Sữa Bất Bại', tag: 'TSBB', emoji: '🐉',
            memberCount: 28, weekTotal: 123456),
        GuildSummary(id: 'b', name: 'Hội Quán Nhỏ Xinh Xắn Của Chúng Tôi', tag: 'HQ',
            emoji: '🧋', memberCount: 5, weekTotal: 9, requiresApproval: true),
        GuildSummary(id: 'c', name: 'Boba Club', tag: 'BC', emoji: '🔥',
            memberCount: 12, weekTotal: 777, requiresApproval: true, requested: true),
      ],
    )
      ..board = const [
        GuildSummary(id: 'a', name: 'Trà Sữa Bất Bại', tag: 'TSBB', emoji: '🐉',
            memberCount: 28, weekTotal: 123456, rank: 1),
        GuildSummary(id: 'b', name: 'Hội Quán Nhỏ Xinh Xắn Của Chúng Tôi', tag: 'HQ',
            emoji: '🧋', memberCount: 5, weekTotal: 99999999, rank: 2),
      ]
      ..boardAvg = const [
        GuildSummary(id: 'b', name: 'Hội Quán Nhỏ', tag: 'HQ', emoji: '🧋',
            memberCount: 6, weekTotal: 60000, rank: 1, avgPoints: 10000),
      ]
      ..boardStreak = const [
        GuildSummary(id: 'a', name: 'Trà Sữa Bất Bại', tag: 'TSBB', emoji: '🐉',
            memberCount: 28, weekTotal: 123456, rank: 1, streak: 7),
      ];

    // ===== A. Giữa game: màn chính + Kho + vòng quay + hộp thoại =====
    var c = await launch(tester, _mid(now), now, guild: repo);
    await dismissBlocking(tester);
    await shot(tester, 'A01_home');

    await tester.tap(find.byKey(const Key('collection-chip')));
    await shot(tester, 'A02_collection');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await shot(tester, 'A03_collection_festival');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -99999));
    await shot(tester, 'A04_collection_bottom_guild');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 99999));
    await settle(tester);

    await tester.tap(find.byKey(const Key('accessory-pack-button')));
    await shot(tester, 'A05_packs_wheel');
    await tester.tap(find.byKey(const Key('accessory-wheel-gems')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 900));
    }
    await shot(tester, 'A06_wheel_after_spin');
    await tester.tap(find.byKey(const Key('accessory-wheel-gems')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 900));
    }
    await shot(tester, 'A07_wheel_after_spin2');
    await closeDialog(tester);
    await back(tester);

    await tester.tap(find.byKey(const Key('daily-quests-chip')));
    await shot(tester, 'A08_daily_quests');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('rewards-chip')));
    await shot(tester, 'A09_rewards');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('prestige-button')));
    await shot(tester, 'A10_prestige');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('achievements-button')));
    await shot(tester, 'A11_achievements');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await shot(tester, 'A12_gemshop');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('settings-button')));
    await shot(tester, 'A13_settings');
    await tester.tap(find.byKey(const Key('how-to-play-button')));
    await shot(tester, 'A14_how_to_play');
    await closeDialog(tester);
    await closeDialog(tester);

    // ===== B. Hội: danh sách → của mình → cửa hàng → BXH =====
    repo.mine = null;
    await tester.tap(find.byKey(const Key('compete-button')));
    await shot(tester, 'B01_compete_hub');
    await tester.tap(find.byKey(const Key('compete-guild')));
    await shot(tester, 'B02_guild_list');
    await tester.tap(find.byKey(const Key('guild-create-button')));
    await shot(tester, 'B03_guild_create');
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    repo.mine = fakeGuild(
      name: 'Trà Sữa Bất Bại',
      tag: 'TSBB',
      emoji: '🐉',
      total: 56789,
      streak: 3,
      buffSeconds: 5400,
      wallet: 1234,
      donatedToday: 250,
      claimed: const [1],
      ownedItems: const ['guild_flag'],
      requiresApproval: true,
      requests: const [
        GuildJoinRequest(userId: 'r1', nickname: 'Người Xin Vào Tên Rất Dài Luôn'),
        GuildJoinRequest(userId: 'r2', nickname: 'Rin'),
      ],
      members: const [
        GuildMemberInfo(userId: 'me', nickname: 'Alice', points: 23456),
        GuildMemberInfo(userId: 'u2', nickname: 'Biệt Danh Cực Kỳ Dài Không Khoảng Trắng', points: 12345678),
        GuildMemberInfo(userId: 'u3', nickname: 'Cy', points: 0),
      ],
    );
    await back(tester);
    await tester.tap(find.byKey(const Key('compete-button')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('compete-guild')));
    await shot(tester, 'B04_guild_mine');
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await shot(tester, 'B05_guild_mine_scrolled');
    await tester.drag(find.byType(ListView).first, const Offset(0, 900));
    await settle(tester);
    await tester.tap(find.byKey(const Key('guild-shop-button')));
    await shot(tester, 'B06_guild_shop');
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await shot(tester, 'B07_guild_shop_scrolled');
    await back(tester);
    await tester.tap(find.byKey(const Key('guild-leaderboard-button')));
    await shot(tester, 'B08_guild_lb_total');
    await tester.tap(find.byKey(const Key('guild-lb-tab-avg')));
    await shot(tester, 'B09_guild_lb_avg');
    await tester.tap(find.byKey(const Key('guild-lb-tab-streak')));
    await shot(tester, 'B10_guild_lb_streak');
    await back(tester);
    await back(tester);

    // Trang Pearls (Ghép 3).
    await tester.tap(find.byKey(const Key('match3-button')));
    await shot(tester, 'B11_pearls_journey');
    await back(tester);
    await end(tester, c);

    // ===== C. Người mới: hướng dẫn tương tác =====
    home.debugAutoShowTutorial = true;
    c = await launch(tester, GameState.newGame(nowMillis: now), now, guild: repo);
    await dismissBlocking(tester);
    await shot(tester, 'C01_ftue_tap');
    for (var i = 0; i < 16; i++) {
      await tester.tap(find.byKey(const Key('tap-circle')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 60));
    }
    await shot(tester, 'C02_ftue_buy');
    await tester.tap(find.byKey(const Key('ftue-skip')).evaluate().isEmpty
        ? find.byType(FilledButton).last
        : find.byKey(const Key('ftue-skip')));
    await settle(tester);
    await shot(tester, 'C03_after_skip');
    await end(tester, c);
    home.debugAutoShowTutorial = false;

    // ===== D. Số cực lớn / tên dài (whale) =====
    c = await launch(tester, _whale(now), now, guild: repo);
    await dismissBlocking(tester);
    await shot(tester, 'D01_whale_home');
    await tester.tap(find.byKey(const Key('collection-chip')));
    await shot(tester, 'D02_whale_collection');
    await back(tester);
    await tester.tap(find.byKey(const Key('prestige-button')));
    await shot(tester, 'D03_whale_prestige');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('achievements-button')));
    await shot(tester, 'D04_whale_achievements');
    await closeDialog(tester);
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await shot(tester, 'D05_whale_gemshop');
    await closeDialog(tester);
    await end(tester, c);

    // ===== E. Lễ hội (Halloween) + banner sự kiện =====
    final halloween = DateTime.utc(2026, 10, 27, 12).millisecondsSinceEpoch;
    c = await launch(tester, _mid(halloween), halloween, guild: repo);
    await dismissBlocking(tester);
    await shot(tester, 'E01_festival_home');
    await tester.tap(find.byKey(const Key('event-banner')));
    await shot(tester, 'E02_festival_dialog');
    await closeDialog(tester);
    await end(tester, c);

    // ===== F. Popup mở app: offline / điểm danh / cốt truyện =====
    home.debugAutoShowDaily = true;
    home.debugAutoShowStory = true;
    final offlineSeed = _mid(now)
      ..lastDailyDay = now ~/ 86400000
      ..storyChapter = 4
      ..stage = 3
      ..lastSeenMillis = now - 3 * 3600 * 1000;
    c = await launch(tester, offlineSeed, now, guild: repo);
    await shot(tester, 'F01_offline_dialog');
    await end(tester, c);

    final dailySeed = _mid(now)..lastDailyDay = 0;
    c = await launch(tester, dailySeed, now, guild: repo);
    await shot(tester, 'F02_daily_reward');
    await end(tester, c);

    final storySeed = _mid(now)
      ..storyChapter = 5
      ..stage = 5;
    c = await launch(tester, storySeed, now, guild: repo);
    await shot(tester, 'F03_story_choice');
    await end(tester, c);
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;
  });
}
