import 'dart:async';

import 'package:boba_empire/ui/widgets/mascot.dart';

/// flutter_test tự nạp file này cho MỌI test trong thư mục test/.
/// Tắt animation Lottie lặp để pumpAndSettle không bị treo bởi ticker vô hạn.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugDisableMascotAnimation = true;
  await testMain();
}
