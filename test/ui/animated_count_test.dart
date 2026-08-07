import 'package:boba_empire/ui/widgets/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(double value) => Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedCount(value, suffix: ' Xu'),
    );

void main() {
  testWidgets('lần dựng đầu hiện ngay giá trị (không animate)', (tester) async {
    await tester.pumpWidget(_host(500));
    expect(find.text('500 Xu'), findsOneWidget);
  });

  testWidgets('đổi giá trị: chạy mượt qua khoảng giữa rồi chốt đúng đích',
      (tester) async {
    await tester.pumpWidget(_host(0));
    expect(find.text('0 Xu'), findsOneWidget);

    // Đổi lên 1000: sau nửa thời lượng chưa tới đích, nhưng đã rời điểm đầu.
    await tester.pumpWidget(_host(1000));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0 Xu'), findsNothing);
    expect(find.text('1000 Xu'), findsNothing);

    // Chạy hết thời lượng → chốt đúng 1000.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('1.00K Xu'), findsOneWidget);
  });
}
