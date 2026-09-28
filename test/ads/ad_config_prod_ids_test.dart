// Dán nhầm App ID (dấu `~`) vào chỗ unit id (dấu `/`) là lỗi IM LẶNG: SDK
// không tải được quảng cáo mà không báo gì, và chỉ lộ ra ở bản release. Đọc
// thẳng file cấu hình để soi vì các hằng số này là private.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final src = File('lib/ads/ad_config.dart').readAsStringSync();

  /// Các hằng số id THẬT: tên kết thúc bằng `Prod`.
  final prodIds = RegExp(r"static const String (_\w*Prod)\s*=\s*\n?\s*'([^']*)'")
      .allMatches(src)
      .map((m) => (m.group(1)!, m.group(2)!))
      .toList();

  test('tìm thấy đủ các hằng số id thật', () {
    expect(prodIds.length, greaterThanOrEqualTo(4),
        reason: 'đổi tên hằng số thì sửa cả regex ở test này');
  });

  test('id thật phải là UNIT id (ca-app-pub-XXX/YYY), không phải App ID', () {
    final unitId = RegExp(r'^ca-app-pub-\d+/\d+$');
    for (final (name, value) in prodIds) {
      if (value.isEmpty) continue; // rỗng = chưa tạo trên AdMob, hợp lệ
      expect(value.contains('~'), isFalse,
          reason: '$name đang là App ID chứ không phải unit id');
      expect(unitId.hasMatch(value), isTrue, reason: '$name sai định dạng');
    }
  });

  test('không lẫn test id của Google vào hằng số thật', () {
    for (final (name, value) in prodIds) {
      expect(value.startsWith('ca-app-pub-3940256099942544'), isFalse,
          reason: '$name đang là test id của Google');
    }
  });
}
