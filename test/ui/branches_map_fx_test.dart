// Hiệu ứng bản đồ chi nhánh: ngày/đêm theo giờ, máy bay ✈️ dọc đường nối (tắt khi giảm chuyển động/máy yếu),
// hiệu ứng khai trương khi mở chi nhánh mới.

import 'package:boba_empire/ui/branches_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 400, height: 400, child: child)),
);

BranchesMap _map(Map<String, int> levels, {bool? animations, int? now}) =>
    BranchesMap(
      levels: levels,
      since: {for (final k in levels.keys) k: 0},
      stage: 18,
      now: now ?? DateTime(2026, 1, 1, 12).millisecondsSinceEpoch,
      nameOf: (id) => id,
      onPin: (_) {},
      animations: animations,
    );

void main() {
  group('ngày / đêm', () {
    test(
      'độ đêm: trưa 0, nửa đêm 1, chuyển dần lúc chiều tối và bình minh',
      () {
        expect(mapNightness(12), 0);
        expect(mapNightness(17.5), 0);
        expect(mapNightness(18.5), closeTo(0.5, 1e-9));
        expect(mapNightness(19.5), 1);
        expect(mapNightness(23), 1);
        expect(mapNightness(3), 1);
        expect(mapNightness(5), 1);
        expect(mapNightness(6), closeTo(0.5, 1e-9));
        expect(mapNightness(7), 0);
        expect(mapNightness(24 + 12), 0, reason: 'tuần hoàn theo 24 giờ');
      },
    );

    test(
      'sắc cam hoàng hôn/bình minh chỉ có ở hai khoảng chuyển, đỉnh giữa khoảng',
      () {
        expect(mapWarmth(12), 0);
        expect(mapWarmth(2), 0);
        expect(mapWarmth(18.5), closeTo(1, 1e-9));
        expect(mapWarmth(6), closeTo(1, 1e-9));
        expect(mapWarmth(17.5), closeTo(0, 1e-9));
      },
    );

    testWidgets('vẽ được ở mọi giờ (ngày, hoàng hôn, đêm) với đèn thành phố', (
      tester,
    ) async {
      for (final h in [12, 18, 23, 6]) {
        await tester.pumpWidget(
          _app(
            _map(
              {'saigon': 3, 'hanoi': 2},
              animations: false,
              now: DateTime(2026, 1, 1, h).millisecondsSinceEpoch,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'giờ $h');
      }
    });

    test('painter chỉ vẽ lại khi đổi đáng kể', () {
      final a = BranchesMapPainter(
        route: const [Offset(1, 1)],
        dark: false,
        night: 0.5,
        lights: const [Offset(1, 1)],
      );
      expect(
        a.shouldRepaint(
          BranchesMapPainter(
            route: const [Offset(1, 1)],
            dark: false,
            night: 0.51,
            lights: const [Offset(1, 1)],
          ),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          BranchesMapPainter(
            route: const [Offset(1, 1)],
            dark: false,
            night: 0.7,
            lights: const [Offset(1, 1)],
          ),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          BranchesMapPainter(
            route: const [Offset(1, 1)],
            dark: false,
            night: 0.5,
            lights: const [Offset(2, 2)],
          ),
        ),
        isTrue,
      );
    });
  });

  test(
    'cung bay: t=0 ở điểm đầu, t=1 ở điểm cuối, nhô lên phía trên đường thẳng',
    () {
      const a = Offset(100, 300), b = Offset(500, 300);
      expect(branchCurveAt(a, b, 0).$1, a);
      final end = branchCurveAt(a, b, 1).$1;
      expect((end - b).distance, lessThan(1e-9));
      expect(
        branchCurveAt(a, b, 0.5).$1.dy,
        lessThan(300),
        reason: 'cung cong lên trên',
      );
    },
  );

  group('máy bay', () {
    testWidgets(
      'có ≥2 chi nhánh đã mở và bật hiệu ứng → có máy bay, bay (đổi vị trí theo thời gian)',
      (tester) async {
        await tester.pumpWidget(
          _app(_map({'saigon': 1, 'hanoi': 1, 'tokyo': 1}, animations: true)),
        );
        await tester.pump();
        expect(find.byKey(const Key('branch-planes')), findsOneWidget);
        expect(find.text('✈️'), findsWidgets);
        final p0 = tester.getTopLeft(find.text('✈️').first);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.getTopLeft(find.text('✈️').first), isNot(p0));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'tắt hiệu ứng (giảm chuyển động/máy yếu) hoặc chưa đủ 2 chi nhánh → không có máy bay',
      (tester) async {
        await tester.pumpWidget(
          _app(_map({'saigon': 1, 'hanoi': 1}, animations: false)),
        );
        await tester.pump();
        expect(find.byKey(const Key('branch-planes')), findsNothing);
        await tester.pumpWidget(_app(_map({'saigon': 1}, animations: true)));
        await tester.pump();
        expect(
          find.byKey(const Key('branch-planes')),
          findsNothing,
          reason: 'một chi nhánh thì không có đường nối',
        );
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'mặc định (animations = null) tôn trọng giảm chuyển động: trong test luôn tắt',
      (tester) async {
        await tester.pumpWidget(_app(_map({'saigon': 1, 'hanoi': 1})));
        await tester.pump();
        expect(find.byKey(const Key('branch-planes')), findsNothing);
      },
    );

    testWidgets(
      'mở thêm chi nhánh thứ hai giữa chừng → máy bay xuất hiện; không rò ticker',
      (tester) async {
        await tester.pumpWidget(_app(_map({'saigon': 1}, animations: true)));
        await tester.pump();
        expect(find.byKey(const Key('branch-planes')), findsNothing);
        await tester.pumpWidget(
          _app(_map({'saigon': 1, 'hanoi': 1}, animations: true)),
        );
        await tester.pump();
        expect(find.byKey(const Key('branch-planes')), findsOneWidget);
        await tester.pumpWidget(
          const SizedBox(),
        ); // dispose: nếu ticker còn chạy, test sẽ báo
      },
    );
  });

  group('khai trương', () {
    testWidgets(
      'chi nhánh mới mở → hiệu ứng bung ra quanh ghim rồi tự hết sau ~2,2 giây',
      (tester) async {
        await tester.pumpWidget(_app(_map({'saigon': 1}, animations: true)));
        await tester.pump();
        expect(
          find.byKey(const Key('branch-burst-saigon')),
          findsNothing,
          reason: 'đã mở sẵn từ đầu thì không có',
        );
        await tester.pumpWidget(
          _app(_map({'saigon': 1, 'danang': 1}, animations: true)),
        );
        await tester.pump();
        expect(find.byKey(const Key('branch-burst-danang')), findsOneWidget);
        expect(find.byKey(const Key('branch-burst-saigon')), findsNothing);
        expect(find.text('🎉'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(find.byKey(const Key('branch-burst-danang')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.pump();
        expect(find.byKey(const Key('branch-burst-danang')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'phát hiện chi nhánh mới dù bản đồ mức độ là CÙNG một instance bị sửa tại chỗ',
      (tester) async {
        final levels = <String, int>{'saigon': 1};
        await tester.pumpWidget(_app(_map(levels, animations: true)));
        await tester.pump();
        levels['hanoi'] = 1; // snapshot dùng chung instance: old == new
        await tester.pumpWidget(_app(_map(levels, animations: true)));
        await tester.pump();
        expect(find.byKey(const Key('branch-burst-hanoi')), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'nâng cấp (đã mở rồi) không có khai trương; tắt hiệu ứng thì không có',
      (tester) async {
        await tester.pumpWidget(_app(_map({'saigon': 1}, animations: true)));
        await tester.pump();
        await tester.pumpWidget(_app(_map({'saigon': 2}, animations: true)));
        await tester.pump();
        expect(find.byKey(const Key('branch-burst-saigon')), findsNothing);
        await tester.pumpWidget(
          _app(_map({'saigon': 2, 'danang': 1}, animations: false)),
        );
        await tester.pump();
        expect(find.byKey(const Key('branch-burst-danang')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
