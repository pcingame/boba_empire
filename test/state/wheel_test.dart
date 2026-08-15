import 'package:boba_empire/core/daily.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/wheel.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Clock = 2 ngày → dayIndex(now) = 2 > lastFreeSpinDay mặc định (0).
  const twoDaysMs = 2 * 24 * 60 * 60 * 1000;

  Future<ProviderContainer> makeContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // tra_den cấp 2 = 1 Xu/s → phần thưởng coins khác 0.
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
      nowMillis: 0,
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => twoDaysMs),
      ],
    );
    return container;
  }

  test('freeSpinAvailable true khi chưa quay hôm nay', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    expect(container.read(gameControllerProvider).freeSpinAvailable, isTrue);
  });

  test('spin(free:true) tiêu lượt free và ghi ngày quay', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.spin(free: true);

    expect(container.read(gameControllerProvider).freeSpinAvailable, isFalse);
    // Quay lại cùng ngày: đã tiêu → vẫn hết lượt free.
    ctrl.spin(free: true);
    expect(container.read(gameControllerProvider).freeSpinAvailable, isFalse);
  });

  test('spin(free:false) KHÔNG tiêu lượt free', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.spin(free: false);
    expect(container.read(gameControllerProvider).freeSpinAvailable, isTrue);
  });

  test(
    'mỗi lần quay: kind khớp ô trúng và đúng loại thưởng được cộng',
    () async {
      final container = await makeContainer();
      addTearDown(container.dispose);
      final ctrl = container.read(gameControllerProvider.notifier);

      final kinds = <WheelKind>{};
      // Quay nhiều lần để chạm đủ 3 nhánh (coins/gems/x2) và kiểm bất biến.
      for (var n = 0; n < 300; n++) {
        final beforeMoney = container.read(gameControllerProvider).money;
        final beforeGems = container.read(gameControllerProvider).gems;
        final beforeX2 = container
            .read(gameControllerProvider)
            .x2IncomeRemainingSeconds;

        final r = ctrl.spin(free: false);
        kinds.add(r.kind);

        expect(
          wheelPrizes[r.index].kind,
          r.kind,
          reason: 'kind trả về phải khớp ô trúng',
        );

        final money = container.read(gameControllerProvider).money;
        final gems = container.read(gameControllerProvider).gems;
        final x2 = container
            .read(gameControllerProvider)
            .x2IncomeRemainingSeconds;

        switch (r.kind) {
          case WheelKind.coins:
            expect(r.value, greaterThan(0));
            expect(money, greaterThan(beforeMoney));
            expect(gems, beforeGems);
          case WheelKind.gems:
            expect(r.value, greaterThan(0));
            expect(gems, greaterThan(beforeGems));
          case WheelKind.x2:
            expect(x2, greaterThan(beforeX2));
        }
      }

      // Với 300 lần quay, gần như chắc chắn chạm cả 3 loại.
      expect(kinds, containsAll(WheelKind.values));
    },
  );

  test('spin lưu ngày quay = dayIndex hiện tại', () async {
    final container = await makeContainer();
    addTearDown(container.dispose);
    container.read(gameControllerProvider.notifier).spin(free: true);
    // Không đọc trực tiếp state nội bộ được; kiểm gián tiếp qua snapshot.
    expect(container.read(gameControllerProvider).freeSpinAvailable, isFalse);
    expect(dayIndex(twoDaysMs), 2);
  });
}
