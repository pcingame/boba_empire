import 'dart:io';

import 'package:boba_empire/core/topup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hằng số SQL ↔ Dart của VIP phải khớp (cấp suy ra ở server từ mảng mốc EXP; trần
/// cấp của bảng vip_level).
void main() {
  final sql = File('supabase/accessory_market_schema.sql').readAsStringSync();

  test('mảng mốc EXP trong vip_level_for_exp khớp topupTiers', () {
    final m = RegExp(r'unnest\(array\[([\d,\s]+)\]::bigint\[\]\)').firstMatch(sql);
    expect(m, isNotNull);
    final server = m!.group(1)!.split(',').map((e) => int.parse(e.trim())).toList();
    expect(server, [for (final t in topupTiers) t.exp]);
  });

  test('trần cấp của vip_level và set_vip_level khớp số bậc', () {
    final n = topupTiers.length;
    expect(sql, contains('check (level between 1 and $n)'));
    expect(sql, contains('least(p_level, $n)'));
  });

  test('web: tab VIP gọi RPC vip_leaderboard_top có trong SQL', () {
    expect(sql, contains('function vip_leaderboard_top('));
    expect(File('docs/assets/site.js').readAsStringSync(),
        contains("rpc('vip_leaderboard_top')"));
  });
}
