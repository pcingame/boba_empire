// `remote_config_template.json` là file dán vào Firebase Console. Nó PHẢI khớp
// giá trị đang biên dịch trong app — lệch thì lần publish đầu tiên đã âm thầm
// đổi cân bằng game mà không ai cố ý.
import 'dart:convert';
import 'dart:io';

import 'package:boba_empire/data/remote_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tpl = jsonDecode(
    File('remote_config_template.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final params = (tpl['parameters'] as Map<String, dynamic>)
      .cast<String, Map<String, dynamic>>();
  final defaults = RemoteBalance.defaults();

  test('template có đúng bộ tham số như RemoteBalance', () {
    expect(params.keys.toSet(), defaults.keys.toSet());
  });

  test('mọi giá trị trong template khớp giá trị biên dịch trong app', () {
    for (final entry in defaults.entries) {
      final node = params[entry.key]!;
      expect(node['valueType'], 'NUMBER', reason: entry.key);
      final raw = (node['defaultValue'] as Map)['value'] as String;
      expect(
        double.parse(raw),
        closeTo((entry.value as num).toDouble(), 1e-9),
        reason: entry.key,
      );
    }
  });

  test('giá trị trong template nằm trong khoảng hợp lệ của app', () {
    // applyValues bỏ qua giá trị ngoài khoảng; nếu template có số bị bỏ qua thì
    // publish lên cũng vô tác dụng — lỗi im lặng đúng kiểu khó tìm.
    final values = {
      for (final e in params.entries)
        e.key: double.parse((e.value['defaultValue'] as Map)['value'] as String)
    };
    expect(RemoteBalance.applyValues(values), 0,
        reason: 'khớp sẵn nên không nút nào phải đổi, và không nút nào bị bỏ qua');
  });
}
