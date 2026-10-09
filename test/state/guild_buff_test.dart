// Buff thu nhập cả hội (mua bằng Xu Hội): nhân vào thu nhập/giây + chạm cốc khi còn
// hạn, hết hạn tự tắt, KHÔNG áp offline, cộng dồn được với buff lễ hội, và sống sót
// qua lần mở lại.
import 'package:boba_empire/core/accessories.dart';
import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, void Function(int), SharedPreferences)> _open(
    int at, {GameState? seed, int lastSeen = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(
      seed ?? (GameState.newGame(nowMillis: lastSeen)..levels['tra_den'] = 2),
      nowMillis: lastSeen);
  var now = at;
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => now),
  ]);
  addTearDown(c.dispose);
  return (c, (int t) => now = t, prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('còn hạn: thu nhập × hệ số; hết giây buff thì về 1.0 (tự tắt qua tick)',
      () async {
    final (c, setNow, _) = await _open(1000, lastSeen: 1000);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(c.read(gameControllerProvider).incomePerSecond, closeTo(1.0, 1e-9));

    ctrl.applyGuildBuff(60);
    expect(c.read(gameControllerProvider).guildBuffActive, isTrue);
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(Balance.guildBuffMult, 1e-9));

    setNow(1000 + 59 * 1000);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(Balance.guildBuffMult, 1e-9), reason: 'còn 1 giây');

    setNow(1000 + 60 * 1000);
    ctrl.debugTick();
    expect(c.read(gameControllerProvider).guildBuffActive, isFalse);
    expect(c.read(gameControllerProvider).incomePerSecond, closeTo(1.0, 1e-9));
  });

  test('chạm cốc cũng được nhân buff', () async {
    final (c, _, _) = await _open(1000, lastSeen: 1000);
    final ctrl = c.read(gameControllerProvider.notifier);
    final base = ctrl.tapCup();
    ctrl.applyGuildBuff(600);
    expect(ctrl.tapCup(), closeTo(base * Balance.guildBuffMult, 1e-9));
  });

  test('applyGuildBuff(0) xoá buff; gọi lại cùng giá trị không làm gì thêm', () async {
    final (c, _, _) = await _open(1000, lastSeen: 1000);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.applyGuildBuff(600);
    ctrl.applyGuildBuff(0);
    expect(c.read(gameControllerProvider).guildBuffActive, isFalse);
    ctrl.applyGuildBuff(-5); // số âm = không buff
    expect(c.read(gameControllerProvider).guildBuffActive, isFalse);
  });

  test('buff KHÔNG áp cho thu nhập offline (cùng quy ước boost tạm)', () async {
    // Lưu có buff còn hạn dài; vắng 10 giây rồi mở lại: offline = 10 Xu, không × hệ số.
    final seed = GameState.newGame(nowMillis: 0)
      ..levels['tra_den'] = 2
      ..guildBuffUntilMillis = 10 * 60 * 1000
      ..lastSeenMillis = 0;
    final (c, _, _) = await _open(10000, seed: seed);
    expect(c.read(gameControllerProvider).offlineEarned, closeTo(10.0, 1e-6));
  });

  test('cộng dồn với buff lễ hội: nhân với nhau', () async {
    final inFestival = festivals.first.start.millisecondsSinceEpoch + 60000;
    final (c, _, _) = await _open(inFestival, lastSeen: inFestival);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.applyGuildBuff(600);
    expect(c.read(gameControllerProvider).incomePerSecond,
        closeTo(Balance.festivalIncomeMult * Balance.guildBuffMult, 1e-9));
  });

  test('buff và cờ "ở hội" sống sót qua lưu rồi mở lại (cùng đồng hồ)', () async {
    final (c, _, prefs) = await _open(1000, lastSeen: 1000);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.setGuildJoined(true);
    ctrl.applyGuildBuff(600);
    await ctrl.saveNow();
    c.dispose();
    final c2 = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 2000),
    ]);
    addTearDown(c2.dispose);
    final s = c2.read(gameControllerProvider);
    expect(s.guildJoined, isTrue);
    expect(s.guildBuffActive, isTrue);
  });

  test('JSON: save cũ (thiếu trường) → không buff, chưa ở hội', () {
    final old = GameState.newGame(nowMillis: 0).toJson()
      ..remove('guildJoined')
      ..remove('guildBuffUntilMillis');
    final s = GameState.fromJson(old);
    expect((s.guildJoined, s.guildBuffUntilMillis), (false, 0));
  });

  test('chargeGuildDonation: trừ đúng, không âm, từ chối khi thiếu', () async {
    final seed = GameState.newGame(nowMillis: 0)..gems = 100;
    final (c, _, _) = await _open(0, seed: seed);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.chargeGuildDonation(150), isFalse);
    expect(c.read(gameControllerProvider).gems, 100);
    expect(ctrl.chargeGuildDonation(100), isTrue);
    expect(c.read(gameControllerProvider).gems, 0);
    expect(ctrl.chargeGuildDonation(1), isFalse);
    expect(ctrl.chargeGuildDonation(0), isFalse);
  });

  test('grantGuildItems: chỉ nhận id trong cửa hàng hội, không trùng, đếm đúng món mới',
      () async {
    final (c, _, _) = await _open(0);
    final ctrl = c.read(gameControllerProvider.notifier);
    expect(ctrl.grantGuildItems(['guild_flag', 'bat', 'zzz']), 1,
        reason: 'bat (lễ hội) và id lạ bị bỏ qua');
    expect(ctrl.grantGuildItems(['guild_flag']), 0);
    expect(c.read(gameControllerProvider).ownedLimited, ['guild_flag']);
  });
}
