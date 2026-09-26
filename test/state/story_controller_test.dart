import 'dart:convert';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/core/rival.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/state/game_controller.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/state/game_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bơm controller với [seed] và một đồng hồ đổi được ([clockRef.value]).
Future<
    ({
      GameController ctrl,
      GameSnapshot Function() snap,
      _Clock clock,
    })> _boot(GameState seed) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await GameStorage(prefs).save(seed, nowMillis: 0);
  final clock = _Clock();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    clockProvider.overrideWithValue(() => clock.now),
  ]);
  addTearDown(container.dispose);
  return (
    ctrl: container.read(gameControllerProvider.notifier),
    snap: () => container.read(gameControllerProvider),
    clock: clock,
  );
}

class _Clock {
  int now = 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ván mới → Chương 1 chờ; acknowledge bump con trỏ', () async {
    final b = await _boot(GameState.newGame(nowMillis: 0));
    expect(b.snap().pendingStoryChapterId, 1);
    b.ctrl.acknowledgeStoryBeat();
    expect(b.snap().storyChapter, 1);
    expect(b.snap().pendingStoryChapterId, isNull);
  });

  test('makeStoryChoice ghi nhánh và áp perk vào snapshot', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..storyChapter = 5
      ..stage = 5
      ..levels['tra_den'] = 10; // 5 Xu/s nền
    final b = await _boot(seed);
    expect(b.snap().pendingStoryChapterId, 6);
    final before = b.snap().incomePerSecond;
    expect(b.ctrl.makeStoryChoice('scale'), isTrue);
    expect(b.snap().storyChoiceA, 'scale');
    expect(b.snap().pendingStoryChapterId, isNull);
    expect(b.snap().incomePerSecond, greaterThan(before));
  });

  test('sự kiện đối thủ không nổ trước giờ, nổ sau khi tới hạn', () async {
    final seed = GameState.newGame(nowMillis: 0)..storyChapter = 3;
    final b = await _boot(seed);
    b.clock.now = 1000;
    b.ctrl.debugTick();
    expect(b.snap().pendingRivalEvent, isNull);
    b.clock.now = Balance.rivalEventSpawnMaxMs + 5000;
    b.ctrl.debugTick();
    expect(b.snap().pendingRivalEvent, isNotNull);
  });

  test('resolveRivalEvent trừ tài nguyên và đẩy lùi sức ép', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..storyChapter = 3
      ..money = 5000
      ..gems = 100
      ..rivalPressureSeconds = 4000;
    final b = await _boot(seed);
    b.ctrl.debugSpawnRivalEvent(RivalEventType.priceWar);
    expect(b.ctrl.resolveRivalEvent(1), isTrue); // trả 💎
    expect(b.snap().gems, lessThan(100));
    expect(b.snap().pendingRivalEvent, isNull);
    // pressureDelta âm → sức ép giảm → tỉ số nhỏ hơn.
    expect(b.snap().rivalPowerRatio, lessThan(rivalPowerRatio(seed)));
  });

  test('phớt lờ: debuff tạm giảm thu nhập rồi hết hạn', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..storyChapter = 3
      ..levels['tra_den'] = 10; // 5 Xu/s
    final b = await _boot(seed);
    final full = b.snap().incomePerSecond;
    b.ctrl.debugSpawnRivalEvent(RivalEventType.smearCampaign);
    b.ctrl.ignoreRivalEvent();
    expect(b.snap().rivalModifierMult, lessThan(1.0));
    expect(b.snap().incomePerSecond, lessThan(full));
    // Qua thời hạn debuff → trở lại bình thường.
    b.clock.now = Balance.rivalIgnoreDebuffSeconds * 1000 + 1000;
    b.ctrl.debugTick();
    expect(b.snap().rivalModifierMult, 1.0);
    expect(b.snap().incomePerSecond, closeTo(full, 1e-6));
  });

  test('hạ đối thủ ở giai đoạn 6 → Chương 8 chờ', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..storyChapter = 7
      ..stage = 6
      ..rivalPressureSeconds = 0; // đang dẫn trước
    final b = await _boot(seed);
    b.clock.now = 1000;
    b.ctrl.debugTick();
    expect(b.snap().rivalDefeated, isTrue);
    expect(b.snap().pendingStoryChapterId, 8);
  });

  test(
      'hoàn thành Chương 18 lần đầu -> ghi storyCompleteSeconds (giây thực '
      'tế từ firstPlayedMillis); acknowledge lại không đổi mốc', () async {
    final seed = GameState.newGame(nowMillis: 1000)
      ..storyChapter = 17
      ..stage = 12;
    final b = await _boot(seed);
    b.clock.now = 1000 + 500000; // 500s sau khi tạo save
    expect(b.snap().pendingStoryChapterId, 18);
    expect(b.snap().storyCompleteSeconds, isNull);

    b.ctrl.acknowledgeStoryBeat();
    expect(b.snap().storyChapter, 18);
    expect(b.snap().storyCompleteSeconds, 500);

    // Mở lại app / acknowledge lại sau khi đã hoàn thành — mốc không đổi.
    b.clock.now = 1000 + 999000;
    b.ctrl.acknowledgeStoryBeat();
    expect(b.snap().storyCompleteSeconds, 500);
  });

  test(
      'Chương 18 CŨNG là chương lựa chọn — đường thật của người chơi là '
      'makeStoryChoice (không có nút "Tiếp tục" cho chương lựa chọn, xem '
      'story_dialog.dart), vẫn phải ghi storyCompleteSeconds ở đây', () async {
    final seed = GameState.newGame(nowMillis: 1000)
      ..storyChapter = 17
      ..stage = 12;
    final b = await _boot(seed);
    b.clock.now = 1000 + 500000; // 500s sau khi tạo save
    expect(b.snap().pendingStoryChapterId, 18);
    expect(b.snap().storyCompleteSeconds, isNull);

    expect(b.ctrl.makeStoryChoice('soul'), isTrue);
    expect(b.snap().storyChapter, 18);
    expect(b.snap().storyCompleteSeconds, 500);

    // Gọi lại (không nên xảy ra vì đã chọn rồi, nhưng an toàn) — mốc không đổi.
    b.clock.now = 1000 + 999000;
    expect(b.ctrl.makeStoryChoice('global'), isFalse);
    expect(b.snap().storyCompleteSeconds, 500);
  });

  test(
      'Save cũ đã hoàn thành Chương 18 TỪ TRƯỚC lúc sửa bug (storyChapter=18, '
      'storyCompleteSeconds vẫn null vì mốc chưa từng được ghi) — build() '
      'phải bù mốc ngay khi mở app, không để mãi mãi null (không bao giờ lên '
      'được Bảng xếp hạng tốc độ)', () async {
    final seed = GameState.newGame(nowMillis: 1000)
      ..storyChapter = 18
      ..storyChoiceD = 'soul'
      ..stage = 12;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(seed, nowMillis: 5000);
    // Đặt đồng hồ TRƯỚC KHI build() chạy (khác _boot() — helper đó luôn tạo
    // đồng hồ ở mặc định 0 rồi mới trigger build lúc container.read).
    final clock = _Clock()..now = 1000 + 777000; // mở app 777s sau khi tạo save
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => clock.now),
    ]);
    addTearDown(container.dispose);

    final snap = container.read(gameControllerProvider);
    expect(snap.storyChapter, 18);
    expect(snap.storyCompleteSeconds, 777);
  });

  test(
      'HỒI QUY "phá đảo 1s": save cũ thiếu firstPlayedMillis (mặc định = '
      'lastSeen) KHÔNG được bù mốc ~1s — phải để null', () async {
    final seed = GameState.newGame(nowMillis: 1000)
      ..storyChapter = 18
      ..storyChoiceD = 'soul'
      ..stage = 12;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(seed, nowMillis: 5000);
    final payload =
        jsonDecode(prefs.getString('game_state')!) as Map<String, dynamic>;
    (payload['state'] as Map<String, dynamic>).remove('firstPlayedMillis');
    await prefs.setString('game_state', jsonEncode(payload));
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 5000 + 1000),
    ]);
    addTearDown(container.dispose);

    expect(container.read(gameControllerProvider).storyCompleteSeconds, isNull);
  });

  group('mốc Hồi 2 (Chương 28)', () {
    test(
        'Chương 28 là chương lựa chọn: makeStoryChoice ghi storyExtCompleteSeconds '
        '(tổng giây từ đầu game), giữ nguyên mốc Hồi 1 đã có, chỉ ghi 1 lần', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 27
        ..stage = 18
        ..storyCompleteSeconds = 300;
      final b = await _boot(seed);
      b.clock.now = 1000 + 2000000; // 2000s sau khi tạo save
      expect(b.snap().pendingStoryChapterId, 28);
      expect(b.snap().storyExtCompleteSeconds, isNull);

      expect(b.ctrl.makeStoryChoice('recipe'), isTrue);
      expect(b.snap().storyChapter, 28);
      expect(b.snap().storyExtCompleteSeconds, 2000);
      expect(b.snap().storyCompleteSeconds, 300); // mốc Hồi 1 không bị đè

      b.clock.now = 1000 + 9999000;
      expect(b.ctrl.makeStoryChoice('people'), isFalse);
      expect(b.snap().storyExtCompleteSeconds, 2000);
    });

    test('đường acknowledgeStoryBeat cũng chốt mốc Chương 28', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 27
        ..stage = 18;
      final b = await _boot(seed);
      b.clock.now = 1000 + 800000;
      b.ctrl.acknowledgeStoryBeat();
      expect(b.snap().storyExtCompleteSeconds, 800);
    });

    test('xong Chương 18 chỉ chốt mốc Hồi 1, KHÔNG chốt Hồi 2', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 17
        ..stage = 12;
      final b = await _boot(seed);
      b.clock.now = 1000 + 500000;
      expect(b.ctrl.makeStoryChoice('soul'), isTrue);
      expect(b.snap().storyCompleteSeconds, 500);
      expect(b.snap().storyExtCompleteSeconds, isNull);
    });

    Future<GameSnapshot> openAt(GameState seed, {required int savedAt, required int now, bool dropFirstPlayed = false}) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await GameStorage(prefs).save(seed, nowMillis: savedAt);
      if (dropFirstPlayed) {
        final payload = jsonDecode(prefs.getString('game_state')!) as Map<String, dynamic>;
        (payload['state'] as Map<String, dynamic>).remove('firstPlayedMillis');
        await prefs.setString('game_state', jsonEncode(payload));
      }
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => now),
      ]);
      addTearDown(container.dispose);
      return container.read(gameControllerProvider);
    }

    test('save đã qua Chương 28 mà chưa có mốc: mở app bù mốc cả 2 hồi', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 28
        ..storyChoiceD = 'soul'
        ..storyChoiceF = 'recipe'
        ..stage = 18;
      final snap = await openAt(seed, savedAt: 5000, now: 1000 + 777000);
      expect(snap.storyExtCompleteSeconds, 777);
      expect(snap.storyCompleteSeconds, 777);
    });

    test('save chưa tới Chương 28 (đang ở 20) không bị bù mốc Hồi 2', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 20
        ..stage = 14
        ..storyCompleteSeconds = 400;
      final snap = await openAt(seed, savedAt: 5000, now: 1000 + 900000);
      expect(snap.storyExtCompleteSeconds, isNull);
      expect(snap.storyCompleteSeconds, 400);
    });

    test('HỒI QUY "1s": save cũ thiếu firstPlayedMillis (mặc định = lastSeen) KHÔNG bị bù mốc nào', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 28
        ..storyChoiceD = 'soul'
        ..storyChoiceF = 'recipe'
        ..stage = 18;
      final snap = await openAt(seed, savedAt: 5000, now: 6000, dropFirstPlayed: true);
      expect(snap.storyExtCompleteSeconds, isNull);
      expect(snap.storyCompleteSeconds, isNull);
    });
  });
}
