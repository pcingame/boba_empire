// Trao đổi vật phẩm: hằng số khớp SQL, kho cục bộ đổi ĐÚNG (đưa đi/nhận về) và chỉ khi server xác nhận,
// nhận lại món theo hai pha (không thêm hai lần), lỗi server được dịch, server cũ không làm hỏng Chợ.
import 'dart:io';

import 'package:boba_empire/market/accessory_market_controller.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/accessory_swap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final SupabaseClient _client;

AccessorySwap _swap(String id, {String give = 'dragon', String want = 'cupcake', String seller = 'other'}) =>
    AccessorySwap(id: id, sellerId: seller, giveId: give, wantId: want, createdAt: DateTime.utc(2026, 10, 12));

class _Repo extends AccessoryMarketRepository {
  _Repo() : super(_client);
  Object? createError;
  Object? acceptError;
  Object? cancelError;
  bool failSwapFetch = false;
  bool failCollect = false;
  bool failAck = false;
  List<SwapPickup> pickups = [];
  final created = <(String, String)>[];
  final accepted = <String>[];
  final cancelled = <String>[];
  final acks = <List<String>>[];

  @override
  Future<String> createSwap(String giveId, String wantId) async {
    if (createError != null) throw createError!;
    created.add((giveId, wantId));
    return 'new-id';
  }

  @override
  Future<void> acceptSwap(String swapId) async {
    if (acceptError != null) throw acceptError!;
    accepted.add(swapId);
  }

  @override
  Future<void> cancelSwap(String swapId) async {
    if (cancelError != null) throw cancelError!;
    cancelled.add(swapId);
  }

  @override
  Future<List<SwapPickup>> collectSwaps() async {
    if (failCollect) throw Exception('mạng');
    return pickups;
  }

  @override
  Future<void> ackSwaps(List<String> ids) async {
    if (failAck) throw Exception('mạng');
    acks.add(ids);
  }

  @override
  Future<List<AccessorySwap>> fetchOpenSwaps({int limit = 50}) async {
    if (failSwapFetch) throw PostgrestException(message: 'relation does not exist');
    return [_swap('s1')];
  }

  @override
  Future<List<AccessorySwap>> fetchMyOpenSwaps() async {
    if (failSwapFetch) throw PostgrestException(message: 'relation does not exist');
    return [];
  }

  @override
  String? get currentUserId => 'me';
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

Future<(AccessoryMarketController, _Repo, List<String>, List<String>, List<int>)> _setup() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  final ctrl = c.read(accessoryMarketControllerProvider.notifier);
  final repo = _Repo();
  final added = <String>[];
  final removed = <String>[];
  final notices = <int>[];
  ctrl
    ..debugRepo = repo
    ..onAccessoryAddedLocally = added.add
    ..onAccessoryRemovedLocally = removed.add
    ..onSwapsCollected = notices.add;
  return (ctrl, repo, added, removed, notices);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => _client = SupabaseClient('http://localhost', 'anon', authOptions: const AuthClientOptions(autoRefreshToken: false)));

  group('khớp SQL', () {
    final sql = File('supabase/accessory_swap_schema.sql').readAsStringSync();
    test('giới hạn đề nghị mở', () {
      expect(RegExp(r'function swap_max_open\(\) returns integer\s+language sql immutable as \$\$ select (\d+) \$\$')
          .firstMatch(sql)!
          .group(1), '$swapMaxOpen');
    });
    test('hạn đề nghị dùng chung market_listing_days với tin đăng', () {
      expect(sql, contains('make_interval(days => market_listing_days())'));
      expect(marketDaysForSwap, marketListingDays);
    });
    test('RPC cấp quyền cho authenticated, khoá anon; quét nội bộ khoá hẳn', () {
      for (final f in ['swap_create(text, text)', 'swap_cancel(uuid)', 'swap_accept(uuid)', 'swap_collect()', 'swap_ack(uuid[])']) {
        expect(sql, contains('grant execute on function $f to authenticated'), reason: f);
        expect(sql, contains('revoke all on function $f from public, anon'), reason: f);
      }
      expect(sql, contains('revoke all on function swap_sweep(uuid) from public, anon, authenticated'));
    });
  });

  group('tạo đề nghị', () {
    test('thành công: món đưa rời kho cục bộ; không thêm gì', () async {
      final (ctrl, repo, added, removed, _) = await _setup();
      expect(await ctrl.createSwap('dragon', 'cupcake'), isNull);
      expect(repo.created, [('dragon', 'cupcake')]);
      expect(removed, ['dragon']);
      expect(added, isEmpty);
    });

    test('server từ chối: KHÔNG đổi kho cục bộ; lỗi được dịch', () async {
      final (ctrl, repo, added, removed, _) = await _setup();
      for (final (msg, want) in [
        ('not_owned', SwapError.notOwned),
        ('too_many_swaps', SwapError.tooMany),
        ('invalid_swap', SwapError.invalid),
      ]) {
        repo.createError = PostgrestException(message: msg);
        expect(await ctrl.createSwap('dragon', 'cupcake'), want, reason: msg);
      }
      repo.createError = Exception('mạng');
      expect(await ctrl.createSwap('dragon', 'cupcake'), SwapError.network);
      expect(removed, isEmpty);
      expect(added, isEmpty);
    });
  });

  group('nhận đề nghị', () {
    test('thành công: mất món họ cần, được món họ đưa', () async {
      final (ctrl, repo, added, removed, _) = await _setup();
      expect(await ctrl.acceptSwap(_swap('s1')), isNull);
      expect(repo.accepted, ['s1']);
      expect(removed, ['cupcake']);
      expect(added, ['dragon']);
    });

    test('lỗi: không đổi kho; "not_owned_want" khác "not_owned"', () async {
      final (ctrl, repo, added, removed, _) = await _setup();
      for (final (msg, want) in [
        ('not_owned_want', SwapError.notOwnedWant),
        ('swap_not_open', SwapError.notOpen),
        ('cannot_accept_own_swap', SwapError.ownSwap),
      ]) {
        repo.acceptError = PostgrestException(message: msg);
        expect(await ctrl.acceptSwap(_swap('s1')), want, reason: msg);
      }
      expect(removed, isEmpty);
      expect(added, isEmpty);
      // Đường lỗi để lại refresh() chạy nền: chờ nó xong trước khi dispose (cùng lý do ở test analytics).
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  group('huỷ đề nghị', () {
    test('thành công: món ký quỹ về kho cục bộ', () async {
      final (ctrl, repo, added, removed, _) = await _setup();
      expect(await ctrl.cancelSwap(_swap('s2', seller: 'me')), isNull);
      expect(repo.cancelled, ['s2']);
      expect(added, ['dragon']);
      expect(removed, isEmpty);
    });

    test('đề nghị vừa được nhận: lỗi swap_not_open, kho không đổi', () async {
      final (ctrl, repo, added, _, _) = await _setup();
      repo.cancelError = PostgrestException(message: 'swap_not_open');
      expect(await ctrl.cancelSwap(_swap('s2', seller: 'me')), SwapError.notOpen);
      expect(added, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  group('nhận lại món (hai pha)', () {
    test('done → thêm món đổi được; expired → thêm món bị trả lại; ack đủ id; báo UI', () async {
      final (ctrl, repo, added, _, notices) = await _setup();
      repo.pickups = [
        const SwapPickup(id: 'a', expired: false, accessoryId: 'cupcake'),
        const SwapPickup(id: 'b', expired: true, accessoryId: 'dragon'),
      ];
      await ctrl.refresh(silent: true);
      expect(added, ['cupcake', 'dragon']);
      expect(repo.acks.single, ['a', 'b']);
      expect(notices, [2]);
    });

    test('ack lỗi mạng: lần mở sau trả lại cùng id nhưng KHÔNG thêm món lần hai', () async {
      final (ctrl, repo, added, _, _) = await _setup();
      repo.pickups = [const SwapPickup(id: 'a', expired: false, accessoryId: 'cupcake')];
      repo.failAck = true;
      await ctrl.refresh(silent: true);
      expect(added, ['cupcake']);
      repo.failAck = false;
      await ctrl.refresh(silent: true);
      expect(added, ['cupcake']);
      expect(repo.acks.single, ['a']);
    });

    test('RPC lỗi (mạng / server cũ): nuốt im lặng', () async {
      final (ctrl, repo, added, _, notices) = await _setup();
      repo.failCollect = true;
      await ctrl.refresh(silent: true);
      expect(added, isEmpty);
      expect(notices, isEmpty);
    });
  });

  group('tải Chợ', () {
    test('có đề nghị của người khác và của mình', () async {
      final (ctrl, _, _, _, _) = await _setup();
      await ctrl.refresh(silent: true);
      final view = ctrl.state as AccessoryMarketLoaded;
      expect(view.swaps.map((s) => s.id), ['s1']);
      expect(view.mySwaps, isEmpty);
    });

    test('server cũ chưa có bảng: đề nghị rỗng, Chợ (tin đăng) vẫn tải được', () async {
      final (ctrl, repo, _, _, _) = await _setup();
      repo.failSwapFetch = true;
      await ctrl.refresh(silent: true);
      final view = ctrl.state;
      expect(view, isA<AccessoryMarketLoaded>());
      expect((view as AccessoryMarketLoaded).swaps, isEmpty);
      expect(view.mySwaps, isEmpty);
    });
  });
}
