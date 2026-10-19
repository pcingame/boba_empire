// CountUpText + showRewardBurst: chạy hữu hạn rồi dừng/tự gỡ; giảm chuyển động thì hiện thẳng / không overlay.
import 'package:boba_empire/ui/widgets/count_up.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/reward_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => mascot.debugDisableMascotAnimation = true);

  testWidgets('CountUpText: chạy từ giá trị cũ tới mới rồi dừng', (tester) async {
    mascot.debugDisableMascotAnimation = false;
    Widget app(double v) => MaterialApp(home: CountUpText(value: v, builder: (x) => x.round().toString()));
    await tester.pumpWidget(app(100));
    expect(find.text('100'), findsOneWidget);
    await tester.pumpWidget(app(200));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
    expect(mid, inInclusiveRange(101, 199));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
  });

  testWidgets('CountUpText: giảm chuyển động hiện thẳng; giá trị vô hạn không văng', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CountUpText(value: 500, builder: (x) => x.round().toString())));
    expect(find.text('500'), findsOneWidget);
    mascot.debugDisableMascotAnimation = false;
    await tester.pumpWidget(MaterialApp(home: CountUpText(value: double.infinity, builder: (x) => '$x')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('showRewardBurst: hiện nhãn, tự gỡ sau khi xong, không chặn chạm', (tester) async {
    mascot.debugDisableMascotAnimation = false;
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                taps++;
                showRewardBurst(ctx, emojis: const ['💎'], label: '+5 💎');
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('+5 💎'), findsOneWidget);
    await tester.tap(find.text('go'), warnIfMissed: false); // overlay không chặn chạm
    expect(taps, 2);
    await tester.pumpAndSettle();
    expect(find.text('+5 💎'), findsNothing);
  });

  testWidgets('showRewardBurst: giảm chuyển động thì không tạo overlay', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        return ElevatedButton(onPressed: () => showRewardBurst(ctx, label: 'X'), child: const Text('go'));
      }),
    ));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('X'), findsNothing);
  });
}
