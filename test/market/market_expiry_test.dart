// Tin đăng Chợ hết hạn sau 3 ngày: hằng số khớp SQL, tính thời gian còn lại, và máy người bán
// nhận lại món đúng một lần (thêm vào kho cục bộ rồi mới ack; lỗi mạng không làm hỏng Chợ).
import 'dart:io';

import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient _client;

class _Repo extends AccessoryMarketRepository {
  _Repo() : super(_client);
  List<({String listingId, String accessoryId})> back = [];
  bool failExpire = false;
  bool failAck = false;
  final acks = <List<String>>[];
  int expireCalls = 0;

  @override
  Future<List<({String listingId, String accessoryId})>> expireMyListings() async {
    expireCalls++;
    if (failExpire) throw Exception('mạng');
    return back;
  }

  @override
  Future<void> ackExpiredListings(List<String> listingIds) async {
    if (failAck) throw Exception('mạng');
    acks.add(listingIds);
  }

  @override
  Future<Map<String, int>> fetchServerCopies() async => {};
  @override
  Future<List<MarketListing>> fetchActiveListings({int limit = 50}) async => [];
  @override
  Future<List<MarketListing>> fetchMyActiveListings() async => [];
  @override
  Future<int> fetchWalletBalance() async => 0;
  @override
  Future<List<RecentSale>> fetchRecentSales({int limit = 10}) async => [];
}

Future<(AccessoryMarketController, _Repo, List<String>, List<int>)> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  final ctrl = c.read(accessoryMarketControllerProvider.notifier);
  final repo = _Repo();
  final added = <String>[];
  final notices = <int>[];
  ctrl
    ..debugRepo = repo
    ..onAccessoryAddedLocally = added.add
    ..onListingsExpired = notices.add;
  return (ctrl, repo, added, notices);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => _client = SupabaseClient('http://localhost', 'anon'));

  test('hạn 3 ngày khớp market_listing_days() trong SQL', () {
    final sql = File('supabase/accessory_market_schema.sql').readAsStringSync();
    expect(
        RegExp(r'function market_listing_days\(\) returns integer\s+language sql immutable as \$\$ select (\d+) \$\$')
            .firstMatch(sql)!
            .group(1),
        '$marketListingDays');
    expect(marketListingDays, 3);
  });

  test('MarketListing: hết hạn sau đúng 3 ngày; còn lại không âm', () {
    final t0 = DateTime.utc(2026, 10, 1, 12);
    final l = MarketListing(id: 'a', sellerId: 's', accessoryId: 'x', price: 1, createdAt: t0);
    expect(l.expiresAt, DateTime.utc(2026, 10, 4, 12));
    expect(l.remaining(t0), const Duration(days: 3));
    expect(l.remaining(t0.add(const Duration(days: 2, hours: 5))), const Duration(hours: 19));
    expect(l.remaining(t0.add(const Duration(days: 9))), Duration.zero);
  });

  test('món hết hạn: thêm vào kho cục bộ, ack đúng id, báo UI một lần', () async {
    final (ctrl, repo, added, notices) = await _setup();
    repo.back = [(listingId: 'l1', accessoryId: 'dragon'), (listingId: 'l2', accessoryId: 'dragon')];
    await ctrl.refresh(silent: true);
    expect(added, ['dragon', 'dragon']);
    expect(repo.acks.single, ['l1', 'l2']);
    expect(notices, [2]);
  });

  test('không có gì hết hạn: không ack, không báo', () async {
    final (ctrl, repo, added, notices) = await _setup();
    await ctrl.refresh(silent: true);
    expect(added, isEmpty);
    expect(repo.acks, isEmpty);
    expect(notices, isEmpty);
  });

  test('ack lỗi mạng: lần mở sau server trả lại cùng tin nhưng KHÔNG thêm món lần hai', () async {
    final (ctrl, repo, added, notices) = await _setup();
    repo.back = [(listingId: 'l1', accessoryId: 'dragon')];
    repo.failAck = true;
    await ctrl.refresh(silent: true);
    expect(added, ['dragon']);
    expect(repo.acks, isEmpty);
    repo.failAck = false;
    await ctrl.refresh(silent: true);
    expect(added, ['dragon'], reason: 'đã thêm trong phiên này');
    expect(repo.acks.single, ['l1'], reason: 'lần này ack được');
    expect(notices.length, lessThanOrEqualTo(1));
  });

  test('RPC lỗi (mạng / server cũ chưa có): nuốt im lặng, Chợ vẫn tải', () async {
    final (ctrl, repo, added, notices) = await _setup();
    repo.failExpire = true;
    await ctrl.refresh(silent: true);
    expect(repo.expireCalls, 1);
    expect(added, isEmpty);
    expect(notices, isEmpty);
  });
}
