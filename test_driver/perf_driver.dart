/// Driver cho `integration_test/perf_test.dart`: ghi số đo khung hình ra JSON.
///
///   PERF_OUT=build/perf/`nhãn`.json flutter drive --profile --no-dds \
///     -d `thiết bị` --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

// Driver chạy trên máy host nên đọc BIẾN MÔI TRƯỜNG (`--dart-define` chỉ tới app).
final String _out = Platform.environment['PERF_OUT'] ?? 'build/perf/result.json';

Future<void> main() => integrationDriver(
      responseDataCallback: (Map<String, dynamic>? data) async {
        if (data == null) return;
        final file = File(_out);
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
        stdout.writeln('đã ghi: ${file.path}');
      },
    );
