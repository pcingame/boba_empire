// Sinh ảnh chụp màn hình cho store — chạy được trên iPad lẫn iPhone.
//
//   ./scripts/shoot.sh <udid-máy-ảo> [ngôn_ngữ]
//
// hoặc gọi thẳng:
//
//   flutter drive --driver=test_driver/screenshots.dart \
//     --target=integration_test/screenshots_test.dart \
//     -d <udid> --dart-define=SHOT_LOCALE=vi
//
// Vì sao là integration_test chứ không phải gõ tay trên máy ảo: thao tác chạy
// BÊN TRONG app nên không vướng quyền Accessibility của macOS (thử điều khiển
// Simulator bằng AppleScript đã thất bại), và chụp lại được y hệt mỗi lần UI
// đổi — với 6 ngôn ngữ thì chụp tay là không kham nổi.
//
// KHÔNG dùng save mới tinh: màn hình lúc đó chỉ có 1 dòng shop và một dải
// trống lớn (đo được: khung shop 526dp, không cuộn được dòng nào trên iPad).
// Ảnh store phải cho thấy game lúc đang chơi thật.
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

/// Ngôn ngữ của lượt chụp này. Đổi bằng `--dart-define=SHOT_LOCALE=en`.
const String kLocale = String.fromEnvironment('SHOT_LOCALE', defaultValue: 'vi');

/// Save "đang chơi giữa chừng" — đủ giàu để shop đầy màn, đủ nhiều Sao/💎 để
/// các hộp thoại có số đẹp, nhưng KHÔNG phá kỷ lục gì (ảnh store không nên
/// khoe số vô lý).
GameState _showcaseSave(int now) {
  final s = GameState.newGame(nowMillis: now)
    ..tutorialSeen = true
    ..m3HowToSeen = true
    ..stage = 6
    ..money = 4.2e9
    ..gems = 640
    ..tapValue = 12
    ..lifetimeEarnings = 8.7e15
    ..prestigeStars = 1840
    ..storyChapter = 4
    ..m3Stars.addAll([3, 3, 2, 3, 1, 2])
    // Tắt quảng cáo cho ảnh store: bản debug dùng test unit của Google nên
    // banner hiện đúng chữ "Test mode / Google test ad" — đưa cái đó lên
    // App Store vừa xấu vừa dễ bị từ chối. `adsRemoved` là đường có sẵn
    // trong game (người mua gói gỡ QC), không phải cờ riêng cho test.
    ..adsRemoved = true
    // PHẢI là thời điểm hiện tại: để 0 thì game tính là vắng mặt từ 1970 và
    // bật hộp "thu nhập lúc vắng" che kín màn — mọi cú bấm sau đó trượt vào
    // lớp chặn của hộp thoại (lần chạy trước hỏng đúng vì cái này).
    ..lastSeenMillis = now
    ..firstPlayedMillis = now;
  for (final g in const [
    'black_tea', 'milk_tea', 'boba', 'fruit_tea',
    'cheese_tea', 'matcha', 'taro', 'brown_sugar',
  ]) {
    s.levels[g] = 30;
  }
  return s;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chụp ảnh store — $kLocale', (tester) async {
    // Chặn mọi popup tự bật, nếu không nó che đúng thứ cần chụp.
    home.debugAutoShowTutorial = false;
    home.debugAutoShowDaily = false;
    home.debugAutoShowStory = false;

    // iOS bắt buộc bước này trước khi chụp được; Android thì không cần và gọi
    // vào sẽ ném, nên bọc try.
    try {
      await binding.convertFlutterSurfaceToImage();
    } catch (_) {}

    SharedPreferences.setMockInitialValues({'flutter.app_locale': kLocale});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await GameStorage(prefs).save(_showcaseSave(now), nowMillis: now);
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const BobaEmpireApp()),
    );
    await settle(tester);
    // Hộp "Chào mừng trở lại" (thu nhập lúc vắng) vẫn bật dù save đóng dấu
    // thời gian hiện tại: bản thân việc build + cài app đã mất vài chục giây,
    // đủ để game tính ra tiền offline. Nó đặt barrierDismissible: false nên
    // bấm ra ngoài KHÔNG đóng được — phải bấm đúng nút.
    await _dismissBlockingDialog(tester);

    Future<void> shoot(String name) async {
      await settle(tester);
      await binding.takeScreenshot('${kLocale}_$name');
    }

    // 1. Màn chính — thứ quan trọng nhất, quyết định lượt cài.
    await shoot('1_home');

    // 2. Kho Sao (Nhượng quyền): cho thấy chiều sâu meta-game.
    await tester.tap(find.byKey(const Key('prestige-button')));
    await shoot('2_prestige');
    await _closeDialog(tester);

    // 3. Thành tựu.
    await tester.tap(find.byKey(const Key('achievements-button')));
    await shoot('3_achievements');
    await _closeDialog(tester);

    // 4. Cửa hàng 💎.
    await tester.tap(find.byKey(const Key('gem-shop-button')));
    await shoot('4_gemshop');
    await _closeDialog(tester);

    // 5. Hành trình Trân Châu Rơi (lưới màn).
    await tester.tap(find.byKey(const Key('match3-button')));
    await shoot('5_pearls_journey');

    // 6. Đang chơi Trân Châu Rơi — bàn cờ là thứ dễ "bán" nhất của chế độ này.
    await tester.tap(find.text('1').first);
    await shoot('6_pearls_play');
  });
}

/// Đóng hộp thoại đang mở bằng nút Đóng/Huỷ, không phụ thuộc chữ theo ngôn
/// ngữ: bấm ra ngoài vùng hộp (barrier) là cách duy nhất chạy đúng cho cả 6.
Future<void> _closeDialog(WidgetTester tester) async {
  await tester.tapAt(const Offset(12, 12));
  await settle(tester);
}

/// Thay cho `pumpAndSettle`: game idle có tick 1 giây chạy mãi, nên hàm đó
/// KHÔNG BAO GIỜ trả về — lần chạy đầu treo cứng ở "request_data message is
/// taking a long time". Bơm một số khung cố định là đủ cho chuyển trang và
/// animation mở hộp thoại.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Đóng hộp thoại KHÔNG cho bấm ra ngoài (hộp "thu nhập lúc vắng" đặt
/// `barrierDismissible: false`) bằng cách bấm nút chữ đầu tiên của nó — không
/// phụ thuộc chữ trên nút nên chạy đúng cho cả 6 ngôn ngữ.
Future<void> _dismissBlockingDialog(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    if (find.byType(Dialog).evaluate().isEmpty) return;
    final btn = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextButton),
    );
    if (btn.evaluate().isEmpty) return;
    await tester.tap(btn.first, warnIfMissed: false);
    await settle(tester);
  }
}
