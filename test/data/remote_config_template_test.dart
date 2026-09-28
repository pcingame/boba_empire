// `remote_config_template.json` là nội dung dán vào ô giá trị của tham số
// `boba_remote_config` trên Firebase Console. Nó PHẢI khớp giá trị đang biên
// dịch trong app — lệch thì lần publish đầu tiên đã âm thầm đổi cân bằng game.
import 'dart:io';

import 'package:boba_empire/data/remote_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = File('remote_config_template.json').readAsStringSync();
  final parsed = RemoteBalance.parseJsonParam(raw);
  final defaults = RemoteBalance.defaults();

  test('template có đúng bộ nút vặn như RemoteBalance', () {
    // Key không phải số (dòng ghi chú "_") bị parseJsonParam loại sẵn.
    expect(parsed.keys.toSet(), defaults.keys.toSet());
  });

  test('mọi giá trị trong template khớp giá trị biên dịch trong app', () {
    for (final entry in defaults.entries) {
      expect(
        parsed[entry.key]!.toDouble(),
        closeTo((entry.value as num).toDouble(), 1e-9),
        reason: entry.key,
      );
    }
  });

  test('không giá trị nào bị app bỏ qua vì ngoài khoảng hợp lệ', () {
    // applyValues bỏ qua số ngoài khoảng; template có số như vậy thì publish
    // lên cũng vô tác dụng — lỗi im lặng đúng kiểu khó tìm.
    expect(RemoteBalance.applyValues(parsed), 0,
        reason: 'khớp sẵn nên không nút nào phải đổi, và không nút nào bị loại');
  });

  group('parseJsonParam', () {
    test('bỏ qua key không phải số, giữ key số', () {
      final r = RemoteBalance.parseJsonParam(
        '{"_": "ghi chú", "prestigeK": 0.03, "m3Moves": 18}',
      );
      expect(r, {'prestigeK': 0.03, 'm3Moves': 18});
    });

    test('JSON hỏng / rỗng / không phải object → map rỗng, KHÔNG ném lỗi', () {
      expect(RemoteBalance.parseJsonParam(''), isEmpty);
      expect(RemoteBalance.parseJsonParam('   '), isEmpty);
      expect(RemoteBalance.parseJsonParam('{thiếu ngoặc'), isEmpty);
      expect(RemoteBalance.parseJsonParam('[1,2,3]'), isEmpty);
      expect(RemoteBalance.parseJsonParam('"chuỗi"'), isEmpty);
    });
  });
}
