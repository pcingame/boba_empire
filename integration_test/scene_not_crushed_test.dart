// Mở khóa giai đoạn 2 thêm 3 nguồn thu cùng lúc. Trước đây shop "phình" ăn hết
// chỗ của _StageScene (Expanded) làm nền quán "co lại". Bố cục giờ chia theo
// flex (scene 42 / shop 58) → chiều cao cảnh quán KHÔNG đổi khi mở giai đoạn;
// shop chỉ thêm dòng và tự cuộn.
//
//   flutter test integration_test/scene_not_crushed_test.dart -d <udid>

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

  testWidgets('mở giai đoạn không làm cảnh quán bị co', (tester) async {
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

    final scene =
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_StageScene');
    final tile =
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ShopTile');
    expect(scene, findsOneWidget);
    final sceneBefore = tester.getSize(scene).height;
    expect(sceneBefore, greaterThan(120), reason: 'cảnh quán phải có chỗ tử tế');
    expect(tile, findsOneWidget); // chỉ "Trà đen" ở giai đoạn 1

    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.debugGrantCash(5000);
    await tester.pump();
    expect(ctrl.unlockStage(), isTrue);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final sceneAfter = tester.getSize(scene).height;
    debugPrint('SCENE HEIGHT before=$sceneBefore after=$sceneAfter');

    // Giai đoạn 2 thêm nguồn thu vào shop (list dài ra)...
    expect(tile, findsAtLeastNWidgets(3));
    // ...nhưng cảnh quán giữ nguyên chiều cao (flex, không bị "ăn").
    expect((sceneAfter - sceneBefore).abs(), lessThan(1.0),
        reason: 'cảnh quán bị co khi mở giai đoạn');
  });
}
