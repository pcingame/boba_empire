// Khách đi ngang cảnh quán: kịch bản (thuần) và widget theo mức chất lượng.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:boba_empire/ui/widgets/ambient_ticker.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/stage_walkers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;

  group('WalkerScript', () {
    test('lượt đầu tới sớm (≤5s); đi 6.5–9s; tiến độ 0→1; xong thì chờ', () {
      final s = WalkerScript(Random(1), EffectsQuality.high);
      var t = 0.0;
      while (!s.walking && t < 10) {
        s.step(0.1);
        t += 0.1;
      }
      expect(t, lessThanOrEqualTo(5.1));
      expect(s.progress, 0);
      var walked = 0.0;
      var prev = 0.0;
      var finished = false;
      while (!finished) {
        finished = s.step(0.1);
        walked += 0.1;
        if (!finished) {
          expect(s.progress, greaterThanOrEqualTo(prev));
          prev = s.progress;
        }
      }
      expect(walked, inInclusiveRange(6.4, 9.2));
      expect(s.walking, isFalse);
    });

    test('mỗi lượt: hướng ±1, bộ màu hợp lệ, cỡ 0.9..1.1', () {
      final s = WalkerScript(Random(7), EffectsQuality.high);
      final dirs = <int>{};
      final pals = <int>{};
      final specs = <int>{};
      int? last;
      for (var i = 0; i < 60; i++) {
        while (!s.walking) {
          s.step(0.5);
        }
        dirs.add(s.dir);
        pals.add(s.palette);
        expect(s.spec, inInclusiveRange(0, walkerSpecs.length - 1));
        expect(s.palette, inInclusiveRange(0, walkerSpecs[s.spec].palettes.length - 1));
        specs.add(s.spec);
        if (last != null) expect(s.spec, isNot(last), reason: 'không đi hai kiểu giống nhau liền nhau');
        last = s.spec;
        expect(s.scale, inInclusiveRange(0.9, 1.1));
        while (s.walking) {
          s.step(0.5);
        }
      }
      expect(dirs, {1, -1});
      expect(pals.length, greaterThan(1)); // có đổi màu
      expect(specs.length, walkerSpecs.length); // đủ mọi kiểu khách
    });

    test('khoảng chờ giữa hai lượt: Cao < Vừa < Thấp', () {
      double gap(EffectsQuality q) {
        final s = WalkerScript(Random(5), q);
        while (!s.walking) {
          s.step(0.1);
        }
        while (s.walking) {
          s.step(0.1);
        }
        var t = 0.0;
        while (!s.walking) {
          s.step(0.1);
          t += 0.1;
        }
        return t;
      }

      expect(gap(EffectsQuality.high), lessThan(14.2));
      expect(gap(EffectsQuality.medium), inInclusiveRange(11.9, 26.2));
      expect(gap(EffectsQuality.low), greaterThan(44.9));
    });

    test('mọi kiểu khách: file Lottie đọc được; layer cần ẩn có thật ở gốc file', () {
      for (final spec in walkerSpecs) {
        final json = jsonDecode(File(spec.asset).readAsStringSync()) as Map<String, dynamic>;
        final names = [for (final l in json['layers'] as List) (l as Map)['nm']];
        for (final path in spec.hidePaths) {
          // Đường dẫn bắt đầu bằng tên layer gốc → layer đó phải có thật ở gốc file.
          if (path.first != '**') {
            expect(names, contains(path.first), reason: '${spec.asset} thiếu layer ${path.first}');
          }
        }
        expect(spec.canvasFrac, inInclusiveRange(0.2, 0.6));
        expect(spec.feetFromBottom, inInclusiveRange(0.0, 0.4));
        expect(spec.palettes, isNotEmpty);
        expect(spec.palettes.first, isNull); // bộ đầu luôn là màu gốc
      }
    });

    test('chân khách nằm TRONG dải đất (không lơ lửng trên thân xe, không chìm khỏi cảnh)', () {
      for (final stage in [1, 5, 10, 12]) {
        for (final w in [320.0, 390.0, 430.0]) {
          final feet = walkerFeetFromBottom(stage, w, 1.5);
          final bandTop = (stage == 10 ? 0.202 : 0.183) * 0.5 * 1.5 * w;
          expect(feet, greaterThan(0));
          expect(feet, lessThan(bandTop), reason: 'giai đoạn $stage, rộng $w');
        }
      }
      // Dải đất dày hơn ở giai đoạn 10 (đồng cỏ) nên chân cao hơn một chút.
      expect(walkerFeetFromBottom(10, 390, 1.5), greaterThan(walkerFeetFromBottom(1, 390, 1.5)));
    });

    test('giai đoạn có khách: 1..12', () {
      expect([for (var s = 0; s <= 14; s++) stageHasWalkers(s)],
          [false, ...List.filled(12, true), false, false]);
    });
  });

  group('widget', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fx.init(await SharedPreferences.getInstance(),
          platformStart: EffectsQuality.high, listenFrames: false);
      mascot.debugDisableMascotAnimation = false;
    });
    tearDown(() {
      fx.debugReset();
      mascot.debugDisableMascotAnimation = true;
    });

    Widget app(Widget w, {GlobalKey<NavigatorState>? key}) => MaterialApp(
        navigatorKey: key,
        home: Scaffold(body: SizedBox(width: 360, height: 400, child: w)));

    Future<void> run(WidgetTester tester, double seconds) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (i % 5 == 0) await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      }
    }

    testWidgets('đang chờ: không dựng Lottie; tới lượt: có; đi xong: gỡ', (tester) async {
      await tester.pumpWidget(app(StageWalkers(stage: 1, random: Random(3))));
      expect(find.byType(Lottie), findsNothing);
      await run(tester, 6); // quá lượt chờ đầu (≤ 5s)
      expect(find.byType(Lottie), findsOneWidget);
      await run(tester, 10); // đi xong (≤ 9s)
      expect(find.byType(Lottie), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(AmbientTicker.instance.running, isFalse);
    });

    testWidgets('mức Tắt / giai đoạn 13+ / giảm chuyển động: không có khách, không có nhịp', (tester) async {
      await fx.setPref(EffectsPref.off);
      await tester.pumpWidget(app(StageWalkers(stage: 1, random: Random(3))));
      await run(tester, 8);
      expect(find.byType(Lottie), findsNothing);
      expect(AmbientTicker.instance.running, isFalse);

      await fx.setPref(EffectsPref.high);
      await tester.pumpWidget(app(StageWalkers(stage: 13, random: Random(3))));
      await run(tester, 8);
      expect(find.byType(Lottie), findsNothing);
      expect(AmbientTicker.instance.running, isFalse);

      mascot.debugDisableMascotAnimation = true;
      await tester.pumpWidget(app(StageWalkers(stage: 1, random: Random(3))));
      await run(tester, 8);
      expect(find.byType(Lottie), findsNothing);
    });

    testWidgets('bật lại mức hiệu ứng giữa chừng thì khách xuất hiện', (tester) async {
      await fx.setPref(EffectsPref.off);
      await tester.pumpWidget(app(StageWalkers(stage: 1, random: Random(3))));
      await fx.setPref(EffectsPref.high);
      await tester.pump();
      await run(tester, 6);
      expect(find.byType(Lottie), findsOneWidget);
      await run(tester, 10);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('bị hộp thoại phủ lên thì đứng yên; không chặn chạm', (tester) async {
      final key = GlobalKey<NavigatorState>();
      var taps = 0;
      await tester.pumpWidget(app(
          Stack(children: [
            GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque, child: const SizedBox.expand()),
            Positioned.fill(child: StageWalkers(stage: 1, random: Random(3))),
          ]),
          key: key));
      await run(tester, 6);
      expect(find.byType(Lottie), findsOneWidget);
      await tester.tapAt(const Offset(180, 200));
      expect(taps, 1);

      showDialog<void>(context: key.currentContext!, builder: (_) => const AlertDialog(title: Text('x')));
      await tester.pumpAndSettle();
      Offset pos() => tester.getTopLeft(find.byType(Lottie));
      final before = pos();
      await run(tester, 1);
      expect(pos(), before); // đứng yên dưới hộp thoại
      key.currentState!.pop();
      await tester.pumpAndSettle();
      await run(tester, 1);
      expect(pos(), isNot(before)); // chạy lại
      await run(tester, 10);
      await tester.pumpWidget(const SizedBox());
    });

    group('boa', () {
      Widget host({bool Function()? canTip, void Function(Offset)? onTip, int seed = 3}) => app(
          Stack(children: [
            Positioned.fill(child: StageWalkers(stage: 1, random: Random(seed), canTip: canTip, onTip: onTip)),
          ]));

      // Seed cho nhiều lượt đầu: tìm seed có bong bóng ở lượt đầu (xác suất 70%).
      Future<int?> seedWithTip(WidgetTester tester) async {
        for (var seed = 1; seed < 30; seed++) {
          await tester.pumpWidget(host(canTip: () => true, seed: seed));
          await run(tester, 6);
          final found = find.byKey(const Key('walker-tip')).evaluate().isNotEmpty;
          await tester.pumpWidget(const SizedBox()); // gỡ hẳn để lần dựng sau bắt đầu lại từ đầu
          if (found) return seed;
        }
        return null;
      }

      testWidgets('canTip=true: có lượt khách mang bong bóng; bấm → onTip một lần, bong bóng biến mất', (tester) async {
        final taps = <Offset>[];
        final seed = await seedWithTip(tester);
        expect(seed, isNotNull, reason: 'trong 30 lượt phải có ít nhất một khách có boa');
        await tester.pumpWidget(host(canTip: () => true, onTip: taps.add, seed: seed!));
        await run(tester, 6);
        final bubble = find.byKey(const Key('walker-tip'));
        expect(bubble, findsOneWidget);
        // Vùng chạm đủ cho ngón tay (≥ 44dp).
        expect(tester.getSize(bubble).shortestSide, greaterThanOrEqualTo(44));
        await tester.tap(bubble);
        await tester.pump();
        expect(taps, hasLength(1));
        expect(bubble, findsNothing);
        // Đã bấm thì khách đó không còn gì để bấm tiếp.
        await run(tester, 1);
        expect(find.byKey(const Key('walker-tip')), findsNothing);
        expect(taps, hasLength(1));
        await run(tester, 10);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('canTip=false hoặc không truyền: không bao giờ có bong bóng', (tester) async {
        for (final canTip in <bool Function()?>[() => false, null]) {
          for (var seed = 1; seed < 8; seed++) {
            await tester.pumpWidget(host(canTip: canTip, seed: seed));
            await run(tester, 6);
            expect(find.byKey(const Key('walker-tip')), findsNothing, reason: 'seed $seed');
            await run(tester, 10);
          }
        }
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('bong bóng mất khi khách đi khỏi cảnh dù chưa bấm; không chặn chạm vùng khác', (tester) async {
        final seed = await seedWithTip(tester);
        var under = 0;
        await tester.pumpWidget(app(Stack(children: [
          GestureDetector(onTap: () => under++, behavior: HitTestBehavior.opaque, child: const SizedBox.expand()),
          Positioned.fill(child: StageWalkers(stage: 1, random: Random(seed!), canTip: () => true)),
        ])));
        await run(tester, 6);
        expect(find.byKey(const Key('walker-tip')), findsOneWidget);
        await tester.tapAt(const Offset(5, 395)); // góc xa bong bóng
        expect(under, 1);
        await run(tester, 10);
        expect(find.byKey(const Key('walker-tip')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    });
  });
}
