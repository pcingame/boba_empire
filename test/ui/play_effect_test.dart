// playEffect theo mức chất lượng (Tắt/Thấp bỏ hiệu ứng nặng/trần đồng thời) và EffectOnIncrease.
import 'package:boba_empire/ui/widgets/anim_assets.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/gain_effects.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/one_shot_lottie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;

  Future<void> setQuality(EffectsPref p) async {
    SharedPreferences.setMockInitialValues({});
    fx.init(await SharedPreferences.getInstance(),
        platformStart: EffectsQuality.high, listenFrames: false);
    await fx.setPref(p);
  }

  setUp(() => mascot.debugDisableMascotAnimation = false);
  tearDown(() {
    fx.debugReset();
    mascot.debugDisableMascotAnimation = true;
  });

  late BuildContext ctx;
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return const SizedBox.expand();
    }))));
  }

  /// Chờ hiệu ứng chạy hết (Lottie nạp bất đồng bộ rồi chạy theo thời lượng thật của file).
  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('mức Tắt: không phát gì nhưng vẫn báo kết thúc', (tester) async {
    await setQuality(EffectsPref.off);
    await pumpHost(tester);
    var done = 0;
    playEffect(ctx, AnimAssets.sparkle, heavy: false, onFinished: () => done++);
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
    expect(done, 1);
  });

  testWidgets('mức Thấp: bỏ hiệu ứng nặng, vẫn phát hiệu ứng nhỏ', (tester) async {
    await setQuality(EffectsPref.low);
    await pumpHost(tester);
    playEffect(ctx, AnimAssets.confetti); // mặc định heavy
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
    playEffect(ctx, AnimAssets.sparkle, heavy: false);
    await tester.pump();
    expect(find.byType(Lottie), findsOneWidget);
    await drain(tester);
    expect(find.byType(Lottie), findsNothing);
  });

  testWidgets('trần đồng thời theo mức: bản dư bị bỏ và báo kết thúc ngay; xong thì phát lại được',
      (tester) async {
    await setQuality(EffectsPref.medium); // trần 3
    await pumpHost(tester);
    var rejected = 0;
    for (var i = 0; i < 5; i++) {
      playEffect(ctx, AnimAssets.sparkle, heavy: false, onFinished: () => rejected++);
    }
    await tester.pump();
    expect(find.byType(Lottie), findsNWidgets(3));
    expect(rejected, 2);
    await drain(tester);
    expect(find.byType(Lottie), findsNothing);
    expect(rejected, 5); // cả 3 bản kia cũng đã kết thúc
    playEffect(ctx, AnimAssets.sparkle, heavy: false);
    await tester.pump();
    expect(find.byType(Lottie), findsOneWidget); // bộ đếm đã về 0
    await drain(tester);
  });

  testWidgets('"giảm chuyển động"/chế độ test: không phát', (tester) async {
    await setQuality(EffectsPref.high);
    mascot.debugDisableMascotAnimation = true;
    await pumpHost(tester);
    playEffect(ctx, AnimAssets.sparkle, heavy: false);
    await tester.pump();
    expect(find.byType(Lottie), findsNothing);
  });

  group('EffectOnIncrease', () {
    Widget host(num v, {int gap = 0}) => MaterialApp(
        home: Scaffold(
            body: Center(
                child: EffectOnIncrease(
                    value: v,
                    asset: AnimAssets.gemBurst,
                    minGapMs: gap,
                    child: const Text('💎')))));

    testWidgets('chỉ phát khi giá trị TĂNG; lần dựng đầu và giảm thì không', (tester) async {
      await setQuality(EffectsPref.high);
      await tester.pumpWidget(host(10));
      await tester.pump();
      expect(find.byType(Lottie), findsNothing); // dựng đầu
      await tester.pumpWidget(host(5)); // giảm
      await tester.pump();
      expect(find.byType(Lottie), findsNothing);
      await tester.pumpWidget(host(5)); // không đổi
      await tester.pump();
      expect(find.byType(Lottie), findsNothing);
      await tester.pumpWidget(host(20)); // tăng
      await tester.pump();
      await tester.pump();
      expect(find.byType(Lottie), findsOneWidget);
      await drain(tester);
    });

    testWidgets('các lần tăng dồn dập trong khoảng gộp chỉ phát một lần', (tester) async {
      await setQuality(EffectsPref.high);
      await tester.pumpWidget(host(1, gap: 100000));
      await tester.pumpWidget(host(2, gap: 100000));
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(host(3, gap: 100000));
      await tester.pump();
      await tester.pump();
      expect(find.byType(Lottie), findsOneWidget);
      await drain(tester);
    });
  });
}
