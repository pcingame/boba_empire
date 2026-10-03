/// Nhận Gói Khởi Nghiệp / thưởng mốc sưu tập với server giả: thành công, đã
/// nhận, hết trần, mất mạng, bấm đúp — không được cấp đôi, không được mất tiến
/// độ khi lỗi mạng.
library;

import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/market/accessory_market_repository.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRepo extends AccessoryMarketRepository {
  _FakeRepo() : super(SupabaseClient('http://localhost', 'anon'));

  /// Lỗi ném ra ở lần gọi claim kế tiếp (null = thành công).
  Object? starterError;
  Object? milestoneError;
  int starterCalls = 0;
  int milestoneCalls = 0;
  int milestoneCoins = 20;
  final registered = <String, int>{};
  Map<String, int> serverCopies = {};
  Future<void>? gate; // giữ lời gọi lại để mô phỏng bấm đúp

  @override
  Future<Map<String, int>> fetchServerCopies() async => serverCopies;

  @override
  Future<void> registerDrop(String accessoryId, {int copies = 1}) async {
    registered[accessoryId] = copies;
  }

  @override
  Future<void> claimStarterPack(String accessoryId, int stage) async {
    starterCalls++;
    final g = gate;
    if (g != null) await g;
    final e = starterError;
    if (e != null) throw e;
    // Server thật chỉ cho nhận 1 lần.
    starterError = Exception('already_claimed');
  }

  @override
  Future<int> claimCollectionMilestone(int milestone) async {
    milestoneCalls++;
    final g = gate;
    if (g != null) await g;
    final e = milestoneError;
    if (e != null) throw e;
    milestoneError = Exception('already_claimed');
    return milestoneCoins;
  }
}

Future<(ProviderContainer, GameController, _FakeRepo)> _setup(
    GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => 0),
  ]);
  addTearDown(c.dispose);
  final ctrl = c.read(gameControllerProvider.notifier);
  final repo = _FakeRepo();
  ctrl.debugMarketRepo = repo;
  return (c, ctrl, repo);
}

GameState _eligible() => GameState.newGame(nowMillis: 0)
  ..stage = 3
  ..dailyQuestEverClaimed = true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gói Khởi Nghiệp', () {
    test('thành công: cấp món + 1 bản dư, đánh dấu đã nhận, ẩn thẻ', () async {
      final (c, ctrl, repo) = await _setup(_eligible());
      expect(c.read(gameControllerProvider).starterPackReady, isTrue);
      expect(await ctrl.claimMarketStarter(), isNull);
      final s = c.read(gameControllerProvider);
      expect(repo.starterCalls, 1);
      expect(s.ownedAccessories.length, 1);
      expect(s.accessorySpares.values.single, 1);
      expect(s.starterPackReady, isFalse);
    });

    test('nhận lần 2: không gọi server, không cấp thêm', () async {
      final (c, ctrl, repo) = await _setup(_eligible());
      await ctrl.claimMarketStarter();
      expect(await ctrl.claimMarketStarter(), 'not_eligible');
      expect(repo.starterCalls, 1);
      expect(c.read(gameControllerProvider).ownedAccessories.length, 1);
    });

    test('server báo already_claimed: ẩn thẻ, KHÔNG cấp gì', () async {
      final (c, ctrl, repo) = await _setup(_eligible());
      repo.starterError = Exception('already_claimed');
      expect(await ctrl.claimMarketStarter(), 'already_claimed');
      final s = c.read(gameControllerProvider);
      expect(s.starterPackReady, isFalse);
      expect(s.ownedAccessories, isEmpty);
    });

    test('hết trần ngày / mất mạng: không cấp, vẫn đủ điều kiện để thử lại',
        () async {
      final (c, ctrl, repo) = await _setup(_eligible());
      repo.starterError = Exception('daily_cap');
      expect(await ctrl.claimMarketStarter(), 'daily_cap');
      repo.starterError = Exception('SocketException: no route');
      expect(await ctrl.claimMarketStarter(), 'network');
      final s = c.read(gameControllerProvider);
      expect(s.ownedAccessories, isEmpty);
      expect(s.starterPackReady, isTrue);
      repo.starterError = null;
      expect(await ctrl.claimMarketStarter(), isNull); // thử lại được
    });

    test('chưa đủ giai đoạn: không gọi server', () async {
      final (_, ctrl, repo) = await _setup(_eligible()..stage = 2);
      expect(await ctrl.claimMarketStarter(), 'not_eligible');
      expect(repo.starterCalls, 0);
    });

    test('bấm đúp lúc đang chờ server: chỉ cấp MỘT lần', () async {
      final (c, ctrl, repo) = await _setup(_eligible());
      final gate = Future<void>.delayed(const Duration(milliseconds: 20));
      repo.gate = gate;
      final results = await Future.wait(
          [ctrl.claimMarketStarter(), ctrl.claimMarketStarter()]);
      expect(results.where((r) => r == null).length, 1);
      final s = c.read(gameControllerProvider);
      expect(s.ownedAccessories.length, 1);
      expect(s.accessorySpares.values.single, 1);
    });
  });

  group('Mốc sưu tập', () {
    GameState seed(int owned) => GameState.newGame(nowMillis: 0)
      ..ownedAccessories.addAll(accessories.take(owned).map((a) => a.id));

    test('thành công: trả Xu Chợ, đánh dấu đã nhận, bù món local lên server',
        () async {
      final (c, ctrl, repo) = await _setup(seed(10));
      repo.serverCopies = {accessories.first.id: 1}; // server thiếu 9 món
      final r = await ctrl.claimCollectionMilestone(10);
      expect(r.coins, 20);
      expect(r.error, isNull);
      expect(repo.registered.length, 9);
      expect(c.read(gameControllerProvider).collectionMilestonesClaimed, [10]);
    });

    test('chưa đạt mốc: không gọi server', () async {
      final (_, ctrl, repo) = await _setup(seed(9));
      final r = await ctrl.claimCollectionMilestone(10);
      expect(r.error, 'not_reached');
      expect(repo.milestoneCalls, 0);
    });

    test('mốc không tồn tại (id lạ): không ném, không gọi server', () async {
      final (_, ctrl, repo) = await _setup(seed(50));
      final r = await ctrl.claimCollectionMilestone(7);
      expect(r.error, 'not_reached');
      expect(repo.milestoneCalls, 0);
    });

    test('mất mạng: KHÔNG đánh dấu đã nhận (thử lại được)', () async {
      final (c, ctrl, repo) = await _setup(seed(10));
      repo.milestoneError = Exception('timeout');
      expect((await ctrl.claimCollectionMilestone(10)).error, 'network');
      expect(c.read(gameControllerProvider).collectionMilestonesClaimed,
          isEmpty);
      repo.milestoneError = null;
      expect((await ctrl.claimCollectionMilestone(10)).coins, 20);
    });

    test('server báo already_claimed: đánh dấu cục bộ để ẩn nút', () async {
      final (c, ctrl, repo) = await _setup(seed(10));
      repo.milestoneError = Exception('already_claimed');
      expect((await ctrl.claimCollectionMilestone(10)).error,
          'already_claimed');
      expect(c.read(gameControllerProvider).collectionMilestonesClaimed, [10]);
    });

    test('bấm đúp: chỉ một lần nhận được Xu Chợ', () async {
      final (c, ctrl, repo) = await _setup(seed(10));
      repo.gate = Future<void>.delayed(const Duration(milliseconds: 20));
      final r = await Future.wait([
        ctrl.claimCollectionMilestone(10),
        ctrl.claimCollectionMilestone(10),
      ]);
      expect(r.where((x) => x.coins != null).length, 1);
      expect(c.read(gameControllerProvider).collectionMilestonesClaimed, [10]);
    });
  });

  test('save hỏng ở các trường mới KHÔNG làm mất cả save', () {
    final base = GameState.newGame(nowMillis: 0).toJson();
    final r = GameState.fromJson({
      ...base,
      'collectionMilestonesClaimed': 'oops',
      'wishlist': {'a': 1},
      'starterPackClaimed': 'yes',
      'dailyQuestEverClaimed': 3,
      'equippedAccessories': [1, null, 'x'],
    });
    expect(r.collectionMilestonesClaimed, isEmpty);
    expect(r.wishlist, isEmpty);
    expect(r.starterPackClaimed, isFalse);
    expect(r.dailyQuestEverClaimed, isFalse);
    expect(r.equippedAccessories, ['x']);
  });
}
