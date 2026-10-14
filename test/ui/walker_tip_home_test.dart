// Từ màn chính tới ví: bấm bong bóng boa của khách → Xu tăng đúng số, hiện thông báo, bong bóng mất;
// hết khách đó thì khách sau KHÔNG mang bong bóng cho tới khi hết thời gian hồi.
import 'dart:math';

import 'package:boba_empire/core/balance.dart';
import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/stage_walkers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seed làm lượt khách ĐẦU có bong bóng (lặp đúng thứ tự gọi Random của widget).
int _seedFirstWalkHasTip({required bool want}) {
  for (var seed = 1; seed < 200; seed++) {
    final r = Random(seed);
    final s = WalkerScript(r, EffectsQuality.high);
    while (!s.walking) {
      s.step(0.1);
    }
    if ((r.nextDouble() < 0.7) == want) return seed;
  }
  throw StateError('không tìm được seed');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;
  var now = 0;
  // GameController có Timer.periodic: container phải dispose NGAY sau khi gỡ cây, trước bước kiểm "không còn timer".
  final _live = <ProviderContainer>[];
  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    for (final c in _live) {
      c.dispose();
    }
    _live.clear();
  }

  setUp(() async {
    mascot.debugDisableMascotAnimation = false;
    SharedPreferences.setMockInitialValues({});
    fx.init(await SharedPreferences.getInstance(),
        platformStart: EffectsQuality.high, listenFrames: false);
  });
  tearDown(() {
    fx.debugReset();
    debugWalkerRandom = null;
    mascot.debugDisableMascotAnimation = true;
  });

  Future<ProviderContainer> pumpHome(WidgetTester tester, int seed) async {
    debugWalkerRandom = Random(seed);
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..stage = 1
          ..tutorialSeen = true,
        nowMillis: 0);
    now = 0;
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(() => now),
    ]);
    _live.add(c);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const BobaEmpireApp()));
    return c;
  }

  Future<void> run(WidgetTester tester, double seconds) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('bấm bong bóng: +Xu đúng số (sàn 5 lần chạm), có thông báo, bong bóng biến mất', (tester) async {
    final c = await pumpHome(tester, _seedFirstWalkHasTip(want: true));
    await run(tester, 6);
    final bubble = find.byKey(const Key('walker-tip'));
    expect(bubble, findsOneWidget);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(bubble);
    await tester.pump();
    final after = c.read(gameControllerProvider).money;
    expect(after - before, closeTo(Balance.walkerTipFloorTaps * 1.0, 1e-9)); // tapValue 1, chưa có thu nhập
    expect(find.textContaining('Khách boa +5'), findsOneWidget);
    expect(bubble, findsNothing);
    // Bấm lại chỗ cũ không cộng thêm.
    await tester.tapAt(const Offset(195, 250));
    await run(tester, 1);
    expect(c.read(gameControllerProvider).money - after, lessThan(5)); // chỉ có thể là chạm cốc nếu trúng
    await run(tester, 10);
    await teardown(tester);
  });

  testWidgets('đang hồi: khách lượt sau không có bong bóng; hết hồi: lại có thể có', (tester) async {
    final c = await pumpHome(tester, _seedFirstWalkHasTip(want: true));
    await run(tester, 6);
    await tester.tap(find.byKey(const Key('walker-tip')));
    await tester.pump();
    // Cho khách đi hết và các lượt kế tiếp diễn ra trong lúc còn hồi (đồng hồ game đứng yên ở 0).
    for (var lap = 0; lap < 4; lap++) {
      await run(tester, 25);
      expect(find.byKey(const Key('walker-tip')), findsNothing, reason: 'lượt $lap còn hồi');
    }
    // Hết thời gian hồi → khách sau lại có thể mang bong bóng (xác suất 70% mỗi lượt: thử nhiều lượt).
    now = Balance.walkerTipCooldownMs;
    var seen = false;
    for (var lap = 0; lap < 12 && !seen; lap++) {
      await run(tester, 25);
      seen = find.byKey(const Key('walker-tip')).evaluate().isNotEmpty;
    }
    expect(seen, isTrue);
    final before = c.read(gameControllerProvider).money;
    await tester.tap(find.byKey(const Key('walker-tip')));
    await tester.pump();
    expect(c.read(gameControllerProvider).money - before, closeTo(5, 1e-9));
    await run(tester, 12);
    await teardown(tester);
  });

  testWidgets('lượt không có boa (30%): không có bong bóng dù hết hồi; mức Tắt: không khách', (tester) async {
    final c = await pumpHome(tester, _seedFirstWalkHasTip(want: false));
    await run(tester, 6);
    expect(find.byKey(const Key('walker-tip')), findsNothing);
    expect(c.read(gameControllerProvider).money, 0);
    await run(tester, 10);
    await teardown(tester);

    await fx.setPref(EffectsPref.off);
    await pumpHome(tester, _seedFirstWalkHasTip(want: true));
    await run(tester, 8);
    expect(find.byKey(const Key('walker-tip')), findsNothing);
    await teardown(tester);
  });
}
