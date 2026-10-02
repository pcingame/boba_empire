// Đo hiệu năng khung hình (build/raster) của các thao tác nặng nhất — chạy ở
// PROFILE mode trên máy thật (debug/simulator không đại diện).
//
//   flutter drive --profile --no-dds -d `thiết bị` \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart \
//   (đặt PERF_OUT=build/perf/`nhãn`.json trước lệnh để chọn file ra)
//
// LƯU Ý khi đọc kết quả: khung do Timer lên lịch (vd IdleMascot 30Hz) bị harness này
// đếm GẤP ĐÔI (đo ngoài harness: app thật đứng yên ~30 khung/giây, trong khi
// harness báo ~60). Số "khung" ở kịch bản 1_idle chỉ so sánh được trước/sau khi
// cùng loại animation; thời gian build/raster MỖI khung thì đáng tin.
//
// Dùng SharedPreferences trong bộ nhớ (setMockInitialValues) nên KHÔNG đụng vào
// ván chơi thật trên máy. Không khởi tạo Firebase/Supabase/quảng cáo — chỉ đo UI.

import 'package:boba_empire/core/models.dart';
import 'package:boba_empire/data/game_storage.dart';
import 'package:boba_empire/main.dart';
import 'package:boba_empire/state/game_providers.dart';
import 'package:boba_empire/ui/home_page.dart' as home;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hiệu năng màn chính', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;

    // Ván "cuối game": giai đoạn 18, đủ tiền → shop dài nhất, mọi ô đều mua được.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await GameStorage(prefs).save(
      GameState.newGame(nowMillis: now)
        ..stage = 18
        ..money = 1e60
        ..gems = 500
        ..storyChapter = 30,
      nowMillis: now, // lưu đúng lúc "bây giờ" → không có popup tiền offline
    );
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const BobaEmpireApp(),
    ));
    // KHÔNG pumpAndSettle: màn chính có animation lặp vô hạn nên không bao giờ "yên".
    await tester.pump(const Duration(seconds: 2));

    // 1. Đứng yên: tick 1Hz + AnimatedCount + animation lặp (cup nhún...).
    await binding.watchPerformance(() async {
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }, reportKey: '1_idle_10s');

    // 2. Chạm cốc liên tục (~25 lần/giây): pop + floater + combo + haptic.
    final circle = find.byKey(const Key('tap-circle'));
    expect(circle, findsOneWidget);
    await binding.watchPerformance(() async {
      for (var i = 0; i < 80; i++) {
        await tester.tap(circle);
        await tester.pump(const Duration(milliseconds: 40));
      }
    }, reportKey: '2_tap_cup_x80');

    // 3. Cuộn danh sách shop dài (bóng đổ kép trên từng ô).
    final list = find.byType(ListView).last;
    await binding.watchPerformance(() async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -600), 3000);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.fling(list, const Offset(0, 600), 3000);
        await tester.pump(const Duration(milliseconds: 700));
      }
    }, reportKey: '3_scroll_shop');

    // 4. Mở/đóng các hộp thoại & trang nặng (chuyển trang + dựng nội dung).
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    await binding.watchPerformance(() async {
      for (final key in const [
        'gem-shop-button',
        'prestige-button',
        'achievements-button',
        'compete-button',
        'match3-button',
      ]) {
        await tester.tap(find.byKey(Key(key)));
        await tester.pump(const Duration(milliseconds: 700));
        nav.popUntil((r) => r.isFirst);
        await tester.pump(const Duration(milliseconds: 500));
      }
    }, reportKey: '4_open_close_screens');
  });
}
