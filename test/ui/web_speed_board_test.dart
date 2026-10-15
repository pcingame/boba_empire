import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bảng "Phá đảo" trên web gộp 4 hồi (mỗi người một dòng ở hồi xa nhất): site.js gọi đủ 4 RPC
/// công khai (tồn tại trong SQL, cấp quyền anon) và nhãn "Hồi {n}" có đủ 7 ngôn ngữ.
void main() {
  test('site.js gộp 4 bảng tốc độ; RPC có trong SQL và mở cho anon', () {
    final js = File('docs/assets/site.js').readAsStringSync();
    expect(js, contains('rows: speedRows'));
    const rpcs = {
      'story_speedrun_top': 'supabase/story_speedrun_schema.sql',
      'story_speedrun2_top': 'supabase/story_speedrun2_schema.sql',
      'story_speedrun3_top': 'supabase/story_speedrun3_schema.sql',
      'story_speedrun4_top': 'supabase/story_speedrun4_schema.sql',
    };
    rpcs.forEach((rpc, file) {
      expect(js, contains("'$rpc'"), reason: 'site.js thiếu $rpc');
      final sql = File(file).readAsStringSync();
      expect(sql, contains('function $rpc('), reason: file);
      expect(sql, contains('$rpc(integer) to anon'), reason: '$rpc phải mở cho anon');
    });
  });

  test('nhãn "Hồi {n}" đủ 7 ngôn ngữ', () {
    for (final l in ['vi', 'en', 'es', 'id', 'pt', 'th', 'ko']) {
      final t = File('docs/assets/i18n/$l.js').readAsStringSync();
      expect(RegExp(r'"lbAct": "[^"]*\{n\}').hasMatch(t), isTrue, reason: l);
    }
  });
}
