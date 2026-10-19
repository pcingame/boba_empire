// showAppDialog: nảy vào (có animation) rồi ổn định ở kích thước thật; chạm nền đóng được; giảm chuyển động chỉ mờ; trả giá trị pop.
import 'package:boba_empire/ui/widgets/app_dialog.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(void Function(BuildContext) onTap) => MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => onTap(ctx), child: const Text('open')))),
      ),
    );

void main() {
  tearDown(() => mascot.debugDisableMascotAnimation = true);

  testWidgets('có animation: bắt đầu nhỏ hơn rồi về đúng kích thước; trả giá trị', (tester) async {
    mascot.debugDisableMascotAnimation = false;
    int? result;
    await tester.pumpWidget(_app((c) async {
      result = await showAppDialog<int>(
        context: c,
        builder: (ctx) => AlertDialog(
          title: const Text('hi'),
          actions: [TextButton(key: const Key('ok'), onPressed: () => Navigator.pop(ctx, 7), child: const Text('OK'))],
        ),
      );
    }));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 40));
    double scale() => tester
        .widget<ScaleTransition>(find.ancestor(of: find.byType(AlertDialog), matching: find.byType(ScaleTransition)).first)
        .scale
        .value;
    expect(scale(), lessThan(1), reason: 'đang phóng to từ nhỏ');
    await tester.pumpAndSettle();
    expect(scale(), 1);
    await tester.tap(find.byKey(const Key('ok')));
    await tester.pumpAndSettle();
    expect(result, 7);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('chạm nền đóng; barrierDismissible=false thì không', (tester) async {
    await tester.pumpWidget(_app((c) => showAppDialog<void>(context: c, builder: (_) => const AlertDialog(title: Text('hi')))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.pumpWidget(_app((c) => showAppDialog<void>(
        context: c, barrierDismissible: false, builder: (_) => const AlertDialog(title: Text('hi')))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('giảm chuyển động: không có ScaleTransition (chỉ mờ, không phóng to)', (tester) async {
    await tester.pumpWidget(_app((c) => showAppDialog<void>(context: c, celebrate: true, builder: (_) => const AlertDialog(title: Text('hi')))));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.ancestor(of: find.byType(AlertDialog), matching: find.byType(ScaleTransition)), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('hi'), findsOneWidget);
  });
}
