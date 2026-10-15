// Ép liên kết email Ở SERVER cho mọi bảng xếp hạng có ghi từ client: mọi policy INSERT/UPDATE của hàng-của-mình
// phải kèm is_linked_user(), mọi RPC nộp điểm phải chặn ẩn danh. Kiểm động nằm ở
// supabase/tests/linked_enforce_scenarios.sql (scripts/test_lb_rewards_sql.sh); test này chặn việc thêm bảng/RPC
// mới mà quên cổng.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _sql(String name) => File('supabase/$name.sql').readAsStringSync();

void main() {
  // Bảng ghi trực tiếp bằng policy: schema → số policy ghi (insert + update; Phá đảo chỉ insert).
  const policyTables = {
    'leaderboard_schema': 3,
    'm3_leaderboard_schema': 3,
    'accessory_leaderboard_schema': 3,
    'recipe_leaderboard_schema': 3,
    'recipe_order_leaderboard_schema': 3,
    'story_speedrun_schema': 1,
    'story_speedrun2_schema': 1,
    'story_speedrun3_schema': 1,
    'story_speedrun4_schema': 1,
  };

  policyTables.forEach((file, expected) {
    test('$file: mọi policy ghi hàng-của-mình kèm is_linked_user()', () {
      final sql = _sql(file);
      expect(sql, contains('create or replace function is_linked_user()'), reason: 'thiếu định nghĩa hàm');
      final own = RegExp(r'auth\.uid\(\) = user_id[^;]*').allMatches(sql).toList();
      expect(own.length, greaterThanOrEqualTo(expected - 1), reason: '$file: số chỗ kiểm chủ sở hữu');
      for (final m in RegExp(r'auth\.uid\(\) = user_id').allMatches(sql)) {
        final tail = sql.substring(m.start, (m.start + 60).clamp(0, sql.length));
        expect(tail, contains('is_linked_user()'), reason: '$file: policy ghi không kèm is_linked_user() → "${tail.trim()}"');
      }
    });
  });

  test('RPC nộp điểm (VIP, Sự kiện) chặn tài khoản chưa liên kết', () {
    final vip = _sql('accessory_market_schema');
    final i = vip.indexOf('create or replace function submit_vip_exp');
    expect(vip.substring(i, i + 900), contains("if not is_linked_user()"));
    expect(vip.substring(i, i + 900), contains("email link required"));
    final ev = _sql('event_leaderboard_schema');
    final j = ev.indexOf('create or replace function event_leaderboard_submit');
    expect(ev.substring(j, j + 800), contains("if not is_linked_user()"));
  });

  test('thưởng hạng cũ leaderboard_claim_reward không trả cho tài khoản chưa liên kết', () {
    final sql = _sql('leaderboard_schema');
    final i = sql.indexOf('create or replace function leaderboard_claim_reward');
    final body = sql.substring(i, sql.indexOf(r'$$;', i + 60));
    expect(body, contains('is_linked_user()'));
  });

  test('is_linked_user: security definer, đọc auth.users.is_anonymous, chỉ authenticated gọi được — mọi file định nghĩa giống nhau', () {
    final defs = <String>{};
    for (final f in [...policyTables.keys, 'accessory_market_schema', 'event_leaderboard_schema', 'recipe_daily_schema']) {
      final sql = _sql(f);
      final m = RegExp(r'create or replace function is_linked_user\(\) returns boolean\s+language sql stable security definer set search_path = public as \$\$\s+(select exists[^$]*)\$\$;', dotAll: true).firstMatch(sql);
      expect(m, isNotNull, reason: '$f: định nghĩa is_linked_user lệch khuôn');
      defs.add(m!.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim());
      expect(sql, contains('revoke all on function is_linked_user() from public, anon'), reason: f);
      expect(sql, contains('grant execute on function is_linked_user() to authenticated'), reason: f);
    }
    expect(defs.length, 1, reason: 'các bản định nghĩa phải trùng nhau');
    expect(defs.single, contains('not u.is_anonymous'));
  });
}
