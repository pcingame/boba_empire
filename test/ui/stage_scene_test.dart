// Mỗi giai đoạn phải có file cảnh riêng. Thiếu file thì `errorBuilder` nuốt
// lỗi và hiện nền trơn — người chơi tới giai đoạn đó thấy màn hình trống mà
// không có dấu hiệu gì báo là thiếu asset.
import 'dart:io';

import 'package:boba_empire/core/balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('có đủ ảnh cảnh cho mọi giai đoạn', () {
    final stages = Balance.stages.length;
    expect(stages, greaterThanOrEqualTo(18));
    for (var i = 1; i <= stages; i++) {
      expect(File('assets/scene/stage$i.png').existsSync(), isTrue,
          reason: 'thiếu assets/scene/stage$i.png (chạy scripts/make_scenes.py)');
    }
  });

  test('ảnh cảnh không rỗng và không quá nặng', () {
    for (var i = 1; i <= Balance.stages.length; i++) {
      final bytes = File('assets/scene/stage$i.png').lengthSync();
      expect(bytes, greaterThan(2000), reason: 'stage$i.png có vẻ rỗng');
      // Cảnh flat vài chục KB là bình thường; vượt 200KB là ai đó thả ảnh chụp
      // vào, sẽ phình app.
      expect(bytes, lessThan(200 * 1024), reason: 'stage$i.png quá nặng');
    }
  });
}
