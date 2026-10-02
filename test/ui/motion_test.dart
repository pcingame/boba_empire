import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_test_config bật "giảm chuyển động" cho mọi test (ticker lặp làm
/// pumpAndSettle treo) — các test dưới đây tắt nó để kiểm tra animation thật.
void withMotion() {
  mascot.debugDisableMascotAnimation = false;
  addTearDown(() => mascot.debugDisableMascotAnimation = true);
}

double scaleOf(WidgetTester tester, Finder f) => tester
    .widget<ScaleTransition>(
        find.ancestor(of: f, matching: find.byType(ScaleTransition)).first)
    .scale
    .value;

void main() {
  const marker = Key('child');
  Widget host(Widget child) =>
      MaterialApp(home: Scaffold(body: Center(child: child)));

  group('PulseOnIncrease', () {
    testWidgets('value TĂNG: phóng lên rồi về 1.0, hữu hạn (pumpAndSettle xong)',
        (tester) async {
      withMotion();
      Widget app(int v) =>
          host(PulseOnIncrease(value: v, child: const SizedBox(key: marker)));
      await tester.pumpWidget(app(1));
      expect(scaleOf(tester, find.byKey(marker)), 1.0);

      await tester.pumpWidget(app(2));
      await tester.pump(const Duration(milliseconds: 90)); // ~đỉnh (40% của 220ms)
      expect(scaleOf(tester, find.byKey(marker)), greaterThan(1.0));

      await tester.pumpAndSettle();
      expect(scaleOf(tester, find.byKey(marker)), 1.0);
    });

    testWidgets('value GIẢM hoặc không đổi: không animation', (tester) async {
      withMotion();
      Widget app(int v) =>
          host(PulseOnIncrease(value: v, child: const SizedBox(key: marker)));
      await tester.pumpWidget(app(5));
      await tester.pumpWidget(app(3));
      await tester.pump(const Duration(milliseconds: 90));
      expect(scaleOf(tester, find.byKey(marker)), 1.0);
    });

    testWidgets('giảm chuyển động: không animation dù value tăng', (tester) async {
      // mặc định của test: debugDisableMascotAnimation = true
      Widget app(int v) =>
          host(PulseOnIncrease(value: v, child: const SizedBox(key: marker)));
      await tester.pumpWidget(app(1));
      await tester.pumpWidget(app(2));
      await tester.pump(const Duration(milliseconds: 90));
      expect(scaleOf(tester, find.byKey(marker)), 1.0);
    });
  });

  group('PulseOnMount', () {
    testWidgets('chạy đúng 2 nhịp rồi DỪNG (không lặp vô hạn)', (tester) async {
      withMotion();
      await tester.pumpWidget(
          host(const PulseOnMount(child: SizedBox(key: marker))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleOf(tester, find.byKey(marker)), greaterThan(1.0));
      // pumpAndSettle chỉ kết thúc nếu mọi animation hữu hạn.
      await tester.pumpAndSettle();
      expect(scaleOf(tester, find.byKey(marker)), 1.0);
    });

    testWidgets('giảm chuyển động: đứng yên ngay từ đầu', (tester) async {
      await tester.pumpWidget(
          host(const PulseOnMount(child: SizedBox(key: marker))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleOf(tester, find.byKey(marker)), 1.0);
    });
  });

  group('AppearIn', () {
    double opacityOf(WidgetTester tester) =>
        tester.widget<Opacity>(find.byType(Opacity)).opacity;

    testWidgets('enabled: mờ → rõ dần rồi hiện đủ', (tester) async {
      withMotion();
      await tester.pumpWidget(
          host(const AppearIn(child: SizedBox(key: marker, width: 10, height: 10))));
      expect(opacityOf(tester), 0.0);
      await tester.pump(const Duration(milliseconds: 160));
      expect(opacityOf(tester), inExclusiveRange(0.0, 1.0));
      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1.0);
    });

    testWidgets('enabled=false: hiện ngay, không animation', (tester) async {
      withMotion();
      await tester.pumpWidget(host(const AppearIn(
          enabled: false, child: SizedBox(key: marker, width: 10, height: 10))));
      expect(opacityOf(tester), 1.0);
    });

    testWidgets('đang animation mà enabled đổi sang false: KHÔNG dựng lại con/cắt',
        (tester) async {
      withMotion();
      Widget app(bool e) => host(AppearIn(
          enabled: e, child: const SizedBox(key: marker, width: 10, height: 10)));
      await tester.pumpWidget(app(true));
      final before = tester.element(find.byKey(marker));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(app(false));
      expect(identical(tester.element(find.byKey(marker)), before), isTrue);
      await tester.pumpAndSettle();
      expect(opacityOf(tester), 1.0);
    });
  });

  group('PopIn', () {
    testWidgets('phóng từ 0 lên 1', (tester) async {
      withMotion();
      await tester.pumpWidget(
          host(const PopIn(child: SizedBox(key: marker, width: 10, height: 10))));
      double scale() => tester
          .widget<Transform>(find
              .descendant(of: find.byType(PopIn), matching: find.byType(Transform))
              .first)
          .transform
          .storage[0]; // hệ số phóng theo trục x (trục z luôn 1)
      expect(scale(), lessThan(0.5));
      await tester.pumpAndSettle();
      expect(scale(), closeTo(1.0, 0.001));
    });
  });
}
