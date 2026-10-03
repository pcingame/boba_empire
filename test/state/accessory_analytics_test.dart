/// Sự kiện analytics của Chợ/Sưu tập: đúng tên, đúng props, không PII, và chỉ
/// ghi khi hành động THÀNH CÔNG.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/analytics_repository.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient _client;

class _Rec extends AnalyticsRepository {
  _Rec(SharedPreferences prefs) : super(_client, prefs);
  final events = <(String, Map<String, dynamic>)>[];
  @override
  Future<void> log(String event, [Map<String, dynamic> props = const {}]) async =>
      events.add((event, props));
  Iterable<Map<String, dynamic>> of(String e) =>
      events.where((x) => x.$1 == e).map((x) => x.$2);
}

class _MarketRepo extends AccessoryMarketRepository {
  _MarketRepo() : super(_client);
  bool fail = false;
  @override
  Future<String> listAccessory(String accessoryId, int price) async {
    if (fail) throw Exception('boom');
    return 'id';
  }

  @override
  Future<void> buyListing(String listingId) async {
    if (fail) throw Exception('boom');
  }

  @override
  Future<Map<String, int>> fetchServerCopies() async => {};
  @override
  Future<void> registerDrop(String accessoryId, {int copies = 1}) async {}
  @override
  Future<int> claimCollectionMilestone(int milestone) async => 20;
  @override
  Future<void> claimStarterPack(String accessoryId, int stage) async {}
  @override
  Future<List<MarketListing>> fetchActiveListings({int limit = 50}) async => [];
  @override
  Future<List<MarketListing>> fetchMyActiveListings() async => [];
  @override
  Future<int> fetchWalletBalance() async => 0;
  @override
  Future<List<RecentSale>> fetchRecentSales({int limit = 10}) async => [];
}

Future<(ProviderContainer, GameController, _Rec)> _setup(GameState seed,
    {int clockMs = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => clockMs),
  ]);
  addTearDown(c.dispose);
  final ctrl = c.read(gameControllerProvider.notifier);
  final rec = _Rec(prefs);
  ctrl.debugAnalytics = rec;
  ctrl.debugMarketRepo = _MarketRepo();
  return (c, ctrl, rec);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => _client = SupabaseClient('http://localhost', 'anon'));

  test('Kỷ Nguyên: accessory_dropped source=ascension, epic/legendary', () async {
    final (_, ctrl, rec) = await _setup(GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = Balance.ascensionMinLifetime * 100
      ..prestigeStars = 1000
      ..stage = 18);
    ctrl.doAscend();
    final e = rec.of('accessory_dropped').single;
    expect(e['source'], 'ascension');
    expect(['epic', 'legendary'], contains(e['rarity']));
    expect(accessories.any((a) => a.id == e['accessory']), isTrue);
    expect(e['isNew'], isTrue);
  });

  test('mốc Ghép 3 lần đầu: source=match3; chơi lại không ghi thêm', () async {
    final (_, ctrl, rec) = await _setup(
        GameState.newGame(nowMillis: 0)..m3Stars.addAll(List.filled(9, 3)));
    ctrl.grantMatch3Result(10, 1);
    ctrl.grantMatch3Result(10, 3);
    final e = rec.of('accessory_dropped').single;
    expect(e['source'], 'match3');
    expect(e['rarity'], 'rare');
  });

  test('vòng quay: mỗi ô rương ghi đúng 1 sự kiện source=wheel', () async {
    final (_, ctrl, rec) = await _setup(GameState.newGame(nowMillis: 0));
    var chests = 0;
    for (var i = 0; i < 300; i++) {
      if (ctrl.spin(free: false).drop != null) chests++;
    }
    expect(rec.of('accessory_dropped').length, chests);
    expect(rec.of('accessory_dropped').every((e) => e['source'] == 'wheel'),
        isTrue);
  });

  test('accessory_dropped ghi cờ weekend theo đồng hồ (T7 true, T5 false)',
      () async {
    final sat = DateTime.utc(2026, 10, 3, 12).millisecondsSinceEpoch;
    final (_, a, recA) =
        await _setup(GameState.newGame(nowMillis: 0), clockMs: sat);
    final (_, b, recB) = await _setup(GameState.newGame(nowMillis: 0));
    for (var i = 0; i < 300; i++) {
      a.spin(free: false);
      b.spin(free: false);
    }
    expect(recA.of('accessory_dropped').isNotEmpty, isTrue);
    expect(recA.of('accessory_dropped').every((e) => e['weekend'] == true), isTrue);
    expect(recB.of('accessory_dropped').every((e) => e['weekend'] == false), isTrue);
  });

  test('mốc sưu tập và Gói Khởi Nghiệp: ghi khi thành công', () async {
    final (_, ctrl, rec) = await _setup(GameState.newGame(nowMillis: 0)
      ..stage = 3
      ..dailyQuestEverClaimed = true
      ..ownedAccessories.addAll(accessories.take(10).map((a) => a.id)));
    await ctrl.claimCollectionMilestone(10);
    await ctrl.claimMarketStarter();
    expect(rec.of('collection_milestone').single,
        {'milestone': 10, 'coins': 20});
    expect(rec.of('starter_pack_claimed').length, 1);
  });

  test('Chợ: listing_created / trade_done chỉ ghi khi thành công', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _MarketRepo();
    final market = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(market.dispose);
    final ctrl = market.read(accessoryMarketControllerProvider.notifier);
    final events = <(String, Map<String, dynamic>)>[];
    ctrl.onEvent = (e, p) => events.add((e, p));
    ctrl.debugRepo = repo;

    repo.fail = true;
    await ctrl.listItem('dragon', 500);
    await ctrl.buyItem(MarketListing(
        id: 'l',
        sellerId: 's',
        accessoryId: 'dragon',
        price: 500,
        createdAt: DateTime.utc(2026)));
    expect(events, isEmpty);

    repo.fail = false;
    await ctrl.listItem('dragon', 500);
    await ctrl.buyItem(MarketListing(
        id: 'l',
        sellerId: 's',
        accessoryId: 'angel_wing',
        price: 77,
        createdAt: DateTime.utc(2026)));
    expect(events.map((e) => e.$1), ['listing_created', 'trade_done']);
    expect(events[0].$2, {'accessory': 'dragon', 'price': 500});
    expect(events[1].$2, {'accessory': 'angel_wing', 'price': 77});
    // buyItem để lại refresh() chạy nền (finally): chờ nó xong trước khi dispose.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
}
