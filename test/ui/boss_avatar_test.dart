// BossAvatar: số sát thương bay lên khi tổng điểm tăng, im lặng khi giảm chuyển động / khi đã gục.
import 'package:boba_empire/ui/widgets/boss_avatar.dart';
import 'package:boba_empire/ui/widgets/mascot.dart' as mascot;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(int damage, {bool defeated = false, double hp = 0.5, double size = 52}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: BossAvatar(emoji: '🐉', damage: damage, hpFraction: hp, defeated: defeated, size: size),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => mascot.debugDisableMascotAnimation = false);
  tearDown(() => mascot.debugDisableMascotAnimation = true);

  testWidgets('tăng sát thương → hiện "-N" rồi tự tắt; lần dựng đầu không có', (tester) async {
    await tester.pumpWidget(_host(1000));
    expect(find.byKey(const Key('boss-damage')), findsNothing);
    await tester.pumpWidget(_host(1500));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('-500'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('boss-damage')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('giảm chuyển động: không hiệu ứng nào', (tester) async {
    mascot.debugDisableMascotAnimation = true;
    await tester.pumpWidget(_host(1000));
    await tester.pumpWidget(_host(9000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('boss-damage')), findsNothing);
  });

  testWidgets('bị hạ giữa chừng → ngã (💫); mở sẵn khi đã gục → nằm yên 💫 ngay', (tester) async {
    await tester.pumpWidget(_host(1000, hp: 0.1));
    await tester.pumpWidget(_host(2000, defeated: true, hp: 0));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('💫'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_host(2000, defeated: true, hp: 0));
    expect(find.text('💫'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nổi giận (máu thấp) và cỡ nhỏ 320px × chữ lớn không tràn', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(_host(1000, hp: 0.1));
    await tester.pumpWidget(_host(999999999, hp: 0.05));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
