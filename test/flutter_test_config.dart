import 'dart:async';
import 'dart:ui' as ui;

import 'package:boba_empire/ui/home_page.dart';
import 'package:boba_empire/ui/widgets/mascot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

/// flutter_test tự nạp file này cho MỌI test trong thư mục test/.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // Tắt animation Lottie lặp để pumpAndSettle không bị treo bởi ticker vô hạn.
  debugDisableMascotAnimation = true;
  // Không tự mở "Cách chơi" trong test (dialog modal che thao tác); test hướng
  // dẫn bật lại cục bộ.
  debugAutoShowTutorial = false;
  // Không tự mở popup điểm danh hằng ngày trong test (dialog modal che thao tác).
  debugAutoShowDaily = false;
  // Không tự mở cutscene cốt truyện trong test (dialog modal che thao tác); test
  // cốt truyện bật lại cục bộ.
  debugAutoShowStory = false;
  // Chạy MỌI test ở locale tiếng Việt để các assertion chuỗi VI hiện có giữ
  // nguyên. Đặt lại trong setUp vì binding reset test-values sau mỗi test.
  // Quét rò rỉ bộ nhớ (leak_tracker): chỉ khi chạy với --dart-define=LEAK_TEST=true
  //   flutter test --dart-define=LEAK_TEST=true test/ui/guild_chat_page_test.dart
  // Mặc định tắt vì chậm hơn và làm các test hiện có đỏ nếu phát hiện rò rỉ cũ.
  if (const bool.fromEnvironment('LEAK_TEST')) {
    LeakTesting.enable();
    LeakTesting.settings = LeakTesting.settings.withTrackedAll().withCreationStackTrace();
  }
  setUp(() {
    binding.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
  });
  await testMain();
}
