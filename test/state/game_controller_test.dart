import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_snapshot.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('không có save -> ván mới, tiền 0', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final snap = container.read(gameControllerProvider);
    expect(snap.money, 0);
    expect(snap.incomePerSecond, 0);
  });

  test('tapCup cộng tapValue vào snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    container.read(gameControllerProvider.notifier).tapCup();
    expect(container.read(gameControllerProvider).money, 1);
  });

  test('buy trừ tiền và tăng cấp; thiếu tiền thì thất bại', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..money = 20,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    expect(ctrl.buy('tra_den'), isTrue); // baseCost 15
    var snap = container.read(gameControllerProvider);
    expect(snap.money, closeTo(5, 1e-9));
    expect(snap.levelOf('tra_den'), 1);
    expect(snap.incomePerSecond, closeTo(0.5, 1e-9));

    expect(ctrl.buy('tra_den'), isFalse); // cấp 2 giá 17.25 > 5
    snap = container.read(gameControllerProvider);
    expect(snap.levelOf('tra_den'), 1);
  });

  test('buyBulk / buyMax mua nhiều cấp một lần', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..money = 100000,
      nowMillis: 0,
    );
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    expect(ctrl.buyBulk('tra_den', 10), 10);
    expect(container.read(gameControllerProvider).levelOf('tra_den'), 10);

    final maxed = ctrl.buyMax('tra_den');
    expect(maxed, greaterThan(0));
    expect(container.read(gameControllerProvider).levelOf('tra_den'), 10 + maxed);
    // Đã tiêu gần hết tiền — không mua thêm được cấp nào.
    expect(ctrl.buyMax('tra_den'), 0);
  });

  test('build tính tiền offline theo đồng hồ', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // tra_den cấp 2 = 1.0 Xu/s. Save lúc t=0.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 60000), // mở lại sau 60s
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(gameControllerProvider).money, closeTo(60, 1e-9));
  });

  test('saveNow persist để container sau load lại được', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.tapCup();
    ctrl.tapCup();
    ctrl.tapCup(); // money = 3
    await ctrl.saveNow();

    final reloaded = GameStorage(prefs).load();
    expect(reloaded, isNotNull);
    expect(reloaded!.money, 3);
  });

  test('resetGame xóa save và đưa tiền về 0', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..money = 500,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider).money, 500);
    await ctrl.resetGame();
    expect(container.read(gameControllerProvider).money, 0);
    expect(GameStorage(prefs).load(), isNull);
  });

  test('bản dư phụ kiện: bán/mua trừ-cộng bản dư trước, chỉ mất món khi hết dư',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..ownedAccessories.add('dragon')
        ..accessorySpares['dragon'] = 1,
      nowMillis: 0,
    );
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 0),
    ]);
    final ctrl = container.read(gameControllerProvider.notifier);
    GameSnapshot snap() => container.read(gameControllerProvider);

    ctrl.removeOwnedAccessoryLocally('dragon'); // bán bản dư
    expect(snap().ownedAccessories, ['dragon']);
    expect(snap().accessorySpares, isEmpty);

    ctrl.addOwnedAccessoryLocally('dragon'); // mua/huỷ đăng lại -> thành bản dư
    expect(snap().accessorySpares['dragon'], 1);

    ctrl.removeOwnedAccessoryLocally('dragon');
    ctrl.removeOwnedAccessoryLocally('dragon'); // hết dư -> bán nốt bản đầu
    expect(snap().ownedAccessories, isEmpty);

    container.dispose();
  });

  group('đổi Xu/💎 lấy Xu Chợ — Supabase chưa sẵn sàng trong test (fail-closed)', () {
    test('convertGemsToMarketCoins: thiếu 💎 -> false, không trừ gì', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..gems = 1,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      // 100 Xu Chợ cần 10 💎 (marketCoinsPerGem = 10), chỉ có 1 💎.
      expect(await ctrl.convertGemsToMarketCoins(100), isFalse);
      expect(container.read(gameControllerProvider).gems, 1);
    });

    test(
        'convertGemsToMarketCoins: đủ 💎 nhưng không nối được server -> false, '
        'KHÔNG được trừ 💎 (bug đã sửa: trước đây coi _market null là thành công)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..gems = 100,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      expect(await ctrl.convertGemsToMarketCoins(10), isFalse);
      expect(container.read(gameControllerProvider).gems, 100);
    });

    test('convertMoneyToMarketCoins: thu nhập/giây = 0 -> false, không trừ gì',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..money = 1000000,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      expect(await ctrl.convertMoneyToMarketCoins(10), isFalse);
      expect(container.read(gameControllerProvider).money, 1000000);
    });

    test(
        'convertMoneyToMarketCoins: đủ Xu nhưng không nối được server -> false, '
        'không trừ Xu', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..money = 1000000,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      expect(ctrl.buy('tra_den'), isTrue); // tạo thu nhập/giây > 0
      final before = container.read(gameControllerProvider).money;
      expect(await ctrl.convertMoneyToMarketCoins(1), isFalse);
      expect(container.read(gameControllerProvider).money, before);
    });

    test('convertMoneyToMarketCoins: chi phí tràn/không hữu hạn -> false, không trừ gì',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..money = double.maxFinite,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      expect(ctrl.buy('tra_den'), isTrue);
      final before = container.read(gameControllerProvider).money;
      expect(await ctrl.convertMoneyToMarketCoins(0), isFalse);
      expect(await ctrl.convertMoneyToMarketCoins(-5), isFalse);
      expect(await ctrl.convertMoneyToMarketCoins(1 << 62), isFalse);
      expect(container.read(gameControllerProvider).money, before);
    });

    test('convertGemsToMarketCoins: yêu cầu cực lớn -> false, không trừ 💎',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)..gems = 100,
        nowMillis: 0,
      );
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ]);
      addTearDown(container.dispose);

      final ctrl = container.read(gameControllerProvider.notifier);
      expect(await ctrl.convertGemsToMarketCoins(1 << 62), isFalse);
      expect(await ctrl.convertGemsToMarketCoins(-1), isFalse);
      expect(container.read(gameControllerProvider).gems, 100);
    });
  });
}
