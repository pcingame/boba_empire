// Khách chibi vẽ bằng code: diện mạo ổn định theo seed + đa dạng, nét mặt đổi theo tâm trạng, thở/chớp mắt chỉ khi
// bật chuyển động, không rò animation khi tắt, không tràn.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:boba_empire/ui/widgets/chibi_customer.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/order_visuals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vẽ [painter] ra ảnh RGBA 64×64 (không cần cây widget).
Future<Uint8List> _render(ChibiPainter painter, {double size = 64}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = const Color(0xFFFFFFFF));
  painter.paint(c, Size.square(size));
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  return data!.buffer.asUint8List();
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _Phase extends Animation<double> with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  _Phase(this.value);
  @override
  double value;
  @override
  AnimationStatus get status => AnimationStatus.forward;
  @override
  void didRegisterListener() {}
  @override
  void didUnregisterListener() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChibiLook.fromSeed', () {
    test('cùng seed luôn ra cùng một người; âm/lớn không ném lỗi', () {
      for (final s in [0, 1, 7, 99, -5, 1 << 40]) {
        expect(ChibiLook.fromSeed(s), ChibiLook.fromSeed(s));
      }
    });

    test('đa dạng: 100 seed ra nhiều diện mạo khác nhau, đủ cả 5 kiểu tóc, có người đeo kính và không đeo', () {
      final looks = {for (var s = 0; s < 100; s++) ChibiLook.fromSeed(s)};
      expect(looks.length, greaterThan(40), reason: 'quá ít diện mạo');
      expect({for (final l in looks) l.hairStyle}, {0, 1, 2, 3, 4});
      expect(looks.any((l) => l.glasses), isTrue);
      expect(looks.any((l) => !l.glasses), isTrue);
      expect({for (final l in looks) l.skin}.length, greaterThan(2));
      expect({for (final l in looks) l.shirt}.length, greaterThan(3));
    });

    test('seed liền kề (id món + chỉ số đơn) không cho hai khách giống hệt nhau', () {
      var same = 0;
      for (var s = 0; s < 99; s++) {
        if (ChibiLook.fromSeed(s) == ChibiLook.fromSeed(s + 1)) same++;
      }
      expect(same, lessThan(3));
    });

    test('tóc luôn khác màu da (không "hói" do trùng màu), áo khác màu da', () {
      for (var s = 0; s < 300; s++) {
        final l = ChibiLook.fromSeed(s);
        expect(l.hair, isNot(l.skin));
        expect(l.shirt, isNot(l.skin));
      }
    });
  });

  group('vẽ', () {
    test('mỗi tâm trạng cho một khuôn mặt KHÁC nhau (và sốt ruột khác chờ thường)', () async {
      final look = ChibiLook.fromSeed(5);
      final imgs = <String, Uint8List>{
        for (final m in CustomerMood.values) m.name: await _render(ChibiPainter(look: look, mood: m)),
        'nervous': await _render(ChibiPainter(look: look, mood: CustomerMood.waiting, impatient: true)),
      };
      final names = imgs.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          expect(_same(imgs[names[i]]!, imgs[names[j]]!), isFalse, reason: '${names[i]} giống ${names[j]}');
        }
      }
    });

    test('sốt ruột chỉ có tác dụng khi đang chờ (vui/buồn thì bỏ qua)', () async {
      final look = ChibiLook.fromSeed(5);
      for (final m in [CustomerMood.delighted, CustomerMood.pleased, CustomerMood.upset]) {
        expect(_same(await _render(ChibiPainter(look: look, mood: m)), await _render(ChibiPainter(look: look, mood: m, impatient: true))), isTrue,
            reason: m.name);
      }
    });

    test('hai seed khác nhau vẽ ra hai người khác nhau; cùng seed + cùng trạng thái vẽ ra đúng cùng một ảnh', () async {
      final a = await _render(ChibiPainter(look: ChibiLook.fromSeed(3), mood: CustomerMood.waiting));
      final a2 = await _render(ChibiPainter(look: ChibiLook.fromSeed(3), mood: CustomerMood.waiting));
      final b = await _render(ChibiPainter(look: ChibiLook.fromSeed(4), mood: CustomerMood.waiting));
      expect(_same(a, a2), isTrue);
      expect(_same(a, b), isFalse);
    });

    test('thở: đầu nhấp nhô theo pha; chớp mắt: mắt khép ở cuối chu kỳ rồi mở lại', () async {
      final look = ChibiLook.fromSeed(5);
      Future<Uint8List> at(double t) => _render(ChibiPainter(look: look, mood: CustomerMood.waiting, phase: _Phase(t)));
      final still = await _render(ChibiPainter(look: look, mood: CustomerMood.waiting));
      expect(_same(await at(0.0), still), isTrue, reason: 'pha 0 = đứng yên');
      expect(_same(await at(0.25), await at(0.0)), isFalse, reason: 'đang thở');
      // sin(2π·0.92) == sin(2π·0.58) ⇒ cùng độ nhấp nhô; hai ảnh chỉ có thể khác nhau ở MẮT (0.92 đang khép, 0.58 mở).
      expect(_same(await at(0.92), await at(0.58)), isFalse, reason: 'mắt khép phải khác mắt mở');
      expect(_same(await at(0.88), await at(0.92)), isFalse, reason: 'bắt đầu chớp (mắt mở) khác giữa chớp (mắt khép)');
      // Đối chứng: ngoài khoảng chớp, hai pha cùng độ nhấp nhô (sin(2π·0.3) == sin(2π·0.2)) cho ảnh y hệt.
      expect(_same(await at(0.30), await at(0.20)), isTrue, reason: 'không có thay đổi lạ nào ngoài thở và chớp');
    });

    test('khách cười không chớp mắt thành nét lạ: vẽ mọi pha đều không ném lỗi', () async {
      for (final m in CustomerMood.values) {
        for (var i = 0; i <= 20; i++) {
          await _render(ChibiPainter(look: ChibiLook.fromSeed(11), mood: m, impatient: true, phase: _Phase(i / 20)));
        }
      }
    });
  });

  group('widget', () {
    Widget host(Widget child, {double scale = 1}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: Center(child: child)),
          ),
        );

    testWidgets('tắt chuyển động (mặc định test): không có animation lặp ⇒ pumpAndSettle xong, không rò ticker', (tester) async {
      await tester.pumpWidget(host(const ChibiCustomer(seed: 3, mood: CustomerMood.waiting)));
      await tester.pumpAndSettle(); // sẽ treo nếu có animation lặp
      expect(find.byKey(const Key('chibi-customer')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('bật chuyển động: thở lặp (khung hình liên tục) và dọn ticker khi gỡ widget', (tester) async {
      mascot.debugDisableMascotAnimation = false;
      addTearDown(() => mascot.debugDisableMascotAnimation = true);
      await tester.pumpWidget(host(const ChibiCustomer(seed: 3, mood: CustomerMood.waiting)));
      expect(tester.hasRunningAnimations, isTrue);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox()); // dispose: nếu rò ticker, test báo lỗi ở đây
      expect(tester.takeException(), isNull);
    });

    testWidgets('đổi tâm trạng/diện mạo dựng lại mà không lỗi; kích thước đúng', (tester) async {
      await tester.pumpWidget(host(const ChibiCustomer(seed: 1, mood: CustomerMood.waiting, size: 80)));
      expect(tester.getSize(find.byKey(const Key('chibi-customer'))), const Size(80, 80));
      for (final m in CustomerMood.values) {
        await tester.pumpWidget(host(ChibiCustomer(seed: 9, mood: m, impatient: true, size: 48)));
        expect(tester.getSize(find.byKey(const Key('chibi-customer'))), const Size(48, 48));
      }
    });
  });

  group('OrderCustomer', () {
    Widget host(Widget child, {double scale = 1.0, double width = 320}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 640), textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: SizedBox(width: width, child: child)),
          ),
        );

    testWidgets('dùng khách chibi (không còn avatar emoji người) + huy hiệu mặt cười + bong bóng lời gọi', (tester) async {
      await tester.pumpWidget(host(const OrderCustomer(seed: 4, mood: CustomerMood.waiting, child: Text('Một trà đào'))));
      await tester.pumpAndSettle();
      expect(find.byType(ChibiCustomer), findsOneWidget);
      expect(find.byKey(const Key('order-customer-face')), findsOneWidget);
      expect(find.text('Một trà đào'), findsOneWidget);
      for (final e in ['🧑', '👩', '👨', '👧']) {
        expect(find.text(e), findsNothing);
      }
    });

    testWidgets('tâm trạng và sốt ruột được truyền xuống khách chibi', (tester) async {
      await tester.pumpWidget(host(const OrderCustomer(seed: 4, mood: CustomerMood.upset, impatient: true, child: Text('x'))));
      await tester.pumpAndSettle();
      final w = tester.widget<ChibiCustomer>(find.byType(ChibiCustomer));
      expect(w.mood, CustomerMood.upset);
      expect(w.impatient, isTrue);
      expect(w.seed, 4);
    });

    testWidgets('khách lễ hội đội phụ kiện emoji lên đầu; khách thường thì không', (tester) async {
      await tester.pumpWidget(host(const OrderCustomer(seed: 4, mood: CustomerMood.waiting, avatar: '🦇', child: Text('x'))));
      await tester.pumpAndSettle();
      expect(find.text('🦇'), findsOneWidget);
      await tester.pumpWidget(host(const OrderCustomer(seed: 4, mood: CustomerMood.waiting, child: Text('x'))));
      await tester.pumpAndSettle();
      expect(find.text('🦇'), findsNothing);
    });

    testWidgets('mỗi đơn (seed) một khách khác nhau', (tester) async {
      Future<ChibiLook> lookOf(int seed) async {
        await tester.pumpWidget(host(OrderCustomer(seed: seed, mood: CustomerMood.waiting, child: const Text('x'))));
        await tester.pumpAndSettle();
        return ChibiLook.fromSeed(tester.widget<ChibiCustomer>(find.byType(ChibiCustomer)).seed);
      }

      final looks = {for (var s = 10; s < 16; s++) await lookOf(s)};
      expect(looks.length, greaterThan(3));
    });

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('không tràn ở 320px, chữ ${scale}x, bong bóng dài + phụ kiện', (tester) async {
        await tester.pumpWidget(host(
          OrderCustomer(
              seed: 7,
              mood: CustomerMood.pleased,
              avatar: '🎃',
              child: const Text('Cho mình một ly trà sữa trân châu đường đen ít đá, ít ngọt, thêm thạch và pudding nhé')),
          scale: scale,
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
