library;

import 'package:boba_empire/ui/widgets/marquee_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(String text, {double width = 100, bool disableAnim = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnim),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: MarqueeText(text)),
          ),
        ),
      ),
    );

double _dx(WidgetTester t) => t
    .widget<Transform>(
      find
          .descendant(
            of: find.descendant(
              of: find.byType(MarqueeText),
              matching: find.byType(ClipRect),
            ),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getTranslation()
    .x;

void main() {
  const long = 'Chợ Phụ kiện · Cánh thiên thần (Sử thi) · 12345 🪙 và còn nữa';

  testWidgets('chữ ngắn: hiện bình thường, không chạy', (tester) async {
    await tester.pumpWidget(_host('Ngắn', width: 200));
    await tester.pump();
    expect(find.text('Ngắn'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MarqueeText),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
  });

  testWidgets('chữ dài: chạy sang trái để lộ phần đuôi, rồi quay lại', (
    tester,
  ) async {
    await tester.pumpWidget(_host(long));
    await tester.pump(); // post-frame bật animation
    final x0 = _dx(tester);
    await tester.pump(const Duration(seconds: 12)); // qua đoạn đứng yên đầu
    final x1 = _dx(tester);
    expect(x1, lessThan(x0), reason: 'phải dịch sang trái');
    // Chạy đủ lâu thì quay đầu lại (không dừng ở cuối).
    var minX = x1;
    var returned = false;
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      final x = _dx(tester);
      if (x < minX) minX = x;
      if (x > minX + 1) returned = true;
    }
    expect(returned, isTrue);
    expect(find.text(long), findsOneWidget); // đọc đủ qua semantics/finder
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tắt animation hệ thống: rơi về dấu …, không ticker', (
    tester,
  ) async {
    await tester.pumpWidget(_host(long, disableAnim: true));
    await tester.pump();
    final t = tester.widget<Text>(find.text(long));
    expect(t.overflow, TextOverflow.ellipsis);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('bị hộp thoại phủ lên: dừng hẳn (không còn animation)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => Column(
              children: [
                SizedBox(width: 100, child: MarqueeText(long)),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: c,
                    builder: (_) => const AlertDialog(title: Text('x')),
                  ),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle(); // settle xong = không còn animation nào chạy
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('đổi sang chữ ngắn khi đang chạy: dừng, không ném', (
    tester,
  ) async {
    await tester.pumpWidget(_host(long));
    await tester.pump();
    await tester.pumpWidget(_host('ok', width: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
