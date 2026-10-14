// Hạt trang trí cảnh quán: hàm thuần (vị trí/độ mờ hợp lệ, xác định), ánh xạ giai đoạn → kiểu,
// và widget tôn trọng mức chất lượng (Tắt/giảm chuyển động = không dựng, bị phủ = đứng yên).
import 'package:boba_empire/ui/widgets/ambient_ticker.dart';
import 'package:boba_empire/ui/widgets/effects_quality.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/stage_ambience.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fx = EffectsController.instance;

  group('hàm thuần', () {
    test('mọi giai đoạn 1..18 có kiểu hạt; ngoài khoảng dùng giai đoạn gần nhất', () {
      for (var s = 1; s <= 18; s++) {
        expect(ambienceFor(s), isA<AmbienceKind>());
      }
      expect(ambienceFor(0), ambienceFor(1));
      expect(ambienceFor(99), ambienceFor(18));
      // Mỗi nhóm giai đoạn khác nhau thật (không dồn một kiểu).
      expect({for (var s = 1; s <= 18; s++) ambienceFor(s)}.length, AmbienceKind.values.length);
    });

    test('mọi kiểu: x,y trong khung, độ mờ 0..1, bán kính dương, ở nhiều thời điểm', () {
      for (final k in AmbienceKind.values) {
        for (var i = 0; i < k.max; i++) {
          for (final t in [0.0, 0.7, 3.3, 12.5, 100.0, 5000.0]) {
            final p = particleAt(k, i, t);
            expect(p.x, inInclusiveRange(0, 1), reason: '$k $i $t');
            expect(p.y, inInclusiveRange(0, 1), reason: '$k $i $t');
            expect(p.alpha, inInclusiveRange(0, 1), reason: '$k $i $t');
            expect(p.radius, greaterThan(0));
          }
        }
      }
    });

    test('xác định (cùng đầu vào cùng kết quả); bay lên thì y giảm, rơi thì y tăng; sao đứng yên', () {
      final a = particleAt(AmbienceKind.steam, 3, 2.0);
      final b = particleAt(AmbienceKind.steam, 3, 2.0);
      expect((a.x, a.y, a.alpha), (b.x, b.y, b.alpha));
      // Bước nhỏ (không vòng lại): bay lên → y giảm; rơi → y tăng.
      expect(particleAt(AmbienceKind.motes, 2, 0.2).y, lessThan(particleAt(AmbienceKind.motes, 2, 0.0).y));
      expect(particleAt(AmbienceKind.leaves, 2, 0.2).y, greaterThan(particleAt(AmbienceKind.leaves, 2, 0.0).y));
      expect(particleAt(AmbienceKind.stars, 4, 0).y, particleAt(AmbienceKind.stars, 4, 50).y);
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

    Widget app(Widget home, {GlobalKey<NavigatorState>? key}) =>
        MaterialApp(navigatorKey: key, home: Scaffold(body: SizedBox(width: 300, height: 200, child: home)));

    testWidgets('mức Cao dựng lớp hạt và chạy; mức Tắt không dựng gì và không còn nhịp', (tester) async {
      await tester.pumpWidget(app(const StageAmbience(stage: 3)));
      expect(find.byKey(const Key('stage-ambience')), findsOneWidget);
      expect(AmbientTicker.instance.running, isTrue);

      await fx.setPref(EffectsPref.off);
      await tester.pump();
      expect(find.byKey(const Key('stage-ambience')), findsNothing);
      expect(AmbientTicker.instance.running, isFalse);

      await fx.setPref(EffectsPref.low);
      await tester.pump();
      expect(find.byKey(const Key('stage-ambience')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(AmbientTicker.instance.running, isFalse); // gỡ widget → huỷ đăng ký
    });

    testWidgets('giảm chuyển động / chế độ test: không dựng gì', (tester) async {
      mascot.debugDisableMascotAnimation = true;
      await tester.pumpWidget(app(const StageAmbience(stage: 3)));
      expect(find.byKey(const Key('stage-ambience')), findsNothing);
      expect(AmbientTicker.instance.running, isFalse);
    });

    testWidgets('không chặn thao tác bên dưới (IgnorePointer)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(app(Stack(children: [
        const StageAmbience(stage: 18),
        Positioned.fill(child: GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque)),
      ])));
      // Lớp hạt nằm dưới; thử với lớp hạt nằm TRÊN:
      await tester.pumpWidget(app(Stack(children: [
        Positioned.fill(child: GestureDetector(onTap: () => taps++, behavior: HitTestBehavior.opaque)),
        const Positioned.fill(child: StageAmbience(stage: 18)),
      ])));
      await tester.tapAt(const Offset(100, 100));
      expect(taps, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('bị hộp thoại phủ lên thì đứng yên, đóng hộp thoại thì chạy lại', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(app(const StageAmbience(stage: 3), key: key));
      CustomPaint cp() => tester.widget<CustomPaint>(find.byKey(const Key('stage-ambience')));
      double t() => (cp().painter! as dynamic).time.value as double;

      await tester.pump(const Duration(milliseconds: 200));
      expect(t(), greaterThan(0));

      showDialog<void>(context: key.currentContext!, builder: (_) => const AlertDialog(title: Text('x')));
      await tester.pumpAndSettle();
      final frozen = t();
      await tester.pump(const Duration(milliseconds: 300));
      expect(t(), frozen);

      key.currentState!.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(t(), greaterThan(frozen));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
