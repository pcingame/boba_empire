// Tự động chạm: bật bằng QC (cộng dồn, có trần) hoặc VIP đủ cấp; CHỈ cộng Xu — không tính chạm/nhiệm
// vụ/điểm Hội/điểm sự kiện (điểm Hội là +1/lần chạm nên sẽ bị cày nếu tính).
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/simulation.dart';
import 'package:boba_empire/core/topup.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(int))> _ctl(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  var now = 0;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int ms) => now = ms);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('autoTap (công thức)', () {
    test('mỗi giây = tapGain × tần suất × hiệu suất; tỉ lệ thuận với dt', () {
      final s = GameState.newGame(nowMillis: 0)..tapValue = 100;
      final one = tapGain(s);
      final m0 = s.money;
      final got = autoTap(s, 1);
      expect(got, closeTo(one * Balance.autoTapPerSecond * Balance.autoTapEfficiency, 1e-9));
      expect(s.money, closeTo(m0 + got, 1e-9));
      expect(autoTap(s, 3), closeTo(got * 3, 1e-9));
    });

    test('dt ≤ 0 không cộng gì', () {
      final s = GameState.newGame(nowMillis: 0);
      final m0 = s.money;
      expect(autoTap(s, 0), 0);
      expect(autoTap(s, -5), 0);
      expect(s.money, m0);
    });

    test('hiệu suất < chạm tay (chạm tay vẫn có lợi hơn)', () {
      expect(Balance.autoTapEfficiency, lessThan(1));
      expect(Balance.autoTapPerSecond * Balance.autoTapEfficiency, lessThan(Balance.autoTapPerSecond));
    });

    test('KHÔNG đụng chạm/nhiệm vụ/điểm Hội/điểm sự kiện', () {
      final s = GameState.newGame(nowMillis: 0)..tapValue = 50;
      final before = s.toJson();
      autoTap(s, 10);
      final after = s.toJson();
      for (final k in ['tapCount', 'guildWeekScore', 'dailyProgress', 'eventScore', 'weeklyProgress']) {
        expect(after[k], before[k], reason: k);
      }
    });

    test('số rất lớn vẫn hữu hạn (không tràn)', () {
      final s = GameState.newGame(nowMillis: 0)
        ..tapValue = 1e300
        ..prestigeStars = 1e12;
      autoTap(s, 5);
      expect(s.money.isFinite, isTrue);
      expect(s.money, greaterThanOrEqualTo(0));
    });
  });

  group('bật / tắt', () {
    test('mặc định tắt; xem QC → bật 10 phút', () async {
      final (c, setNow) = await _ctl(GameState.newGame(nowMillis: 0));
      setNow(1000);
      expect(c.read(gameControllerProvider).autoTapActive, isFalse);
      c.read(gameControllerProvider.notifier).activateAutoTap();
      final s = c.read(gameControllerProvider);
      expect(s.autoTapActive, isTrue);
      expect(s.autoTapRemainingSeconds, closeTo(Balance.autoTapAdMs / 1000, 1));
    });

    test('xem nhiều lần cộng dồn nhưng có trần 1 giờ', () async {
      final (c, setNow) = await _ctl(GameState.newGame(nowMillis: 0));
      setNow(1000);
      final ctrl = c.read(gameControllerProvider.notifier);
      for (var i = 0; i < 10; i++) {
        ctrl.activateAutoTap();
      }
      expect(c.read(gameControllerProvider).autoTapRemainingSeconds, closeTo(Balance.autoTapMaxMs / 1000, 1));
    });

    test('hết hạn thì tắt', () async {
      final (c, setNow) = await _ctl(GameState.newGame(nowMillis: 0));
      setNow(1000);
      c.read(gameControllerProvider.notifier).activateAutoTap();
      setNow(1000 + Balance.autoTapAdMs + 1);
      c.read(gameControllerProvider.notifier).debugTick();
      expect(c.read(gameControllerProvider).autoTapActive, isFalse);
    });

    test('VIP đủ cấp: bật vĩnh viễn, không cần QC; thiếu 1 cấp thì không', () async {
      final need = Balance.autoTapVipLevel;
      final (c, _) = await _ctl(GameState.newGame(nowMillis: 0)..vipExp = topupTiers[need - 1].exp);
      expect(c.read(gameControllerProvider).autoTapActive, isTrue);
      expect(c.read(gameControllerProvider).autoTapRemainingSeconds, 0);
      final (c2, _) = await _ctl(GameState.newGame(nowMillis: 0)..vipExp = topupTiers[need - 2].exp);
      expect(c2.read(gameControllerProvider).autoTapActive, isFalse);
    });
  });

  group('trong lúc chơi (tick)', () {
    test('đang bật: mỗi nhịp cộng thêm Xu; tắt thì không', () async {
      final seed = GameState.newGame(nowMillis: 0)..tapValue = 100;
      final (on, setOn) = await _ctl(seed);
      setOn(1000);
      on.read(gameControllerProvider.notifier).activateAutoTap();
      final m0 = on.read(gameControllerProvider).money;
      setOn(2000);
      on.read(gameControllerProvider.notifier).debugTick();
      final gainOn = on.read(gameControllerProvider).money - m0;

      final (off, setOff) = await _ctl(GameState.newGame(nowMillis: 0)..tapValue = 100);
      setOff(1000);
      final m1 = off.read(gameControllerProvider).money;
      setOff(2000);
      off.read(gameControllerProvider.notifier).debugTick();
      final gainOff = off.read(gameControllerProvider).money - m1;
      expect(gainOn, greaterThan(gainOff), reason: 'tự chạm cộng thêm Xu');
    });

    test('tự chạm không làm tăng tapCount / điểm Hội', () async {
      final (c, setNow) = await _ctl(GameState.newGame(nowMillis: 0)..tapValue = 100);
      setNow(1000);
      c.read(gameControllerProvider.notifier).activateAutoTap();
      final ctrl = c.read(gameControllerProvider.notifier);
      final before = ctrl.exportSaveJson();
      for (var t = 2; t <= 6; t++) {
        setNow(t * 1000);
        ctrl.debugTick();
      }
      final after = ctrl.exportSaveJson();
      for (final k in ['tapCount', 'guildWeekScore', 'dailyProgress']) {
        expect(after[k], before[k], reason: k);
      }
    });

    test('nhịp trễ rất dài không đổi thành cú cộng khổng lồ (cắt dt ở 5 giây)', () async {
      final (c, setNow) = await _ctl(GameState.newGame(nowMillis: 0)..tapValue = 100);
      setNow(1000);
      c.read(gameControllerProvider.notifier).activateAutoTap();
      final m0 = c.read(gameControllerProvider).money;
      setNow(1000 + 30 * 60 * 1000); // trễ 30 phút (chưa qua xử lý offline)
      c.read(gameControllerProvider.notifier).debugTick();
      final gained = c.read(gameControllerProvider).money - m0;
      final s = GameState.newGame(nowMillis: 0)..tapValue = 100;
      final perSec = autoTap(s, 1);
      expect(gained, lessThan(perSec * 60), reason: 'không tính tới 30 phút');
    });
  });

  test('lưu/đọc: autoTapUntilMillis giữ qua save; save cũ thiếu khoá → 0', () {
    final s = GameState.newGame(nowMillis: 0)..autoTapUntilMillis = 123456;
    expect(GameState.fromJson(s.toJson()).autoTapUntilMillis, 123456);
    final old = s.toJson()..remove('autoTapUntilMillis');
    expect(GameState.fromJson(old).autoTapUntilMillis, 0);
  });
}
