import 'package:boba_empire/ui/widgets/idle_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// IdleMascot chạy 30Hz bằng Timer thay vì ticker vsync 60Hz — tránh ép Flutter
/// nộp khung (và GPU vẽ lại cả màn chính) mỗi vsync chỉ vì một con cốc nhún.
void main() {
  /// Số lần vị trí nhún đổi trong 1 giây (pump mỗi 16ms ≈ vsync 60Hz): ticker 60Hz
  /// sẽ đổi ở MỌI lần pump (60), còn Timer 33ms chỉ đổi ~30 lần.
  Future<int> bobChangesIn1s(WidgetTester tester, {required bool animate}) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: IdleMascot(
            asset: 'assets/anim/does_not_exist.json',
            emoji: '🧋',
            animate: animate),
      ),
    ));
    double y() => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(IdleMascot), matching: find.byType(Transform))
            .first)
        .transform
        .getTranslation()
        .y;
    await tester.pump(const Duration(milliseconds: 50));
    var last = y();
    var changes = 0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = y();
      if (now != last) changes++;
      last = now;
    }
    return changes;
  }

  testWidgets('animate: ~30 khung/giây (không phải 60 như ticker vsync)',
      (tester) async {
    final n = await bobChangesIn1s(tester, animate: true);
    expect(n, greaterThan(15), reason: 'phải có chuyển động ($n/60)');
    expect(n, lessThan(45), reason: 'không được lên 60Hz như ticker ($n/60)');
    await tester.pumpWidget(const SizedBox()); // dispose → Timer huỷ
  });

  testWidgets('animate=false: hoàn toàn yên (vị trí không đổi, không treo)',
      (tester) async {
    final n = await bobChangesIn1s(tester, animate: false);
    expect(n, 0);
    await tester.pumpAndSettle(); // không treo (không ticker/Timer lặp)
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tắt/bật animate lúc đang chạy: dừng rồi chạy lại', (tester) async {
    Widget app(bool animate) => MaterialApp(
          home: IdleMascot(
              asset: 'assets/anim/does_not_exist.json',
              emoji: '🧋',
              animate: animate),
        );
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(app(false));
    await tester.pump(const Duration(milliseconds: 100));
    var scheduled = 0;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (tester.binding.hasScheduledFrame) scheduled++;
    }
    expect(scheduled, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('bị hộp thoại phủ lên: dừng hẳn; đóng hộp thoại: chạy lại',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      home: const Scaffold(
        body: Center(
          child: IdleMascot(
              asset: 'assets/anim/does_not_exist.json', emoji: '🧋', size: 72),
        ),
      ),
    ));
    double y() => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(IdleMascot), matching: find.byType(Transform))
            .first)
        .transform
        .getTranslation()
        .y;
    Future<int> changesIn1s() async {
      var last = y();
      var changes = 0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final now = y();
        if (now != last) changes++;
        last = now;
      }
      return changes;
    }

    await tester.pump(const Duration(milliseconds: 100));
    expect(await changesIn1s(), greaterThan(15), reason: 'đang chạy');

    showDialog<void>(
        context: navKey.currentContext!,
        builder: (_) => const AlertDialog(title: Text('x')));
    await tester.pumpAndSettle();
    expect(await changesIn1s(), 0, reason: 'bị hộp thoại phủ lên phải đứng yên');

    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(await changesIn1s(), greaterThan(15), reason: 'đóng hộp thoại phải chạy lại');
    await tester.pumpWidget(const SizedBox());
  });
}
