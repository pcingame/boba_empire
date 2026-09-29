// Sự kiện giới hạn thời gian (Remote Config) phải thật sự nhân vào thu nhập
// sống (tap + thu nhập/giây), không chỉ tính đúng ở hàm thuần
// eventMultiplierAt() (đã kiểm riêng trong economy_test.dart) — file này kiểm
// đường dây thật từ Balance.event* tới GameSnapshot.
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(int) setNow)> _harness(
  GameState seed,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 0;
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  return (container, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Balance.event* là static toàn cục (mô phỏng Remote Config) — PHẢI trả
  // lại giá trị gốc sau mỗi ca, nếu không rò rỉ sang test khác chạy cùng tiến
  // trình (đúng lớp lỗi remote_balance_test.dart đã có sẵn 1 ca kiểm riêng).
  late double origMult, origStart, origEnd;
  setUp(() {
    origMult = Balance.eventIncomeMult;
    origStart = Balance.eventStartMillis;
    origEnd = Balance.eventEndMillis;
  });
  tearDown(() {
    Balance.eventIncomeMult = origMult;
    Balance.eventStartMillis = origStart;
    Balance.eventEndMillis = origEnd;
  });

  test('chưa cấu hình sự kiện: thu nhập không đổi, eventActive false', () async {
    final (container, _) =
        await _harness(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2);
    addTearDown(container.dispose);
    final snap = container.read(gameControllerProvider);
    expect(snap.eventActive, isFalse);
    expect(snap.eventRemainingSeconds, 0);
    expect(snap.incomePerSecond, closeTo(1.0, 1e-9)); // tra_den cấp 2 base
  });

  test('trong cửa sổ sự kiện: thu nhập nhân đúng hệ số, hết cửa sổ thì về base',
      () async {
    Balance.eventIncomeMult = 2.0;
    Balance.eventStartMillis = 1000;
    Balance.eventEndMillis = 5000;

    final (container, setNow) =
        await _harness(GameState.newGame(nowMillis: 0)..levels['tra_den'] = 2);
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);

    setNow(500); // trước sự kiện
    ctrl.debugTick();
    var snap = container.read(gameControllerProvider);
    expect(snap.eventActive, isFalse);
    expect(snap.incomePerSecond, closeTo(1.0, 1e-9));

    setNow(2000); // trong sự kiện
    ctrl.debugTick();
    snap = container.read(gameControllerProvider);
    expect(snap.eventActive, isTrue);
    expect(snap.eventRemainingSeconds, 3); // (5000-2000)/1000 làm tròn lên
    expect(snap.incomePerSecond, closeTo(2.0, 1e-9));

    setNow(6000); // sau sự kiện — tự tắt, không cần ai tắt tay
    ctrl.debugTick();
    snap = container.read(gameControllerProvider);
    expect(snap.eventActive, isFalse);
    expect(snap.incomePerSecond, closeTo(1.0, 1e-9));
  });

  test('sự kiện KHÔNG áp cho thu nhập offline (cùng quy ước Mưa vàng/VIP)',
      () async {
    Balance.eventIncomeMult = 2.0;
    Balance.eventStartMillis = 0;
    Balance.eventEndMillis = 100000; // đang chạy suốt

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: 0)
        ..levels['tra_den'] = 2
        ..lastSeenMillis = 0,
      nowMillis: 0,
    );
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 10000), // mở lại sau 10s vắng mặt
    ]);
    addTearDown(container.dispose);
    final snap = container.read(gameControllerProvider);
    // 10s x 1.0 Xu/s base = 10, KHÔNG phải 20 — sự kiện không đụng khoản này.
    expect(snap.offlineEarned, closeTo(10.0, 1e-6));
  });
}
