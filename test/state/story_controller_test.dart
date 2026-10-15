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
    // Xoá cả cờ firstPlayedIsEstimate — save thật thiếu firstPlayedMillis thì
    // cũng thiếu luôn cờ này (cùng thêm một lượt), xoá một mình millis dựng
    // một trạng thái không có thật.
    (payload['state'] as Map<String, dynamic>)
      ..remove('firstPlayedMillis')
      ..remove('firstPlayedIsEstimate');
    await prefs.setString('game_state', jsonEncode(payload));
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 5000 + 1000),
    ]);
    addTearDown(container.dispose);

    expect(container.read(gameControllerProvider).storyCompleteSeconds, isNull);
  });

  test(
      'save có firstPlayedMillis THẬT (không thiếu trường nào) vẫn được chốt '
      'mốc bình thường — cờ firstPlayedIsEstimate không lỡ tay chặn nhầm save '
      'hợp lệ', () async {
    final seed = GameState.newGame(nowMillis: 1000)
      ..storyChapter = 18
      ..storyChoiceD = 'soul'
      ..stage = 12;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(seed, nowMillis: 5000);
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => 1000 + 777000),
    ]);
    addTearDown(container.dispose);
    expect(container.read(gameControllerProvider).storyCompleteSeconds, 777);
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
        // Xoá CẢ HAI trường: save thật trước 2026-09-12 không có trường nào
        // trong hai trường này (cả firstPlayedMillis lẫn cờ
        // firstPlayedIsEstimate đều được thêm cùng lúc) — chỉ xoá một trường
        // là dựng một trạng thái không có thật (cờ nói "tin được" nhưng mốc
        // lại thiếu), không mô phỏng đúng bug đang kiểm.
        (payload['state'] as Map<String, dynamic>)
          ..remove('firstPlayedMillis')
          ..remove('firstPlayedIsEstimate');
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

  group('Hồi 4 (Chương 37-46, mỗi màn một mốc trò chơi nhỏ)', () {
    test('làm Thử thách hằng ngày cộng bộ đếm ngày và mở chương gắn mốc đó; làm lại cùng ngày không đếm thêm', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 39
        ..storyChoiceG = 'open'
        ..recipeDailyCount = 1;
      final b = await _boot(seed);
      b.clock.now = 1000 + 5 * 24 * 3600 * 1000;
      expect(b.snap().pendingStoryChapterId, isNull); // Ch.40 cần 2 ngày
      b.ctrl.completeDailyChallenge(200);
      expect(b.snap().recipeDailyCount, 2);
      expect(b.snap().pendingStoryChapterId, 40);
      b.ctrl.completeDailyChallenge(300); // cùng ngày
      expect(b.snap().recipeDailyCount, 2);
      b.clock.now += 24 * 3600 * 1000;
      b.ctrl.completeDailyChallenge(100); // ngày mới
      expect(b.snap().recipeDailyCount, 3);
    });

    test('pha hoàn hảo đủ số món ở Pha theo đơn mở chương gắn mốc đó', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 38
        ..storyChoiceG = 'open';
      final b = await _boot(seed);
      for (var id = 1; id <= 4; id++) {
        b.ctrl.recordOrderPerfect(id);
      }
      expect(b.snap().pendingStoryChapterId, isNull);
      b.ctrl.recordOrderPerfect(5);
      expect(b.snap().pendingStoryChapterId, 39);
    });

    test('Chương 46 (lựa chọn) chốt mốc Hồi 4 một lần; không bù mốc Hồi 3 cho save còn ở Chương 40', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 45
        ..storyChoiceG = 'open'
        ..storyThirdActCompleteSeconds = 900
        ..recipeOrderPerfect.addAll(List.generate(40, (i) => i + 1));
      final b = await _boot(seed);
      b.clock.now = 1000 + 3000000;
      expect(b.snap().pendingStoryChapterId, 46);
      expect(b.snap().storyFourthActCompleteSeconds, isNull);
      expect(b.ctrl.makeStoryChoice('mastery'), isTrue);
      expect(b.snap().storyFourthActCompleteSeconds, 3000);
      expect(b.snap().storyThirdActCompleteSeconds, 900); // không bị đè
      b.clock.now += 9999000;
      expect(b.ctrl.makeStoryChoice('spirit'), isFalse);
      expect(b.snap().storyFourthActCompleteSeconds, 3000);
    });

    test('CHƠI SUỐT Hồi 4 bằng API thật của controller: 10 chương mở đúng thứ tự, mỗi chương chỉ sau đúng mốc, kết thúc ở Chương 46', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 36
        ..storyChoiceG = 'open';
      final b = await _boot(seed);
      const dayMs = 24 * 3600 * 1000;
      b.clock.now = 1000 + 100 * dayMs;
      int? pending() => b.snap().pendingStoryChapterId;
      void see(int id) {
        expect(pending(), id, reason: 'chương $id phải đang chờ');
        b.ctrl.acknowledgeStoryBeat();
        expect(b.snap().storyChapter, id);
      }

      // Mốc món Thạo: đường thật answerRecipe — 3 lượt đúng cách nhau 40 ngày (mỗi lượt đều đến hạn ôn) đưa món lên Thạo.
      void masterRecipes(int upTo) {
        for (var round = 0; round < 3; round++) {
          b.clock.now += 40 * dayMs;
          for (var id = 1; id <= upTo; id++) {
            b.ctrl.answerRecipe(id, true);
          }
        }
      }

      void clearM3(int levels) {
        final stars = b.ctrl.debugGame.m3Stars;
        while (stars.length < levels) {
          stars.add(1);
        }
        b.ctrl.debugTick(); // dựng lại snapshot (đường chơi thật gọi qua màn Ghép 3)
      }

      expect(pending(), isNull);
      masterRecipes(5);
      see(37);
      expect(pending(), isNull); // Ch.38 cần màn 65
      clearM3(65);
      see(38);
      for (var id = 1; id <= 5; id++) {
        b.ctrl.recordOrderPerfect(id);
      }
      see(39);
      b.ctrl.completeDailyChallenge(100);
      expect(pending(), isNull); // mới 1 ngày
      b.clock.now += dayMs;
      b.ctrl.completeDailyChallenge(100);
      see(40);
      masterRecipes(20);
      see(41);
      clearM3(75);
      see(42);
      for (var id = 6; id <= 15; id++) {
        b.ctrl.recordOrderPerfect(id);
      }
      see(43);
      for (var d = 0; d < 3; d++) {
        b.clock.now += dayMs;
        b.ctrl.completeDailyChallenge(100);
      }
      see(44);
      masterRecipes(50);
      see(45);
      expect(pending(), isNull);
      for (var id = 16; id <= 40; id++) {
        b.ctrl.recordOrderPerfect(id);
      }
      expect(pending(), 46);
      expect(b.snap().storyFourthActCompleteSeconds, isNull);
      expect(b.ctrl.makeStoryChoice('mastery'), isTrue);
      expect(b.snap().storyChapter, 46);
      expect(b.snap().storyFourthActCompleteSeconds, isNotNull);
      expect(pending(), isNull, reason: 'hết truyện');
    });

    test('xong Chương 36 chỉ chốt mốc Hồi 3, KHÔNG chốt Hồi 4', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 35
        ..ascensionCount = 4;
      final b = await _boot(seed);
      b.clock.now = 1000 + 700000;
      expect(b.ctrl.makeStoryChoice('open'), isTrue);
      expect(b.snap().storyThirdActCompleteSeconds, 700);
      expect(b.snap().storyFourthActCompleteSeconds, isNull);
    });

    test('perk Chương 46 vào snapshot: "spirit" tăng thu nhập +8%', () async {
      final seed = GameState.newGame(nowMillis: 1000)
        ..storyChapter = 45
        ..storyChoiceG = 'open'
        ..levels['tra_den'] = 10
        ..recipeOrderPerfect.addAll(List.generate(40, (i) => i + 1));
      final b = await _boot(seed);
      final before = b.snap().incomePerSecond;
      expect(b.ctrl.makeStoryChoice('spirit'), isTrue);
      // Hệ số cộng dồn: trục G ('open') đã +8% ⇒ thêm 'spirit' là 1.08 → 1.16.
      expect(b.snap().incomePerSecond, closeTo(before * (1 + 2 * Balance.storyPerkBonus) / (1 + Balance.storyPerkBonus), before * 1e-6));
    });
  });

  test('mở app với save bị đẩy lên vòng nhiệm vụ lặp quá cao -> tự đưa về đúng vòng, nút Nhận tắt', () async {
    final seed = GameState.newGame(nowMillis: 0)
      ..lifetimeEarnings = 1e30
      ..questIndex = 10 + 300
      ..repeatQuestBaseline = 1e30;
    final b = await _boot(seed);
    final snap = b.snap();
    expect(snap.currentQuest.threshold.isFinite, isTrue);
    expect(snap.currentQuest.threshold, lessThan(1e100));
    expect(snap.questDone, isFalse);
    expect(b.ctrl.claimCurrentQuest(), 0);
  });
}
