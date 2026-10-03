/// Driver cho `integration_test/screenshots_test.dart`: nhận byte ảnh do app
/// gửi về rồi ghi ra `assets/store/screenshots/<thiết bị>/`.
///
/// Xem hướng dẫn chạy ở đầu `integration_test/screenshots_test.dart`.
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Thư mục con cho từng loại máy — ảnh iPad và iPhone có kích thước khác nhau
/// và App Store đòi riêng từng bộ, trộn chung là nộp nhầm.
///
/// Đọc từ BIẾN MÔI TRƯỜNG `SHOT_DIR`: `--dart-define` của `flutter drive` chỉ vào
/// app chứ KHÔNG vào driver này (bug cũ: ảnh iPhone luôn rơi vào thư mục ipad và
/// đè ảnh iPad). scripts/shoot.sh đã export biến này.
final String _outDir = Platform.environment['SHOT_DIR'] ?? 'assets/store/screenshots/ipad';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? _]) async {
        final dir = Directory(_outDir);
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final file = File('${dir.path}/$name.png');
        file.writeAsBytesSync(bytes);
        stdout.writeln('ảnh: ${file.path} (${bytes.length ~/ 1024} KB)');
        return true;
      },
    );
