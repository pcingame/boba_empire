import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Container với đồng hồ điều khiển được và save có sẵn.
Future<(ProviderContainer, void Function(int) setNow)> _harness(
  GameState seed,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 0;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ],
  );
  return (container, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('activateGoldenRush không làm gì khi chưa có mèo', () async {
    final (container, _) = await _harness(GameState.newGame(nowMillis: 0));
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.activateGoldenRush(); // chưa spawn mèo
    expect(container.read(gameControllerProvider).boostRemainingSeconds, 0);
  });

  test('chạm mèo → boost x3, thu nhập nhân 3 rồi hết hạn về base', () async {
    // tra_den cấp 2 = 1.0 Xu/s base.
    final (container, setNow) = await _harness(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
    );
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnCat();
    expect(container.read(gameControllerProvider).catVisible, isTrue);

    ctrl.activateGoldenRush(); // boost tới t=120000
    var snap = container.read(gameControllerProvider);
    expect(snap.catVisible, isFalse);
    expect(snap.boostRemainingSeconds, closeTo(120, 1e-9));
    expect(snap.incomePerSecond, closeTo(3, 1e-9)); // 1.0 * x3

    // 1 giây trong lúc boost → +3 Xu.
    setNow(1000);
    ctrl.debugTick();
    expect(container.read(gameControllerProvider).money, closeTo(3, 1e-9));

    // Sau khi boost hết hạn: thêm 10s ở nhịp base (1 Xu/s).
    setNow(130000);
    ctrl.debugTick(); // dt lớn, nhưng lúc này boost đã tắt
    snap = container.read(gameControllerProvider);
    expect(snap.boostRemainingSeconds, 0);
    expect(snap.incomePerSecond, closeTo(1, 1e-9)); // trở lại base
  });

  test('boost sống sót qua "kill app giữa buff" (persist boostUntilMillis)',
      () async {
    // tra_den cấp 2 = 1.0 Xu/s base.
    final (container, setNow) = await _harness(
      GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2,
    );
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnCat();
    ctrl.activateGoldenRush(); // boost tới t=120000, đã lưu ngay
    setNow(5000); // 5s sau, vẫn trong buff

    // Giả lập "kill app": dựng GameController MỚI, cùng đồng hồ đang chạy,
    // cùng storage (đã lưu khi activateGoldenRush) — như mở lại app.
    final freshContainer = ProviderContainer(
      overrides: [
        sharedPreferencesProvider
            .overrideWithValue(container.read(sharedPreferencesProvider)),
        clockProvider.overrideWithValue(() => 5000),
      ],
    );
    addTearDown(freshContainer.dispose);
    final snap = freshContainer.read(gameControllerProvider);

    // Trước fix: boostUntilMillis chỉ ở runtime, ván mới sẽ mất buff → 0/1.0.
    // Sau fix: đọc lại đúng boostUntilMillis đã lưu, còn ~115s và ×3.
    expect(snap.boostRemainingSeconds, closeTo(115, 1e-9));
    expect(snap.incomePerSecond, closeTo(3, 1e-9));
  });

  test('mèo tự biến mất sau catLinger nếu không chạm', () async {
    final (container, setNow) = await _harness(GameState.newGame(nowMillis: 0));
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    ctrl.debugSpawnCat();
    setNow(20000); // > catLingerMs (12s)
    ctrl.debugTick();
    expect(container.read(gameControllerProvider).catVisible, isFalse);
  });
}
