import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/widgets/animated_count.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ngân sách chiều cao màn chính: cảnh quán đủ cao để thấy trọn xe (theo tỉ lệ
/// tranh, không theo flex), Auto-buy không chiếm hàng cố định, 📖 ⚙ cạnh số Coins.
void main() {
  Future<void> pump(WidgetTester tester,
      {required double w,
      required double h,
      bool autoBuy = false,
      double topInset = 0}) async {
    tester.view.physicalSize = Size(w * 3, h * 3);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(top: topInset * 3);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await GameStorage(prefs).save(
        GameState.newGame(nowMillis: 0)
          ..stage = 3
          ..prestigeAutoBuyLevel = autoBuy ? 1 : 0,
        nowMillis: 0);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => 0),
      ],
      child: const BobaEmpireApp(),
    ));
    await tester.pumpAndSettle();
  }

  // (rộng, cao, cảnh tối thiểu để thấy trọn xe ≈ 0.62 × rộng)
  for (final (w, h) in [(360.0, 780.0), (393.0, 852.0), (411.0, 915.0), (430.0, 932.0)]) {
    testWidgets('${w.toInt()}x${h.toInt()}: cảnh quán đủ cao để thấy trọn xe',
        (tester) async {
      await pump(tester, w: w, h: h);
      final scene = tester.getSize(find.byKey(const Key('stage-scene')));
      expect(scene.height, greaterThanOrEqualTo(w * 0.62),
          reason: 'cảnh ${scene.height} < ${w * 0.62} → xe bị cắt');
      // Và danh sách shop vẫn còn chỗ (≥ 1 dòng nâng cấp ~96dp sau tiêu đề giai đoạn).
      expect(find.byType(AppBar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('màn thấp 360x640: cảnh không quá 55% phần còn lại (shop còn chỗ)',
      (tester) async {
    await pump(tester, w: 360, h: 640);
    final scene = tester.getSize(find.byKey(const Key('stage-scene')));
    final header = tester.getTopLeft(find.byKey(const Key('stage-header-name')));
    expect(header.dy, lessThan(640 - 120)); // tiêu đề giai đoạn còn trên thanh dưới
    expect(scene.height, lessThan(640 * 0.5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Auto-buy nằm TRONG danh sách (cuộn cùng list), không phải hàng cố định',
      (tester) async {
    await pump(tester, w: 360, h: 780, autoBuy: true);
    expect(
        find.descendant(
            of: find.byType(ListView), matching: find.byType(Switch)),
        findsOneWidget);
    // Cảnh vẫn đủ cao khi có Auto-buy (không bị bóp thêm một hàng).
    final scene = tester.getSize(find.byKey(const Key('stage-scene')));
    expect(scene.height, greaterThanOrEqualTo(360 * 0.62));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chưa mở Auto-buy: không có Switch nào', (tester) async {
    await pump(tester, w: 360, h: 780, autoBuy: false);
    expect(find.byType(Switch), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('📖 ⚙ hai bên số Coins, bấm được và chừa thanh trạng thái',
      (tester) async {
    await pump(tester, w: 360, h: 780, topInset: 28);
    final story = find.byKey(const Key('story-log-button'));
    final settings = find.byKey(const Key('settings-button'));
    expect(tester.getTopLeft(story).dy, greaterThanOrEqualTo(28)); // dưới status bar
    // Cùng hàng với số Coins, 📖 bên trái, ⚙ bên phải.
    final coins = tester.getCenter(find.byType(AnimatedCount));
    expect(tester.getCenter(story).dx, lessThan(coins.dx));
    expect(tester.getCenter(settings).dx, greaterThan(coins.dx));
    expect((tester.getCenter(story).dy - coins.dy).abs(), lessThan(24));
    // Vùng chạm đủ lớn (≥ 40dp) dù đã thu gọn để nhường chỗ.
    expect(tester.getSize(story).width, greaterThanOrEqualTo(40));
    expect(tester.getSize(settings).height, greaterThanOrEqualTo(40));
    await tester.pumpWidget(const SizedBox());
  });
}
