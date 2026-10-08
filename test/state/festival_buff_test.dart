// Buff doanh thu dịp lễ phải thật sự nhân vào thu nhập sống + chạm ly, tắt khi
// ra khỏi dịp, KHÔNG áp offline, và xếp tầng độc lập với sự kiện Remote Config.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _halloween = festivals.first;
final _inFestival = _halloween.start.millisecondsSinceEpoch + 60000;
final _beforeFestival = _halloween.start.millisecondsSinceEpoch - 60000;
final _afterFestival = _halloween.end.millisecondsSinceEpoch + 60000;

Future<(ProviderContainer, void Function(int))> _harness(
    {required int openAt, required int lastSeen}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
    GameState.newGame(nowMillis: lastSeen)
      ..levels['tra_den'] = 2
      ..lastSeenMillis = lastSeen,
    nowMillis: lastSeen,
  );
  var now = openAt;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int t) => now = t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hệ số dịp lễ là buff thật (>1) và có trần hợp lý', () {
    expect(Balance.festivalIncomeMult, greaterThan(1.0));
    expect(Balance.festivalIncomeMult, lessThanOrEqualTo(2.0));
  });

  test('thu nhập/giây: x mult trong dịp, về 1.0 trước & sau dịp (tick, không '
      'cần ai tắt tay)', () async {
    final (c, setNow) =
        await _harness(openAt: _beforeFestival, lastSeen: _beforeFestival);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(c.read(gameControllerProvider).incomePerSecond, closeTo(1.0, 1e-9));

    setNow(_inFestival);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(Balance.festivalIncomeMult, 1e-9));

    setNow(_afterFestival);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).incomePerSecond, closeTo(1.0, 1e-9));
  });

  test('biên [start, end): đúng giây bắt đầu có buff, đúng giây kết thúc hết',
      () async {
    final (c, setNow) =
        await _harness(openAt: _beforeFestival, lastSeen: _beforeFestival);
    final ctrl = c.read(gameControllerProvider.notifier);
    setNow(_halloween.start.millisecondsSinceEpoch);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(Balance.festivalIncomeMult, 1e-9));
    setNow(_halloween.end.millisecondsSinceEpoch);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).incomePerSecond, closeTo(1.0, 1e-9));
  });

  test('chạm ly cũng được nhân buff', () async {
    final (c, setNow) =
        await _harness(openAt: _beforeFestival, lastSeen: _beforeFestival);
    final ctrl = c.read(gameControllerProvider.notifier);
    final base = ctrl.tapCup();
    setNow(_inFestival);
    final boosted = ctrl.tapCup();
    expect(boosted, closeTo(base * Balance.festivalIncomeMult, 1e-9));
  });

  test('buff KHÔNG áp cho thu nhập offline (cùng quy ước boost tạm)', () async {
    // Vắng mặt 10s ngay trong dịp, mở lại trong dịp.
    final (c, _) = await _harness(
        openAt: _inFestival + 10000, lastSeen: _inFestival);
    expect(c.read(gameControllerProvider).offlineEarned, closeTo(10.0, 1e-6));
  });

  test('xếp tầng với sự kiện Remote Config: nhân với nhau, không ghi đè',
      () async {
    final origMult = Balance.eventIncomeMult;
    final origStart = Balance.eventStartMillis;
    final origEnd = Balance.eventEndMillis;
    addTearDown(() {
      Balance.eventIncomeMult = origMult;
      Balance.eventStartMillis = origStart;
      Balance.eventEndMillis = origEnd;
    });
    Balance.eventIncomeMult = 2.0;
    Balance.eventStartMillis = _inFestival - 1000.0;
    Balance.eventEndMillis = _inFestival + 100000.0;

    final (c, setNow) =
        await _harness(openAt: _beforeFestival, lastSeen: _beforeFestival);
    setNow(_inFestival);
    c.read(gameControllerProvider.notifier).debugTick();
    final snap = c.read(gameControllerProvider);
    expect(snap.incomePerSecond, closeTo(2.0 * Balance.festivalIncomeMult, 1e-9));
    // Banner sự kiện Remote Config không bị dịp lễ làm sai: vẫn theo cấu hình.
    expect(snap.eventMultiplier, 2.0);
  });

  test('dịp lễ không bật banner/đồng hồ của sự kiện Remote Config', () async {
    final (c, setNow) =
        await _harness(openAt: _beforeFestival, lastSeen: _beforeFestival);
    setNow(_inFestival);
    c.read(gameControllerProvider.notifier).debugTick();
    final snap = c.read(gameControllerProvider);
    expect(snap.eventActive, isFalse);
    expect(snap.eventRemainingSeconds, 0);
  });
}
