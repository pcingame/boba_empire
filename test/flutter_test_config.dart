import 'dart:async';
import 'dart:ui' as ui;

import 'package:boba_empire/ui/widgets/mascot.dart';
import 'package:flutter_test/flutter_test.dart';

/// flutter_test tự nạp file này cho MỌI test trong thư mục test/.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // Tắt animation Lottie lặp để pumpAndSettle không bị treo bởi ticker vô hạn.
  debugDisableMascotAnimation = true;
  // Chạy MỌI test ở locale tiếng Việt để các assertion chuỗi VI hiện có giữ
  // nguyên. Đặt lại trong setUp vì binding reset test-values sau mỗi test.
  setUp(() {
    binding.platformDispatcher.localesTestValue = const [ui.Locale('vi')];
  });
  await testMain();
}
