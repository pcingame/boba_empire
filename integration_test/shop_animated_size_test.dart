// Kiểm chứng bản vá AnimatedSize cho panel shop: khi mở khóa giai đoạn 2 (thêm
// 3 nguồn thu cùng lúc), panel phải PHÌNH DẦN qua ~300ms chứ không nhảy tức
// thì trong 1 frame (vốn làm nền quán trông như "co lại").
//
// Chạy trên iOS Simulator:
//   xcrun simctl io booted recordVideo /tmp/shop.mp4 &   # ghi hình
//   flutter test integration_test/shop_animated_size_test.dart -d <udid>
//   kill %1                                              # dừng ghi hình

import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shop panel phình dần (AnimatedSize) khi mở khóa giai đoạn 2',
      (tester) async {
    // Tắt popup tự mở lúc khởi động để không che shop / treo teardown.
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BobaEmpireApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // AnimatedSize nằm trong widget shop (_Shop).
    final shopSize = find.descendant(
      of: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Shop'),
      matching: find.byType(AnimatedSize),
    );
    expect(shopSize, findsOneWidget);
    final beforeH = tester.getSize(shopSize).height;

    // Nạp tiền rồi mở khóa giai đoạn 2 (Kiosk) — thêm Trân châu, Thạch, Pudding.
    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.debugGrantCash(5000);
    await tester.pump();
    expect(ctrl.unlockStage(), isTrue);

    // Đo chiều cao panel qua từng frame trong cửa sổ animation 300ms.
    final heights = <double>[beforeH];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      heights.add(tester.getSize(shopSize).height);
    }
    // Chốt animation bằng vài frame nữa (không dùng pumpAndSettle vì app có
    // animation chạy liên tục).
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final afterH = tester.getSize(shopSize).height;

    debugPrint('SHOP HEIGHTS before=$beforeH frames=$heights after=$afterH');

    expect(afterH, greaterThan(beforeH), reason: 'panel phải cao hơn sau unlock');
    final animatedGradually =
        heights.any((h) => h > beforeH + 1 && h < afterH - 1);
    expect(animatedGradually, isTrue,
        reason: 'panel nhảy tức thì thay vì phình dần — AnimatedSize không ăn');
  });
}
