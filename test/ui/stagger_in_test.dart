// StaggerIn: chạy animation hữu hạn (mờ → rõ, dòng sau trễ hơn), kết thúc ở trạng thái bình thường; giảm chuyển động thì hiện thẳng.
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:boba_empire/ui/widgets/stagger_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _opacity(WidgetTester t, Key k) =>
    t.widget<Opacity>(find.descendant(of: find.byKey(k), matching: find.byType(Opacity)).first).opacity;

void main() {
  tearDown(() => mascot.debugDisableMascotAnimation = true);

  testWidgets('animation: bắt đầu mờ, dòng sau trễ hơn, rồi kết thúc rõ và hết khung chờ', (tester) async {
    mascot.debugDisableMascotAnimation = false;
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [
        StaggerIn(key: Key('a'), index: 0, child: Text('A')),
        StaggerIn(key: Key('b'), index: 8, child: Text('B')),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_opacity(tester, const Key('a')), greaterThan(0));
    expect(_opacity(tester, const Key('b')), 0, reason: 'dòng 8 trễ ~360ms');
    await tester.pumpAndSettle();
    expect(_opacity(tester, const Key('a')), 1);
    expect(_opacity(tester, const Key('b')), 1);
  });

  testWidgets('giảm chuyển động / test: không bọc animation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StaggerIn(key: Key('a'), index: 3, child: Text('A'))));
    expect(find.descendant(of: find.byKey(const Key('a')), matching: find.byType(Opacity)), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });
}
